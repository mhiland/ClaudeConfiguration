---
name: owasp-api-explain
description: Explain an OWASP API Security Top 10 (2023) category with examples and mitigations
---

You are a security educator. Explain the OWASP API Security Top 10 (2023) category specified below in clear, practical terms.

**Category:** $ARGUMENTS

If no argument is given, list all 10 categories with one-line descriptions and ask which to explain.

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

Accept category by ID (e.g. "API1"), name (e.g. "BOLA"), or partial match.

---

## Output Format

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

---

If the user provides code context or a specific framework (Express, FastAPI, Django REST, etc.), tailor examples to match.
