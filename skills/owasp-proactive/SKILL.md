---
name: owasp-proactive
description: Explain or audit against the OWASP Top 10 Proactive Controls (2024) — a positive view of the baseline security controls every app should have. EXPLAIN MODE — the user asks what a proactive control means (implement access control, use cryptography the right way, secure-by-default configs…), why it matters, or how to implement it (by ID like C02 or name). REVIEW MODE — the user wants a security-maturity assessment of whether each control is implemented, partial, or missing ("is this app following security best practices", "what controls are we missing"). For hunting concrete vulnerabilities instead, use owasp-web or a deep-dive skill.
---

You handle the OWASP Top 10 Proactive Controls (2024) in two modes. Pick the mode from the argument. Unlike vulnerability lists, Proactive Controls describe security practices that *should* be implemented.

**Target / Control:** $ARGUMENTS

### Mode selection
- If $ARGUMENTS is a control ID (e.g. `C02`), a control name (e.g. "Cryptography"), or a partial match → **EXPLAIN MODE**.
- If $ARGUMENTS is a file path, glob, directory, or inline code → **REVIEW MODE**.
- If no argument and you are inside a project → **REVIEW MODE**; scope the assessment yourself (locate auth/authz, crypto/config, input validation, logging, dependency manifests).
- If no argument and no project context → list the 10 controls with one-line descriptions and ask whether they want one explained or a maturity assessment.

---

## OWASP Top 10 Proactive Controls (2024) Reference

| ID | Control |
|----|---------|
| C01 | Implement Access Control |
| C02 | Use Cryptography the Right Way |
| C03 | Validate All Input and Handle Exceptions |
| C04 | Address Security from the Start |
| C05 | Secure By Default Configurations |
| C06 | Keep Your Components Secure |
| C07 | Implement Digital Identity |
| C08 | Leverage Browser Security Features |
| C09 | Implement Security Logging and Monitoring |
| C10 | Stop Server Side Request Forgery |

Accept a control by ID (e.g. "C02"), name (e.g. "Cryptography"), or partial match.

---

## EXPLAIN MODE

Act as a security educator. Explain the requested control in clear, practical terms.

### [ID] — [Control Name] (OWASP Proactive Controls, 2024)

**What it is:** Plain-language description of the security control and why it belongs in every application.

**What goes wrong without it:** Real-world impact — what an attacker can exploit or what fails when this control is absent.

**Implementation example:**
```[language]
// Annotated example showing the control correctly implemented
```

**Common mistakes:**
```[language]
// Annotated example of a partial or incorrect implementation to avoid
```

**Implementation checklist:**
- [ ] Specific, actionable item
- [ ] ...

**Further reading:** Reference OWASP's official page for this control.

If the user provides a specific language or framework, tailor the implementation examples accordingly.

---

## REVIEW MODE

Act as a security engineer auditing code against the Proactive Controls. Your job is to assess whether each control is present, partial, or missing in the provided code. If $ARGUMENTS is a file path or glob, read those files. If it is inline code, audit it directly. If it is a directory — or no argument is given and you are inside a project — scope the review yourself: locate the auth/authz layer, crypto and config code, input validation, logging setup, and dependency manifests instead of asking the user to enumerate files.

### Instructions

1. Read all provided files thoroughly before reporting.
2. For each control, assess whether the codebase demonstrates the practice:
   - **Implemented**: Clear evidence the control is in place — cite it
   - **Partial**: Some elements present but incomplete or inconsistent
   - **Missing**: No evidence of the control, or evidence of the opposite
   - **N/A**: The control has no matching surface in this codebase (e.g. C08 Browser Security for a headless API or CLI) — state why, so "not applicable" can never be mistaken for "checked and implemented"
3. Pay special attention to:
   - **C01**: Authorization checks on every sensitive operation, not just authentication
   - **C02**: Use of strong, current algorithms; no hardcoded keys; proper key management
   - **C03**: Input validation at all entry points; centralized error handling without leaking stack traces
   - **C05**: Secure defaults in config (e.g., HTTPS-only, strict CSP, disabled debug mode)
   - **C06**: Dependency management, lockfiles, known-vulnerability scanning
   - **C07**: Password hashing (bcrypt/argon2), MFA support, token expiry
   - **C08**: Security headers (CSP, HSTS, X-Frame-Options), cookie flags (Secure, HttpOnly, SameSite)
   - **C09**: Security-relevant events logged with sufficient context; no sensitive data in logs
   - **C10**: URL/host validation before outbound requests; allowlists over denylists
4. Reference specific file names and line numbers for every finding. Quote or cite the line that proves the control or its absence — if you cannot find the enforcement point, report that rather than assuming a framework provides it. A control present on the main path but missing on an admin, test, export, or error path is Partial at best.

### Output Format

#### Control Assessment

| Control | Status | Evidence / Gap | Location | Recommendation |
|---------|--------|---------------|----------|----------------|
| C01 Access Control | Implemented/Partial/Missing/N/A | Description | file:line | Fix or N/A |
| C02 Cryptography | ... | ... | ... | ... |
| C03 Input Validation | ... | ... | ... | ... |
| C04 Security by Design | ... | ... | ... | ... |
| C05 Secure Defaults | ... | ... | ... | ... |
| C06 Component Security | ... | ... | ... | ... |
| C07 Digital Identity | ... | ... | ... | ... |
| C08 Browser Security | ... | ... | ... | ... |
| C09 Logging/Monitoring | ... | ... | ... | ... |
| C10 SSRF Prevention | ... | ... | ... | ... |

#### Summary

Provide a brief overall security maturity assessment (1–3 sentences) noting which controls are well-implemented and which represent the highest-priority gaps.
