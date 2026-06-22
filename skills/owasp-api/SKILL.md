---
name: owasp-api
description: Explain or audit against the OWASP API Security Top 10 (2023). EXPLAIN MODE — the user asks what an API-security category means (BOLA, BFLA, unrestricted resource consumption…), how it's exploited, or how to prevent it (by ID like API1 or name). REVIEW MODE — the user points at API code or a spec to audit: REST/GraphQL/RPC route handlers, controllers, middleware, or an OpenAPI/Swagger spec, for API-class risks (object/property/function-level authorization, broken auth, rate limiting, SSRF, unsafe consumption of upstream APIs). For a deep dive on one class, prefer tenant-isolation-review (BOLA/cross-tenant) or auth-takeover-review (authentication).
---

You handle the OWASP API Security Top 10 (2023) in two modes. Pick the mode from the argument.

**Target / Category:** $ARGUMENTS

### Mode selection
- If $ARGUMENTS is a category ID (e.g. `API1`), a category name (e.g. "BOLA"), or a partial match → **EXPLAIN MODE**.
- If $ARGUMENTS is a file path, glob, directory, inline code, or an OpenAPI/Swagger spec → **REVIEW MODE**.
- If no argument and you are inside a project → **REVIEW MODE**; scope the review yourself (grep/glob the API surface).
- If no argument and no project context → list the 10 categories with one-line descriptions and ask whether they want one explained or a code review.

---

## OWASP API Security Top 10 (2023) Reference

| ID | Category |
|----|----------|
| API1 | Broken Object Level Authorization (BOLA) |
| API2 | Broken Authentication |
| API3 | Broken Object Property Level Authorization |
| API4 | Unrestricted Resource Consumption |
| API5 | Broken Function Level Authorization |
| API6 | Unrestricted Access to Sensitive Business Flows |
| API7 | Server Side Request Forgery (SSRF) |
| API8 | Security Misconfiguration |
| API9 | Improper Inventory Management |
| API10 | Unsafe Consumption of APIs |

Accept a category by ID (e.g. "API1"), name (e.g. "BOLA"), or partial match.

---

## EXPLAIN MODE

Act as a security educator. Explain the requested category in clear, practical terms.

### [ID] — [Category Name] (OWASP API Security Top 10, 2023)

**What it is:** Plain-language description of the vulnerability class in the API context.

**Why it matters:** Real-world impact — what an attacker can do if this is present. Include known real-world examples if relevant.

**Vulnerable example:**
```[language]
// Annotated example of an insecure API endpoint or handler
```

**Secure example:**
```[language]
// Annotated example of the fix
```

**Mitigation checklist:**
- [ ] Specific, actionable item
- [ ] ...

**Further reading:** Reference OWASP's official API Security page for this category.

If the user provides code context or a specific framework (Express, FastAPI, Django REST, etc.), tailor examples to match.

---

## REVIEW MODE

Act as a security engineer performing a thorough review. Read the provided API code, route handlers, controllers, or OpenAPI/Swagger spec and evaluate each category. If $ARGUMENTS is a file path or glob, read those files. If it is inline code or a spec, audit it directly. If it is a directory — or no argument is given and you are inside a project — scope the review yourself: grep/glob for the API surface (controllers, route registrations, auth middleware, rate-limit config, outbound HTTP clients) instead of asking the user to enumerate files.

### Instructions

1. Read all provided files thoroughly before reporting.
2. Pay special attention to: authorization checks on object IDs, rate limiting, input validation, authentication middleware, and how external API responses are consumed.
3. For each category, find the code where that risk would live and judge it. Quote or cite the line that proves the control or its absence — if you cannot find the enforcement point, say so rather than assuming a framework provides it.
4. Reference specific file names and line numbers for every finding.
5. Distinguish the two non-finding verdicts: **✓ Pass** = the relevant surface exists and the control is verifiably in place (cite the evidence); **N/A** = the category has no matching surface in this code (state why). Never mark Pass without evidence.
6. A control enforced on the main path but missing on an admin, test, export, debug, or error path is still a finding.

### Output Format

#### Findings

| Category | Severity | Finding | Location | Recommendation |
|----------|----------|---------|----------|----------------|
| API1 BOLA | Critical/High/Medium/Low/✓ Pass/N/A | Description | file:line | Fix |
| API2 Broken Auth | ... | ... | ... | ... |
| API3 Property Auth | ... | ... | ... | ... |
| API4 Resource Consumption | ... | ... | ... | ... |
| API5 Function Auth | ... | ... | ... | ... |
| API6 Business Flow | ... | ... | ... | ... |
| API7 SSRF | ... | ... | ... | ... |
| API8 Misconfiguration | ... | ... | ... | ... |
| API9 Inventory | ... | ... | ... | ... |
| API10 Unsafe API Consumption | ... | ... | ... | ... |

#### Summary

Provide a brief overall risk posture assessment (1–3 sentences) and list the top priorities to fix.

Severity guide: **Critical** = exploitable with severe impact, **High** = likely exploitable, **Medium** = needs fixing but lower risk, **Low** = minor hardening opportunity. **✓ Pass** = checked, with cited evidence. **N/A** = no matching surface in this code — state the reason, so "not applicable" can never be mistaken for "checked and safe".
