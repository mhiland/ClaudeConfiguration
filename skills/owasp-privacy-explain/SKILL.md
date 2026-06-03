---
name: owasp-privacy-explain
description: Explain an OWASP Top 10 Privacy Risks (2021) category with examples and mitigations
---

You are a privacy educator. Explain the OWASP Top 10 Privacy Risks (2021) category specified below in clear, practical terms.

**Category:** $ARGUMENTS

If no argument is given, list all 10 categories with one-line descriptions and ask which to explain.

---

## OWASP Top 10 Privacy Risks (2021) Reference

| ID | Category |
|----|----------|
| P1 | Web Application Vulnerabilities |
| P2 | Operator-sided Data Leakage |
| P3 | Insufficient Data Breach Response |
| P4 | Outdated Personal Data |
| P5 | Missing or Insufficient Session Expiry |
| P6 | Insecure Data Transfer |
| P7 | Excessively Permissive Data Retention |
| P8 | Missing or Insufficient Consent |
| P9 | Collection of Data Not Required for Primary Purpose |
| P10 | Non-compliance with Privacy Regulations and Policies |

Accept category by ID (e.g. "P7"), name (e.g. "Data Retention"), or partial match.

---

## Output Format

### [ID] — [Category Name] (OWASP Privacy Top 10, 2021)

**What it is:** Plain-language description of the privacy risk and how it manifests in software systems.

**Why it matters:** Real-world impact — regulatory exposure (GDPR, CCPA, etc.), user harm, or reputational damage if this risk is present.

**Problematic example:**
```[language]
// Annotated example of code or configuration that creates this privacy risk
```

**Better example:**
```[language]
// Annotated example of the privacy-respecting alternative
```

**Mitigation checklist:**
- [ ] Specific, actionable item
- [ ] ...

**Relevant regulations:** Note which privacy laws (GDPR articles, CCPA provisions, etc.) relate to this risk.

**Further reading:** Reference OWASP's official page for this category.

---

If the user provides a specific jurisdiction, framework, or technology context, tailor the regulatory references and code examples accordingly.
