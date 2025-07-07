---
name: docs
description: Extract and analyze code documentation
author: Claude Code Enhanced Setup
version: 1.0
category: analysis
---

# `/docs` - Documentation Extraction and Analysis

Extract comprehensive documentation from code using Claude's extended thinking capabilities.

## Usage
```
/docs [target] [format]
```

**Arguments:**
- `target`: Specific file/directory to document (optional, defaults to current directory)
- `format`: Output format (markdown/html/json, defaults to markdown)

## Extended Thinking Analysis

Use extended thinking to:
1. **Analyze code architecture** - Understand the overall structure and patterns
2. **Extract implicit knowledge** - Document undocumented assumptions and behaviors
3. **Identify missing documentation** - Find gaps in existing documentation
4. **Generate API documentation** - Create comprehensive API docs from code
5. **Create usage examples** - Generate practical examples based on code analysis

## Pre-execution Setup
```bash
!echo "Starting documentation extraction for: $ARGUMENTS"
!find . -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.java" -o -name "*.go" | head -20
```

## Documentation Tasks

### 1. Code Structure Analysis
Analyze the codebase structure and create a high-level architectural overview:
- Directory structure and organization
- Module dependencies and relationships
- Design patterns and architectural decisions
- Entry points and main workflows

### 2. API Documentation Generation
For each public API:
- Function/method signatures and parameters
- Return types and possible values
- Error conditions and exceptions
- Usage examples and best practices
- Performance considerations

### 3. Configuration Documentation
Document configuration options:
- Environment variables and their effects
- Configuration file formats and options
- Default values and valid ranges
- Dependencies between configuration options

### 4. Integration Documentation
Document how to integrate with the code:
- Installation and setup instructions
- Required dependencies and versions
- Authentication and authorization
- Common integration patterns

## Output Format
Generate documentation in the requested format:
- **Markdown**: For README files and wikis
- **HTML**: For web-based documentation
- **JSON**: For API documentation tools

## File References
Include relevant code files for context:
@README.md
@docs/
@src/
@lib/
@api/

## Example Output Structure
```markdown
# Project Documentation

## Overview
[High-level description]

## Architecture
[System architecture and design decisions]

## API Reference
[Detailed API documentation]

## Configuration
[Configuration options and examples]

## Examples
[Usage examples and tutorials]

## Troubleshooting
[Common issues and solutions]
```

**Note**: This command uses Claude's extended thinking to provide comprehensive documentation that goes beyond basic code comments.