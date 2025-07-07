---
name: deployment/validate
description: Pre-deployment validation and readiness check
author: Claude Code Enhanced Setup
version: 1.0
category: deployment
---

# `/deployment/validate` - Pre-deployment Validation

Comprehensive validation checks before deployment to ensure system readiness.

## Usage
```
/deployment/validate [environment] [checklist]
```

**Arguments:**
- `environment`: Target environment (dev/staging/prod, defaults to staging)
- `checklist`: Validation checklist (basic/standard/comprehensive, defaults to standard)

## Pre-deployment Validation Setup
```bash
!echo "Validating deployment readiness for: ${1:-staging}"
!echo "Validation level: ${2:-standard}"
!git status --porcelain
!echo "Last 3 commits:"
!git log --oneline -3
```

## Validation Checks
- All tests passing
- No uncommitted changes
- Dependencies up to date
- Security vulnerabilities addressed
- Performance benchmarks met
- Configuration validated

Ensure deployment readiness with comprehensive validation before releasing to target environment.