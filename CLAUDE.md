# CLAUDE.md

## Base Configuration
This repository **IS** the base configuration source. All development guidelines are defined in `base-config.md` and apply to this repository.

## Repository Purpose
Central Claude Code configuration hub that provides shared development guidelines via `base-config.md` for use across multiple projects through symlink integration.

## Configuration Components
- **`base-config.md`** - Single source of truth for all development standards
- **`skills/`** - Security and compliance skills (OWASP Top 10 audits/explainers plus deep-dive and compliance reviews)
- **`agents/`** - Subagent definitions for the find → fix → verify review fleet (`scout`, `implementer`, `verifier`)
- **`settings.json`** - Reference settings (permissions, env, model defaults)

## Important: Claude Code Config Directory
Claude Code reads configuration from `~/.claude/`, NOT from this directory. This repo is the
source of truth; activate a component by deploying it into `~/.claude/` (copy skills into
`~/.claude/skills/`, agents into `~/.claude/agents/`, and merge any desired settings into
`~/.claude/settings.json`).

## Repository-Specific Notes
When modifying `base-config.md`, consider impact across all projects that reference it via symlinks. Changes propagate to all linked projects immediately.
