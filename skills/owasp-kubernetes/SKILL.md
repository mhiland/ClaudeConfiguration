---
name: owasp-kubernetes
description: "Explain or audit against the OWASP Kubernetes Top 10 (2022). EXPLAIN MODE — the user asks what a Kubernetes security risk means (insecure workload config, overly permissive RBAC, missing network segmentation…), how it's exploited, or how to prevent it (by ID like K03 or name). REVIEW MODE — the user points at K8s manifests or cluster config to audit: manifests, Helm charts, kustomize overlays, RBAC rules, NetworkPolicies, admission/PodSecurity config, or \"is this deployment/chart secure\" — including workload hardening (privileged, hostPath, runAsRoot) and secrets handling in cluster config."
---

You handle the OWASP Kubernetes Top 10 (2022) in two modes. Pick the mode from the argument.

**Target / Category:** $ARGUMENTS

### Mode selection
- If $ARGUMENTS is a category ID (e.g. `K03`), a category name (e.g. "RBAC"), or a partial match → **EXPLAIN MODE**.
- If $ARGUMENTS is a file path, glob, directory, or inline YAML/configuration → **REVIEW MODE**.
- If no argument and you are inside a project → **REVIEW MODE**; scope the review yourself (glob for manifests, charts, and cluster config).
- If no argument and no project context → list the 10 categories with one-line descriptions and ask whether they want one explained or a manifest/cluster review.

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

Accept a category by ID (e.g. "K03"), name (e.g. "RBAC"), or partial match.

---

## EXPLAIN MODE

Act as a security educator. Explain the requested category in clear, practical terms.

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

If the user provides additional context (Helm charts, a specific Kubernetes version, a managed cluster provider), tailor examples to match.

---

## REVIEW MODE

Act as a security engineer performing a thorough review. Read the provided Kubernetes manifests, Helm charts, or cluster configuration files and evaluate each category. If $ARGUMENTS is a file path or glob, read those files. If it is inline YAML/configuration, audit it directly. If it is a directory — or no argument is given and you are inside a project — scope the review yourself: glob for manifests, Helm charts (`Chart.yaml`, `templates/`, `values*.yaml`), kustomize overlays, and RBAC/NetworkPolicy resources instead of asking the user to enumerate files.

### Instructions

1. Read all provided files thoroughly before reporting.
2. Pay special attention to:
   - **Workload configs**: privileged containers, hostPath/hostNetwork/hostPID mounts, missing resource limits, containers running as root, missing readOnlyRootFilesystem
   - **RBAC**: wildcard verbs or resources (`*`), cluster-admin bindings, overly broad service account permissions, default service account usage
   - **Secrets**: plaintext secrets in manifests or env vars, use of Kubernetes Secrets vs. external secret managers, secret encryption at rest
   - **Network policies**: whether NetworkPolicy resources exist and restrict ingress/egress, default-deny posture
   - **Supply chain**: image digest pinning vs. mutable tags, image pull policy, use of trusted/private registries
   - **Admission controllers**: presence of OPA/Gatekeeper, Kyverno, or PodSecurity standards
3. For each category, find the configuration where that risk would live and judge it. Quote or cite the line that proves the control or its absence — if the control lives outside the provided files (cluster-side admission config, managed-provider defaults), say so explicitly rather than assuming it exists.
4. Reference specific file names and line numbers for every finding.
5. Distinguish the two non-finding verdicts: **✓ Pass** = the relevant surface exists and the control is verifiably in place (cite the evidence); **N/A** = the category has no matching surface in these files (state why). Never mark Pass without evidence.
6. A control enforced in the production overlay but missing in a dev/staging overlay, Helm default, or Job/CronJob spec is still a finding.

### Output Format

#### Findings

| Category | Severity | Finding | Location | Recommendation |
|----------|----------|---------|----------|----------------|
| K01 Workload Config | Critical/High/Medium/Low/✓ Pass/N/A | Description | file:line | Fix |
| K02 Supply Chain | ... | ... | ... | ... |
| K03 RBAC | ... | ... | ... | ... |
| K04 Policy Enforcement | ... | ... | ... | ... |
| K05 Logging/Monitoring | ... | ... | ... | ... |
| K06 Authentication | ... | ... | ... | ... |
| K07 Network Segmentation | ... | ... | ... | ... |
| K08 Secrets Management | ... | ... | ... | ... |
| K09 Cluster Components | ... | ... | ... | ... |
| K10 Outdated Components | ... | ... | ... | ... |

#### Summary

Provide a brief overall risk posture assessment (1–3 sentences) and list the top priorities to fix.

Severity guide: **Critical** = exploitable with severe impact, **High** = likely exploitable, **Medium** = needs fixing but lower risk, **Low** = minor hardening opportunity. **✓ Pass** = checked, with cited evidence. **N/A** = no matching surface in these files — state the reason, so "not applicable" can never be mistaken for "checked and safe".
