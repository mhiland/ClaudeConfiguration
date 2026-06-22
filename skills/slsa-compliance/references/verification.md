# Verifying provenance (the consumer side)

Provenance is only worth generating if someone verifies it. SLSA L2 explicitly requires that **downstream verification validates the signature/authenticity** — an unverified attestation is documentation, not assurance. This file covers how consumers check what the recipes produce.

## `gh attestation verify` — L2 attestations from `attest-build-provenance`

The GitHub CLI fetches the attestation from GitHub (by artifact digest) and verifies the sigstore signature and the build identity.

**Files / binaries:**
```bash
gh attestation verify ./app-linux-amd64 -R <org>/<repo>
```

**Container images** (needs registry auth, e.g. `docker login ghcr.io`):
```bash
gh attestation verify oci://ghcr.io/<org>/<repo>:<tag> -R <org>/<repo>
```

**Tighten the check** beyond "signed by someone at this repo" — bind to the exact workflow identity so a different (possibly malicious) workflow in the same org can't satisfy it:
```bash
gh attestation verify ./app-linux-amd64 \
  -R <org>/<repo> \
  --signer-workflow <org>/<repo>/.github/workflows/release.yml
```
Other useful predicates: `--cert-identity` (exact SAN), `--cert-oidc-issuer https://token.actions.githubusercontent.com`, `--format json` for machine parsing in a gate.

## Verifying in a deploy job

Make verification a **gate**, not a manual afterthought — fail closed if it doesn't pass:

```yaml
  deploy:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: read
    steps:
      - run: docker login ghcr.io -u ${{ github.actor }} -p ${{ secrets.GITHUB_TOKEN }}
      - name: Verify provenance before deploy
        run: |
          gh attestation verify oci://ghcr.io/${{ github.repository }}:${{ github.sha }} \
            -R ${{ github.repository }} \
            --signer-workflow ${{ github.repository }}/.github/workflows/release.yml
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## Registry / admission-policy enforcement

For images, push verification to the cluster/registry boundary so unverified images can't run:
- **Kubernetes admission** — sigstore **policy-controller** or **Kyverno** can require a valid attestation/signature matching an expected issuer + workflow identity before a pod is admitted. (For deep K8s hardening, hand off to `owasp-kubernetes`.)
- **Registry policies** — some registries can require attestation presence on pull.

This is what turns "we generate provenance" into "nothing unverified runs."

## L3 — `slsa-verifier`

Artifacts produced by `slsa-github-generator` are verified with the companion **`slsa-verifier`**, which checks the SLSA provenance and lets you pin the **expected builder** and **source repo**:

```bash
slsa-verifier verify-artifact app-linux-amd64 \
  --provenance-path app-linux-amd64.intoto.jsonl \
  --source-uri github.com/<org>/<repo> \
  --builder-id https://github.com/slsa-framework/slsa-github-generator/.github/workflows/builder_go_slsa3.yml
```
`gh attestation verify` may also read these in many cases, but `slsa-verifier` is the canonical L3 path and supports the builder-id binding that makes the L3 guarantee meaningful.

## How verification ties back to each level

| Level | What verification proves |
|-------|--------------------------|
| **L1** | The provenance *exists* and describes the build — but unsigned, so it proves nothing about who produced it. Don't rely on it for trust decisions. |
| **L2** | The provenance is **signed by the expected build identity** — it wasn't forged or swapped after the build. Bind the check to the specific `--signer-workflow` / source repo, not just "someone in the org." |
| **L3** | Same signature guarantee **plus** the assurance that no build *step* could have forged it (isolated builder, protected key). Verify the **builder-id** to claim this. |

A verification that only checks "is it signed" without binding the **source repo** and **workflow identity** is weak — an attacker who can run any workflow in a trusted org could otherwise satisfy it. Always pin identity.

## Scope note — Source track

SLSA v1.0 is Build-track only; a **Source track** (signed commits, protected branches, mandatory review proving the source's integrity) is planned but not yet specified. Source-side controls (branch protection, required reviews, signed commits) are real and worth doing, but they aren't a SLSA *level* yet — don't score them as one. If the user wants source-integrity hardening, treat it as adjacent good practice and note it's not part of the current SLSA spec.
