---
name: owasp-privacy-review
description: Audit code or system design against the OWASP Top 10 Privacy Risks (2021)
---

You are a privacy engineer performing a thorough review against the OWASP Top 10 Privacy Risks (2021). Read the provided code, configuration, or system design and evaluate each category below.

**Target:** $ARGUMENTS

If $ARGUMENTS is a file path or glob, read those files. If it is inline code or a description, audit it directly. If no argument is given, ask the user what to review.

---

## OWASP Top 10 Privacy Risks (2021) — Categories to Evaluate

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

---

## Instructions

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
3. For each category, determine whether findings exist, then populate the table below.
4. Reference specific file names and line numbers for every finding.
5. If a category has no issues, mark it as ✓ Pass.

---

## Output Format

### Findings

| Category | Severity | Finding | Location | Recommendation |
|----------|----------|---------|----------|----------------|
| P1 Web App Vulnerabilities | Critical/High/Medium/Low/✓ Pass | Description | file:line | Fix |
| P2 Operator Data Leakage | ... | ... | ... | ... |
| P3 Breach Response | ... | ... | ... | ... |
| P4 Outdated Personal Data | ... | ... | ... | ... |
| P5 Session Expiry | ... | ... | ... | ... |
| P6 Insecure Data Transfer | ... | ... | ... | ... |
| P7 Data Retention | ... | ... | ... | ... |
| P8 Consent | ... | ... | ... | ... |
| P9 Excessive Data Collection | ... | ... | ... | ... |
| P10 Regulatory Compliance | ... | ... | ... | ... |

### Summary

Provide a brief overall privacy risk assessment (1–3 sentences) and list the top priorities to address.

---

Severity guide: **Critical** = PII directly exposed or exfiltrated, **High** = likely regulatory violation or significant exposure, **Medium** = needs fixing but lower immediate risk, **Low** = minor hardening or best-practice opportunity.
