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
- **OWASP Skills**: Skills for auditing and explaining code against OWASP Top 10 standards

## OWASP Skills

The `skills/` directory contains skills covering eight OWASP Top 10 standards. Each
standard has an `-explain` skill (explain a category with examples and mitigations)
and a `-review` skill (audit code against the standard):

| Standard | Explain | Review |
| --- | --- | --- |
| API Security Top 10 (2023) | `owasp-api-explain` | `owasp-api-review` |
| Top 10 CI/CD Security Risks (2022) | `owasp-cicd-explain` | `owasp-cicd-review` |
| Kubernetes Top 10 (2022) | `owasp-kubernetes-explain` | `owasp-kubernetes-review` |
| Top 10 for LLM Applications (2025) | `owasp-llm-explain` | `owasp-llm-review` |
| Mobile Top 10 (2024) | `owasp-mobile-explain` | `owasp-mobile-review` |
| Top 10 Privacy Risks (2021) | `owasp-privacy-explain` | `owasp-privacy-review` |
| Top 10 Proactive Controls (2024) | `owasp-proactive-explain` | `owasp-proactive-review` |
| Web App Top 10 (2021) | `owasp-web-explain` | `owasp-web-review` |
