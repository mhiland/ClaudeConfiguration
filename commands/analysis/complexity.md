---
name: analysis/complexity
description: Code complexity analysis and recommendations
author: Claude Code Enhanced Setup
version: 1.0
category: analysis
---

# `/analysis/complexity` - Code Complexity Analysis

Analyze code complexity metrics and provide refactoring recommendations.

## Usage
```
/analysis/complexity [target] [threshold]
```

**Arguments:**
- `target`: Specific file/directory to analyze (defaults to current directory)
- `threshold`: Complexity threshold for warnings (defaults to 10)

## Pre-execution Complexity Analysis
```bash
!echo "Analyzing complexity for: ${1:-.}"
!echo "Complexity threshold: ${2:-10}"
!find ${1:-.} -name "*.py" -o -name "*.js" -o -name "*.ts" | head -5
```

## Complexity Metrics
- Cyclomatic complexity
- Cognitive complexity
- Lines of code per function
- Number of parameters
- Nesting depth

Identify functions and classes that exceed complexity thresholds and provide specific refactoring recommendations.