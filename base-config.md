# Claude Code Base Configuration

This file contains shared instructions and settings that apply across multiple coding projects. These guidelines help maintain consistency and quality in development workflows.

## Initialize Base Config in New Projects

When setting up a new project to use this shared configuration:

```bash
# 1. Create symlink to shared config in project root
ln -sf ~/.config/claude/base-config.md .claude-base.md

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
- Run linting and type checking after making changes: `pylint`, `flake8`, `mypy`
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
- Run security scans: `safety check`, `bandit`, `pip-audit`

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

## Development Workflow

### Task Management
- Use TodoWrite tool for complex multi-step tasks (3+ steps)
- Mark todos as `in_progress` before starting work
- Mark todos as `completed` immediately after finishing
- Only have one task `in_progress` at a time

### Code Changes
- Read existing code first to understand patterns and conventions
- Make minimal changes that achieve the specific goal
- Prefer editing existing files over creating new ones
- Never create documentation files unless explicitly requested

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
# Serena cache (allow .serena/ but ignore cache)
.serena/cache/

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
- Link to shared config in projects: `ln -sf ~/.config/claude/base-config.md .claude-base.md`

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