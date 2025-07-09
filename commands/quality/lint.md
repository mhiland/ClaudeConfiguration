---
name: quality/lint
description: Focused linting with unified quality standards
author: Claude Code Enhanced Setup
version: 2.0
category: quality
---

# `/quality/lint` - Focused Linting with Unified Standards

Run targeted linting using unified quality standards with automatic fixes.

## Unified Quality Standards

### Python Linting
- **Pylint Thresholds**: 
  - Backend: 10.0/10
  - Frontend: 7.0/10
  - General: 8.0/10
- **Flake8**: `--max-line-length=120 --ignore=E501,W503,W504`
- **Autopep8**: `--max-line-length=120`

### JavaScript Linting
- **JSHint**: Standard validation
- **Target**: `frontend/static/js/` directory

### HTML Linting
- **html5lib**: HTML5 validation
- **Target**: All HTML templates

## Usage
```
/quality/lint [target] [autofix]
```

**Arguments:**
- `target`: Specific file/directory to lint (defaults to current directory)
- `autofix`: Enable automatic fixes (true/false, defaults to true)

## Implementation
This command uses the shared quality library (`~/.claude/hooks/quality-lib.sh`) to ensure consistent standards across all quality tools.

```bash
# Source shared quality library
source ~/.claude/hooks/quality-lib.sh

# Run linting using unified standards
for file in $(find ${1:-.} -name "*.py" -o -name "*.js" -o -name "*.html"); do
    issues=()
    fixes=()
    
    # Check file quality
    check_file_quality "$file" issues fixes
    
    # Apply automatic fixes if enabled
    if [[ "${2:-true}" == "true" ]]; then
        for fix in "${fixes[@]}"; do
            eval "$fix"
        done
    fi
    
    # Report remaining issues
    for issue in "${issues[@]}"; do
        echo "Issue: $issue"
    done
done
```

This ensures linting is consistent with pre-commit hooks and the `/check` command.