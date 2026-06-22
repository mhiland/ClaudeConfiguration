# GitHub Actions provenance recipes

Copy-paste blocks to add **signed build provenance** to a release job. Default target is **Build L2** via `actions/attest-build-provenance` on a GitHub-hosted runner (keyless OIDC/sigstore — no stored secrets). The **L2→L3** section swaps in the `slsa-framework/slsa-github-generator` reusable workflows.

## Conventions used below

- **Pin to a SHA.** The blocks show tags (`@v2`) for readability. Before committing, resolve each third-party action to its full 40-char commit SHA and pin it with a version comment:
  ```yaml
  - uses: actions/attest-build-provenance@<40-char-sha>  # v2.x.y
  ```
  Resolve with: `gh api repos/actions/attest-build-provenance/git/refs/tags/v2 --jq .object.sha` (deref to the commit if it's an annotated tag). First-party `actions/*` are lower-risk but pinning them is still good hygiene.
- **Least privilege.** Put `permissions:` at the **job** level, not workflow-wide. `attest-build-provenance` needs `id-token: write` (OIDC → sigstore) + `attestations: write` (store the attestation) + `contents: read`. Registry pushes add `packages: write`.
- **Right job, right subject, right time.** The attestation must run in the job that **ships** the artifact, **after** it's built, and name the **exact** artifact (path or digest). Attesting a file you then rebuild/repackage attests the wrong bytes.

## 1. Container image (push to ghcr.io)

Attest by image **name + digest** and push the attestation to the registry so `docker pull` consumers can verify.

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write       # push image to ghcr.io
      id-token: write        # OIDC for keyless signing
      attestations: write    # store the provenance attestation
    steps:
      - uses: actions/checkout@v4

      - uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - id: push
        uses: docker/build-push-action@v6
        with:
          context: .
          push: true
          tags: ghcr.io/${{ github.repository }}:${{ github.sha }}

      - uses: actions/attest-build-provenance@v2
        with:
          subject-name: ghcr.io/${{ github.repository }}
          subject-digest: ${{ steps.push.outputs.digest }}   # sha256:… from build-push-action
          push-to-registry: true
```

Verify: `gh attestation verify oci://ghcr.io/<org>/<repo>:<tag> -R <org>/<repo>` (see `verification.md`).

## 2. Language packages

### npm — use the built-in flag (preferred for npm)

npm has native provenance; it produces the SLSA attestation and links it on the npm registry page. Requires npm ≥ 9.5 and a public package.

```yaml
jobs:
  publish:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      id-token: write        # OIDC for provenance
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
          registry-url: https://registry.npmjs.org
      - run: npm ci
      - run: npm publish --provenance --access public
        env:
          NODE_AUTH_TOKEN: ${{ secrets.NPM_TOKEN }}
```

### PyPI / Maven / NuGet — attest the built distribution files

Build the distributables, then attest them by path before (or alongside) publishing. Example for Python:

```yaml
jobs:
  publish:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      id-token: write
      attestations: write
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: '3.12'
      - run: python -m build            # produces dist/*.whl, dist/*.tar.gz
      - uses: actions/attest-build-provenance@v2
        with:
          subject-path: 'dist/*'
      # then publish, e.g. pypa/gh-action-pypi-publish (which also supports its own
      # PEP 740 attestations via id-token: write — prefer that on PyPI if available)
```

For Maven/NuGet, swap the build step and point `subject-path` at the produced `*.jar` / `*.nupkg`.

## 3. Compiled binaries (Go, Rust, JAR, C/C++)

Attest the produced binaries by path. Globs and multi-line lists are supported.

```yaml
jobs:
  release:
    runs-on: ubuntu-latest
    permissions:
      contents: write        # upload to the GitHub Release
      id-token: write
      attestations: write
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with:
          go-version: '1.22'
      - run: |
          GOOS=linux  GOARCH=amd64 go build -o dist/app-linux-amd64 ./...
          GOOS=darwin GOARCH=arm64 go build -o dist/app-darwin-arm64 ./...
      - uses: actions/attest-build-provenance@v2
        with:
          subject-path: 'dist/*'
      - uses: softprops/action-gh-release@v2   # or: gh release upload
        with:
          files: dist/*
```

## 4. Generic release files (archives, installers, SBOMs)

Same pattern — attest whatever you attach to the Release, by path, in the job that uploads it. The attestation is stored on the repo and retrievable via `gh attestation verify <file>`. For loose files not in a registry, distribute the attestation alongside (or rely on `gh attestation verify`, which fetches it from GitHub by digest).

```yaml
      - uses: actions/attest-build-provenance@v2
        with:
          subject-path: |
            release/installer.msi
            release/bundle.tar.gz
            release/sbom.spdx.json
```

## L2 → L3 upgrade — slsa-github-generator

To reach **L3**, hand the build to a `slsa-framework/slsa-github-generator` **reusable workflow**. Signing then happens in an isolated job your build steps can't reach. Pick the generator matching the artifact:

- **Generic / arbitrary artifacts** — `slsa-framework/slsa-github-generator/.github/workflows/generator_generic_slsa3.yml` — you compute artifact hashes in your build job and pass them in; the generator produces and signs the provenance in isolation.
- **Containers** — `.../generator_container_slsa3.yml` — pass the image + digest; it attests in an isolated job.
- **Language builders** — dedicated builders exist for Go (`builder_go_slsa3.yml`), Node, Maven, etc., where the generator both **builds and attests** from your config.

Sketch (generic, abbreviated — follow the generator's README for the exact inputs/outputs of the version/SHA you pin):

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    outputs:
      digests: ${{ steps.hash.outputs.digests }}
    steps:
      - uses: actions/checkout@v4
      - run: make build              # produce ./dist/*
      - id: hash
        run: echo "digests=$(sha256sum dist/* | base64 -w0)" >> "$GITHUB_OUTPUT"

  provenance:
    needs: [build]
    permissions:
      actions: read
      id-token: write
      contents: write
    uses: slsa-framework/slsa-github-generator/.github/workflows/generator_generic_slsa3.yml@v2.0.0  # pin to SHA
    with:
      base64-subjects: ${{ needs.build.outputs.digests }}
      upload-assets: true
```

**Tradeoffs to flag to the user before adopting L3:**
- The generator **owns** provenance generation (and, for the language builders, the build itself) — workflow shape is constrained to what the generator expects.
- It is a `uses:`-level reusable workflow with its own `permissions` and inputs; pin it to a SHA and read its README for the version you adopt (inputs change between majors).
- Verify L3 artifacts with `slsa-verifier` (the generator's companion) in addition to / instead of `gh attestation verify` — see `verification.md`.
