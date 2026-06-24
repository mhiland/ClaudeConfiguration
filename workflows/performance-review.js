export const meta = {
  name: 'performance-review',
  description: 'Faithful 5-scout performance/scale sweep (the dependably fleet, Wave B6–B10): hot-path serving, metadata store under load, burst/concurrency, memory/allocation, horizontal scale — in parallel → ranked synthesis.',
  whenToUse: 'A scale/throughput audit of the registry hot paths. TUNED FOR dependably-community — the scout prompts hardcode that repo path and its architecture. Read-only analysis (no fix pipeline): perf findings need human prioritization before any change. Run from that repo.',
  phases: [
    { title: 'Scout', detail: '5 performance/architecture scouts in parallel (read-only)' },
    { title: 'Synthesize', detail: 'one Plan agent ranks findings into an action list' },
  ],
}

// The 5 performance/scale scouts exactly as Fable dispatched them, all `Explore` (read-only).
// These ran alongside the 11 security scouts in `security-review.js` — together they were the
// "70-agent" fleet's reconnaissance wave.
const SCOUTS = [
  {
    key: 'hot-path',
    prompt: `Read-only performance/architecture review of /Users/michael/Projects/dependably-community (ASP.NET Core 9 artifact registry serving npm/PyPI/NuGet/Maven/RPM/OCI; SQLite metadata; local/S3/Azure blob storage). Thoroughness: very thorough. Do NOT modify files.

Scope: **the hot serving path** — what happens per request when a package client (npm install, dnf, docker pull, dotnet restore, pip) downloads metadata or an artifact. This app's main job is serving third-party packages fast at scale under bursty load.

For EACH ecosystem (npm packument GET, npm tarball GET, PyPI /simple/ index + /packages/ file, NuGet registration/flatcontainer/query, Maven artifact GET, RPM repodata + packages, OCI manifest/blob GET):

1. **Buffer vs stream**: trace the artifact-serving path from controller → blob store → response. Does it stream (Stream copied to Response.Body / FileStreamResult) or buffer the whole artifact in a byte[]/MemoryStream first? Quote file:line. Pay attention to IBlobStore.GetAsync's return type and how each controller consumes it, for ALL THREE blob backends (LocalBlobStore, S3BlobStore, AzureBlobStore) — does S3/Azure download fully then serve, or pass the network stream through?
2. **Metadata serving**: is metadata (packument, simple index, registration JSON, repodata XML) regenerated/rewritten per request (string building, JSON DOM rewriting, XML reserialization) or cached? How expensive per request — e.g. npm packument rewrite: does it parse + rewrite the full upstream JSON DOM on every GET? Where are the memoisation/cache layers and their invalidation?
3. **HTTP semantics for client caching**: ETag / Last-Modified / If-None-Match → 304 support on metadata and artifacts? Cache-Control headers? HEAD handling without body materialization? HTTP Range requests (critical for OCI blob resume and large artifacts) — supported or ignored?
4. **Response compression**: is response compression middleware enabled? For JSON metadata that matters at scale.
5. **Proxy MISS path cost**: when an artifact is not cached — is the client's response streamed-through while caching (tee), or does the server fully download from upstream, verify checksum, store, THEN serve (latency = full artifact download)? Quote the actual flow in UpstreamClient.FetchAndStageAsync and per-ecosystem callers.

Report findings each with: title, file:line, impact at scale (concrete: memory per concurrent request, latency added), and what GOOD looks like. Also list explicitly what is already well-engineered (one line each, file:line). Return raw findings as final text — data for the orchestrator, not user-facing prose.`,
  },
  {
    key: 'metadata-store',
    prompt: `Read-only performance/architecture review of /Users/michael/Projects/dependably-community (ASP.NET Core 9 artifact registry; Dapper + SQLite via IMetadataStore/SqliteMetadataStore). Thoroughness: very thorough. Do NOT modify files.

Scope: **the metadata store under high-concurrency read load and bursty writes**. SQLite is the community-edition store; the question is whether the data layer supports many clients and request bursts.

1. **SQLite configuration**: find SqliteMetadataStore + SchemaInitializer + connection string construction. Is WAL mode enabled (journal_mode=WAL)? busy_timeout? synchronous level? Cache size? Is \`Pooling=true\` (Microsoft.Data.Sqlite connection pooling)? Shared cache? Quote exact pragmas/connection string with file:line. Without WAL, concurrent reads block on any write — that's the single biggest SQLite scaling lever; verify precisely.
2. **Connections per request**: IMetadataStore returns raw connections and callers \`await using\` them. Count how many DISTINCT connection opens + queries a typical hot request performs — e.g. npm tarball GET: tenant resolution (org by host/slug), token resolve (hash lookup), package/version lookup, settings read, activity/audit insert? Trace one real controller path and enumerate the queries with file:line. Per-request audit/activity INSERTs on the download path would serialize all downloads through SQLite's single writer — check whether downloads write anything synchronously (activity recording? download counters? first-fetch tracking?) and whether those writes are inline (per-request latency) or batched/queued.
3. **In-memory caching**: which repositories cache? (OrgRepository is said to cache settings.) Find every IMemoryCache/ConcurrentDictionary cache: what's cached (org by slug? settings? tokens? upstream registries?), TTL, invalidation on write, and what's NOT cached but hit per-request (token hash lookup per protocol request?).
4. **Indices**: against Schema.sql, check the hot lookups are index-backed: tokens by token_hash; packages by (org_id, ecosystem, name); package_versions by (package_id, version); oci_blobs (digest, org_id); orgs by slug. List any hot query whose WHERE isn't covered by an index/PK.
5. **Write contention points**: enumerate writes on hot paths (proxy version recording on MISS, first-fetch tracking, audit/activity, jwt revocation checks?, negative cache inserts). SQLite serializes writers — judge burst behavior: 500 concurrent npm installs of cached artifacts, how many writes/second does that generate and do any happen inside the request critical path?
6. **The enterprise bridge**: note (briefly) what the Postgres pool path changes — is the data layer written provider-agnostically so the bottlenecks differ?

Report findings each with: title, file:line, impact at scale, what GOOD looks like. List what's already well-engineered (one line each). Return raw findings as final text — data for the orchestrator.`,
  },
  {
    key: 'burst-concurrency',
    prompt: `Read-only performance/architecture review of /Users/michael/Projects/dependably-community (ASP.NET Core 9 artifact registry). Thoroughness: very thorough. Do NOT modify files.

Scope: **burst behavior and concurrency control** — many clients hitting at once (CI fleets kicking off simultaneously is the canonical registry burst: hundreds of \`npm ci\`/\`docker pull\` within seconds).

1. **Thundering herd on cache MISS**: when 200 clients request the same not-yet-cached artifact simultaneously — does each spawn its own upstream fetch (200 parallel downloads of the same file), or is there single-flight/request coalescing? Check UpstreamClient (metadata single-flight was mentioned in code — verify scope: metadata only or artifacts too?), OciUpstreamResolver, RpmUpstreamProxy, MavenUpstreamFetcher. Quote the coalescing mechanism (SemaphoreSlim? ConcurrentDictionary<key,Task>? keyed locks?) and what it covers, file:line. Same question for the upstream HttpClient's MaxConnectionsPerServer (10 for upstream, 20 for OCI) — with 200 concurrent misses to one upstream, requests queue on the connection pool; what's the timeout behavior, do queued requests fail or wait?
2. **Sync-over-async / blocking**: grep for .Result, .Wait(), .GetAwaiter().GetResult(), Task.Run wrapping sync IO, lock statements around IO, synchronous stream CopyTo on request paths (vs CopyToAsync). Each hit: is it on a hot path? Thread-pool starvation under burst is the classic ASP.NET collapse mode.
3. **Rate limiting on protocol surfaces**: management API has a rate limiter — do the PROTOCOL surfaces (npm/pypi/nuget/maven/rpm/oci GET paths) have any rate limiting, concurrency limiting (ConcurrencyLimiter), or queue-depth protection? Is there anything preventing a burst from exhausting memory/threads, or is Kestrel's default the only backstop? Check Kestrel configuration: MaxConcurrentConnections, MaxRequestBodySize, ThreadPool settings (min threads?), request queue limits.
4. **Locks and semaphores inventory**: find every SemaphoreSlim/lock/Mutex/keyed-lock in src/ — what does each protect, is it per-key or global, could a slow upstream hold it while other requests pile up (lock held across network IO = burst killer)? E.g. merged RPM repodata memoisation — is rebuild under a global lock, blocking all RPM clients while upstream is slow?
5. **Timeout/cancellation hygiene**: do upstream fetches flow the client's RequestAborted cancellation? If 200 clients give up (CI timeout), do the server-side upstream fetches cancel or keep running? HttpClient timeouts per client (upstream 30min OCI!) — a hung upstream with no per-request timeout = piled-up requests.
6. **Background work on request paths**: anything fire-and-forget (Task.Run without await) that could accumulate unbounded under burst? Queues (SIEM queue exists — bounded? overflow policy?).

Report findings each with: title, file:line, burst scenario + failure mode, what GOOD looks like. List what's already well-engineered (one line each). Return raw findings as final text — data for the orchestrator.`,
  },
  {
    key: 'memory-profile',
    prompt: `Read-only performance/architecture review of /Users/michael/Projects/dependably-community (ASP.NET Core 9 artifact registry; deploy targets include Raspberry Pi ARM64 — memory matters). Thoroughness: very thorough. Do NOT modify files.

Scope: **memory and allocation behavior per request** — the difference between serving 500 concurrent downloads in constant memory vs OOM.

1. **byte[] artifact buffering inventory**: find every place a whole artifact lands in a byte[] or MemoryStream on a request path. Known suspects: PublishRequest.ArtifactBytes (publish paths — all ecosystems? size caps?), RPM repodata buffering (up to 600MB?), OCI blob/manifest handling, proxy MISS staging (PROXY_STAGING_PATH suggests disk staging — verify the MISS path stages to DISK not RAM, and which paths still buffer), npm packument JSON DOM, NuGet nupkg handling on push (whole nupkg in memory for nuspec extraction?). For each: file:line, max size given existing caps, on hot path or admin path?
2. **Large Object Heap pressure**: arrays >85KB go to LOH; frequent multi-MB byte[] churn = LOH fragmentation + Gen2 GCs = latency spikes under sustained load. Which of the above allocate per-request multi-MB arrays? Is RecyclableMemoryStream used (you'll find Microsoft.IO.RecyclableMemoryStream if so — where, and where it's NOT used but should be)?
3. **Streaming discipline on uploads**: npm publish body cap was added recently (capped buffering); OCI blob upload (PUT, possibly chunked) — streamed to staging/blob store or buffered? Maven PUT? RPM upload? NuGet push (multipart)? For each: file:line, streamed-to-disk vs RAM.
4. **PROXY_STAGING_PATH mechanics**: how the staging dir is used (hash-and-stage on MISS), file cleanup on failure/cancellation (orphaned temp files under burst?), and whether anything else still buffers despite staging existing.
5. **Server GC / runtime config**: check the csproj/runtimeconfig for ServerGarbageCollection, ConcurrentGC, TieredPGO settings. Container memory limits interplay (DOTNET_GCHeapHardLimit?). Kestrel MaxRequestBodySize defaults vs the app's own caps.
6. **Response-side buffering**: any place a response is built as a giant string/StringBuilder per request (RPM primary.xml regeneration? PyPI simple index HTML for orgs with thousands of packages? NuGet registration pages)? Pagination present or unbounded result sets serialized at once (package list endpoints, search)?

Report findings each with: title, file:line, worst-case memory per request × plausible burst concurrency, what GOOD looks like. List what's already well-engineered (one line each). Return raw findings as final text — data for the orchestrator.`,
  },
  {
    key: 'horizontal-scale',
    prompt: `Read-only architecture review of /Users/michael/Projects/dependably-community (ASP.NET Core 9 artifact registry; community = SQLite + local blob; enterprise = Postgres pool + R2 per a bridge model). Thoroughness: very thorough. Do NOT modify files.

Scope: **horizontal scalability and hidden state** — what breaks if you run 2+ instances of this app behind a load balancer, and what limits a single instance vertically.

1. **In-process state inventory**: enumerate every piece of in-memory state that assumes a single process: IMemoryCache uses (org/settings caches — staleness across instances on settings change?), rate-limiter state (the management rate limiter — in-memory partitions?), single-flight/coalescing dictionaries, memoised merged RPM repodata, negative caches (DB or memory?), JWT revocation (DB table or memory?), SIEM queue, login lockout/throttle state if any, OCI upload session state (uploads are chunked + resumable — where does session/offset state live: DB rows, disk, or memory? THIS IS THE BIG ONE for LB'd deployments), proxy staging files (local disk — does a fetch ever resume across requests?).
   For each: file:line, what breaks with 2 instances (correctness vs just cache-miss inefficiency), and whether sticky sessions would mask it.
2. **Filesystem dependencies**: LOCAL_STORAGE_PATH (shared volume viable?), PROXY_STAGING_PATH, SQLite file itself (SQLite over NFS = corruption risk; multi-instance SQLite = not viable — confirm nothing pretends otherwise), data protection keys (ASP.NET DataProtection — where are keys persisted? default = local dir → cookie/JWT? JWTs are HS256 from DB so maybe unused — check if DataProtection matters here), first-boot races if 2 instances start fresh simultaneously.
3. **Graceful degradation & lifecycle**: 30s SIGTERM drain exists — verify (Program.cs). In-flight upstream fetches during shutdown? Health endpoints (liveness vs readiness split? does readiness gate on DB/blob store reachability?). Startup cost (schema init, first boot) under rolling deploys.
4. **Observability for scale**: OTel metrics — are there metrics for the things that matter at scale (request latency histograms per route/ecosystem, cache hit/miss ratio, upstream latency, blob store latency, SQLite busy/retry counts, queue depths)? List what exists vs gaps. Cardinality discipline (no tenant_id labels — confirm).
5. **Vertical ceiling summary**: given SQLite + local blob + in-proc caches, characterize the single-instance ceiling and what the enterprise path (Postgres + R2) changes — which in-proc state items remain blockers even with Postgres (upload sessions? rate limiter? single-flight?).

Report findings each with: title, file:line, what breaks / what limits, what GOOD looks like. List what's already well-engineered (one line each). Return raw findings as final text — data for the orchestrator.`,
  },
]

// ---- Phase: Scout (parallel barrier — the synthesizer ranks across all findings) ----
phase('Scout')
const scoutResults = await parallel(
  SCOUTS.map((s) => () =>
    agent(s.prompt, { label: `scout:${s.key}`, phase: 'Scout', agentType: 'Explore' })
  )
)
const reports = scoutResults.filter(Boolean)
log(`${reports.length}/${SCOUTS.length} performance scouts reported.`)

// ---- Phase: Synthesize (single Plan agent ranks the raw findings into an action list) ----
phase('Synthesize')
const sections = SCOUTS.map((s, i) => `### ${s.key}\n${reports[i] || '(no report)'}`).join('\n\n')
const plan = await agent(
  `You are synthesizing a performance/scale review of dependably-community (repo: /Users/michael/Projects/dependably-community). ` +
  `Five Explore scouts each examined one dimension (hot serving path, metadata store under load, burst/concurrency, memory/allocation, horizontal scale). ` +
  `Their raw findings follow. Do NOT re-explore — rank and consolidate only.\n\n${sections}\n\n` +
  `Deliver:\n` +
  `1. A prioritized table of the top findings across all five dimensions — for each: title, file:line, the scale scenario it bites in (e.g. "200 concurrent CI installs"), estimated impact, and a one-line fix direction. Rank by (impact × likelihood at realistic load).\n` +
  `2. The 3-5 highest-leverage changes to make first (the ones that unblock the most headroom for the least work — e.g. a single WAL pragma).\n` +
  `3. A short "already well-engineered" list so we don't regress those.\n` +
  `Keep it tight — substance, not re-justification. Your final text is data for the orchestrator.`,
  { label: 'synthesize:ranking', phase: 'Synthesize', agentType: 'Plan' }
)

return { scanned: SCOUTS.map((s) => s.key), reports, plan }
