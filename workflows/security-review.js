export const meta = {
  name: 'security-review',
  description: 'Faithful 11-scout security sweep (the dependably fleet): 6 OWASP-API-class reviewers + 5 deep-security scouts in parallel → dedup → per-confirmed-finding sonnet-worktree fix + opus adversarial-verify panel.',
  whenToUse: 'A broad, multi-surface security audit. TUNED FOR dependably-community — the scout prompts hardcode that repo path, the tenancy model, the compliance-gate caveats, and the known-intentional exclusions. Run from that repo. For other projects, edit the SCOUTS prompts (or use the generic skeletons in ~/agent-review-workflows.md §8). Billed multi-agent fan-out; run deliberately.',
  phases: [
    { title: 'Scout', detail: '11 attack-class scouts in parallel (read-only)' },
    { title: 'Fix', detail: 'one sonnet agent per confirmed high/critical finding, isolated worktree' },
    { title: 'Verify', detail: 'opus skeptics adversarially re-review each fix', model: 'opus' },
  ],
}

// The 11 security scouts exactly as Fable dispatched them.
//   Wave A (OWASP API Top 10 classes) ran as `general-purpose` — full tools, held read-only
//     ONLY by the "READ-ONLY — do not edit" instruction in each prompt.
//   Wave B (deep-security) ran as `Explore` — a built-in read-only agent type (no Edit/Write),
//     so read-only is guaranteed at the TOOL layer, not just by instruction.
// agentType is preserved per the original fleet. (The 5 performance/scale scouts that ran
// alongside these live in the companion `performance-review.js`.)
const SCOUTS = [
  // ---- Wave A — OWASP API Top 10 class reviewers (general-purpose) ----
  {
    key: 'bola',
    agentType: 'general-purpose',
    prompt: `You are a security reviewer auditing the Dependably codebase (self-hosted multi-tenant artifact registry, ASP.NET Core 9, Dapper+SQLite) at /Users/michael/Projects/dependably-community. READ-ONLY review — do not edit anything.

Your scope: OWASP API Top 10 2023 categories **API1 Broken Object Level Authorization (BOLA)** and **API3 Broken Object Property Level Authorization**.

Context you must use:
- Tenancy model: strict isolation; users belong 1:1 to a tenant/org; subdomain-routed login; system_admin operator role exists. Management API under /api/v1, protocol surfaces under /o/{org}/... (npm, pypi, nuget, maven, rpm) and /v2/ (OCI, no org prefix).
- There is a compliance test (OrgIdFilteringComplianceTests) that scans raw SQL literals for org_id filters, BUT it only sees verbatim/raw string SQL — SQL in plain strings or built via concatenation is invisible to it, and it does substring matching. So do NOT assume the gate guarantees scoping; check the actual code paths.
- Key files: src/Dependably/Api/*.cs (all controllers), Api/OrgScopedControllerBase.cs, Security/OrgAccessGuard.cs, Security/RouteScopeFilter.cs, Security/RequireCapability.cs, Infrastructure/*Repository.cs.
- Known-intentional (do NOT report): DeleteVersion deletes blobs only from registry tier (record-only in multitenant shared-cache topology) — this is by design. Role policy: admins manage admins+members, owners manage owners (two-tier check: tenant:configure gate + tenant:admin for owner-touch ops) — verify it's implemented, but the policy itself is intentional.

What to check (non-exhaustive):
1. Every management endpoint that takes an object id (token id, user id, invite id, list id, package id/version, upstream registry id, SIEM config, audit export, claims) — does it verify the object belongs to the caller's org before read/update/delete? Trace from controller through repository SQL.
2. OCI endpoints at /v2/ have NO org prefix — how is tenant scoping done there? Blob mounts (POST /v2/.../blobs/uploads/?mount=...&from=...) are a classic cross-tenant leak.
3. Shared proxy cache: can tenant A fetch a blob cached by tenant B in a way that leaks private (non-proxy) artifacts? Check download paths branch on version origin.
4. npm/pypi/nuget/maven/rpm: package name lookups scoped to org? Tarball/file download endpoints — is the file-to-org binding enforced or just by filename?
5. API3: mass assignment in request DTOs (org settings, user PATCH, instance settings) — can a member set fields they shouldn't (role escalation via property, is_admin, org_id in body)? Excess data exposure in responses (password hashes, token hashes, secrets in JSON)?
6. Cross-tenant enumeration: do 404 vs 403 responses or list endpoints leak existence of other tenants' objects?

Method: read the controllers and repositories thoroughly. For each finding, cite file:line and QUOTE the exact code proving the issue. Distinguish confirmed (you traced the full path and the check is absent) from suspected (needs runtime confirmation). Do not report theoretical issues where you found the enforcing code — instead list those as verified-pass with the citation.

Return: a structured report — for each finding: {category, severity (Critical/High/Medium/Low), title, file:line, evidence quote, attack scenario, recommended fix, confidence (confirmed/suspected)}. Then a verified-pass list with citations. Your final message is raw data for the orchestrator, not user-facing prose.`,
  },
  {
    key: 'auth',
    agentType: 'general-purpose',
    prompt: `You are a security reviewer auditing the Dependably codebase (self-hosted multi-tenant artifact registry, ASP.NET Core 9, Dapper+SQLite, JWT sessions, BCrypt passwords) at /Users/michael/Projects/dependably-community. READ-ONLY review — do not edit anything.

Your scope: OWASP API Top 10 2023 category **API2 Broken Authentication** (full account-takeover lens).

Key files: src/Dependably/Api/AuthController.cs, SamlController.cs, BootstrapController.cs, OrgAuthConfigController.cs, OrgInvitesController.cs, Security/TokenAuthentication.cs, TokenAuthExtensions.cs, TokenGenerator.cs, PasswordPolicy.cs, PasswordRotationGuard.cs, RouteScopeFilter.cs, Infrastructure/FirstBootService.cs, TokenRepository.cs, Program.cs (auth wiring).

Context:
- Token auth: npm uses Bearer, PyPI/NuGet use Basic base64(user:token), NuGet push uses X-NuGet-ApiKey. Tokens stored as SHA-256 hashes. JWT for web sessions. Users are 1:1 with tenant; subdomain-routed login.
- RouteScopeFilter requires a scope claim on /api/v1/ routes; API tokens emit scope=tenant.
- e2e harness rotates admin password and is session-invalidation-sensitive — session invalidation on password change is expected behavior.

Check thoroughly (cite file:line + quote evidence for every claim):
1. JWT: algorithm pinning (alg=none/HS-RS confusion), secret strength/source (FirstBootService), expiry + clock skew, audience/issuer validation, token revocation on logout/password change, claims trusted from JWT vs re-checked in DB (e.g., role changes after issuance).
2. Login: user enumeration (timing/messages), brute-force protection/rate limiting on login + token auth paths, credential stuffing defenses, lockout.
3. Password flows: reset flow (if any) — token entropy, expiry, single-use; password change requires current password; invite acceptance flow — invite token entropy, expiry, reuse, org binding.
4. SAML (SamlController): signature validation, response replay, audience restriction, assertion encryption requirements, IdP-initiated flow risks, comment-injection/XML signature wrapping, NameID-to-user binding (can an attacker's IdP assert another tenant's email?), JIT provisioning risks, is SAML config org-scoped.
5. Service/API tokens: generation entropy (TokenGenerator), constant-time comparison or hash lookup, scoping enforced, expiry honored everywhere (all four resolution paths: Bearer, Basic, X-NuGet-ApiKey, query param if any), revoked-token caching.
6. Bootstrap/first-boot: BootstrapController — can it be re-invoked post-setup? Default credentials, admin password output channel.
7. Session fixation, cookie flags if cookies used, CSRF exposure on state-changing /api/v1 endpoints if cookie-authenticated.
8. Cross-scheme confusion: can a protocol token (scope=tenant) reach endpoints meant for JWT users or vice versa; missing scope claim ⇒ 401 expected.

Distinguish confirmed (traced, enforcement absent) vs suspected. Where the control IS present, record verified-pass with citation. Return structured report: findings [{category, severity, title, file:line, evidence, attack scenario, fix, confidence}] + verified-pass list. Your final message is raw data for the orchestrator.`,
  },
  {
    key: 'resource',
    agentType: 'general-purpose',
    prompt: `You are a security reviewer auditing the Dependably codebase (self-hosted multi-tenant artifact registry, ASP.NET Core 9, Dapper+SQLite) at /Users/michael/Projects/dependably-community. READ-ONLY review — do not edit anything.

Your scope: OWASP API Top 10 2023 categories **API4 Unrestricted Resource Consumption** and **API6 Unrestricted Access to Sensitive Business Flows**.

Key files: src/Dependably/Security/UploadSizeLimitMiddleware.cs, RateLimitPartitions.cs, Program.cs (rate limiter + Kestrel limits wiring), Api/*.cs controllers (esp. ImportController, SiemController, OrgAuditController CSV export, VulnerabilityController, all push/upload endpoints in NpmController, PyPiController, NuGetController, MavenController, RpmController, OciController), Protocol/UpstreamClient.cs, Storage/*.

Context: upload size limits checked in order org-ecosystem → org-global → instance-ecosystem, returned 413 before blob write. PROXY_STAGING_PATH stages proxy fetches on disk. Known-intentional (do NOT report): no per-request integrity re-checks on download (ingest-time SHA-256 is canonical — design decision); blob delete semantics.

Check thoroughly (cite file:line + quote for every claim):
1. Rate limiting: which endpoint groups have limiters (login, token auth, push, proxy-miss fetch, search)? Partition keys (per-IP? per-token? per-org?) — note TRUSTED_PROXIES unset means client-spoofable source IP feeds rate-limit keys (known; check whether limiter partitions rely on it). Are /api/v1 management endpoints rate-limited at all?
2. Upload limits: does UploadSizeLimitMiddleware cover ALL write paths (npm PUT, pypi POST legacy, nuget push, maven PUT incl. sidecars, rpm upload, OCI blob upload incl. chunked PATCH/PUT and manifest PUT, import endpoints)? Content-Length lies vs actual stream counting? Kestrel MaxRequestBodySize interplay.
3. Unbounded reads: request bodies read into memory (ReadToEnd, ToArray, JSON deserialization of unbounded docs — npm publish JSON with inline base64 tarball is a classic memory bomb), multipart parsing limits, decompression bombs (gzip/zip handling in any path: SBOM, import, repodata).
4. Pagination: list endpoints (packages, versions, audit log, activity, users, tokens) — server-side max page size or can a caller request everything? CSV export bounded?
5. Proxy amplification: a request for a huge upstream artifact — is upstream response size capped? Staging disk exhaustion, concurrent proxy-miss fetches for same artifact (cache stampede / semaphore), upstream timeout config.
6. Storage quotas: org-level total storage quota enforced or only per-upload size? GetTotalSizeAsync usage.
7. API6 business flows: org/user invite spam (invites rate-limited or capped?), token creation unbounded (token table flooding), SIEM webhook config abuse (can a tenant point SIEM at arbitrary URL and use the server as a beacon/flood?), import flow abuse, signup/bootstrap flows.
8. Regex/parsing DoS: version parsing, PURL parsing, range header parsing, glob/wildcard search params hitting SQL LIKE with leading wildcards on large tables.

Distinguish confirmed vs suspected; record verified-pass with citations where controls exist. Return structured report: findings [{category, severity, title, file:line, evidence, attack scenario, fix, confidence}] + verified-pass list. Final message is raw data for the orchestrator.`,
  },
  {
    key: 'bfla',
    agentType: 'general-purpose',
    prompt: `You are a security reviewer auditing the Dependably codebase (self-hosted multi-tenant artifact registry, ASP.NET Core 9) at /Users/michael/Projects/dependably-community. READ-ONLY review — do not edit anything.

Your scope: OWASP API Top 10 2023 categories **API5 Broken Function Level Authorization (BFLA)** and **API8 Security Misconfiguration**.

Key files: src/Dependably/Security/RequireCapability.cs, Capabilities.cs, RouteScopeFilter.cs, OrgAccessGuard.cs, SecurityHeadersMiddleware.cs, MetricsAccessMiddleware.cs, MetricsAccessConfig.cs, Program.cs (middleware order, CORS, HSTS, exception handling, endpoints), all Api/*.cs controllers (esp. SystemController, InstanceController, BootstrapController, ImportController, SiemController, OrgUsersController, OrgTokensController, OrgSettingsController, LicenseController vs LicensesController, ClaimsController), appsettings.json, Dockerfile, docker-compose.yml.

Context:
- Authorization model: capability-based (RequireCapability attribute + Capabilities.cs), scope claim required on /api/v1 (RouteScopeFilter: missing scope ⇒ 401; API tokens emit scope=tenant). system_admin is the operator role with an apex/system scope — control-plane endpoints must require it. Role policy (intentional): admins manage admins+members; owner-touching ops need tenant:admin.
- TRUSTED_PROXIES unset ⇒ forwarded headers trusted from any client (known startup-warning'd back-compat; the /metrics allowlist + rate-limit keys + audit source_ip become spoofable — assess severity of what that actually exposes, esp. MetricsAccessMiddleware IP allowlist bypass).

Check thoroughly (cite file:line + quote for every claim):
1. BFLA: enumerate every controller action and its auth attribute chain ([AllowAnonymous], [Authorize], RequireCapability, scope filter). Flag: actions with NO capability requirement that mutate state; admin/operator functions reachable with tenant scope; member-reachable functions that should need admin (role changes, token revocation of others, settings writes, SIEM config, upstream registry config, import, audit export, license assignment); HTTP method confusion (same route, GET unprotected vs POST protected).
2. Capability mapping correctness: does each capability string in controllers exist in Capabilities.cs? Typos = silent allow or silent deny — which way does it fail?
3. system/instance endpoints: SystemController + InstanceController — apex/system scope enforced? Can a tenant admin hit instance-wide settings?
4. Misconfig: security headers (CSP, X-Content-Type-Options, frame-ancestors), CORS policy (origins wildcard? credentials?), HTTPS redirection/HSTS, detailed error leakage (stack traces, RFC7807 detail fields echoing internals), Swagger/OpenAPI docs exposure in production (management spec at /api/v1/docs — auth required?), /metrics exposure, default credentials from FirstBootService, JWT secret persistence/permissions, directory listing, verbose Serilog request logging leaking tokens/Authorization headers (check LogSanitizingDestructuringPolicy coverage).
5. Middleware order in Program.cs: auth before authorization, rate limiter placement, UploadSizeLimit before body read, exception handler first, forwarded-headers placement.
6. Container hardening: Dockerfile (root user? secrets in image?), docker-compose (exposed ports, env defaults).

Distinguish confirmed vs suspected; record verified-pass with citations. Return structured report: findings [{category, severity, title, file:line, evidence, attack scenario, fix, confidence}] + verified-pass list. Final message is raw data for the orchestrator.`,
  },
  {
    key: 'ssrf-api',
    agentType: 'general-purpose',
    prompt: `You are a security reviewer auditing the Dependably codebase (self-hosted multi-tenant artifact registry / proxy, ASP.NET Core 9) at /Users/michael/Projects/dependably-community. READ-ONLY review — do not edit anything.

Your scope: OWASP API Top 10 2023 categories **API7 Server-Side Request Forgery** and **API10 Unsafe Consumption of APIs** (upstream registries are the consumed APIs here).

Key files: src/Dependably/Security/SsrfGuard.cs, SsrfConnectCallback.cs, UpstreamUrlValidator.cs, IUpstreamUrlValidator.cs, Protocol/UpstreamClient.cs, Api/UpstreamRegistryController.cs, SiemController.cs, VulnerabilityController.cs (OSV API consumption), ImportController.cs, OciController.cs (Oci:Upstreams), RpmController.cs (repodata proxy, GPG), NpmController.cs (metadata rewriting), PyPiController.cs, NuGetController.cs, MavenController.cs, plus any HttpClient/HttpClientFactory wiring in Program.cs.

Context:
- Upstreams are per-org configurable in Settings→Proxy (DB-backed, priority-ordered). So tenants can set upstream URLs — SSRF surface is tenant-controlled config, not just operator config.
- SIEM webhook config exists (tenant-configurable URL?).
- OSV API is consumed for malicious-package advisories; hydration pattern has dedup/cap/semaphore/caches.
- RPM: Rpm:GpgKey pinned trust anchor; passthrough vs merged modes.
- Known-intentional (do NOT report): no download-time integrity re-verification (ingest-time SHA-256 is canonical).

Check thoroughly (cite file:line + quote for every claim):
1. SSRF guard coverage: which outbound HTTP paths use SsrfGuard/SsrfConnectCallback and which don't? (upstream proxy fetch, SIEM webhook delivery, OSV calls, OCI upstream, SAML metadata fetch if any, license/SPDX fetch if any, import-from-URL if any). A validator applied at config-save time but not at request time is bypassable via DNS rebinding — check if the connect callback does per-connection IP checks.
2. UpstreamUrlValidator: blocklist approach (private ranges, link-local, metadata IPs 169.254.169.254, IPv6 ::1/fc00::/fe80::, 0.0.0.0)? Redirect following (does HttpClient follow redirects after validation — redirect to internal IP bypass)? DNS rebinding (validate-then-connect TOCTOU)? Scheme restrictions (file://, http on internal ports)? Port restrictions?
3. Response handling from upstreams (API10): npm metadata rewriting — XSS/JSON injection via hostile upstream metadata; tarball URL rewriting trusting upstream-supplied URLs (can upstream point us at internal hosts for the next fetch?); PyPI simple index HTML parsing from upstream (XSS into served index?); NuGet registration JSON passthrough; RPM repomd.xml signature verification fail-closed (verify); OCI manifest/blob content-type trust, digest verification on upstream pulls.
4. Checksum verification on proxy ingest: SHA-256 verified against what source of truth per ecosystem? Upstream-supplied hash = trusting the same channel; note where verification is channel-bound vs lockfile-bound.
5. Hostile upstream resilience: unbounded response streaming to memory, missing timeouts, gzip bombs from upstream, header injection from upstream values echoed into our responses (Content-Disposition, Location).
6. SIEM webhook: SSRF via tenant-set webhook URL, response handling, retry amplification.
7. OSV consumption: response validated/size-capped? Injection of advisory HTML into UI without sanitization (stored XSS via advisory text)?

Distinguish confirmed vs suspected; record verified-pass with citations. Return structured report: findings [{category, severity, title, file:line, evidence, attack scenario, fix, confidence}] + verified-pass list. Final message is raw data for the orchestrator.`,
  },
  {
    key: 'inventory-sweep',
    agentType: 'general-purpose',
    prompt: `You are auditing the Dependably codebase (self-hosted multi-tenant artifact registry, ASP.NET Core 9 + Svelte web UI) at /Users/michael/Projects/dependably-community. READ-ONLY review — do not edit anything.

Your scope: (a) OWASP API Top 10 2023 category **API9 Improper Inventory Management**, and (b) a **missing-implementation / feature-incompleteness sweep**.

For API9 (cite file:line):
1. OpenAPI coverage: two docs exist (management at /openapi/management.json, protocol at /openapi/protocol.json, split route-prefix-driven via OpenApiOptions.ShouldInclude in Program.cs). Are any routed endpoints excluded from BOTH docs (invisible inventory)? Check the ShouldInclude predicates vs actual controller route prefixes (e.g. /bootstrap, /saml, /auth, /metrics, /healthz).
2. Deprecated/legacy/alias routes still alive (short aliases /simple/, /npm/ etc. for default org — documented?), debug or test endpoints compiled into production, version drift between docs and behavior.
3. tests/Contracts/openapi.contract.json — does the contract file route count roughly match the controllers? Anything in controllers but missing from contract?

For the incompleteness sweep (cite file:line for each):
1. grep for TODO, FIXME, HACK, XXX, NotImplementedException, NotSupportedException, "not implemented", "not yet", "placeholder", "stub" across src/ and web/src/ — classify each: dead comment vs real gap reachable by users.
2. Endpoints returning hardcoded/empty results (return empty list / null / 501 / Ok() with no body where data is expected).
3. Half-wired features: DB columns/tables in Infrastructure/Schema.sql with no reader (dormant columns are OK by design for enterprise — only flag if community code half-references them), config keys read but never used or used but never documented, UI pages calling endpoints that don't exist (web/src/lib/api or fetch calls vs actual controller routes), controller endpoints no UI or client can reach AND not in docs.
4. Protocol completeness: for each ecosystem controller (npm, PyPI, NuGet, Maven, RPM, OCI) — known protocol operations that are missing or partially implemented (e.g. npm dist-tags/deprecate/unpublish, search; PyPI JSON API, yank; NuGet search/autocomplete/symbols; Maven SNAPSHOT handling, checksums; OCI referrers API, tag listing pagination; RPM groups/modules metadata). Check what clients commonly call vs what's routed — 404s for standard client operations = incompleteness finding.
5. Error paths that swallow exceptions silently (empty catch, catch { return null; }).

Classify findings: {area, title, file:line, evidence quote, user impact, severity (High/Medium/Low for gaps), confidence}. Distinguish real user-facing gaps from intentional design (community vs enterprise boundary: dormant schema OK; semantics live in enterprise repo). Your final message is raw data for the orchestrator.`,
  },

  // ---- Wave B — deep-security scouts (Explore: tool-level read-only) ----
  {
    key: 'csrf-session',
    agentType: 'Explore',
    prompt: `Read-only security review of /Users/michael/Projects/dependably-community (ASP.NET Core 9, Dapper+SQLite, multi-tenant artifact registry; Svelte SPA in web/). Thoroughness: very thorough. Do NOT modify files.

Scope: **browser-session attack surface — CSRF, cookies, CORS, session lifecycle**.

The management API (/api/v1/…) is used by a Svelte SPA. Determine precisely how the SPA authenticates: JWT in a cookie? Authorization header from localStorage? Find the login endpoint, cookie issuance (HttpOnly/Secure/SameSite flags), and how subsequent /api/v1 requests carry credentials. Then answer:

1. **CSRF**: if any state-changing /api/v1 endpoint accepts a cookie-borne credential, is there an antiforgery token, SameSite enforcement, custom-header requirement, or Origin check? Could a malicious site force a logged-in admin's browser to e.g. create a token, invite a user, change settings? Check both single-tenant and subdomain multi-tenant modes (SameSite + subdomains nuance).
2. **CORS**: any UseCors / AddCors config — what origins/credentials are allowed? Any reflective Access-Control-Allow-Origin?
3. **Session lifecycle**: JWT expiry, logout (is it server-side revocation or client-side delete?), password-change/rotation invalidating existing sessions, session fixation. The e2e harness rotates the admin password and is "session-invalidation-sensitive" — find that mechanism and judge whether it's complete (does it cover all credential types?).
4. **Cookie scoping in multi-tenant subdomain mode**: can a session cookie issued on org-a.apex be replayed on org-b.apex (Domain attribute too broad)? Is the JWT bound to the org/tenant and checked against the resolved host org?

Key places to look: Program.cs (auth wiring), anything named Auth/Session/Login controller, web/src auth code (fetch wrappers), TokenAuthExtensions.cs.

Report ONLY findings you verified by reading the actual code, each with: title, file:line, severity (critical/high/medium/low), the attack scenario in 2-3 sentences, and a concrete fix. Also list explicitly what you checked and found SAFE (one line each). Do not report theoretical issues you couldn't ground in code. Return raw findings as your final text — it is data for the orchestrator, not a user-facing message.`,
  },
  {
    key: 'parsers-archives',
    agentType: 'Explore',
    prompt: `Read-only security review of /Users/michael/Projects/dependably-community (ASP.NET Core 9 artifact registry for npm/PyPI/NuGet/Maven/RPM/OCI). Thoroughness: very thorough. Do NOT modify files.

Scope: **hostile-file parsing — XML, archives, package metadata**. Uploaded packages and upstream-fetched artifacts are attacker-influenceable input.

1. **XXE / XML attacks**: find every XML parse site (RPM repomd.xml/primary.xml parsing in RpmUpstreamProxy/RpmRepodataService, NuGet .nuspec parsing, Maven pom/metadata parsing, anything using XDocument/XmlReader/XElement.Parse). For each: are DTDs/external entities disabled (XmlReaderSettings DtdProcessing.Prohibit, or XDocument.Parse which is safe-by-default — verify which API is used)? Any XmlResolver set? Also check for billion-laughs/entity-expansion limits and unbounded XML size (is the input already size-capped upstream?).
2. **Archive extraction / zip-slip**: find every place an uploaded archive is opened — .nupkg (ZipArchive) for nuspec extraction, npm tarball (tar.gz) for package.json/README, RPM header parsing, OCI layer handling. For each: are entry names used to write to disk (zip-slip) or only read in-memory? Decompression-bomb bounds (entry size caps, ratio checks, streaming limits)? Tar entry name traversal?
3. **JSON parsing**: npm publish JSON, OCI manifest JSON — depth/size limits, System.Text.Json defaults. Any JsonNode recursion on attacker JSON without MaxDepth concerns?
4. **RPM binary parsing**: if RPM headers are parsed natively, look for unchecked length fields / allocation based on attacker-controlled sizes.
5. **Filename/path from package contents**: anywhere a name extracted FROM the package contents (nuspec id, package.json name, NEVRA) is used to build a filesystem path or blob key without going through PathSafeValidator/BlobKeys normalization.

Report ONLY findings verified by reading actual code, each with: title, file:line, severity, attack scenario in 2-3 sentences, concrete fix. List what you checked and found SAFE (one line each). Return raw findings as final text — data for the orchestrator, not user-facing.`,
  },
  {
    key: 'ssrf-deep',
    agentType: 'Explore',
    prompt: `Read-only security review of /Users/michael/Projects/dependably-community (ASP.NET Core 9 multi-tenant artifact registry). Thoroughness: very thorough. Do NOT modify files.

Scope: **SSRF and outbound-request trust**. Since 2026-06 upstream registries are configurable PER-ORG via the management UI (Settings→Proxy) and stored in the DB (resolver is DB-only). That makes upstream URLs tenant-admin-controlled input.

1. **SSRF via tenant-configured upstreams**: find where org upstream URLs are written (settings controller/repository) and read (upstream resolver, UpstreamClient, RpmUpstreamProxy, npm/pypi/nuget proxy paths). Is there ANY validation of the URL at write or fetch time — scheme allowlist (https only?), private/link-local/loopback IP blocking (169.254.169.254 cloud metadata, 10.x, 127.x, ::1), DNS-rebinding consideration, redirect following policy (does HttpClient follow redirects to internal hosts?), port restrictions? A tenant admin pointing their npm upstream at http://169.254.169.254/ and fetching a "package" would read the response back through the proxy — verify whether response bytes are returned to the client.
2. **Redirects**: even with a validated initial URL, do proxy fetches follow 3xx? To where? Is the redirect target re-validated?
3. **Other outbound calls**: OSV API client, SMTP (settings-controlled host?), webhook/notification senders if any, OCI Oci:Upstreams — same questions. Which are operator-controlled (env/appsettings — lower risk) vs tenant-controlled (DB — high risk)? Be precise about WHO can set each URL (system admin vs org admin) — that determines severity.
4. **Response handling**: are upstream response sizes bounded everywhere (compare: OSV got a cap recently; do npm/pypi/nuget/rpm/oci proxy fetch paths bound metadata responses, or stream artifact bodies with limits)? Unbounded buffering of upstream metadata JSON/XML?
5. **Credential leakage**: per-registry auth for upstreams — could a tenant set upstream URL to attacker.com and have the instance send it stored upstream credentials belonging to defaults/another scope? Where are upstream credentials stored and how are they paired with URLs?

Report ONLY findings verified by reading actual code, each with: title, file:line, severity, attack scenario 2-3 sentences, concrete fix. List what you checked and found SAFE (one line each). Return raw findings as final text — data for the orchestrator, not user-facing.`,
  },
  {
    key: 'secrets-crypto',
    agentType: 'Explore',
    prompt: `Read-only security review of /Users/michael/Projects/dependably-community (ASP.NET Core 9 multi-tenant artifact registry; SQLite; JWT; BCrypt). Thoroughness: very thorough. Do NOT modify files.

Scope: **secrets, randomness, crypto, and credential-handling hygiene**.

1. **Token/secret generation entropy**: find every place a secret is generated — API tokens, invite tokens, JWT signing secret (FirstBootService), password-reset tokens if any, OCI upload session IDs. Each must use a CSPRNG (RandomNumberGenerator) with ≥128 bits. Flag any Guid.NewGuid() used as a security token (v4 GUIDs are not guaranteed CSPRNG in all runtimes and only ~122 bits — judge contextually), any Random, any short/truncated tokens.
2. **Token comparison**: token lookup is by SHA-256 hash in DB (fine). But find any OTHER secret comparison — invite token check, NuGet X-NuGet-ApiKey, metrics allowlist, webhook signatures — done with == / string.Equals instead of fixed-time comparison, where the comparison is against a stored secret (DB-indexed hash lookups are fine; direct string compares of secrets are not).
3. **Password handling**: BCrypt work factor (default vs explicit), password length limits (BCrypt 72-byte truncation — is >72-byte input rejected or silently truncated?), first-boot admin password generation and where it's printed/stored, password policy on change.
4. **JWT**: secret length/strength at generation, where the secret lives (DB? file? env?), rotation story, token lifetime, what claims are trusted, clock skew. HS256 pinning already merged — don't re-report that.
5. **Secrets in logs/responses/audit**: grep for logging of Authorization headers, tokens, passwords, connection strings, SMTP creds; token values echoed in API responses after creation (one-time display is fine; persistent retrieval is not); secrets in audit_log detail JSON.
6. **Stored credentials encryption**: upstream registry credentials, SMTP password — stored plaintext in SQLite? (May be acceptable for self-hosted — note it as a finding only if there's a documented expectation otherwise, else list under SAFE/accepted with a one-liner.)

Report ONLY findings verified by reading actual code, each with: title, file:line, severity, attack scenario 2-3 sentences, concrete fix. List what you checked and found SAFE (one line each). Return raw findings as final text — data for the orchestrator, not user-facing.`,
  },
  {
    key: 'cross-org-races',
    agentType: 'Explore',
    prompt: `Read-only security review of /Users/michael/Projects/dependably-community (ASP.NET Core 9 multi-tenant artifact registry; content-addressed SHARED blob storage across orgs — pool model: shared cache tier and shared SQLite). Thoroughness: very thorough. Do NOT modify files.

Scope: **cross-tenant side channels, oracles, and race conditions** — NOT basic missing org_id filters (a compliance gate plus a previous review covered those). Look for the subtle class:

1. **Existence oracles via shared content-addressed storage**: anywhere a request can reveal whether a blob/digest exists GLOBALLY rather than within the caller's org. Candidates: OCI blob HEAD/GET by digest (does it check the org's oci_blobs row first, or Registry/Cache ExistsAsync directly on the shared store?), OCI cross-repo blob mount (POST ?mount=digest&from=repo — is \`from\` org-scoped?), NuGet/npm/PyPI proxy cache hits (BlobKeys.Proxy(sha256) is org-agnostic by design — can timing or status differences tell org B that org A already fetched a specific artifact version? note: deduped proxy cache is an accepted design, only flag if a response DIFFERS based on another org's actions in a way that leaks private package existence, e.g. hosted/private package hashes probeable via proxy key).
2. **First-fetch / dedup write races**: proxy MISS path (hash-and-stage then store) — can two concurrent fetches or a fetch racing a delete corrupt or serve partial blobs? Upload paths: GetOrCreate package patterns — TOCTOU on org quota enforcement (two concurrent uploads both passing the quota check), token-count ceiling races. SQLite serializes writes, but check-then-act across two queries is still racy under concurrency.
3. **Timing/enumeration on auth surfaces**: login (does a nonexistent user short-circuit before BCrypt, enabling username enumeration by timing?), invite acceptance, org slug resolution (does subdomain for a nonexistent org respond differently than wrong-password — fine — but do error MESSAGES distinguish "no such user" vs "wrong password"?).
4. **Audit/activity injection**: user-controlled strings (package names, user agents, usernames) written into audit_log/activity and later rendered in the SPA — any HTML/JS injection risk in the web UI rendering of these (check web/src pages that render audit/activity/package metadata — Svelte escapes by default; look for {@html ...} usages anywhere in web/src)?
5. **npm/PyPI/NuGet metadata rewriting**: upstream metadata is rewritten to point at local routes — can a malicious UPSTREAM (or a tenant-configured upstream) inject URLs/HTML that survive the rewrite and reach another consumer (stored XSS in README rendered by the SPA, tarball URL pointing offsite so the client fetches directly from attacker)?

Report ONLY findings verified by reading actual code, each with: title, file:line, severity, attack scenario 2-3 sentences, concrete fix. List what you checked and found SAFE (one line each). Return raw findings as final text — data for the orchestrator, not user-facing.`,
  },
]

const FINDING_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['findings'],
  properties: {
    findings: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['title', 'file', 'line', 'category', 'severity', 'exploit', 'fix', 'confidence'],
        properties: {
          title: { type: 'string' },
          file: { type: 'string' },
          line: { type: 'integer' },
          category: { type: 'string', description: 'OWASP class or attack class' },
          severity: { type: 'string', enum: ['critical', 'high', 'medium', 'low'] },
          exploit: { type: 'string', description: '2-3 sentence concrete attack scenario, grounded in the quoted code' },
          fix: { type: 'string' },
          confidence: { type: 'string', enum: ['confirmed', 'suspected'], description: 'confirmed = full path traced, enforcement absent; suspected = needs runtime confirmation' },
        },
      },
    },
    verifiedSafe: { type: 'array', items: { type: 'string' }, description: 'one line each: what was checked and found safe, with citation' },
  },
}

const VERDICT_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['refuted', 'reason'],
  properties: {
    refuted: { type: 'boolean', description: 'true if this finding is NOT a real, exploitable issue' },
    reason: { type: 'string' },
  },
}

function fixPrompt(f) {
  return `You are implementing a security fix in the dependably-community repo (ASP.NET Core 9, Dapper+SQLite) at /Users/michael/Projects/dependably-community. You are in an isolated git worktree. Read CLAUDE.md first and follow it exactly.

## Finding (${f.severity}, ${f.category}, ${f.confidence})
${f.title}
Location: ${f.file}:${f.line}
Exploit: ${f.exploit}
Proposed fix: ${f.fix}

## Workflow (mandatory)
1. Branch off local main: \`git checkout -b fix/<slug> main\` (NOT the current branch).
2. Offline restore: \`dotnet restore --source ~/.nuget/packages\` (nuget.config pins api.nuget.org; fresh worktrees hang otherwise).
3. Implement. Rules from CLAUDE.md you must NOT violate: parameterized Dapper SQL only; blob keys only via BlobKeys; org_id filtering on tenant tables; injected TimeProvider (no DateTime.UtcNow); comments present-tense with NO issue/MR refs (a compliance test bans #NNN patterns); Serilog only.
4. Add/extend tests under tests/Dependably.Tests, including a mixed partial-failure scenario (house rule). The regression test MUST fail on the OLD code and pass on the fix.
5. Verify by exit code: \`dotnet format --verify-no-changes\`, \`dotnet build -p:TreatWarningsAsErrors=true\`, \`dotnet test --no-restore --filter "Category!=Integration"\`, then full \`dotnet test --no-restore\`. All must pass.
6. If any route shape/response code changed, regenerate the contract: \`UPDATE_API_CONTRACT=1 dotnet test --no-restore --filter ApiContractTests\`.
7. \`git commit --no-verify\` (checks already run; the pre-commit hook can hang ~19min). Do NOT push.

Return: branch name, files changed + what changed, exact test pass/fail counts, and any judgment calls. Your final message is data for the orchestrator.`
}

function verifyPrompt(f, lens) {
  return `You are a senior security reviewer. READ-ONLY — do not edit or commit. Repo: /Users/michael/Projects/dependably-community (read CLAUDE.md for project rules).

A fix was implemented for: "${f.title}" (${f.category}, ${f.file}:${f.line}). Claimed fix: ${f.fix}

Review the fix branch (\`git diff main...<branch>\`) through the **${lens}** lens and try to REFUTE that it is a real, complete, correctly-fixed issue. Check especially: does the regression test actually fail on the OLD code (i.e. does it pin the fix)? Are CLAUDE.md rules honored? Any regression or bypass left? Default to refuted=true if you are not convinced. Return the structured verdict.`
}

// ---- Phase: Scout (parallel barrier — we dedup across the full result set) ----
phase('Scout')
const scoutResults = await parallel(
  SCOUTS.map((s) => () =>
    agent(s.prompt, { label: `scout:${s.key}`, phase: 'Scout', agentType: s.agentType, schema: FINDING_SCHEMA })
  )
)

const allFindings = scoutResults.filter(Boolean).flatMap((r) => r.findings || [])
const seen = new Set()
const deduped = allFindings.filter((f) => {
  const k = `${f.file}:${f.line}:${f.category}`
  if (seen.has(k)) return false
  seen.add(k)
  return true
})
log(`${SCOUTS.length} scouts returned ${allFindings.length} findings; ${deduped.length} unique after dedup.`)

// Triage: only spawn a fix+verify pipeline for CONFIRMED critical/high findings — that's
// what justifies a worktree + opus panel. Everything else is reported, not auto-fixed.
const FIX_SEVERITIES = new Set(['critical', 'high'])
const toFix = deduped.filter((f) => f.confidence === 'confirmed' && FIX_SEVERITIES.has(f.severity))
const deferred = deduped.filter((f) => !(f.confidence === 'confirmed' && FIX_SEVERITIES.has(f.severity)))
log(`Triage: ${toFix.length} confirmed high/critical → fix pipeline; ${deferred.length} deferred (suspected or medium/low) → reported only.`)
if (toFix.length === 0) {
  return { scanned: SCOUTS.map((s) => s.key), uniqueFindings: deduped.length, confirmed: [], deferred, note: 'No confirmed high/critical findings to auto-fix.' }
}

// ---- Phase: Fix → Verify (pipeline — each finding fixes then faces an opus refute panel) ----
const results = await pipeline(
  toFix,
  (f) => agent(fixPrompt(f), { label: `fix:${f.file}`, phase: 'Fix', model: 'sonnet', isolation: 'worktree' })
    .then((report) => ({ finding: f, report })),
  ({ finding, report }) =>
    parallel(['correctness', 'security', 'test-adequacy'].map((lens) => () =>
      agent(verifyPrompt(finding, lens), { label: `verify:${finding.file}:${lens}`, phase: 'Verify', model: 'opus', schema: VERDICT_SCHEMA })
    )).then((votes) => {
      const valid = votes.filter(Boolean)
      const survives = valid.filter((v) => !v.refuted).length >= 2 // majority of 3 must NOT refute
      return { finding, report, survives, votes: valid }
    })
)

const settled = results.filter(Boolean)
const confirmed = settled.filter((r) => r.survives)
const rejected = settled.filter((r) => !r.survives)
log(`Fixes verified: ${confirmed.length} survived the opus panel, ${rejected.length} refuted/dropped.`)

return {
  scanned: SCOUTS.map((s) => s.key),
  uniqueFindings: deduped.length,
  confirmed: confirmed.map((r) => ({ finding: r.finding, fix: r.report })),
  refuted: rejected.map((r) => ({ finding: r.finding, votes: r.votes })),
  deferred,
}
