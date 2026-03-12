# Claude Code Base Configuration

This file contains shared instructions and settings that apply across multiple coding projects. These guidelines help maintain consistency and quality in development workflows.

## Initialize Base Config in New Projects

When setting up a new project to use this shared configuration:

```bash
# 1. Create symlink to shared config in project root
ln -sf /home/mhiland/.config/claude/base-config.md .claude-base.md

# 2. Verify symlink creation
ls -la .claude-base.md

# 3. Validate base config is accessible
head -n 3 .claude-base.md

# 4. Add symlink to .gitignore (check for existing entries first)
if ! grep -q ".claude-base.md" .gitignore 2>/dev/null; then
    echo "# Claude shared config symlink" >> .gitignore
    echo ".claude-base.md" >> .gitignore
fi

# 5. Reference base config in project's CLAUDE.md (idempotent)
if ! grep -q "## Base Configuration" CLAUDE.md 2>/dev/null; then
    # Add section after first header
    sed -i '3i\\n## Base Configuration\nThis project inherits common development guidelines from: **[Base Config](.claude-base.md)** - Shared Claude Code configuration with core principles, coding standards, and workflow patterns used across multiple projects.\n' CLAUDE.md
fi
```

## Core Development Principles

### Code Quality Standards
- Always activate Python virtual environments before running commands: `source .venv/bin/activate`
- Run linting and type checking after making changes: `pylint`, `flake8`, `autopep8`
- Ensure all tests pass before considering tasks complete
- Follow existing code conventions and patterns in each project
- Never assume libraries are available - check imports and dependencies first

### Testing Approach
- Distinguish between unit tests (fast, no external dependencies) and integration tests (database, network)
- Run unit tests frequently during development: `python -m pytest tests/unit/ -v`
- Use appropriate test environment variables: `APP_ENV=test` for integration tests
- Verify solutions with tests before marking tasks complete

### Security and Safety
- Never commit secrets, API keys, or credentials to repositories
- Follow principle of least privilege for containers and processes
- Use input validation and sanitization at all layers
- Run security scans: `pip-audit`, `bandit`

## Claude Code Hooks Configuration

### Automated Quality Checks
Add to `~/.claude/settings.json` (the actual Claude Code config directory):

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "~/.config/claude/hooks/quality-check.sh"
          }
        ]
      }
    ]
  }
}
```

### Quality Check Hook
Located at `~/.config/claude/hooks/quality-check.sh`:

```bash
#!/bin/bash
# Auto-detect project type and run appropriate quality checks
set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Running quality checks...${NC}"

# Python projects
if [[ -f "requirements.txt" || -f "pyproject.toml" || -f "setup.py" ]]; then
    echo -e "${GREEN}Python project detected${NC}"
    
    # Python linting with pylint and flake8
    if command -v pylint &> /dev/null; then
        pylint --fail-under=8.0 . || (echo -e "${RED}Pylint issues found${NC}" && exit 1)
    fi
    if command -v flake8 &> /dev/null; then
        flake8 --max-line-length=120 --ignore=E501,W503,W504 . || (echo -e "${RED}Flake8 issues found${NC}" && exit 1)
    fi
    if command -v autopep8 &> /dev/null; then
        autopep8 --diff --recursive --max-line-length=120 . | grep -q . && (echo -e "${RED}Format issues. Run: autopep8 --in-place --recursive --max-line-length=120 .${NC}" && exit 1)
    fi
    
    # Security scanning
    if command -v pip-audit &> /dev/null; then
        pip-audit || (echo -e "${RED}pip-audit found vulnerabilities${NC}" && exit 1)
    fi
fi

# JavaScript/Node projects
if [[ -f "package.json" ]]; then
    echo -e "${GREEN}JavaScript project detected${NC}"
    if command -v npm &> /dev/null && npm list eslint &> /dev/null; then
        npm run lint || (echo -e "${RED}ESLint issues found${NC}" && exit 1)
    fi
fi


echo -e "${GREEN}Quality checks passed!${NC}"
```

## Development Tools

### Performance Profiling
```bash
# Profile Python script performance
python -m cProfile -o profile.stats script.py
python -c "import pstats; pstats.Stats('profile.stats').sort_stats('cumulative').print_stats(20)"

# Memory profiling (requires: pip install memory_profiler)
python -m memory_profiler script.py

# Monitor system resources during execution
htop  # or 'top' on systems without htop
```

### Environment Verification
```bash
# Verify Python environment and key packages
python --version && pip list | head -10

# Check system resources
free -h && df -h

# Verify virtual environment is active
echo $VIRTUAL_ENV || echo "No virtual environment active"

# Check for common development tools
which git && which python && which pip
```

### Cleanup Commands
```bash
# Clean Python cache files
find . -name "*.pyc" -delete
find . -name "__pycache__" -type d -exec rm -rf {} +

# Clean common output directories (adjust patterns as needed)
rm -rf output/ frames/ temp/ *.png *.mp4 *.stats

# Clean Python bytecode (alternative method)
python -Bc "import pathlib; [p.unlink() for p in pathlib.Path('.').rglob('*.py[co]')]"
```

## Custom Commands

### `/check` - Aggressive Quality Enforcement
Located in `~/.claude/commands/check.md`, this command implements zero-tolerance quality enforcement:

- **Auto-fixes ALL formatting issues** with autopep8
- **Enforces strict linting standards**: Backend 10.0/10 pylint, Frontend 10.0/10
- **Spawns multiple agents** to fix complex issues in parallel
- **Continues until EVERY check passes** - no partial fixes allowed
- **Covers all tools**: pylint, flake8, autopep8, pip-audit, jshint, html5lib

Usage: Type `/check` to trigger comprehensive quality enforcement that automatically fixes all detected issues.

## Development Workflow

### Mandatory Three-Phase Approach
1. **Research Phase**: Always understand the codebase before making changes
   - Use search tools to understand existing patterns
   - Read relevant files to understand context
   - Identify dependencies and constraints
2. **Plan Phase**: Create concrete implementation plan
   - Use TodoWrite for multi-step tasks (3+ steps)
   - Break complex problems into manageable pieces
   - Consider edge cases and error handling
3. **Implement Phase**: Execute plan with validation
   - Make changes systematically
   - Validate each step
   - Run quality checks before completion

### Task Management
- Use TodoWrite tool for complex multi-step tasks (3+ steps)
- Mark todos as `in_progress` before starting work
- Mark todos as `completed` immediately after finishing
- Only have one task `in_progress` at a time
- **Stop when stuck**: Delegate complex problems to agents rather than struggling
- **Reality checkpoints**: Regularly assess if approach is working

### Code Changes
- Read existing code first to understand patterns and conventions
- Make minimal changes that achieve the specific goal
- Prefer editing existing files over creating new ones
- Never create documentation files unless explicitly requested

### Implementation Discipline
- **Replace existing implementation entirely** - avoid creating parallel versions of functionality
- **Delete old code when replacing** - eliminate compatibility layers and transition code
- **Fix issues immediately, not "later"** - treat warnings as blocking issues
- **Implement the final design in the first iteration** - avoid temporary solutions that become permanent

### Environment Management
- Check for existing virtual environments before creating new ones
- Use project-specific dependency files (`requirements.txt`, `package.json`)
- Verify database connections and ports before running integration tests
- Use environment variables for configuration, not hard-coded values

## Communication Style
- Be concise and direct - avoid unnecessary explanations
- Answer specific questions without tangential information
- Keep responses under 4 lines unless detail is requested
- Don't add preamble or postamble unless asked
- Use tool results efficiently without over-explaining

## Git and Version Control
- Never commit changes unless explicitly requested
- Run `git status` and `git diff` to understand current state
- Follow existing commit message patterns in the repository
- Check for pre-commit hooks and linting requirements
- Use simple, descriptive commit messages focused on the change
- Do NOT add "Co-Authored-By: Claude" lines to commit messages
- Do NOT add "🤖 Generated with [Claude Code](https://claude.ai/code)" to commit messages
- Keep commit messages concise and in imperative mood

### Common .gitignore Patterns
```gitignore
# Python
__pycache__/
*.py[cod]
*.so
.venv/
env/

# OS
.DS_Store
Thumbs.db
```

## Docker and Containerization
- Use appropriate capabilities (`NET_ADMIN`, `NET_RAW`) for network tools
- Mount host networks when required: `--net=host`
- Check existing Dockerfiles for patterns before creating new ones
- Use multi-stage builds for production optimization

## Language-Specific Guidelines

### Python
- Always use virtual environments
- Follow PEP 8 standards with 120-character line length
- Use descriptive variable names over abbreviations
- Separate concerns with clear service/repository layers
- **Forbidden practices**:
  - No `time.sleep()` in production code (use proper async patterns)
  - No generic `Exception` catching without specific handling
  - No hardcoded paths or configuration values
- **Required practices**:
  - Use concrete types over generic `Any` or `object`
  - Implement proper error handling with specific exception types
  - Use context managers for resource management

### JavaScript
- Use modern ES11+ features when appropriate
- Configure linting with `.jshintrc` for project consistency
- Validate HTML templates with html5lib
- Use consistent indentation and formatting

## File Organization
- Keep project-specific instructions in `CLAUDE.md` files
- Use `docs/` folder for feature documentation
- Maintain module-specific guides (`backend/CLAUDE.md`, `frontend/CLAUDE.md`)
- Update documentation when introducing new patterns or architectures
- Link to shared config in projects: `ln -sf /home/mhiland/.config/claude/base-config.md .claude-base.md`

### Documentation Update Guidelines

**When to Update Documentation**

**Base Config Updates:**
- New cross-project development patterns emerge
- Common workflow improvements are identified across multiple projects
- New tools or standards are adopted organization-wide
- Security practices or guidelines change
- Development environment setup procedures evolve

**Project-Specific Updates:**
- New features that change user workflows or capabilities
- Architectural changes that affect development patterns
- New development tools or testing approaches specific to the project
- Breaking changes to existing functionality
- Security-related changes specific to the project

**Update Triggers for Base Config:**
- ✅ New development tools adopted across projects
- ✅ Changes to coding standards or quality requirements
- ✅ New security practices or compliance requirements
- ✅ Environment setup improvements that benefit multiple projects
- ✅ Cross-project architectural patterns
- ❌ Project-specific features or fixes
- ❌ Minor dependency updates
- ❌ Individual project workflow changes

**Update Triggers for Project Documentation:**
- ✅ New user-facing features
- ✅ New development patterns specific to the project
- ✅ API changes or new endpoints
- ✅ Breaking changes to existing functionality
- ✅ Security-related changes
- ❌ Minor bug fixes
- ❌ Code refactoring without pattern changes
- ❌ Standard dependency updates

## Error Handling
- Check for common issues: missing dependencies, wrong Python version, database connectivity
- Suggest virtual environment activation when Python commands fail
- Provide specific commands for fixing linting or test failures
- Ask for clarification when requirements are ambiguous

These guidelines should be adapted to each project's specific needs while maintaining consistency in development practices.