# Claude Code Base Configuration

Global Claude Code configuration providing comprehensive development guidelines for consistent, high-quality code across all projects.

## Installation

Clone this repository to the expected location:

```bash
git clone https://github.com/mhiland/ClaudeConfiguration.git ~/.claude
```

## What's Included

- **Code Quality**: Linting, type checking, testing standards with automated hooks
- **Security**: Best practices for credentials, input validation, security scans
- **Development Workflow**: Three-phase approach, task management, environment setup
- **Tools & Commands**: Performance profiling, cleanup utilities, environment verification
- **Language Guidelines**: Python (PEP 8), JavaScript (ES11+), Docker containerization
- **Custom Commands**: `/check` command for aggressive quality enforcement
- **Hooks System**: Automated quality checks triggered by file changes
- **Security Skills**: Skills for auditing and explaining code against OWASP Top 10 standards plus deep-dive security and compliance reviews
- **Review Agents**: Subagents for a multi-agent find → fix → verify review fleet

## OWASP Skills

The `skills/` directory contains skills covering eight OWASP Top 10 standards. Each skill
operates in two modes: **explain** a category with examples and mitigations, or **review**
(audit) code against the standard.

| Standard | Skill |
| --- | --- |
| API Security Top 10 (2023) | `owasp-api` |
| Top 10 CI/CD Security Risks (2022) | `owasp-cicd` |
| Kubernetes Top 10 (2022) | `owasp-kubernetes` |
| Top 10 for LLM Applications (2025) | `owasp-llm` |
| Mobile Top 10 (2024) | `owasp-mobile` |
| Top 10 Privacy Risks (2021) | `owasp-privacy` |
| Top 10 Proactive Controls (2024) | `owasp-proactive` |
| Web App Top 10 (2025) | `owasp-web` |

## Deep-Dive & Compliance Skills

Reasoning-driven reviews for specific attack classes and compliance frameworks:

| Skill | Purpose |
| --- | --- |
| `auth-takeover-review` | Audit auth/SSO against account-takeover attack classes |
| `tenant-isolation-review` | Audit multi-tenant code for cross-tenant data exposure (BOLA/IDOR) |
| `supply-chain-review` | Audit dependency/artifact trust for supply-chain compromise |
| `cbom-scan` | Generate a Cryptographic Bill of Materials + post-quantum risk assessment |
| `slsa-compliance` | Assess and remediate a repo's SLSA build-provenance level |
| `fleet-review` | Launch a multi-agent security or performance review fleet |

## Review Agents

The `agents/` directory contains subagent definitions for a project-agnostic
find → fix → verify review fleet. They drive off the target repo's `CLAUDE.md` for
project-specific rules and gates.

| Agent | Role |
| --- | --- |
| `scout` | Read-only scout — audits one scoped surface, grounds findings in quoted code |
| `implementer` | Implements one confirmed finding end-to-end on its own branch (build + test gated) |
| `verifier` | Read-only adversarial verifier — tries to refute a fix, returns APPROVE / FIX_REQUIRED |
