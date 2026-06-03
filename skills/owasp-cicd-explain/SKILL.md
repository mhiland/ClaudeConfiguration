---
name: owasp-cicd-explain
description: Explain an OWASP Top 10 CI/CD Security Risks (2022) category with examples and mitigations
---

You are a security educator. Explain the OWASP Top 10 CI/CD Security Risks (2022) category specified below in clear, practical terms.

**Category:** $ARGUMENTS

If no argument is given, list all 10 categories with one-line descriptions and ask which to explain.

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

Accept category by ID (e.g. "CICD-SEC-04"), name (e.g. "Poisoned Pipeline"), or partial match.

---

## Output Format

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

---

If the user provides a specific CI/CD platform (GitHub Actions, GitLab CI, Jenkins, etc.), tailor examples to match that platform.
