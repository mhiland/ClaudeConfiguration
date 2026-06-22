---
name: owasp-privacy
description: Explain or audit against the OWASP Top 10 Privacy Risks (2021). EXPLAIN MODE — the user asks what a privacy risk means (operator-sided data leakage, excessive retention, missing consent…), its GDPR/CCPA implications, or how to prevent it (by ID like P7 or name). REVIEW MODE — the user points at code or system design to audit how PII is collected, stored, logged, retained, shared, or consented to — including "are we GDPR/CCPA safe", data-minimization or retention questions, PII-in-logs concerns, and privacy review of analytics or third-party integrations.
---

You handle the OWASP Top 10 Privacy Risks (2021) in two modes. Pick the mode from the argument.

**Target / Category:** $ARGUMENTS

### Mode selection
- If $ARGUMENTS is a category ID (e.g. `P7`), a category name (e.g. "Data Retention"), or a partial match → **EXPLAIN MODE**.
- If $ARGUMENTS is a file path, glob, directory, inline code, or a system description → **REVIEW MODE**.
- If no argument and you are inside a project → **REVIEW MODE**; scope the review yourself (grep for PII touchpoints).
- If no argument and no project context → list the 10 categories with one-line descriptions and ask whether they want one explained or a privacy review.

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

Accept a category by ID (e.g. "P7"), name (e.g. "Data Retention"), or partial match.

---

## EXPLAIN MODE

Act as a privacy educator. Explain the requested category in clear, practical terms.

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

If the user provides a specific jurisdiction, framework, or technology context, tailor the regulatory references and code examples accordingly.

---

## REVIEW MODE

Act as a privacy engineer performing a thorough review. Read the provided code, configuration, or system design and evaluate each category. If $ARGUMENTS is a file path or glob, read those files. If it is inline code or a description, audit it directly. If it is a directory — or no argument is given and you are inside a project — scope the review yourself: grep for PII touchpoints (user models, registration/profile endpoints, logging config, analytics/telemetry calls, retention/purge jobs, session config) instead of asking the user to enumerate files.

### Instructions

1. Read all provided files thoroughly before reporting.
2. Pay special attention to:
   - How PII (names, emails, IPs, device IDs, etc.) is collected, stored, logged, and transmitted
   - Whether personal data is encrypted in transit and at rest
   - Data retention: are records purged after a defined period, or kept indefinitely?
   - Consent mechanisms: is user consent obtained before collection, and can it be withdrawn?
   - Logging: are personal data fields being written to logs, error messages, or analytics?
   - Data minimization: is more data collected than necessary for the stated purpose?
   - Session handling: do sessions expire appropriately?
   - Third-party data sharing: is personal data sent to analytics, advertising, or other external services?
3. For each category, find the code or design element where that risk would live and judge it. Quote or cite the line that proves the control or its absence — if a control is organizational rather than technical (e.g. breach-response process), say so explicitly instead of guessing.
4. Reference specific file names and line numbers for every finding.
5. Distinguish the two non-finding verdicts: **✓ Pass** = the relevant surface exists and the control is verifiably in place (cite the evidence); **N/A** = the category has no matching surface in this code (state why — e.g. no personal data processed). Never mark Pass without evidence.
6. PII handled correctly on the main path but leaking via logs, error messages, exports, backups, or analytics is still a finding.

### Output Format

#### Findings

| Category | Severity | Finding | Location | Recommendation |
|----------|----------|---------|----------|----------------|
| P1 Web App Vulnerabilities | Critical/High/Medium/Low/✓ Pass/N/A | Description | file:line | Fix |
| P2 Operator Data Leakage | ... | ... | ... | ... |
| P3 Breach Response | ... | ... | ... | ... |
| P4 Outdated Personal Data | ... | ... | ... | ... |
| P5 Session Expiry | ... | ... | ... | ... |
| P6 Insecure Data Transfer | ... | ... | ... | ... |
| P7 Data Retention | ... | ... | ... | ... |
| P8 Consent | ... | ... | ... | ... |
| P9 Excessive Data Collection | ... | ... | ... | ... |
| P10 Regulatory Compliance | ... | ... | ... | ... |

#### Summary

Provide a brief overall privacy risk assessment (1–3 sentences) and list the top priorities to address.

Severity guide: **Critical** = PII directly exposed or exfiltrated, **High** = likely regulatory violation or significant exposure, **Medium** = needs fixing but lower immediate risk, **Low** = minor hardening or best-practice opportunity. **✓ Pass** = checked, with cited evidence. **N/A** = no matching surface in this code — state the reason, so "not applicable" can never be mistaken for "checked and safe".
