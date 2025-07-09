# CLAUDE.md

## Repository Purpose
Central Claude Code configuration with comprehensive development guidelines for consistent, high-quality code across all projects.

## Core Development Principles

### Code Quality Standards
- Always activate Python virtual environments before running commands: `source .venv/bin/activate`
- Run linting and type checking after making changes: `pylint`, `flake8`, `autopep8`
- Ensure all tests pass before considering tasks complete
- Follow existing code conventions and patterns in each project
- Never assume libraries are available - check imports and dependencies first
- **Naming conventions**: Use descriptive variable names over abbreviations (e.g., `wifi_access_point_signal_strength` vs `signal`)
- **Module organization**: Use modular architecture with clear separation (API, service, repository layers)
- **Legacy Support**: Do not add extra code for fallback or legacy support

### Testing Approach
- Distinguish between unit tests (fast, no external dependencies) and integration tests (database, network)
- Run unit tests frequently during development: `python -m pytest tests/unit/ -v`
- Use appropriate test environment variables: `APP_ENV=test` for integration tests
- Verify solutions with tests before marking tasks complete
- **Test automation**: Use automated test scripts (e.g., `./run_integration_tests.sh`) for consistent environments

### Security and Safety
- Never commit secrets, API keys, or credentials to repositories
- Follow principle of least privilege for containers and processes
- Use input validation and sanitization at all layers
- Run security scans: `pip-audit`, `bandit`

## Claude Code Hooks Configuration

### Pre-commit Quality Checks
Quality checks now run before git commits using PreToolUse hooks:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash(git commit*)",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/pre-commit-quality.sh",
            "timeout": 15000
          }
        ]
      }
    ]
  }
}
```

### Quality Check Response Protocol
When pre-commit hooks block a commit with quality issues:

1. **Read the error output** - Hook provides specific fix commands
2. **Run the suggested fixes** - Execute each command shown
3. **Stage the fixed files** - `git add <fixed-files>`
4. **Retry the commit** - Re-run the original commit command

**Example workflow:**
```bash
# Commit blocked by quality issues
git commit -m "fix: update feature"
# Hook shows: "Run: autopep8 --in-place --max-line-length=120 file.py"

# Fix the issues
autopep8 --in-place --max-line-length=120 file.py
git add file.py

# Retry commit
git commit -m "fix: update feature"
```

### Unified Quality Standards
All quality tools now use shared standards from `~/.claude/hooks/quality-lib.sh`:

**Python Quality Standards:**
- **Pylint Thresholds**: 
  - Backend: 10.0/10
  - Frontend: 7.0/10
  - General: 8.0/10
- **Flake8**: `--max-line-length=120 --ignore=E501,W503,W504`
- **Autopep8**: `--max-line-length=120`

**JavaScript Quality Standards:**
- **JSHint**: Standard validation
- **Target**: `frontend/static/js/` directory

**HTML Quality Standards:**
- **html5lib**: HTML5 validation
- **Target**: All HTML templates

**Shell Script Quality Standards:**
- **Shellcheck**: Static analysis for shell scripts
- **Shfmt**: Shell script formatting with 2-space indentation (`-i 2 -ci`)
- **Target**: All `.sh` files
- **Installation**: `sudo apt install shellcheck` and `go install mvdan.cc/sh/v3/cmd/shfmt@latest`

**Security Standards:**
- **pip-audit**: Zero vulnerabilities required

### Quality Tools Integration
All quality tools now use the shared library:
- `hooks/pre-commit-quality.sh` - Pre-commit guard
- `hooks/quality-check.sh` - PostToolUse hook
- `commands/check.md` - Aggressive quality enforcement
- `commands/quality/format.md` - Formatting command
- `commands/quality/lint.md` - Linting command

This ensures consistent quality standards across all tools and eliminates code duplication.

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
- **Enforces strict linting standards**: Backend 10.0/10 pylint, Frontend 7.0+
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
- **Base config inheritance**: Use `.claude-base.md` for shared configuration across projects

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
- Keep commit messages concise and in imperative mood
- **Never include Claude attribution**: Do not add "Co-Authored-By: Claude" or "Generated with Claude Code" to commit messages

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
- **Global variables**: Define shared functions in `.jshintrc` to avoid linting errors
- **Test framework**: Use Jest for frontend testing with coverage tracking

## File Organization
- Keep project-specific instructions in `CLAUDE.md` files
- Use `docs/` folder for feature documentation
- Maintain module-specific guides (`backend/CLAUDE.md`, `frontend/CLAUDE.md`)
- Update documentation when introducing new patterns or architectures
- **Documentation and MD files should be in a docs/ folder**

### Documentation Update Guidelines

**Update this config when:**
- New development tools adopted across projects
- Changes to coding standards or quality requirements
- New security practices or compliance requirements
- Environment setup improvements that benefit multiple projects

**Update project documentation when:**
- New user-facing features or API changes
- Architectural changes that affect development patterns
- Breaking changes to existing functionality

## Error Handling
- Check for common issues: missing dependencies, wrong Python version, database connectivity
- Suggest virtual environment activation when Python commands fail
- Provide specific commands for fixing linting or test failures
- Ask for clarification when requirements are ambiguous

These guidelines should be adapted to each project's specific needs while maintaining consistency in development practices.