# Claude Code Base Configuration

Shared development guidelines and configuration used across multiple coding projects.

## Installation

Clone this repository to the expected location:

```bash
git clone https://github.com/mhiland/ClaudeConfiguration.git ~/.config/claude
```

## Purpose

This repository provides a centralized `base-config.md` file that projects can reference via symlinks to maintain consistent development practices, coding standards, and workflows.

## Setup for New Projects

To use this configuration in your projects, ask Claude Code:

```
Read this config and follow its setup ~/.config/claude/base-config.md
```

Claude will automatically create the symlink, update gitignore, and reference the base config in your project's CLAUDE.md file.

## What's Included

- **Code Quality**: Linting, type checking, testing standards
- **Security**: Best practices for credentials, input validation, security scans
- **Development Workflow**: Task management, environment setup, git practices
- **Tools & Commands**: Performance profiling, cleanup utilities, environment verification
- **Language Guidelines**: Python (PEP 8), JavaScript (ES11+), Docker containerization

## Files

- `base-config.md` - Core shared development guidelines
- `CLAUDE.md` - Project-specific instructions for this repository

## Usage

Projects reference the base configuration through symlinks, allowing them to inherit common standards while maintaining project-specific customizations in their own `CLAUDE.md` files.
