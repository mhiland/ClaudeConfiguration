---
name: quality/lint
description: Focused linting with automatic fixes
author: Claude Code Enhanced Setup
version: 1.0
category: quality
---

# `/quality/lint` - Focused Linting with Auto-fix

Run targeted linting with automatic fixes and comprehensive error reporting.

## Usage
```
/quality/lint [target] [autofix]
```

**Arguments:**
- `target`: Specific file/directory to lint (defaults to current directory)
- `autofix`: Enable automatic fixes (true/false, defaults to true)

## Pre-execution Linting Setup
```bash
!echo "Starting focused linting for: ${1:-.}"
!echo "Auto-fix enabled: ${2:-true}"
!find ${1:-.} -name "*.py" -o -name "*.js" -o -name "*.ts" | head -5
```

## Automatic Fixes Applied
- Python: autopep8 formatting
- JavaScript: ESLint auto-fixes
- TypeScript: TSLint auto-fixes
- JSON: Format and validate
- YAML: Format and validate

Focus on immediate, safe automatic fixes while reporting complex issues for manual review.