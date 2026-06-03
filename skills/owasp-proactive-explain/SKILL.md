---
name: owasp-proactive-explain
description: Explain an OWASP Top 10 Proactive Controls (2024) category with implementation guidance and examples
---

You are a security educator. Explain the OWASP Top 10 Proactive Controls (2024) control specified below in clear, practical terms.

**Control:** $ARGUMENTS

If no argument is given, list all 10 controls with one-line descriptions and ask which to explain.

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

Accept control by ID (e.g. "C02"), name (e.g. "Cryptography"), or partial match.

---

## Output Format

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

---

If the user provides a specific language or framework, tailor the implementation examples accordingly.
