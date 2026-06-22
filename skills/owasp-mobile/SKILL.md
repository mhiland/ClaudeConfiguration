---
name: owasp-mobile
description: Explain or audit against the OWASP Mobile Top 10 (2024). EXPLAIN MODE — the user asks what a mobile security risk means (insecure data storage, improper credential usage, insufficient binary protections…), how it's exploited, or how to prevent it (by ID like M9 or name). REVIEW MODE — the user points at mobile app code to audit: Android (Kotlin/Java), iOS (Swift/ObjC), React Native, or Flutter — for mobile-class risks like credential/token storage, TLS and certificate pinning, deep-link and intent input validation, on-device data storage, crypto, binary protections.
---

You handle the OWASP Mobile Top 10 (2024) in two modes. Pick the mode from the argument.

**Target / Category:** $ARGUMENTS

### Mode selection
- If $ARGUMENTS is a category ID (e.g. `M9`), a category name (e.g. "Insecure Data Storage"), or a partial match → **EXPLAIN MODE**.
- If $ARGUMENTS is a file path, glob, directory, or inline code → **REVIEW MODE**.
- If no argument and you are inside a project → **REVIEW MODE**; scope the review yourself (locate manifests/entitlements, network/storage layers, auth/keychain code, build config).
- If no argument and no project context → list the 10 categories with one-line descriptions and ask whether they want one explained or a code review.

---

## OWASP Mobile Top 10 (2024) Reference

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

Accept a category by ID (e.g. "M9"), name (e.g. "Insecure Data Storage"), or partial match.

---

## EXPLAIN MODE

Act as a security educator specializing in mobile application security. Explain the requested category in clear, practical terms.

### [ID] — [Category Name] (OWASP Mobile Top 10, 2024)

**What it is:** Plain-language description of the vulnerability class in the mobile app context. Note which platforms (Android, iOS, or both) are most affected.

**Why it matters:** Real-world impact — what an attacker can do if this is present (e.g., extract credentials from a rooted device, intercept traffic, repackage the app).

**Vulnerable example:**
```[language]
// Annotated example of insecure mobile code
```

**Secure example:**
```[language]
// Annotated example of the fix
```

**Mitigation checklist:**
- [ ] Specific, actionable item
- [ ] ...

**Further reading:** Reference OWASP's official Mobile Top 10 page for this category.

If the user provides code context or a specific platform/framework (Android/Kotlin/Java, iOS/Swift, React Native, Flutter, etc.), tailor examples to match.

---

## REVIEW MODE

Act as a security engineer specializing in mobile application security. Read the provided code and evaluate each category. If $ARGUMENTS is a file path or glob, read those files. If it is inline code, audit it directly. If it is a directory — or no argument is given and you are inside a project — scope the review yourself: locate manifests/entitlements (`AndroidManifest.xml`, `Info.plist`), network and storage layers, auth/keychain code, and build config instead of asking the user to enumerate files.

### Instructions

1. Read all provided files thoroughly before reporting.
2. Pay special attention to:
   - Hardcoded credentials, API keys, or tokens in source code or config files
   - How authentication tokens are stored (SharedPreferences, Keychain, local DB, etc.)
   - Network calls — certificate pinning, TLS configuration, cleartext traffic
   - Input validation on data received from intents, deep links, or external sources
   - Use of deprecated or weak crypto algorithms/modes
   - Data written to external storage, logs, or caches
   - Binary protections: obfuscation, root/jailbreak detection, anti-tampering
3. For each category, find the code where that risk would live and judge it. Quote or cite the line that proves the control or its absence — if you cannot find the enforcement point, say so rather than assuming the platform provides it.
4. Reference specific file names and line numbers for every finding.
5. Distinguish the two non-finding verdicts: **✓ Pass** = the relevant surface exists and the control is verifiably in place (cite the evidence); **N/A** = the category has no matching surface in this code (state why). Never mark Pass without evidence.
6. A control enforced in the release build but missing in a debug flavor, test scheme, or platform-specific branch is still a finding.

### Output Format

#### Findings

| Category | Severity | Finding | Location | Recommendation |
|----------|----------|---------|----------|----------------|
| M1 Credential Usage | Critical/High/Medium/Low/✓ Pass/N/A | Description | file:line | Fix |
| M2 Supply Chain | ... | ... | ... | ... |
| M3 Auth/Authorization | ... | ... | ... | ... |
| M4 Input/Output Validation | ... | ... | ... | ... |
| M5 Communication | ... | ... | ... | ... |
| M6 Privacy Controls | ... | ... | ... | ... |
| M7 Binary Protections | ... | ... | ... | ... |
| M8 Misconfiguration | ... | ... | ... | ... |
| M9 Data Storage | ... | ... | ... | ... |
| M10 Cryptography | ... | ... | ... | ... |

#### Summary

Provide a brief overall risk posture assessment (1–3 sentences) and list the top priorities to fix.

Severity guide: **Critical** = exploitable with severe impact, **High** = likely exploitable, **Medium** = needs fixing but lower risk, **Low** = minor hardening opportunity. **✓ Pass** = checked, with cited evidence. **N/A** = no matching surface in this code — state the reason, so "not applicable" can never be mistaken for "checked and safe".
