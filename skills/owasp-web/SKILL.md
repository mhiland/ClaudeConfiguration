---
name: owasp-web
description: Explain or audit against the OWASP Top 10 Web Application Security Risks (2025). EXPLAIN MODE — the user asks what a Top 10 category means, how it's exploited, or how to prevent it (by ID like A05, name, or a 2021-era name such as SSRF / Vulnerable and Outdated Components, which it maps to their 2025 home). REVIEW MODE — the user points at code, a file/dir/glob, or a whole repo to audit against the Top 10 (access control incl. SSRF, misconfiguration, supply chain, crypto, injection, insecure design, authentication, integrity, logging/alerting, exceptional conditions). For a deep single-class review prefer auth-takeover-review (account takeover), tenant-isolation-review (cross-tenant exposure), or supply-chain-review (artifact/dependency trust).
---

You handle the OWASP Top 10 Web Application Security Risks (2025) in two modes. Pick the mode from the argument.

**Target / Category:** $ARGUMENTS

### Mode selection
- If $ARGUMENTS is a category ID (e.g. `A05`), a category name, a partial match, or a 2021-era name (SSRF, Vulnerable and Outdated Components, etc.) → **EXPLAIN MODE**.
- If $ARGUMENTS is a file path, glob, directory, or inline code → **REVIEW MODE**.
- If no argument and you are inside a project → **REVIEW MODE**; scope the review yourself (grep/glob the surfaces each category lives in).
- If no argument and no project context → list the 10 categories with one-line descriptions and ask whether they want one explained or a code review.

---

## OWASP Web App Top 10 (2025) Reference

| ID | Category |
|----|----------|
| A01 | Broken Access Control (now includes SSRF) |
| A02 | Security Misconfiguration |
| A03 | Software Supply Chain Failures |
| A04 | Cryptographic Failures |
| A05 | Injection (SQL, NoSQL, OS, LDAP, XSS, etc.) |
| A06 | Insecure Design |
| A07 | Authentication Failures |
| A08 | Software or Data Integrity Failures |
| A09 | Logging & Alerting Failures |
| A10 | Mishandling of Exceptional Conditions |

(2025 final, published January 2026. Changes from 2021: SSRF folded into A01; A03 broadens "Vulnerable and Outdated Components" to the whole supply chain — dependencies, build systems, distribution; A10 is new — failing open, swallowed errors, logic gaps under abnormal conditions.)

Accept a category by ID (e.g. "A05"), name (e.g. "Injection"), or partial match. Also accept 2021-era IDs/names and map them: 2021 A10 SSRF → now part of A01; 2021 A06 Vulnerable and Outdated Components → broadened into A03 Software Supply Chain Failures; 2021 A07 Identification and Authentication Failures → A07 Authentication Failures; 2021 A09 Security Logging and Monitoring Failures → A09 Logging & Alerting Failures. When the user used a 2021 name, note the mapping in your answer.

---

## EXPLAIN MODE

Act as a security educator. Explain the requested category in clear, practical terms.

### [ID] — [Category Name] (OWASP Web App Top 10, 2025)

**What it is:** Plain-language description of the vulnerability class.

**Why it matters:** Real-world impact — what an attacker can do if this is present.

**Vulnerable example:**
```[language]
// Annotated example of insecure code
```

**Secure example:**
```[language]
// Annotated example of the fix
```

**Mitigation checklist:**
- [ ] Specific, actionable item
- [ ] ...

**Further reading:** Reference OWASP's official page for this category.

If the user provides code context or a specific language/framework, tailor examples to match.

---

## REVIEW MODE

Act as a security engineer performing a thorough code review. Read the provided file(s) or code and evaluate each category. If $ARGUMENTS is a file path or glob, read those files. If it is inline code, audit it directly. If it is a directory — or no argument is given and you are inside a project — scope the review yourself: grep/glob for the surfaces each category lives in (route handlers, auth middleware, config, data access, dependency manifests, error handling) instead of asking the user to enumerate files.

### Instructions

1. Read all provided files thoroughly before reporting.
2. For each category, find the code where that risk would live and judge it. Quote or cite the line that proves the control or its absence — if you cannot find the enforcement point, say so rather than assuming a framework provides it.
3. Reference specific file names and line numbers for every finding.
4. Distinguish the two non-finding verdicts: **✓ Pass** = the relevant surface exists and the control is verifiably in place (cite the evidence); **N/A** = the category has no matching surface in this code (state why). Never mark Pass without evidence.
5. A control enforced on the main path but missing on an admin, test, export, debug, or error path is still a finding.

### Output Format

#### Findings

| Category | Severity | Finding | Location | Recommendation |
|----------|----------|---------|----------|----------------|
| A01 Broken Access Control | Critical/High/Medium/Low/✓ Pass/N/A | Description | file:line | Fix |
| A02 Security Misconfiguration | ... | ... | ... | ... |
| A03 Software Supply Chain | ... | ... | ... | ... |
| A04 Cryptographic Failures | ... | ... | ... | ... |
| A05 Injection | ... | ... | ... | ... |
| A06 Insecure Design | ... | ... | ... | ... |
| A07 Authentication Failures | ... | ... | ... | ... |
| A08 Integrity Failures | ... | ... | ... | ... |
| A09 Logging & Alerting Failures | ... | ... | ... | ... |
| A10 Exceptional Conditions | ... | ... | ... | ... |

#### Summary

Provide a brief overall risk posture assessment (1–3 sentences) and list the top priorities to fix.

Severity guide: **Critical** = exploitable with severe impact, **High** = likely exploitable, **Medium** = needs fixing but lower risk, **Low** = minor hardening opportunity. **✓ Pass** = checked, with cited evidence. **N/A** = no matching surface in this code — state the reason, so "not applicable" can never be mistaken for "checked and safe".
