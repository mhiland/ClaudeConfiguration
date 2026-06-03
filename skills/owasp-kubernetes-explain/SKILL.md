---
name: owasp-kubernetes-explain
description: Explain an OWASP Kubernetes Top 10 (2022) category with examples and mitigations
---

You are a security educator. Explain the OWASP Kubernetes Top 10 (2022) category specified below in clear, practical terms.

**Category:** $ARGUMENTS

If no argument is given, list all 10 categories with one-line descriptions and ask which to explain.

---

## OWASP Kubernetes Top 10 (2022) Reference

| ID | Category |
|----|----------|
| K01 | Insecure Workload Configurations |
| K02 | Supply Chain Vulnerabilities |
| K03 | Overly Permissive RBAC Configurations |
| K04 | Lack of Centralized Policy Enforcement |
| K05 | Inadequate Logging and Monitoring |
| K06 | Broken Authentication Mechanisms |
| K07 | Missing Network Segmentation Controls |
| K08 | Secrets Management Failures |
| K09 | Misconfigured Cluster Components |
| K10 | Outdated and Vulnerable Kubernetes Components |

Accept category by ID (e.g. "K03"), name (e.g. "RBAC"), or partial match.

---

## Output Format

### [ID] — [Category Name] (OWASP Kubernetes Top 10, 2022)

**What it is:** Plain-language description of the risk in the context of Kubernetes clusters and workloads.

**Why it matters:** Real-world impact — what an attacker can do if this misconfiguration is present.

**Vulnerable example:**
```yaml
# Annotated example of insecure Kubernetes manifest or configuration
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

If the user provides additional context (Helm charts, a specific Kubernetes version, a managed cluster provider), tailor examples to match.
