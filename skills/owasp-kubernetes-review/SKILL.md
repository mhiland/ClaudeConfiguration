---
name: owasp-kubernetes-review
description: Audit Kubernetes manifests and cluster configuration against the OWASP Kubernetes Top 10 (2022)
---

You are a security engineer performing a thorough review against the OWASP Kubernetes Top 10 (2022). Read the provided Kubernetes manifests, Helm charts, or cluster configuration files and evaluate each category below.

**Target:** $ARGUMENTS

If $ARGUMENTS is a file path or glob, read those files. If it is inline YAML/configuration, audit it directly. If no argument is given, ask the user what to review.

---

## OWASP Kubernetes Top 10 (2022) — Categories to Evaluate

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

---

## Instructions

1. Read all provided files thoroughly before reporting.
2. Pay special attention to:
   - **Workload configs**: privileged containers, hostPath/hostNetwork/hostPID mounts, missing resource limits, containers running as root, missing readOnlyRootFilesystem
   - **RBAC**: wildcard verbs or resources (`*`), cluster-admin bindings, overly broad service account permissions, default service account usage
   - **Secrets**: plaintext secrets in manifests or env vars, use of Kubernetes Secrets vs. external secret managers, secret encryption at rest
   - **Network policies**: whether NetworkPolicy resources exist and restrict ingress/egress, default-deny posture
   - **Supply chain**: image digest pinning vs. mutable tags, image pull policy, use of trusted/private registries
   - **Admission controllers**: presence of OPA/Gatekeeper, Kyverno, or PodSecurity standards
3. For each category, determine whether findings exist, then populate the table below.
4. Reference specific file names and line numbers for every finding.
5. If a category has no issues, mark it as ✓ Pass.

---

## Output Format

### Findings

| Category | Severity | Finding | Location | Recommendation |
|----------|----------|---------|----------|----------------|
| K01 Workload Config | Critical/High/Medium/Low/✓ Pass | Description | file:line | Fix |
| K02 Supply Chain | ... | ... | ... | ... |
| K03 RBAC | ... | ... | ... | ... |
| K04 Policy Enforcement | ... | ... | ... | ... |
| K05 Logging/Monitoring | ... | ... | ... | ... |
| K06 Authentication | ... | ... | ... | ... |
| K07 Network Segmentation | ... | ... | ... | ... |
| K08 Secrets Management | ... | ... | ... | ... |
| K09 Cluster Components | ... | ... | ... | ... |
| K10 Outdated Components | ... | ... | ... | ... |

### Summary

Provide a brief overall risk posture assessment (1–3 sentences) and list the top priorities to fix.

---

Severity guide: **Critical** = exploitable with severe impact, **High** = likely exploitable, **Medium** = needs fixing but lower risk, **Low** = minor hardening opportunity.
