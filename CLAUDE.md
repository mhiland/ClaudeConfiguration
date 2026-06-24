# CLAUDE.md

## Base Configuration
This repository **IS** the base configuration source. All development guidelines are defined in `base-config.md` and apply to this repository.

## Repository Purpose
Central Claude Code configuration hub that provides shared development guidelines via `base-config.md` for use across multiple projects through symlink integration.

## Configuration Components
- **`base-config.md`** - Single source of truth for all development standards
- **`skills/`** - Security and compliance skills (OWASP Top 10 audits/explainers plus deep-dive and compliance reviews), plus the `fleet-review` launcher
- **`agents/`** - Subagent definitions for the review fleet: the find → fix → verify triad (`scout`, `implementer`, `verifier`) plus `security-reviewer` (deep single-MR/surface review that routes to a deep-dive skill and may file issues + fix branches)
- **`workflows/`** - Scripted multi-agent `Workflow` fan-outs: `security-review.js` (11-scout sweep → per-finding fix + adversarial-verify pipeline) and `performance-review.js` (5-scout scale sweep → ranked synthesis), both launched by `fleet-review` and tuned for dependably-community (adapt the `SCOUTS` bodies for other stacks); `feature-review.js` (parallel recon → plan) and `documentation-review.js` (per-page grounding audit + answerability gate → consolidated report, the `documentation` skill's REVIEW mode), both stack-agnostic (operate in the current working directory).
- **`settings.json`** - Reference settings (permissions, env, model defaults)

## Important: Claude Code Config Directory
Claude Code reads configuration from `~/.claude/`, NOT from this directory. This repo is the
source of truth; activate a component by deploying it into `~/.claude/` (copy skills into
`~/.claude/skills/`, agents into `~/.claude/agents/`, workflow scripts into
`~/.claude/workflows/`, and merge any desired settings into `~/.claude/settings.json`).

## Repository-Specific Notes
When modifying `base-config.md`, consider impact across all projects that reference it via symlinks. Changes propagate to all linked projects immediately.
