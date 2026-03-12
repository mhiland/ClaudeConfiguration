# CLAUDE.md

## Base Configuration
This repository **IS** the base configuration source. All development guidelines are defined in `base-config.md` and apply to this repository.

## Repository Purpose
Central Claude Code configuration hub that provides shared development guidelines via `base-config.md` for use across multiple projects through symlink integration.

## Configuration Components
- **`base-config.md`** - Single source of truth for all development standards
- **`commands/check.md`** - Source for the `/check` command (deployed to `~/.claude/commands/check.md`)
- **`hooks/quality-check.sh`** - Quality check hook script (configured via `~/.claude/settings.json`)

## Important: Claude Code Config Directory
Claude Code reads configuration from `~/.claude/`, NOT from this directory. To activate components:
- **Commands**: Copy to `~/.claude/commands/` (e.g., `cp commands/check.md ~/.claude/commands/`)
- **Hooks**: Reference this directory's scripts from `~/.claude/settings.json`

## Repository-Specific Notes
When modifying `base-config.md`, consider impact across all projects that reference it via symlinks. Changes propagate to all linked projects immediately.
