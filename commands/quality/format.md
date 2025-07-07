---
name: quality/format
description: Code formatting with style consistency
author: Claude Code Enhanced Setup
version: 1.0
category: quality
---

# `/quality/format` - Code Formatting

Apply consistent code formatting across the entire codebase.

## Usage
```
/quality/format [target] [style]
```

**Arguments:**
- `target`: Specific file/directory to format (defaults to current directory)
- `style`: Formatting style (pep8/google/black for Python, defaults to project standard)

## Pre-execution Formatting Setup
```bash
!echo "Applying code formatting to: ${1:-.}"
!echo "Style guide: ${2:-project standard}"
!find ${1:-.} -name "*.py" -o -name "*.js" -o -name "*.ts" | head -5
```

## Formatting Standards
- Python: Black/autopep8 with 120 character line length
- JavaScript: Prettier with consistent indentation
- TypeScript: TSLint formatting rules
- JSON: 2-space indentation
- YAML: 2-space indentation

Ensure consistent formatting across the entire codebase while preserving functionality.