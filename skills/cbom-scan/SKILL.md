---
name: cbom-scan
description: "Scan a repository and produce a CBOM — a Cryptographic Bill of Materials — inventorying every cryptographic asset (algorithms, keys, certificates, protocols, and the crypto libraries that implement them), then assess post-quantum and deprecated-crypto risk and map it to EU compliance obligations. Use this whenever the user wants a CBOM, a cryptographic inventory, a crypto audit, a \"what cryptography do we use\" report, post-quantum / PQC migration readiness, or help meeting the Cyber Resilience Act (CRA), NIS2, or the EU PQC Roadmap requirement for a cryptographic inventory — even when they just say \"scan this repo for crypto\", \"what algorithms are we using\", \"are we quantum-safe\", or \"generate a cbom\". Produces a standards-compliant CycloneDX 1.6 CBOM (ECMA-424) plus a human-readable compliance report. This is a read-only inventory-and-report task: not for generating an SBOM or scanning dependencies for known CVEs (that is SBOM/supply-chain tooling), and not for writing or implementing cryptographic code, configuring TLS, or renewing/rotating certificates — it inventories and assesses the cryptography already present, it does not change it."
---

# CBOM Scan — Cryptographic Bill of Materials

You are producing a **Cryptographic Bill of Materials (CBOM)** for a codebase: a machine-readable inventory of every cryptographic asset it uses, plus a risk-and-compliance assessment on top of that inventory.

CBOM is **not a bespoke format** — it is part of OWASP **CycloneDX**, which added native cryptography support in **v1.6** and is published as the international standard **ECMA-424**. The EU PQC Roadmap (June 2025) names CBOM as the standardized format for the cryptographic inventories that organizations must establish (the binding milestone is end of 2026, driven by the Cyber Resilience Act and NIS2). So the deliverable that matters to regulators is a *valid CycloneDX 1.6 CBOM*, not a prose summary — emit the JSON, then explain it.

## Why this is a reasoning task, not a regex dump

The point of a CBOM is to answer "what cryptography do we depend on, and how exposed is it?" — especially to the quantum threat (RSA/ECC fall to Shor's algorithm) and to already-broken primitives (MD5, SHA-1, DES, RC4). A list of grep hits is not that. Your job is to find the crypto that is actually *used*, attribute it to a real location in the code, classify its risk, and present it so a security or compliance owner can act. Be honest about what static, source-level detection can and cannot see — under-claiming with stated limitations is far more useful than a confident-looking inventory that missed the TLS termination in a sidecar.

## Two deliverables, always

1. **`cbom.json`** — a valid CycloneDX 1.6 CBOM. This is the artifact. It is what feeds tooling, regulators, and downstream PQC-migration planning.
2. **`CBOM-report.md`** — a human-readable report: executive summary, inventory tables, prioritized risk findings, PQC posture, and compliance mapping.

Write both into a `cbom/` directory at the scan target root (e.g. `cbom/cbom.json`, `cbom/CBOM-report.md`) unless the user asks otherwise.

## Workflow

### 1. Scope the scan

**Target:** `$ARGUMENTS` — a repo path, a subdirectory, or empty (use the current working directory). Confirm the target before scanning a large tree.

Identify what you're scanning: read the top-level layout and the dependency manifests to learn the languages and frameworks. **Exclude noise** so detection stays signal-rich: skip `node_modules/`, `vendor/`, `.git/`, build output (`dist/`, `build/`, `target/`, `bin/`, `obj/`), test fixtures of random keys, and minified bundles — but *do* note if a vendored crypto library is present, since it's still a dependency. Record the scope (paths included/excluded) for the report's methodology section.

### 2. Detect cryptographic assets

Read **`references/detection-patterns.md`** — it has the per-language library map, the grep/API patterns, the file globs for keys and certs, and the algorithm reference tables (deprecated, quantum-vulnerable, PQC-ready). Work through these source families:

- **Crypto libraries** — parse dependency manifests (`package.json`, `requirements.txt`/`pyproject.toml`, `go.mod`, `pom.xml`/`build.gradle`, `Cargo.toml`, `*.csproj`, `Gemfile`, `composer.json`) for known crypto providers (OpenSSL, BouncyCastle, pyca/cryptography, libsodium, WolfSSL, Go `crypto/*`, etc.). Each library is context for what algorithms are reachable.
- **Algorithm usage** — grep source for algorithm names and crypto API calls (AES, RSA, ECDSA/ECDH, DH, DSA, ChaCha20, SHA-1/256/512, MD5, HMAC, PBKDF2, bcrypt/scrypt/Argon2, and PQC: ML-KEM/Kyber, ML-DSA/Dilithium, SLH-DSA/SPHINCS+, FALCON). Capture the **file path and line number** of each — that becomes the CBOM's evidence.
- **Protocols & configuration** — TLS/SSL versions and cipher-suite config, SSH config, IPsec/IKE, mTLS settings, certificate pinning. These become `protocol` assets.
- **Keys, certificates & secrets material** — file globs (`*.pem`, `*.crt`, `*.cer`, `*.key`, `*.p12`, `*.pfx`, `*.jks`) and embedded PEM blocks (`-----BEGIN ...-----`). These become `certificate` and `related-crypto-material` assets. **Do not exfiltrate or print private key material**; record its existence, location, type, and (for certs) metadata only.

Detection is heuristic and source-level: it finds declared and called crypto, not crypto resolved dynamically at runtime, inside opaque binaries, or behind a managed service (KMS/HSM). Track what you could *not* determine — it goes in the report's limitations.

> **Higher-fidelity option:** for AST-level detection (resolving which concrete algorithm a generic `Cipher.getInstance(alg)` call uses), the reference file documents **CBOMkit** (IBM/PQCA, the de-facto open-source CBOM generator: Sonar Cryptography plugin + CBOMkit-theia). If the user wants production-grade depth or already runs it, point them there and offer to merge its output. Your self-contained scan is the default and works with no installs.

### 3. Build the CBOM (`cbom.json`)

Read **`references/cyclonedx-cbom-schema.md`** for the exact data model, field tables, allowed enum values, and a full valid example. Construct the document:

- Top level: `bomFormat: "CycloneDX"`, `specVersion: "1.6"`, a `serialNumber` (`urn:uuid:…`), `version: 1`, and `metadata` (timestamp, the scanned application as `metadata.component`, and this skill as `metadata.tools`).
- One `components[]` entry per **distinct** crypto asset, `type: "cryptographic-asset"`, with `cryptoProperties` shaped by its `assetType` (`algorithm` | `certificate` | `protocol` | `related-crypto-material`). Deduplicate: AES used in 12 files is one algorithm component with 12 `evidence.occurrences`, not 12 components.
- Attach **`evidence.occurrences[]`** (`location`, `line`) to every asset so each finding is traceable to the code. This traceability is what makes a CBOM auditable rather than anecdotal.
- Add **`dependencies[]`** to express relationships where you can see them (a protocol *uses* its cipher-suite algorithms; a certificate *uses* its signature algorithm; the application *depends on* its crypto libraries).
- Use `"other"`/`"unknown"` for enum fields you genuinely can't determine — never invent a value the schema doesn't define. Set `nistQuantumSecurityLevel` and `classicalSecurityLevel` per the reference tables.

### 4. Assess risk

For every algorithm asset, classify it (the reference tables give the lookup):
- **Quantum-vulnerable** — broken by a cryptographically-relevant quantum computer: all RSA, ECC (ECDSA/ECDH/EdDSA), Diffie-Hellman, DSA. These are the PQC-migration priority. (`nistQuantumSecurityLevel: 0` for public-key primitives with no quantum resistance.)
- **Classically broken / deprecated** — MD5, SHA-1, DES, 3DES, RC4, ECB mode, RSA/DH < 2048, plus password hashing with raw/fast hashes. These are *already* unsafe, independent of quantum.
- **Acceptable today** — AES-128+/GCM, SHA-256+, ChaCha20-Poly1305, Argon2/scrypt/bcrypt, X25519/Ed25519 (note: still quantum-vulnerable).
- **PQC-ready** — ML-KEM, ML-DSA, SLH-DSA, FALCON (FIPS 203/204/205).

Then run the bundled analyzer (`scripts/analyze_cbom.py`, relative to this skill's directory) to validate the JSON and get deterministic tallies for the report:

```bash
python3 <skill-dir>/scripts/analyze_cbom.py cbom/cbom.json
```

It checks the required CycloneDX 1.6 structure and prints counts by asset type and by risk class (deprecated / quantum-vulnerable / acceptable / PQC-ready), plus the priority findings with locations. If it reports validation errors, fix the JSON before writing the report — an invalid CBOM is the one thing that fails the compliance use-case outright. Use its tallies for the report so the numbers aren't hand-counted. (Pass `--json` for machine-readable output.)

### 5. Write the report (`CBOM-report.md`)

Read **`references/compliance-mapping.md`** for the CRA / NIS2 / EU PQC Roadmap obligations to map against. Use this exact structure:

```markdown
# Cryptographic Bill of Materials — <project name>

## Executive summary
<3–6 sentences: how many crypto assets, the headline risk (e.g. "N quantum-vulnerable, M deprecated"), and the single most important action. Plain language for a non-cryptographer.>

## Scan scope & method
<What was scanned, what was excluded, detection technique (source-level/heuristic), and explicit limitations / confidence. Name what you could not see.>

## Cryptographic inventory
<Tables by asset type: Algorithms (name, primitive, key size, where used, occurrences); Protocols; Certificates; Keys & key material; Crypto libraries.>

## Risk findings
<Prioritized, most severe first. Each: the asset, why it's risky (quantum / deprecated / weak params), where it appears (file:line), and the remediation. Lead with already-broken primitives, then quantum-vulnerable public-key crypto.>

## Post-quantum migration posture
<Quantum-vulnerable inventory, what to prioritize, crypto-agility observations, PQC-readiness. Reference NIST FIPS 203/204/205.>

## Compliance mapping
<Map findings to CRA, NIS2, and the EU PQC Roadmap obligations — see references/compliance-mapping.md. State what the CBOM itself satisfies (the inventory mandate) and what gaps remain.>

## Appendix
<Path to cbom.json, generation method/version, and how to regenerate or deepen the scan (CBOMkit).>
```

### 6. Close out

Tell the user the two file paths and the headline numbers (total assets, quantum-vulnerable count, deprecated count). State plainly that the inventory is source-level and where its blind spots are. Offer next steps: deeper AST scan via CBOMkit, wiring CBOM generation into CI, or drafting a PQC migration plan from the quantum-vulnerable list.

## Principles

- **The JSON is the deliverable; validate it.** A pretty report over an invalid CBOM fails the actual compliance purpose. Run the analyzer.
- **Every asset traces to code.** No occurrence-less assets unless it's a declared dependency with no callsite found (say so).
- **Honest beats impressive.** State detection limits. A CBOM that admits "TLS config not found in repo — likely terminated at the load balancer" is more trustworthy than one that silently omits it.
- **Never leak secrets.** Inventory key/cert *existence and metadata*, never private key contents.
- **Don't reinvent enums.** Stick to CycloneDX 1.6 values; use `other`/`unknown` when unsure.
