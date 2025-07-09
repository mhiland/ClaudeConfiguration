---
name: quality/format
description: Code formatting with unified quality standards
author: Claude Code Enhanced Setup
version: 2.0
category: quality
---

# `/quality/format` - Code Formatting

Apply consistent code formatting using unified quality standards.

## Unified Quality Standards

### Python Standards
- **Line Length**: 120 characters
- **Tool**: autopep8 with `--max-line-length=120`
- **Pylint Thresholds**: 
  - Backend: 10.0/10
  - Frontend: 7.0/10
  - General: 8.0/10
- **Flake8**: `--max-line-length=120 --ignore=E501,W503,W504`

### JavaScript Standards
- **Tool**: JSHint validation
- **Target**: `frontend/static/js/` directory

### HTML Standards
- **Tool**: html5lib validation
- **Target**: All HTML templates

## Usage
```
/quality/format [target]
```

**Arguments:**
- `target`: Specific file/directory to format (defaults to current directory)

## Implementation
This command uses the shared quality library (`~/.claude/hooks/quality-lib.sh`) to ensure consistent standards across all quality tools.

```bash
# Source shared quality library
source ~/.claude/hooks/quality-lib.sh

# Apply formatting using unified standards (respects CLAUDE_LOG_LEVEL from settings.json)
for file in $(find ${1:-.} -name "*.py" -o -name "*.js" -o -name "*.html"); do
    check_file_quality "$file" issues fixes
    # Apply automatic fixes
    for fix in "${fixes[@]}"; do
        eval "$fix"
    done
done
```

**Output**: Respects `CLAUDE_LOG_LEVEL` from settings.json (default: `error` for quiet operation).  
**Consistency**: Ensures formatting is consistent with pre-commit hooks and the `/check` command.