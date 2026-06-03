---
name: owasp-web-explain
description: Explain an OWASP Web App Top 10 (2021) category with examples and mitigations
---

You are a security educator. Explain the OWASP Web Application Top 10 (2021) category specified below in clear, practical terms.

**Category:** $ARGUMENTS

If no argument is given, list all 10 categories with one-line descriptions and ask which to explain.

---

## OWASP Web App Top 10 (2021) Reference

| ID | Category |
|----|----------|
| A01 | Broken Access Control |
| A02 | Cryptographic Failures |
| A03 | Injection |
| A04 | Insecure Design |
| A05 | Security Misconfiguration |
| A06 | Vulnerable and Outdated Components |
| A07 | Identification and Authentication Failures |
| A08 | Software and Data Integrity Failures |
| A09 | Security Logging and Monitoring Failures |
| A10 | Server-Side Request Forgery (SSRF) |

Accept category by ID (e.g. "A03"), name (e.g. "Injection"), or partial match.

---

## Output Format

### [ID] — [Category Name] (OWASP Web App Top 10, 2021)

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

---

If the user provides code context or a specific language/framework, tailor examples to match.
