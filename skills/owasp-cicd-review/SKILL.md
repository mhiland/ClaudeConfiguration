---
name: owasp-cicd-review
description: Audit CI/CD pipeline configuration and code against the OWASP Top 10 CI/CD Security Risks (2022)
---

You are a security engineer performing a thorough review against the OWASP Top 10 CI/CD Security Risks (2022). Read the provided pipeline configuration files, scripts, and supporting code and evaluate each category below.

**Target:** $ARGUMENTS

If $ARGUMENTS is a file path or glob, read those files. If it is inline configuration, audit it directly. If no argument is given, ask the user what to review.

---

## OWASP Top 10 CI/CD Security Risks (2022) — Categories to Evaluate

| ID | Category |
|----|----------|
| CICD-SEC-01 | Insufficient Flow Control Mechanisms |
| CICD-SEC-02 | Inadequate Identity and Access Management |
| CICD-SEC-03 | Dependency Chain Abuse |
| CICD-SEC-04 | Poisoned Pipeline Execution (PPE) |
| CICD-SEC-05 | Insufficient PBAC (Pipeline-Based Access Controls) |
| CICD-SEC-06 | Insufficient Credential Hygiene |
| CICD-SEC-07 | Insecure System Configuration |
| CICD-SEC-08 | Ungoverned Usage of 3rd-Party Services |
| CICD-SEC-09 | Improper Artifact Integrity Validation |
| CICD-SEC-10 | Insufficient Logging and Visibility |

---

## Instructions

1. Read all provided files thoroughly before reporting.
2. Pay special attention to:
   - Pipeline YAML files (GitHub Actions, GitLab CI, Jenkins, CircleCI, etc.) for unsafe triggers, missing branch protections, and direct code execution from untrusted input
   - Third-party actions/orbs/plugins — whether they are pinned to a commit SHA vs. a mutable tag
   - Secrets and credentials: hardcoded values, overly broad scopes, exposure in logs or environment variables
   - Dependency lockfiles and how packages are fetched — pinned vs. floating versions, use of private registries
   - Artifact handling — whether build outputs are signed, checksums validated, and provenance tracked
   - IAM permissions granted to pipeline service accounts and tokens — least privilege vs. over-permissioned
3. For each category, determine whether findings exist, then populate the table below.
4. Reference specific file names and line numbers for every finding.
5. If a category has no issues, mark it as ✓ Pass.

---

## Output Format

### Findings

| Category | Severity | Finding | Location | Recommendation |
|----------|----------|---------|----------|----------------|
| CICD-SEC-01 Flow Control | Critical/High/Medium/Low/✓ Pass | Description | file:line | Fix |
| CICD-SEC-02 IAM | ... | ... | ... | ... |
| CICD-SEC-03 Dependency Chain | ... | ... | ... | ... |
| CICD-SEC-04 Poisoned Pipeline | ... | ... | ... | ... |
| CICD-SEC-05 PBAC | ... | ... | ... | ... |
| CICD-SEC-06 Credential Hygiene | ... | ... | ... | ... |
| CICD-SEC-07 System Config | ... | ... | ... | ... |
| CICD-SEC-08 3rd-Party Services | ... | ... | ... | ... |
| CICD-SEC-09 Artifact Integrity | ... | ... | ... | ... |
| CICD-SEC-10 Logging/Visibility | ... | ... | ... | ... |

### Summary

Provide a brief overall risk posture assessment (1–3 sentences) and list the top priorities to fix.

---

Severity guide: **Critical** = exploitable with severe impact, **High** = likely exploitable, **Medium** = needs fixing but lower risk, **Low** = minor hardening opportunity.
