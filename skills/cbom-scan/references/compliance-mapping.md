# Compliance mapping — why a CBOM matters in the EU

Use this to write the report's **Compliance mapping** section. The goal is to connect the inventory you produced to the obligations driving demand for it, and to state honestly what a CBOM does and does not satisfy.

> A CBOM is necessary but not sufficient. It *establishes the cryptographic inventory* these regimes increasingly require, and it makes deprecated/quantum-vulnerable crypto visible so you can plan remediation. It does **not**, by itself, make a product compliant — that needs the actual remediation, governance, and (for CRA) conformity assessment.

## The three drivers

### 1. Cyber Resilience Act (CRA) — Regulation (EU) 2024/2847
Horizontal cybersecurity regulation for "products with digital elements" sold in the EU.
- **Timeline:** entered into force Dec 2024; main obligations apply from **11 December 2027** (reporting obligations from Sept 2026). Manufacturers should be preparing now.
- **Relevant requirements (Annex I):** products must be secure by design, ship without known exploitable vulnerabilities, protect data confidentiality/integrity (Annex I 1.2), and minimize attack surface. Manufacturers must perform a cybersecurity risk assessment and maintain documentation. The CRA explicitly requires an **SBOM** for vulnerability management — a CBOM is the cryptography-specific extension of that same transparency principle.
- **How the CBOM helps:** demonstrates you know your cryptographic attack surface; surfaces "known exploitable" weak crypto (MD5/SHA-1/DES/RC4) that would violate the no-known-vulnerabilities expectation; feeds the risk assessment and technical documentation.

### 2. NIS2 Directive — Directive (EU) 2022/2555
Raises cybersecurity risk-management obligations for essential and important entities across 18 sectors.
- **Timeline:** national transposition was due **17 October 2024**; enforcement is ramping through Member States now.
- **Relevant requirements (Article 21):** entities must take appropriate risk-management measures including "policies and procedures regarding the use of cryptography and, where appropriate, encryption" (Art. 21(2)(h)), plus asset management and supply-chain security. Management bodies are accountable, with significant fines for non-compliance.
- **How the CBOM helps:** you cannot have a cryptography *policy* you can enforce without a cryptography *inventory*. The CBOM is the evidence base for Art. 21(2)(h) and for the asset-management and supply-chain measures.

### 3. EU Coordinated Implementation Roadmap for the transition to PQC (June 2025)
Joint roadmap from Member States / ENISA for migrating to post-quantum cryptography against the "harvest-now, decrypt-later" threat.
- **Binding-style milestones:** Member States begin PQC transitions and **establish cryptographic inventories by the end of 2026**; high-risk use cases targeted for PQC migration by ~2030; broader migration by ~2035.
- **The roadmap names the format:** it calls for maintaining a cryptographic inventory using **standardized formats such as CBOM**. This is the single clearest regulatory pull for producing exactly this artifact.
- **How the CBOM helps:** it *is* the deliverable. The quantum-vulnerable inventory (all `nistQuantumSecurityLevel: 0` assets) is the migration backlog; crypto-agility observations feed the transition plan.

## Supporting standards & references (cite as relevant)
- **CycloneDX 1.6 / ECMA-424** — the CBOM format standard itself.
- **NIST FIPS 203 (ML-KEM), 204 (ML-DSA), 205 (SLH-DSA)** — the PQC algorithms migration targets adopt (2024).
- **NIST SP 1800-38 / NCCoE Migration to PQC** and **CNSA 2.0** (US) — useful migration-planning references.
- **BSI TR-02102 / ANSSI guidance** — EU national-authority crypto recommendations the report can defer to for "is this algorithm acceptable".

## How to write the section

Produce a short table mapping the report's findings to obligations, then a paragraph on residual gaps. Example shape:

| Obligation | What it asks | What this CBOM provides | Gap / next step |
|---|---|---|---|
| EU PQC Roadmap (inventory by end-2026) | Cryptographic inventory in a standard format | `cbom.json` (CycloneDX 1.6) + quantum-vulnerable list | Build migration plan for the N `nistQuantumSecurityLevel:0` assets |
| NIS2 Art. 21(2)(h) | Policy on use of cryptography | Evidence base of what crypto is actually used | Define/enforce an approved-algorithm policy; remediate deprecated crypto |
| CRA Annex I (no known exploitable vulns) | Don't ship known-vulnerable crypto | Flags MD5/SHA-1/DES/RC4/ECB findings | Remediate deprecated crypto before the CRA application date |

Keep it accurate and non-alarmist: give dates, name the article/annex, and distinguish "the CBOM satisfies this" from "this still requires action." Note that exact applicability depends on the organization's sector, role (manufacturer/operator), and Member State — recommend confirming scope with their compliance function rather than asserting they are in or out of scope.
