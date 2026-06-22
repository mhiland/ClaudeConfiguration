# SLSA Build track — levels, threats, and scoring rubric

Source: [slsa.dev/spec/v1.0](https://slsa.dev/spec/v1.0/levels). SLSA v1.0 defines one track today — the **Build track** — measuring how trustworthy an artifact's *build provenance* is. (A **Source track** covering source-control integrity is planned for a future version; out of scope here — see `verification.md` note.)

**Provenance** = a signed, machine-readable statement describing how an artifact was produced: the build platform, the build process/entry point, and the top-level inputs (source repo + commit). On GitHub it is emitted as an in-toto attestation with a SLSA provenance predicate, signed keyless via sigstore (Fulcio cert from the workflow's OIDC identity, logged to Rekor).

## The levels

### Build L0 — no guarantees
No provenance. A plain build. Baseline for "we ship a binary and can't prove anything about it."

### Build L1 — provenance exists
**Requirements:**
- A **consistent build process** others can form expectations about (the build is defined, e.g. in a workflow, not run ad hoc on a laptop).
- **Provenance exists** describing how the artifact was built — including the build platform, the build process, and the top-level inputs.
- The producer **distributes that provenance** to consumers (attached to the release/registry, retrievable).

**Threats mitigated:** mistakes in the release process — e.g. building from a commit not actually in the upstream repo, or shipping an artifact built by an unknown process. Provenance at L1 may be **unsigned or incomplete**; it is documentation, not yet a tamper-proof guarantee.

### Build L2 — hosted, signed provenance
**All of L1, plus:**
- The build runs on a **hosted build platform** (dedicated shared infrastructure), **not an individual's workstation**.
- Provenance is **tied to that platform by a digital signature** (non-falsifiable — the consumer can confirm it was produced by the expected builder).
- **Downstream verification** validates that signature/authenticity.

**Threats mitigated:** **tampering after the build** — a signed provenance from a known builder can't be silently swapped or forged by someone without the signing identity. Raises the bar to where forging it carries real legal/financial risk.

### Build L3 — hardened build
**All of L2, plus the platform implements controls to:**
- **Prevent runs from influencing one another**, even within the same project (build **isolation** — no cross-run contamination of cache, state, or environment).
- **Prevent the signing secret** used for provenance **from being accessible to user-defined build steps** (a compromised build step cannot steal the key and forge provenance for anything).

**Threats mitigated:** **tampering during the build** — insider threats, compromised build credentials, or a malicious co-tenant. This is the strongest Build-track assurance: even a fully compromised build *step* cannot forge provenance, because it never touches the signing key.

> SLSA v1.0 stops at L3. (Older drafts had an L4 covering hermetic/reproducible builds; v1.0 folded the essentials in and dropped the separate level. If a user references "SLSA 4", clarify they likely mean a pre-1.0 draft.)

## GitHub mapping

| SLSA Build level | How to reach it on GitHub Actions |
|------------------|-----------------------------------|
| **L1** | Generate any provenance and attach it to the release. In practice you'd jump straight to L2 — the same action gives signed provenance for free. |
| **L2** | `actions/attest-build-provenance` (or npm `--provenance`) running on a **GitHub-hosted runner**. GitHub is the hosted platform; sigstore keyless OIDC signs the provenance. This is the recommended starting target. |
| **L3** | `slsa-framework/slsa-github-generator` **reusable workflows**. The generator runs the signing in a separate, isolated reusable-workflow job whose OIDC token / signing material is not exposed to your build steps, satisfying the isolation + secret-protection requirements. |

**Self-hosted runners:** do not assume L2/L3 automatically. A self-hosted runner is only a "hosted build platform" if it is genuinely dedicated, isolated, shared infrastructure with protected signing — most ad-hoc self-hosted setups are not. Flag self-hosted runners and require explicit justification before crediting L2+.

## L2 vs L3 — decision guide

Start at **L2** for essentially everything: it is a few lines per job, keyless, and needs no change to how you build.

Move an artifact to **L3** when its compromise is high-impact and worth the added constraints:
- Widely-distributed binaries / base images / packages many downstreams trust.
- Anything where "a malicious build step forged provenance" is in your threat model.
- Compliance or customer requirements that name SLSA L3.

L3 cost: the `slsa-github-generator` reusable workflow **owns** the build-and-upload step (you hand it a build command / artifacts), which constrains workflow shape and can require restructuring. Adopt it deliberately, per high-value artifact, not blanket.

## Scoring rubric

Score **per released artifact**, then the repo's level is the **lowest** across artifacts you'd call released.

| Requirement | Level | Met when… | Common gap |
|-------------|-------|-----------|------------|
| Consistent build process | L1 | The artifact is built by a defined workflow, not manually. | Released artifacts built/uploaded by hand. |
| Provenance exists & distributed | L1 | Provenance is generated and attached where consumers get the artifact. | No provenance at all. |
| Hosted build platform | L2 | Build runs on a GitHub-hosted runner (or a justified dedicated hosted platform). | Self-hosted runner with no isolation justification. |
| Provenance signed (non-falsifiable) | L2 | `attest-build-provenance` / `--provenance` / generator signs it via OIDC, covering this artifact by digest, in the job that ships it. | Step present but on the wrong job, wrong subject, or skipped on the release path. |
| Build isolation | L3 | Build runs via `slsa-github-generator` (or equivalent isolated builder); runs can't influence each other. | Inline attestation in a shared job — L2 only. |
| Signing secrets unreachable from build steps | L3 | Signing happens in the generator's isolated job; user steps never see the key. | Inline signing in the same job as user build code. |

Be explicit about **N/A**: if the repo releases no artifact of a given type, the recipe rows for it are N/A — say so rather than scoring a phantom artifact.
