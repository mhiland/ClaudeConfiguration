---
name: supply-chain-review
description: Audit a codebase for software supply-chain compromise — the attack classes where what you build, serve, or install is not what you trusted. Use this whenever reviewing or hardening dependency consumption (lockfiles, registries, install scripts), an artifact registry/proxy/mirror (npm, PyPI, NuGet, Maven, OCI, RPM…), checksum or signature verification, publish/ingest paths, or investigating dependency-confusion / typosquatting / cache-poisoning / malicious-package risk — even when the user just says "are our dependencies safe", "review the proxy path", or "can someone poison our cache". Works on consumers (apps, CI), producers (publish pipelines), and intermediaries (registries/proxies). Complements auth-takeover-review (becoming another *user*) and tenant-isolation-review (crossing the *tenant* boundary); this covers trusting the wrong *artifact*. The OWASP CI/CD checklist treats this as two line items (CICD-SEC-3, -9) — this is the deep, reasoning-driven review.
---

You are a security engineer reviewing a codebase for **software supply-chain compromise**: an attacker getting their artifact, or a tampered artifact, accepted somewhere downstream trusts it — into a build, a registry, a cache, or a runtime — without ever authenticating as the victim. These flaws evade automated scanners because exploiting them spans systems (a public registry + a resolver + a build) and depends on resolution order, trust anchors, and cache semantics that no single file reveals. This is a manual, reasoning-driven review, not a scan.

The critical skill is **not** running a checklist of "pin your dependencies." Each of the five patterns below is an *attack class*; your job is to find which mechanism in **this** codebase each class maps to (a resolver's source order, a lockfile mode, a checksum comparison, a publish authorization, an install hook policy) and judge that mechanism. The same classes apply whether the code *consumes* artifacts, *publishes* them, or *proxies* them — but the enforcement points differ; identify the role first.

**Target:** $ARGUMENTS

If $ARGUMENTS is a file path or glob, read those files. If it is inline code, audit it directly. If no argument is given, ask the user what to review (dependency/build config, a proxy or registry implementation, a publish pipeline, or the whole repo).

---

## Step 0 — Identify the artifact flow FIRST

Before judging anything, establish with evidence which roles this codebase plays and where each mechanism lives:

- **Consumer** (installs dependencies): lockfiles (`package-lock.json`, `packages.lock.json`, `poetry.lock`, `requirements.txt` + hashes, `go.sum`, `Cargo.lock`), registry config (`.npmrc`, `nuget.config`, `pip.conf`, `index-url`, `--registry`), CI install steps.
- **Producer** (publishes artifacts): publish/release jobs, signing steps, version/tag derivation.
- **Intermediary** (registry/proxy/mirror): `upstream|proxy|mirror|passthrough|merged|fetch`, cache key construction, metadata rewriting, publish/ingest endpoints.
- **Verification machinery:** `sha256|sha512|checksum|integrity|digest|signature|gpg|pgp|sigstore|cosign|minisign|repomd`
- **Resolution order / namespaces:** scope or prefix routing, source priority, "check local then upstream" branches, negative caches.
- **Install-time execution:** `postinstall|preinstall|setup.py|build.rs|csproj targets|scripts` policy (`--ignore-scripts`, `NODE_OPTIONS`, sandboxing).

**A pattern that maps to no mechanism present in the code is marked `N/A` with the reason — it is neither a finding nor a pass.** A consumer-only repo still gets classes 1, 2, and 5; a registry gets all five.

---

## The 5 supply-chain compromise patterns

| # | Pattern | Generalized class | What to check across roles |
|---|---|---|---|
| 1 | **Resolution hijack** (dependency confusion / typosquat / shadowing) | The name the resolver asks for can be satisfied by a source the attacker controls | Private package names resolvable from a public registry (the classic dependency-confusion); multiple sources without scope/prefix binding (a scope or id-prefix must be **pinned to one source**, not "first answer wins"); proxy merge order — can an upstream artifact **shadow** a local one (or a newly published upstream version outrank the internal one)?; negative-cache entries that let a later upstream answer claim a previously-missing internal name; typosquat-prone install instructions |
| 2 | **Integrity verification gaps** | The artifact isn't bound to an expected digest at the moment of trust | What is the hash compared **against, and when**? Ingest-time verification proves you stored what you fetched — it does *not* authenticate the upstream. A digest from the **same channel** as the artifact (upstream-declared hash) is self-referential unless that metadata is itself authenticated. Lockfile integrity fields present **and enforced** (locked/frozen mode in CI — a lockfile that CI silently regenerates is decorative); TOFU: is the first-fetch digest **recorded** and later drift detected/refused?; version pins without hashes are **not** integrity (the attacker publishes the pinned version too) |
| 3 | **Upstream trust & cache poisoning** | One bad upstream response becomes durable truth served to everyone | TLS enforced to upstream (no scheme downgrade, redirect targets validated); trust anchor **operator-pinned, not fetched from the upstream it authenticates** (circular against MITM); signed **metadata** (index/`repomd`) vs signed artifacts — verifying one but consuming the other unverified; verification **fail-closed** (a network/parse error must not skip the check); a poisoned or unverified cache entry persisted and served to all later consumers (and, in multitenant systems, across tenants); can a cached verified entry be **overwritten or evicted** by an unauthenticated path? |
| 4 | **Publish / ingest abuse** | The write path into the artifact store accepts more than it should | Publish authorization scoped per name/namespace (not just "any authenticated user" — that's BOLA by package name); **version immutability**: does re-pushing an existing version replace bytes consumers already resolved?; delete/unlist semantics — can a deleted name be re-registered by someone else (resurrection attack)?; filename/path traversal and zip-slip in archive ingestion; size limits before bytes are written; metadata fields that get rendered or executed downstream (README HTML, repo URLs, install commands) |
| 5 | **Install-time execution & credential reach** | A merely *downloaded* malicious package becomes *executed* code, and reaches secrets | Install hooks (npm `postinstall`, `setup.py`, MSBuild targets, build scripts) run during CI install — disabled (`--ignore-scripts`), sandboxed, or accepted-with-justification?; what can a malicious dependency reach when it runs: registry tokens in env or `.npmrc`/`nuget.config` baked into images, cloud credentials, the publish token itself (worm potential); does the build emit **provenance** (SBOM, signed attestation) so a compromise can be traced and scoped? |

---

## Instructions

1. **Read the real resolution and verification code, not just config.** Open the resolver/source-order logic, the digest comparison, the cache write, the publish authorization, and the CI install step. A `sha256` appearing in the code says nothing about *what* it's compared to or *whether failure blocks*.
2. For **each** of the 5 patterns:
   - State the concrete mechanism(s) in *this* codebase it maps to (or `N/A`, with the reason).
   - Cite `file:line` evidence for whether the control is present, absent, or bypassable.
   - Assign a verdict (`Gap` / `Safe` / `N/A`).
3. **Watch the common false-negatives** — these are exactly where real findings hide:
   - "We pin versions" ≠ integrity. A version pin without a content hash still trusts whichever source answers; dependency-confusion attacks publish the pinned version at the attacker's source.
   - "Checksum verified" must answer **against what**. Verifying against a hash served by the same upstream over the same connection authenticates nothing; verifying ingest-stored bytes at serve time protects your storage, not your upstream.
   - A signature check whose **key is fetched from the upstream it validates** is circular — the trust anchor must be operator-provided out of band.
   - A lockfile that exists but isn't enforced (`npm ci` vs `npm install`, `RestoreLockedMode`, `--require-hashes`, `--frozen-lockfile`) is decorative; check the CI invocation, not the file's presence.
   - Verification that **fails open** on error (timeout, unparseable signature, missing key → proceed) is a Gap, not a Safe.
   - A registry where publish requires auth but any authenticated user can push to **any name** has the same shape as BOLA — authorization must bind publisher → namespace.
   - Mutable-by-design references (`latest` tags, floating ranges, unpinned base images and CI actions) are part of this review when they cross a trust boundary.
   - Scripts disabled in one ecosystem but not another (npm `--ignore-scripts` set, `setup.py` builds still run arbitrary code) — judge **every** ecosystem present.
4. Prefer evidence over assertion: quote the line that proves the control (or its absence). If you cannot find the enforcement point, say so rather than assuming a package manager or framework default provides it.

---

## Output Format

### Findings

| # Pattern | Maps to (mechanism in this codebase) | Verdict | Evidence | Recommendation |
|-----------|--------------------------------------|---------|----------|----------------|
| 1 Resolution hijack | e.g. proxy source order · scoped registry config · N/A | Gap (Critical/High/Medium/Low) · Safe · N/A | file:line | Fix |
| 2 Integrity gaps | ... | ... | ... | ... |
| 3 Upstream trust / cache poisoning | ... | ... | ... | ... |
| 4 Publish / ingest abuse | ... | ... | ... | ... |
| 5 Install-time execution / credential reach | ... | ... | ... | ... |

### Summary

- 1–3 sentences on overall supply-chain risk posture and the top priorities to fix.
- An explicit list of every pattern marked **N/A and why** — so "not applicable" can never be mistaken for "checked and safe."

---

**Verdict guide:**
- **Gap** — the control is missing, incomplete, fail-open, or bypassable. Grade the impact: **Critical** = attacker-supplied code executes in builds/runtime or is served to consumers · **High** = likely exploitable artifact substitution · **Medium** = needs fixing, narrower exposure · **Low** = minor hardening / traceability.
- **Safe** — the control is present, fail-closed, and enforced at the trust boundary, with `file:line` evidence.
- **N/A** — no matching mechanism exists in this codebase; state the reason.
