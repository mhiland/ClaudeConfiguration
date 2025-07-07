# `/check` - Aggressive Quality Enforcement Command

**THIS IS NOT A REPORTING TASK - THIS IS A FIXING TASK!**

## Mission
Fix ALL code quality issues until EVERY check passes. Zero tolerance for warnings, errors, or style violations.

## Mandatory Actions

### 1. Initial Assessment
- Identify ALL errors, warnings, and style violations
- Document every single issue found
- Create fixing strategy using multiple agents if needed

### 2. Python Quality Enforcement

**Backend Code (Strict Standards):**
- Pylint MUST achieve 10.0/10 score
- Flake8 with `--max-line-length=120 --ignore=E501,W503,W504`
- Autopep8 formatting with 120-char line length
- AUTOMATICALLY FIX all formatting issues

**Frontend Code (Lenient but Still Required):**
- Pylint MUST achieve 7.0/10 minimum
- Same flake8 and autopep8 standards
- Flask template mixing considerations

**General Python (if no backend/frontend structure):**
- Pylint MUST achieve 8.0/10 minimum
- Apply same formatting and linting standards

### 3. JavaScript Quality Enforcement
- JSHint MUST pass on all JavaScript files
- Focus on `frontend/static/js/` directory
- Fix ALL JSHint warnings and errors

### 4. HTML Template Validation
- ALL HTML templates MUST pass html5lib validation
- Fix malformed HTML immediately
- Ensure proper HTML5 structure

### 5. Security Enforcement
- pip-audit MUST show zero vulnerabilities
- Address ALL security issues immediately
- Update packages if required

### 6. Auto-Fixing Protocol

**Immediate Auto-Fixes:**
```bash
# Format all Python code automatically
autopep8 --in-place --recursive --max-line-length=120 .

# Fix common linting issues where possible
# (Use agents for complex fixes)
```

**Agent Delegation:**
- Spawn specialized agents for complex pylint issues
- Use separate agents for different file types
- Continue until ALL agents report success

### 7. Verification Loop

**MUST repeat until ALL checks pass:**
1. Run pylint - FIX any issues
2. Run flake8 - FIX any issues  
3. Run autopep8 - APPLY all fixes
4. Run pip-audit - UPDATE packages if needed
5. Run jshint - FIX JavaScript issues
6. Validate HTML - FIX template issues
7. Run tests if present - FIX any failures

**Exit Criteria:**
- ✅ Pylint: Backend 10.0/10, Frontend 7.0+, General 8.0+
- ✅ Flake8: Zero violations
- ✅ Autopep8: No formatting changes needed
- ✅ pip-audit: Zero vulnerabilities
- ✅ JSHint: Zero warnings/errors
- ✅ HTML validation: All templates valid
- ✅ Tests: All passing (if present)

## Workflow Rules

### Research Phase
- Understand existing code patterns BEFORE fixing
- Identify dependencies and constraints
- Check for project-specific configuration files

### Planning Phase  
- Create systematic fixing approach
- Prioritize critical security issues first
- Plan auto-fixes vs manual interventions

### Implementation Phase
- Fix issues systematically, not randomly
- Validate each fix before moving to next
- Use TodoWrite to track fixing progress

### Agent Usage
- Spawn agents for complex refactoring
- Use parallel agents for different problem domains
- Each agent MUST achieve their specific quality targets

## Forbidden Actions
- ❌ Leaving ANY warnings unfixed
- ❌ Stopping before ALL checks pass
- ❌ Ignoring security vulnerabilities
- ❌ Partial fixes that break other code
- ❌ Adding temporary workarounds instead of real fixes

## Success Criteria
Command is ONLY complete when:
1. ALL quality tools show green/passing status
2. ALL auto-fixable issues have been automatically fixed
3. ALL manual issues have been properly resolved
4. Code maintains or improves functionality
5. No regressions introduced during fixing

## Example Usage Flow
```
User: /check
Claude: 
1. Running comprehensive quality assessment...
2. Found 15 pylint issues, 8 flake8 violations, 3 security issues
3. Spawning fixing agents...
4. Agent 1: Fixing pylint issues in backend/
5. Agent 2: Fixing flake8 violations
6. Agent 3: Updating vulnerable packages
7. Re-running all checks...
8. ✅ ALL CHECKS PASSED - Code quality enforcement complete!
```

**Remember: This is about FIXING, not reporting. Every issue found MUST be resolved.**