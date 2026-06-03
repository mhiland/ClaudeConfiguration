---
name: owasp-mobile-review
description: Audit mobile app code against the OWASP Mobile Top 10 (2024)
---

You are a security engineer specializing in mobile application security. Perform a thorough review against the OWASP Mobile Top 10 (2024). Read the provided code and evaluate each category below.

**Target:** $ARGUMENTS

If $ARGUMENTS is a file path or glob, read those files. If it is inline code, audit it directly. If no argument is given, ask the user what to review.

---

## OWASP Mobile Top 10 (2024) — Categories to Evaluate

| ID | Category |
|----|----------|
| M1 | Improper Credential Usage |
| M2 | Inadequate Supply Chain Security |
| M3 | Insecure Authentication/Authorization |
| M4 | Insufficient Input/Output Validation |
| M5 | Insecure Communication |
| M6 | Inadequate Privacy Controls |
| M7 | Insufficient Binary Protections |
| M8 | Security Misconfiguration |
| M9 | Insecure Data Storage |
| M10 | Insufficient Cryptography |

---

## Instructions

1. Read all provided files thoroughly before reporting.
2. Pay special attention to:
   - Hardcoded credentials, API keys, or tokens in source code or config files
   - How authentication tokens are stored (SharedPreferences, Keychain, local DB, etc.)
   - Network calls — certificate pinning, TLS configuration, cleartext traffic
   - Input validation on data received from intents, deep links, or external sources
   - Use of deprecated or weak crypto algorithms/modes
   - Data written to external storage, logs, or caches
   - Binary protections: obfuscation, root/jailbreak detection, anti-tampering
3. For each category, determine whether findings exist, then populate the table below.
4. Reference specific file names and line numbers for every finding.
5. If a category has no issues, mark it as ✓ Pass.

---

## Output Format

### Findings

| Category | Severity | Finding | Location | Recommendation |
|----------|----------|---------|----------|----------------|
| M1 Credential Usage | Critical/High/Medium/Low/✓ Pass | Description | file:line | Fix |
| M2 Supply Chain | ... | ... | ... | ... |
| M3 Auth/Authorization | ... | ... | ... | ... |
| M4 Input/Output Validation | ... | ... | ... | ... |
| M5 Communication | ... | ... | ... | ... |
| M6 Privacy Controls | ... | ... | ... | ... |
| M7 Binary Protections | ... | ... | ... | ... |
| M8 Misconfiguration | ... | ... | ... | ... |
| M9 Data Storage | ... | ... | ... | ... |
| M10 Cryptography | ... | ... | ... | ... |

### Summary

Provide a brief overall risk posture assessment (1–3 sentences) and list the top priorities to fix.

---

Severity guide: **Critical** = exploitable with severe impact, **High** = likely exploitable, **Medium** = needs fixing but lower risk, **Low** = minor hardening opportunity.
