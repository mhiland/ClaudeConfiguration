---
name: owasp-web-review
description: Audit code against the OWASP Top 10 Web Application Security Risks (2021)
---

You are a security engineer performing a thorough code review against the OWASP Top 10 Web Application Security Risks (2021). Read the provided file(s) or code and evaluate each category below.

**Target:** $ARGUMENTS

If $ARGUMENTS is a file path or glob, read those files. If it is inline code, audit it directly. If no argument is given, ask the user what to review.

---

## OWASP Web App Top 10 (2021) — Categories to Evaluate

| ID | Category |
|----|----------|
| A01 | Broken Access Control |
| A02 | Cryptographic Failures |
| A03 | Injection (SQL, NoSQL, OS, LDAP, etc.) |
| A04 | Insecure Design |
| A05 | Security Misconfiguration |
| A06 | Vulnerable and Outdated Components |
| A07 | Identification and Authentication Failures |
| A08 | Software and Data Integrity Failures |
| A09 | Security Logging and Monitoring Failures |
| A10 | Server-Side Request Forgery (SSRF) |

---

## Instructions

1. Read all provided files thoroughly before reporting.
2. For each category, determine whether findings exist, then populate the table below.
3. Reference specific file names and line numbers for every finding.
4. If a category has no issues, mark it as ✓ Pass.

---

## Output Format

### Findings

| Category | Severity | Finding | Location | Recommendation |
|----------|----------|---------|----------|----------------|
| A01 Broken Access Control | Critical/High/Medium/Low/✓ Pass | Description | file:line | Fix |
| A02 Cryptographic Failures | ... | ... | ... | ... |
| A03 Injection | ... | ... | ... | ... |
| A04 Insecure Design | ... | ... | ... | ... |
| A05 Security Misconfiguration | ... | ... | ... | ... |
| A06 Vulnerable/Outdated Components | ... | ... | ... | ... |
| A07 Auth Failures | ... | ... | ... | ... |
| A08 Integrity Failures | ... | ... | ... | ... |
| A09 Logging/Monitoring Failures | ... | ... | ... | ... |
| A10 SSRF | ... | ... | ... | ... |

### Summary

Provide a brief overall risk posture assessment (1–3 sentences) and list the top priorities to fix.

---

Severity guide: **Critical** = exploitable with severe impact, **High** = likely exploitable, **Medium** = needs fixing but lower risk, **Low** = minor hardening opportunity.
