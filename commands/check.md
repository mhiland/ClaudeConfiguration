# `/check` - Advanced Quality Enforcement Command

**THIS IS NOT A REPORTING TASK - THIS IS A FIXING TASK!**

## Mission
Fix ALL code quality issues until EVERY check passes. Zero tolerance for warnings, errors, or style violations with intelligent automation and performance tracking.

## Enhanced Workflow

### Phase 1: Quick Assessment
- **Early Success Detection**: Run all quality checks immediately
- **Performance Tracking**: Start timer and measure each tool execution
- **Smart Exit**: If all checks pass, report success immediately without agents

### Phase 2: Issue Analysis (if needed)
- **Issue Categorization**: Group by severity (critical/security/style)
- **Priority Matrix**: Security > Functionality > Style > Documentation
- **Agent Planning**: Determine which agents are needed based on issue types

### Phase 3: Intelligent Fixing
- **Conditional Agent Spawning**: Only spawn agents when complex issues detected
- **Parallel Processing**: Run compatible fixes simultaneously
- **Real-time Progress**: Show incremental improvements

### Phase 4: Integration Validation
- **Functionality Testing**: Run tests after fixes to prevent regressions
- **Git Integration**: Show modified files and suggest commit message
- **Performance Metrics**: Report total time and bottlenecks

## Quality Standards

### Python Quality Enforcement

**Backend Code (Strict Standards):**
- Pylint MUST achieve 10.0/10 score
- Flake8 with `--max-line-length=120 --ignore=E501,W503,W504`
- Autopep8 formatting with 120-char line length
- isort for import sorting
- AUTOMATICALLY FIX all formatting issues

**Frontend Code (Lenient but Consistent):**
- Pylint MUST achieve 7.0/10 minimum
- Same flake8 and autopep8 standards
- Flask template mixing considerations

**General Python (if no backend/frontend structure):**
- Pylint MUST achieve 8.0/10 minimum
- Apply same formatting and linting standards

### JavaScript Quality Enforcement
- JSHint MUST pass on all JavaScript files
- Focus on `frontend/static/js/` directory (exclude vendor/)
- Auto-fix common issues: missing semicolons, unused vars
- Fix ALL JSHint warnings and errors

### HTML Template Validation
- ALL HTML templates MUST pass html5lib validation
- Fix malformed HTML immediately
- Ensure proper HTML5 structure and accessibility

### Security Enforcement
- pip-audit MUST show zero vulnerabilities
- safety check for known vulnerabilities
- bandit security scan for code issues
- Auto-update packages when safe
- Address ALL security issues immediately

## Enhanced Auto-Fixing Protocol

### Immediate Auto-Fixes (Applied First):
```bash
# 1. Format all Python code automatically
autopep8 --in-place --recursive --max-line-length=120 .

# 2. Sort imports automatically
isort --line-length 120 .

# 3. Fix trailing whitespace and end-of-file issues
# (Built into most tools)
```

### Intelligent Agent Delegation:

**Security Agent** (Spawned for security issues):
- pip-audit failures
- bandit security warnings
- Package vulnerability updates
- Credential scanning

**Style Agent** (Spawned for bulk style issues):
- Complex pylint violations (>5 issues)
- Large-scale refactoring needs
- Docstring generation
- Naming convention fixes

**JavaScript Agent** (Spawned for JS issues):
- Complex JSHint violations
- Cross-file dependency issues
- ES6+ modernization needs
- Function scope problems

**Template Agent** (Spawned for HTML issues):
- HTML5 validation errors
- Accessibility improvements
- Template inheritance issues
- Asset reference problems

### Agent Coordination Rules:
- **File Locking**: Prevent agents from modifying same files simultaneously
- **Dependency Awareness**: Style agents wait for security agents
- **Progress Reporting**: Each agent reports completion status
- **Rollback Capability**: Track changes for potential rollback

## Performance Monitoring

### Metrics Tracked:
- **Total Execution Time**: Start to completion
- **Tool Performance**: Individual tool execution times
- **Issue Breakdown**: Count by category and severity
- **Fix Efficiency**: Issues fixed per minute
- **Agent Utilization**: Which agents were needed and their performance

### Progress Reporting:
```
🔍 Quick Assessment: 2.3s
   ✅ Backend Pylint: 10.0/10 (0.8s)
   ✅ Frontend Pylint: 10.0/10 (0.4s)  
   ✅ Flake8: 0 violations (0.3s)
   ⚠️  JSHint: 1 error found (0.2s)
   ✅ HTML: All valid (0.6s)

🔧 Auto-Fixing: 0.3s
   ✅ Autopep8: No changes needed
   ✅ Import sorting: No changes needed

🤖 Agent Deployment: JavaScript Agent (0.5s)
   ✅ Fixed: Unused expression in main.js

🧪 Integration Testing: 1.2s
   ✅ Unit tests: All passing
   ✅ No regressions detected

📊 Summary: 4.3s total, 1 issue fixed, 0 regressions
```

## Project Intelligence

### Configuration Awareness:
- **Auto-detect project structure**: backend/, frontend/, or general Python
- **Respect existing configs**: .pylintrc, .jshintrc, pyproject.toml, setup.cfg
- **Custom thresholds**: Use project-specific quality targets if configured
- **Environment detection**: development vs CI/CD vs production standards

### Framework-Specific Handling:
- **Flask projects**: Handle template/static file mixing
- **FastAPI projects**: Focus on async/await patterns
- **Django projects**: Handle apps structure
- **Package projects**: Focus on public API quality

## Enhanced Verification Loop

### Incremental Verification:
1. **Run quick checks first** (flake8, basic syntax)
2. **Apply auto-fixes** (autopep8, isort)
3. **Re-run quick checks** to verify auto-fixes
4. **Run comprehensive checks** (pylint, security scans)
5. **Deploy agents** only if issues remain
6. **Validate each fix** before proceeding
7. **Run integration tests** after all fixes
8. **Generate final report** with metrics

### Smart Exit Conditions:
- ✅ **Early Success**: All checks pass immediately
- ✅ **Incremental Success**: All issues fixed progressively
- ⚠️ **Partial Success**: Major issues fixed, minor warnings documented
- ❌ **Failure**: Unable to fix critical issues (rare, requires manual intervention)

## Integration Testing

### Post-Fix Validation:
```bash
# 1. Run project tests if they exist
pytest tests/ -x --tb=short  # Exit on first failure
npm test                     # Frontend tests
python -m doctest            # Docstring tests

# 2. Check for functionality regressions
python -c "import sys; sys.exit(0)"  # Basic import test
flask --help >/dev/null 2>&1         # Flask app validation

# 3. Verify git status
git status --porcelain  # Show modified files
git diff --stat         # Show change summary
```

### Regression Prevention:
- **Import validation**: Ensure all modules still import correctly
- **Syntax checking**: Verify Python syntax is valid
- **Basic functionality**: Run smoke tests if available
- **Configuration validation**: Check that configs are still valid

## Git Integration

### Change Tracking:
```
📝 Files Modified:
   M frontend/static/js/main.js (1 line)
   
🔧 Fixes Applied:
   ✅ JSHint: Fixed unused expression
   
💡 Suggested Commit Message:
   Fix code quality issues found by /check command
   
   - Fix JSHint unused expression in main.js
   
   🤖 Generated with Claude Code /check command
```

### Smart Commit Suggestions:
- **Categorize changes**: Group fixes by tool/type
- **Generate descriptive messages**: Include specific fixes applied
- **Preserve attribution**: Note automated vs manual fixes
- **Suggest staging**: Recommend which files to stage

## Error Handling & Recovery

### Graceful Degradation:
- **Tool unavailable**: Skip non-critical checks, warn user
- **Agent failures**: Continue with remaining agents, report failures
- **Test failures**: Report but don't block quality fixes
- **Network issues**: Handle pip-audit/security check failures gracefully

### Recovery Mechanisms:
- **Backup creation**: Automatically backup files before major changes
- **Rollback capability**: Quick rollback if tests fail after fixes
- **Safe mode**: Option to run read-only analysis first
- **Incremental mode**: Fix one category at a time for debugging

## Success Criteria (Enhanced)

Command is ONLY complete when:
1. **ALL quality tools show green/passing status**
2. **ALL auto-fixable issues have been automatically fixed**
3. **ALL manual issues have been properly resolved**
4. **Integration tests pass** (if available)
5. **No regressions introduced** during fixing
6. **Performance metrics recorded** and reported
7. **Git status clean** or changes documented

## Example Enhanced Usage Flow

```
User: /check

Claude: 🔍 Running quick assessment...

⚡ Early Success Detection (2.1s):
   ✅ Backend Pylint: 10.0/10 
   ✅ Frontend Pylint: 10.0/10
   ✅ Flake8: 0 violations
   ⚠️  JSHint: 1 error (frontend/static/js/main.js:670)
   ✅ HTML: All 10 templates valid
   ✅ Security: pip-audit clean

🔧 Auto-fixing JavaScript issue...
   ✅ Fixed unused expression in main.js

🧪 Integration validation (0.8s):
   ✅ All imports valid
   ✅ No test regressions

📊 Quality Enforcement Complete (3.2s total):
   🎯 1 issue fixed, 0 regressions
   📝 1 file modified: frontend/static/js/main.js
   🚀 All quality checks now passing!

💡 Ready for commit:
   git add frontend/static/js/main.js
   git commit -m "Fix JSHint unused expression in main.js"
```

**Remember: This command provides intelligent automation while maintaining the zero-tolerance approach to code quality issues.**