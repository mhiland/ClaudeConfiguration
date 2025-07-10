---
name: quality  
description: Unified quality checking and fixing with parameterized modes
author: Claude Code Enhanced Setup
version: 3.0
category: quality
---

# `/quality` - Unified Quality Management

Unified command for all quality operations using centralized standards from `~/.claude/quality-standards.json`.

## Usage
```
/quality [mode] [target] [options]
```

### Modes
- `check` - Aggressive quality enforcement (zero tolerance, auto-fix everything)
- `lint` - Focused linting with optional auto-fix  
- `format` - Apply code formatting only
- `report` - Generate quality report without fixing

### Arguments
- `target` - File/directory to process (defaults to current directory)
- `options` - Mode-specific options:
  - `--no-fix` - Disable automatic fixes (lint/check modes)
  - `--project` - Scan entire project (default: modified files only)
  - `--type=TYPE` - Limit to specific file types (python,javascript,html,shell)

## Implementation

### Bypass Hook Configuration (for check/format modes)
```bash
export CLAUDE_HOOK_BYPASS=true  # Prevent circular hook calls
export CLAUDE_OPERATION_CONTEXT=quality  # Mark as quality operation
```

### Quality Standards Integration
```bash
# Load unified standards from JSON
source ~/.claude/hooks/quality-lib.sh

# Standards automatically loaded from ~/.claude/quality-standards.json:
# - Python: Pylint thresholds (Backend: 10.0, Frontend: 7.0, General: 8.0)
# - Python: Flake8 120-char line length, ignore E501,W503,W504
# - Python: Autopep8 120-char formatting
# - JavaScript: JSHint validation for frontend/static/js/
# - HTML: html5lib validation for all templates
# - Shell: Shellcheck + shfmt with 2-space indentation
# - Security: pip-audit with zero vulnerabilities
```

### Mode Implementations

#### Check Mode (Zero Tolerance)
```bash
# Initial project scan
export CLAUDE_QUALITY_MODE=project
echo "=== SCANNING ENTIRE PROJECT FOR ISSUES ===" >&2

# Find all code files
files=$(find ${target:-.} -name "*.py" -o -name "*.js" -o -name "*.html" -o -name "*.sh")

# Process each file
for file in $files; do
    check_file_quality "$file"
    
    # Apply ALL fixes automatically
    for fix in "${QUALITY_FIXES[@]}"; do
        echo "Applying fix: $fix" >&2
        eval "$fix"
    done
done

# Verify all issues are resolved
echo "=== VERIFICATION PASS ===" >&2
# Re-run checks to ensure everything passes
```

#### Lint Mode
```bash
# Targeted linting with optional fixes
for file in $(find ${target:-.} -name "*.py" -o -name "*.js" -o -name "*.html" -o -name "*.sh"); do
    check_file_quality "$file"
    
    # Report issues
    for issue in "${QUALITY_ISSUES[@]}"; do
        echo "Issue: $issue"
    done
    
    # Apply fixes if enabled (default: true)
    if [[ "${autofix:-true}" == "true" ]]; then
        for fix in "${QUALITY_FIXES[@]}"; do
            eval "$fix"
        done
    fi
done
```

#### Format Mode
```bash
# Apply formatting only
for file in $(find ${target:-.} -name "*.py" -o -name "*.js" -o -name "*.html" -o -name "*.sh"); do
    file_type=$(get_file_type "$file")
    
    case "$file_type" in
        "python")
            autopep8 --in-place --max-line-length=120 "$file"
            ;;
        "shell")
            shfmt -w -i 2 -ci "$file"
            ;;
        "javascript"|"html")
            echo "No automatic formatting for $file_type files"
            ;;
    esac
done
```

#### Report Mode
```bash
# Generate quality report without fixing
echo "=== QUALITY REPORT ===" >&2
for file in $(find ${target:-.} -name "*.py" -o -name "*.js" -o -name "*.html" -o -name "*.sh"); do
    check_file_quality "$file"
    
    if [[ ${#QUALITY_ISSUES[@]} -gt 0 ]]; then
        echo "File: $file"
        for issue in "${QUALITY_ISSUES[@]}"; do
            echo "  - $issue"
        done
    fi
done
```

## Logging
- Respects `CLAUDE_LOG_LEVEL` from settings.json (default: `error`)
- Uses unified logging from quality-lib.sh
- Outputs structured results for easy parsing

## Benefits
- **Single Source of Truth**: All standards defined in `quality-standards.json`
- **Consistent Behavior**: Same logic across all quality operations
- **Simplified Maintenance**: One command instead of three separate files
- **Flexible Usage**: Different modes for different workflows
- **No Duplication**: Eliminates redundant standard definitions