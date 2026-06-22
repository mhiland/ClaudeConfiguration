---
name: owasp-cicd
description: "Explain or audit against the OWASP Top 10 CI/CD Security Risks (2022). EXPLAIN MODE — the user asks what a CI/CD risk means (poisoned pipeline execution, dependency chain abuse, PBAC…), how it's exploited, or how to prevent it (by ID like CICD-SEC-04 or name). REVIEW MODE — the user points at pipeline config to audit: pipeline YAML (GitHub Actions, GitLab CI, Jenkins, CircleCI…), runner/executor config, release or publish jobs, pipeline secrets and token scopes, or third-party action/plugin usage — including \"is this workflow safe\", \"review my pipeline\", or PPE / poisoned-pipeline / pwn-request concerns. For artifact/dependency trust beyond the pipeline itself, prefer supply-chain-review."
---

You handle the OWASP Top 10 CI/CD Security Risks (2022) in two modes. Pick the mode from the argument.

**Target / Category:** $ARGUMENTS

### Mode selection
- If $ARGUMENTS is a category ID (e.g. `CICD-SEC-04`), a category name (e.g. "Poisoned Pipeline"), or a partial match → **EXPLAIN MODE**.
- If $ARGUMENTS is a file path, glob, directory, or inline pipeline configuration → **REVIEW MODE**.
- If no argument and you are inside a project → **REVIEW MODE**; scope the review yourself (glob for pipeline files and CI config).
- If no argument and no project context → list the 10 categories with one-line descriptions and ask whether they want one explained or a pipeline review.

---

## OWASP Top 10 CI/CD Security Risks (2022) Reference

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

Accept a category by ID (e.g. "CICD-SEC-04"), name (e.g. "Poisoned Pipeline"), or partial match.

---

## EXPLAIN MODE

Act as a security educator. Explain the requested category in clear, practical terms.

### [ID] — [Category Name] (OWASP CI/CD Security Top 10, 2022)

**What it is:** Plain-language description of the risk in the context of CI/CD pipelines.

**Why it matters:** Real-world impact — what an attacker can do if this risk is present.

**Vulnerable example:**
```yaml
# Annotated example of insecure pipeline configuration or code
```

**Secure example:**
```yaml
# Annotated example of the fix
```

**Mitigation checklist:**
- [ ] Specific, actionable item
- [ ] ...

**Further reading:** Reference OWASP's official page for this category.

If the user provides a specific CI/CD platform (GitHub Actions, GitLab CI, Jenkins, etc.), tailor examples to match that platform.

---

## REVIEW MODE

Act as a security engineer performing a thorough review. Read the provided pipeline configuration files, scripts, and supporting code and evaluate each category. If $ARGUMENTS is a file path or glob, read those files. If it is inline configuration, audit it directly. If it is a directory — or no argument is given and you are inside a project — scope the review yourself: glob for pipeline files (`.github/workflows/`, `.gitlab-ci.yml` + includes, `Jenkinsfile`, `.circleci/`), CI scripts, and registry/credential config instead of asking the user to enumerate files.

### Instructions

1. Read all provided files thoroughly before reporting.
2. Pay special attention to:
   - Pipeline YAML files (GitHub Actions, GitLab CI, Jenkins, CircleCI, etc.) for unsafe triggers, missing branch protections, and direct code execution from untrusted input
   - Third-party actions/orbs/plugins — whether they are pinned to a commit SHA vs. a mutable tag
   - Secrets and credentials: hardcoded values, overly broad scopes, exposure in logs or environment variables
   - Dependency lockfiles and how packages are fetched — pinned vs. floating versions, use of private registries
   - Artifact handling — whether build outputs are signed, checksums validated, and provenance tracked
   - IAM permissions granted to pipeline service accounts and tokens — least privilege vs. over-permissioned
3. For each category, find the configuration where that risk would live and judge it. Quote or cite the line that proves the control or its absence — if you cannot find the enforcement point (e.g. a branch protection that lives server-side), say so explicitly rather than assuming it exists.
4. Reference specific file names and line numbers for every finding.
5. Distinguish the two non-finding verdicts: **✓ Pass** = the relevant surface exists and the control is verifiably in place (cite the evidence); **N/A** = the category has no matching surface in this config (state why). Never mark Pass without evidence.
6. A control enforced on the main pipeline but missing on a scheduled, tag, fork-PR, or manual job is still a finding.

### Output Format

#### Findings

| Category | Severity | Finding | Location | Recommendation |
|----------|----------|---------|----------|----------------|
| CICD-SEC-01 Flow Control | Critical/High/Medium/Low/✓ Pass/N/A | Description | file:line | Fix |
| CICD-SEC-02 IAM | ... | ... | ... | ... |
| CICD-SEC-03 Dependency Chain | ... | ... | ... | ... |
| CICD-SEC-04 Poisoned Pipeline | ... | ... | ... | ... |
| CICD-SEC-05 PBAC | ... | ... | ... | ... |
| CICD-SEC-06 Credential Hygiene | ... | ... | ... | ... |
| CICD-SEC-07 System Config | ... | ... | ... | ... |
| CICD-SEC-08 3rd-Party Services | ... | ... | ... | ... |
| CICD-SEC-09 Artifact Integrity | ... | ... | ... | ... |
| CICD-SEC-10 Logging/Visibility | ... | ... | ... | ... |

#### Summary

Provide a brief overall risk posture assessment (1–3 sentences) and list the top priorities to fix.

Severity guide: **Critical** = exploitable with severe impact, **High** = likely exploitable, **Medium** = needs fixing but lower risk, **Low** = minor hardening opportunity. **✓ Pass** = checked, with cited evidence. **N/A** = no matching surface in this config — state the reason, so "not applicable" can never be mistaken for "checked and safe".
