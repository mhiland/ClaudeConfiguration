---
name: slsa-compliance
description: "Assess a GitHub repository's SLSA Build level and remediate its GitHub Actions pipelines to generate signed, verifiable build provenance. Use this whenever the user wants to \"make this SLSA compliant\", \"add build provenance\", \"attest my build\", \"sign my artifacts\", \"reach SLSA Build L2/L3\", asks \"what SLSA level am I\", or points at slsa.dev — even when they just say \"harden my release pipeline so I can prove how it was built\". Covers the SLSA Build track (L0–L3) on GitHub Actions: it scores the current level with evidence, then edits workflow YAML to add provenance generation (actions/attest-build-provenance, npm --provenance, or the slsa-github-generator reusable workflows for L3), least-privilege permissions, OIDC keyless signing, and SHA-pinned actions, plus the verification side (gh attestation verify). It is GitHub-Actions-focused and Build-track-scoped — for general pipeline-config risks (unsafe triggers, PPE, credential hygiene) prefer owasp-cicd, and for dependency/artifact-consumption trust (lockfiles, registries, dependency confusion) prefer supply-chain-review. Not an SBOM generator."
---

# SLSA Compliance — Build Provenance for GitHub Pipelines

You are bringing a repository's GitHub Actions pipelines into **SLSA** (Supply-chain Levels for Software Artifacts, [slsa.dev](https://slsa.dev)) compliance on the **Build track**. The goal is concrete: produce **provenance** — a signed, machine-readable statement of *how and where each released artifact was built* — and make it **verifiable** by consumers. You both **assess** the current level and **remediate** the workflows to raise it.

SLSA is a graded standard, not pass/fail. The Build track has four levels:

| Level | Requirement (one line) | GitHub mechanism |
|-------|------------------------|------------------|
| **Build L0** | No guarantees. | — (a plain build with no provenance) |
| **Build L1** | Provenance **exists** and is distributed — describes the build platform, process, and top-level inputs. | Any provenance attached to the release (even unsigned) |
| **Build L2** | Provenance is generated on a **hosted** platform and is **signed** (non-falsifiable). | `actions/attest-build-provenance` on GitHub-hosted runners (keyless OIDC/sigstore) |
| **Build L3** | Builds are **isolated** from one another and the **signing key is unreachable** from user-defined build steps. | `slsa-framework/slsa-github-generator` reusable workflows |

Most repos should target **L2** first — it is low-friction and keyless on GitHub-hosted runners — then move to **L3** for high-value artifacts. Full requirement text, threat model, and the scoring rubric are in **`references/slsa-build-levels.md`**.

## Why this is a reasoning task, not a checkbox

A signal that `attest-build-provenance` *appears* in a workflow is not the same as "every released artifact is provably attested." Provenance attached to an artifact nobody verifies, or generated only on the `main` push while releases ship from a tag job that skips it, buys nothing. Your job is to trace each **released artifact** to the job that builds it, confirm that job emits **signed** provenance covering that exact artifact by digest, and confirm a consumer *can* verify it. Under-claiming with a clear gap list ("L2 on the container image, but the npm package job has no provenance") is far more useful than a confident "L2 ✓" that missed half the artifacts.

## Mode selection

**Target:** `$ARGUMENTS` — a repo path, a workflow file/glob, a target level ("get me to L3"), or empty (use the current working directory).

- **ASSESS MODE** (default) — "what SLSA level am I", "score this", "audit my provenance", or no actionable verb. Inventory and grade; do not edit.
- **REMEDIATE MODE** — "make it compliant", "add provenance", "get me to L2/L3", "sign my artifacts". Always run Assess first, then edit workflows.

If the target is ambiguous, run Assess and ask whether to remediate.

## ASSESS MODE

### 1. Scope

Find the build/release/publish workflows under `.github/workflows/` (and reusable workflows they call). For each, identify:
- **What artifacts it produces and releases** — container images (pushed to a registry), language packages (npm/PyPI/Maven/NuGet), compiled binaries (Go/Rust/JAR/C), or generic release files (archives, installers, SBOMs on a GitHub Release). One workflow may emit several.
- **Runner type** — GitHub-hosted (`runs-on: ubuntu-latest`, etc.) vs **self-hosted** (affects L2/L3 claims; self-hosted runners are not automatically a hosted, isolated platform).
- **Where the artifact leaves the build** — registry push, `npm publish`, release upload. That exit point is where provenance must attach.

### 2. Collect deterministic signals

Run the bundled scanner for a first pass (relative to this skill's directory):

```bash
python3 <skill-dir>/scripts/assess_slsa.py <repo-root-or-workflows-dir>
```

It reports, per workflow, whether it finds `attest-build-provenance` / `attest` / `slsa-github-generator`, `id-token: write`, `attestations: write`, npm `--provenance`, hosted vs self-hosted runners, and whether added third-party actions are pinned to a commit SHA vs a mutable tag — plus a heuristic suggested level. Treat it as **input to your judgment, not the verdict** (`--json` for machine-readable output, exit `0` clean / `1` gaps found / `2` usage error). Then read the workflows yourself: confirm the attestation step actually covers the released artifact (right `subject-path`/`subject-digest`, runs in the release job, not skipped on the path that ships).

### 3. Score the level

Apply the rubric in **`references/slsa-build-levels.md`**. Score **per released artifact**, then take the repo's level as the **lowest** across artifacts you'd call "released" (a chain is as strong as its weakest shipped artifact). For each requirement, cite `file:line` evidence for why it's Met or a Gap.

### 4. Report

Emit the assessment using the Output Format below: the findings table, the explicit current level, the recommended target, and the shortest path to it.

## REMEDIATE MODE

### 1. Assess and confirm target

Run Assess. Confirm with the user the **target level** (default **L2**; offer **L3** for high-value artifacts) and **which workflows/artifacts** to change. Note any self-hosted runners — L2/L3 claims on them need extra justification.

### 2. Apply the recipe

Read **`references/github-recipes.md`** and apply the block matching each artifact type. Edit the **actual workflow YAML** — do not just print advice. The core L2 change is, per build job:

- Add least-privilege `permissions:` — `id-token: write` and `attestations: write` (and `contents: read`; `packages: write` only for registry pushes). Set them at the **job** level, not workflow-wide, and grant nothing beyond what the job needs.
- Add the provenance step **after** the artifact is built and **before/at** the publish step, targeting the artifact by `subject-path` (files) or `subject-name` + `subject-digest` (images). For npm, add `--provenance` to `npm publish`.
- **SHA-pin** any action you add (full 40-char commit SHA, with a `# vX.Y.Z` comment), and keep keyless OIDC — do not introduce stored signing keys.

### 3. For L3, switch to the generator

To reach **L3**, replace the inline attestation with the `slsa-framework/slsa-github-generator` reusable workflow appropriate to the artifact (generic, container, or language-specific). This moves signing into an isolated job whose key is unreachable from user build steps. Call out the tradeoffs (stricter build shape, the generator owns the build/upload step) so the user opts in deliberately.

### 4. Wire up verification

Show consumers how to verify, from **`references/verification.md`**: `gh attestation verify <file|oci://…> -R <org>/<repo>`, verifying inside a deploy job, and registry/admission-policy enforcement. Provenance no one verifies provides no assurance — make the verification step explicit.

### 5. Summarize

State the level **before → after** per artifact, the files changed, and the **residual gaps** to reach the next level. Remind the user to test the workflow on a real release and to verify the produced attestation end-to-end.

## Output Format

### SLSA Build assessment — `<repo>`

**Current level: Build L<n>** · **Target: Build L<n>** · per the weakest released artifact: `<artifact>`

| Requirement | Build Level | Status | Evidence (file:line) | Remediation |
|-------------|-------------|--------|----------------------|-------------|
| Consistent build process | L1 | Met / Gap / N/A | `.github/workflows/release.yml:12` | … |
| Provenance exists & distributed | L1 | … | … | … |
| Hosted build platform | L2 | … | … | … |
| Provenance signed (non-falsifiable) | L2 | … | … | … |
| Build isolation | L3 | … | … | … |
| Signing secrets unreachable from build steps | L3 | … | … | … |

Add a row per **released artifact** when a repo ships several (e.g. image vs npm package) and they differ.

### Summary

One to three sentences on overall posture and the single highest-value next step (usually "add `attest-build-provenance` to the release job to reach L2"). In Remediate mode, follow with the before→after table and files changed.

**Status guide:** **Met** = the requirement is verifiably satisfied for that artifact, with cited evidence (don't mark Met without it). **Gap** = the requirement is unmet — grade the shortfall and give the fix. **N/A** = no matching surface (e.g. no released artifact of that type) — state why, so "not applicable" is never mistaken for "checked and safe". A control present on the `main` build but missing on the tag/release job that actually ships is a **Gap**, not Met.

## Principles

- **Reason over signals.** A matched action name is a lead, not a verdict — confirm it covers the released artifact, in the shipping job, by digest.
- **Score the weakest shipped artifact.** The repo's level is the lowest across what it actually releases; name each artifact.
- **Least privilege.** Set `id-token` / `attestations` / `packages` at the job level and grant nothing more.
- **Keyless over keys.** Prefer OIDC/sigstore signing; don't add long-lived signing secrets to reach a level.
- **Pin what you add.** Third-party actions go to a full commit SHA with a version comment.
- **No level without verifiable evidence.** Don't claim L2+ unless the provenance is signed *and* a consumer can verify it.
- **Stay in lane; hand off.** Pipeline-config risks (unsafe triggers, PPE, credential hygiene) → `owasp-cicd`. Dependency/artifact-consumption trust (lockfiles, registries, dependency confusion) → `supply-chain-review`. Name the skill rather than half-reviewing it here.
