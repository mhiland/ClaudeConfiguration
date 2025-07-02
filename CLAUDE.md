# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Base Configuration
This repository **IS** the base configuration source used across multiple projects. All development guidelines defined in `base-config.md` apply to this repository as well.

## Repository Purpose

This is a Claude Code configuration repository that maintains shared development guidelines and base configuration (`base-config.md`) used across multiple projects. The base configuration provides common coding standards, development workflows, and tooling guidance.

## Key Commands

### Setting Up Base Config in New Projects
```bash
# Create symlink to shared config
ln -sf ~/.config/claude/base-config.md .claude-base.md

# Add to gitignore
if ! grep -q ".claude-base.md" .gitignore 2>/dev/null; then
    echo "# Claude shared config symlink" >> .gitignore
    echo ".claude-base.md" >> .gitignore
fi

# Reference in project CLAUDE.md
if ! grep -q "## Base Configuration" CLAUDE.md 2>/dev/null; then
    sed -i '3i\\n## Base Configuration\nThis project inherits common development guidelines from: **[Base Config](.claude-base.md)**\n' CLAUDE.md
fi
```

### Validation Commands
```bash
# Verify symlink works
head -n 3 .claude-base.md

# Check for existing entries before adding to gitignore
grep -q ".claude-base.md" .gitignore
```

## Architecture

This repository serves as a central configuration hub:

- **base-config.md**: Core shared development guidelines covering code quality, testing, security, tooling, and workflows
- **Symlink Integration**: Projects reference this config via symlinks to maintain consistency while allowing project-specific customization
- **Documentation Strategy**: Separates universal practices (base config) from project-specific patterns (individual CLAUDE.md files)

## Configuration Management

The base configuration covers:
- Development environment setup (Python virtual environments, testing frameworks)
- Code quality standards (linting, type checking, security scanning)
- Git workflow patterns and commit message standards
- Task management with TodoWrite tool usage
- Language-specific guidelines (Python, JavaScript)
- Docker containerization best practices
- Cross-project tooling and performance profiling

When modifying `base-config.md`, consider impact across all projects that reference it via symlinks.

## Development Standards

Since this repository serves as the base configuration source, it must follow its own standards:

- Follow all code quality standards defined in `base-config.md`
- Use TodoWrite tool for multi-step tasks
- Be concise and direct in communication
- Never commit changes unless explicitly requested
- Keep commit messages simple and in imperative mood
- Avoid creating unnecessary documentation files
- Make minimal changes that achieve specific goals