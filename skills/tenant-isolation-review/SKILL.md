---
name: tenant-isolation-review
description: Audit a multi-tenant (B2B SaaS) codebase for cross-tenant data exposure — the BOLA / IDOR / confused-deputy class where a fully-authenticated tenant can read, write, delete, or enumerate another tenant's data. Use this whenever reviewing or hardening multi-tenant code, org/tenant scoping, row-level isolation, shared caches or object stores, tenant-context resolution (subdomain / Host / JWT claim), or investigating cross-tenant leakage / IDOR / BOLA / BFLA risk — even when the user just says "check tenant isolation", "can one customer see another's data", or "is this query scoped". Complements auth-takeover-review (becoming another *user*) and supply-chain-review (trusting the wrong *artifact*); this covers crossing the *tenant* boundary inside a valid session. The OWASP-API checklist treats BOLA as one item — this is the deep, reasoning-driven isolation review.
---

You are a security engineer reviewing a multi-tenant system for **cross-tenant data exposure**: a fully-authenticated user of tenant A reading, writing, deleting, or enumerating tenant B's data. This is the BOLA / IDOR / confused-deputy class — consistently the #1 API risk in practice and the one automated scanners miss, because exploiting it needs two real tenants, real object ids, and knowledge of the data model and the tenant-resolution path. This is a manual, reasoning-driven review, not a scan.

This is **distinct from account takeover** (see the `auth-takeover-review` skill). There the attacker tries to *become* another user; here the attacker is already a legitimate tenant and the only question is whether the tenant boundary holds on **every** data path. The critical skill is not running an IDOR checklist — it's tracing each data path in **this** codebase to the point where the tenant boundary is (or isn't) enforced, and judging that point.

**Target:** $ARGUMENTS

If $ARGUMENTS is a file path or glob, read those files. If it is inline code, audit it directly. If no argument is given, ask the user what to review (a data-access/repository layer, an API surface, the tenant-resolution middleware, or the whole repo).

---

## Step 0 — Identify the tenancy model FIRST

You cannot judge isolation without knowing how tenants are separated. Establish, with evidence:

- **Topology:** single-tenant appliance · pool/shared DB with a tenant column · schema-per-tenant · DB-per-tenant · plus any **shared data plane** (a cache or object store deliberately shared across tenants for dedup).
- **Tenant-context resolution:** where does the request's tenant come from — subdomain, `Host` header, path segment, a JWT/session claim, a lookup? **Is that source attacker-settable?** (A raw `Host`/`X-Forwarded-*`/header/param with no trusted-proxy allowlist is spoofable.)
- **The tenant column name** in use: `org_id` / `tenant_id` / `account_id` / `workspace_id`.
- **Control plane vs data plane:** are there system-admin / apex / operator endpoints that operate across tenants *by design*? Those are legitimate; everything else must stay within one tenant.

Greps to locate each:

- **Tenant column:** `org_id|tenant_id|account_id|workspace_id|customer_id`
- **Resolution:** `subdomain|Host|X-Tenant|X-Forwarded-Host|tenantId|current_tenant|HttpContext.Items|RequestContext|RLS|row.?level`
- **Shared stores:** `cache|blob|bucket|s3|azure|key prefix|content.?address|sha256|rate.?limit|GetPartitionKey|temp|staging`
- **Cross-tenant by design:** `system.?admin|superuser|is_admin|apex|cross.?tenant|all tenants|xtenant`

**A class that maps to no mechanism present is marked `N/A` with the reason — neither a finding nor a pass.** Do not assume "framework handles it"; find the enforcement point.

---

## The 5 cross-tenant exposure classes

| # | Class | What goes wrong | Where to look |
|---|-------|-----------------|---------------|
| 1 | **Missing tenant predicate** | A read / write / delete / aggregate / list query lacks the `org_id`/`tenant_id` filter — or silently loses it inside a JOIN, subquery, `IN (...)`, or ORM scope. Legitimately cross-tenant queries (system-admin views, one-shot migrations, an id that is *already* FK-bound to one tenant) must be **explicit and justified**, never accidental. | Every repository/DAO method, every raw SQL string, list & search & report & export & metrics endpoints (the ones most often forgotten). |
| 2 | **IDOR / BOLA & BFLA** | An endpoint takes an object id (path/body/query) and fetches or mutates it after authenticating the *user* but **without** verifying the object belongs to the caller's tenant. The id being a GUID is not isolation. BFLA variant: a role/function-gated action is reachable without the role. | `GET/PUT/DELETE /things/{id}`, download/artifact-by-key routes, "fetch by id then use" patterns, admin actions behind only a UI check. |
| 3 | **Shared-resource keying** | Blob keys, cache keys, rate-limit partitions, temp/staging paths, or export filenames aren't namespaced by tenant where isolation is required — or are content-addressed/dedup'd in a way that lets one tenant **poison**, **evict**, or **learn the existence of** another tenant's entry. (Inverse mistake: namespacing per-tenant where dedup of genuinely tenant-agnostic immutable data was intended.) | The single place keys are constructed; cache lookup/store; any `sha256`-addressed store; rate-limit partition function. |
| 4 | **Tenant-context integrity & token scope** | The resolved tenant comes from a client-settable source with no trusted-proxy allowlist (spoofable). Or a token/session issued for tenant A is accepted on tenant B's routes — the binding to a tenant isn't **re-checked on every request**, only at login. | Tenant-resolution middleware; token/session validation; the point where `resolved tenant` meets `token's tenant`. |
| 5 | **Control-plane / data-plane boundary** | A cross-tenant operation lives on a data-plane (in-tenant) endpoint instead of behind explicit system/operator scope; or a new feature silently reaches across tenants. Rule of thumb: if a feature inherently spans tenants, it belongs to the **control plane** (system scope) — not a data-plane endpoint with a widened query. | New/changed endpoints; "list all", counts, dashboards; anything that aggregates beyond one tenant. |

---

## Instructions

1. **Read the real data path, not the route name.** Open the query, the key-construction site, and the resolution middleware. A route that "takes a tenant id" proves nothing about whether the row it returns belongs to that tenant.
2. For **each** of the 5 classes:
   - State the concrete mechanism(s) in *this* codebase it maps to (or `N/A`, with the reason).
   - Cite `file:line` evidence for whether the boundary is enforced, missing, or bypassable.
   - Assign a verdict (`Gap` / `Safe` / `N/A`).
3. **Watch the common false-negatives** — this is where real cross-tenant bugs hide:
   - A `WHERE id = @id` that looks safe but never checks the row's tenant. The id's unguessability is **not** an access control.
   - The tenant filter is present on the hot path but **missing on an admin / report / export / search / aggregate / count** path.
   - "It's behind authentication" ≠ isolated. Auth proves *who the user is*, not *which tenant's data they may touch*.
   - A static linter / compliance grep that enforces an `org_id` filter only catches the query *shapes it recognizes*; a query it doesn't scan, or one marked "exempt", still needs a human to confirm the exemption is genuinely cross-tenant-safe.
   - Content-addressed / shared caches are fine for **immutable, tenant-agnostic** data (e.g. a public artifact keyed by hash) — but they leak existence or allow poisoning the moment a tenant's *private* data shares that keyspace.
   - Tenant resolved from a client-controlled `Host`/forwarded header without a trusted-proxy allowlist is spoofable — one tenant can impersonate another's routing.
4. Prefer evidence over assertion: quote the line that proves the boundary (or its absence). If you can't find the enforcement point, say so rather than assuming a framework adds it.

---

## Output Format

### Findings

| # Class | Maps to (mechanism in this codebase) | Verdict | Evidence | Recommendation |
|---------|--------------------------------------|---------|----------|----------------|
| 1 Missing tenant predicate | e.g. PackageRepository.ListAsync · N/A | Gap (Critical/High/Medium/Low) · Safe · N/A | file:line | Fix |
| 2 IDOR / BOLA & BFLA | ... | ... | ... | ... |
| 3 Shared-resource keying | ... | ... | ... | ... |
| 4 Tenant context / token scope | ... | ... | ... | ... |
| 5 Control-plane / data-plane boundary | ... | ... | ... | ... |

### Summary

- 1–3 sentences on overall cross-tenant isolation posture and the top priorities to fix.
- An explicit list of every class marked **N/A and why** — so "not applicable" can never be mistaken for "checked and safe".

---

**Verdict guide:**
- **Gap** — the boundary is missing, incomplete, or bypassable. Grade the impact: **Critical** = trivial cross-tenant read/write of sensitive data · **High** = likely exploitable cross-tenant access · **Medium** = needs fixing, narrower exposure · **Low** = minor hardening / existence-disclosure.
- **Safe** — the tenant boundary is enforced server-side on this path, with `file:line` evidence.
- **N/A** — no matching mechanism exists in this codebase; state the reason.
