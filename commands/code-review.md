---
name: code-review
description: Security-focused code review with best practices analysis
author: Claude Code Enhanced Setup
version: 2.0
category: security
---

# Security Code Review

Perform a security-focused code review of the target path. Default to the project root if no argument is given.

**Argument:** `$ARGUMENTS` (file or directory path, optionally followed by `quick`, `standard`, or `comprehensive`)

Parse the argument: extract the target path (default: project root) and depth level (default: `standard`).

## Step 1: Identify Target Files

Use Glob and Read to collect the files under review. Focus on Python (.py) and JavaScript (.js) files. Exclude virtual environments, node_modules, and __pycache__ directories.

## Step 2: Run Static Analysis Tools

Run these commands in bash (activate venv first). Capture and parse the output.

```bash
source .venv/bin/activate

# Bandit security scan for Python (if Python files exist)
bandit -r <target_path> -f json -ll 2>/dev/null || true

# Grep-based pattern scanning (always run)
# SQL injection - string concatenation in queries
grep -rn --include="*.py" -E "(execute|cursor|query)\(.*(%s|format|f\"|\\+.*input)" <target_path> || true

# Command injection - shell=True or unsanitized subprocess
grep -rn --include="*.py" -E "(subprocess\.(call|run|Popen).*shell\s*=\s*True|os\.system\()" <target_path> || true

# Hardcoded secrets - passwords, tokens, keys in assignments
grep -rn --include="*.py" --include="*.js" --include="*.yml" --include="*.yaml" --include="*.json" -iE "(password|secret|api_key|token|private_key)\s*[:=]\s*['\"][^'\"]{4,}" <target_path> || true

# Dangerous deserialization
grep -rn --include="*.py" -E "(pickle\.loads?|yaml\.load\((?!.*Loader)|marshal\.loads?)" <target_path> || true

# XSS - innerHTML or unsafe Jinja rendering
grep -rn --include="*.js" "\.innerHTML\s*=" <target_path> || true
grep -rn --include="*.html" -E "\{\{.*\|.*safe\}\}|\{% autoescape false %\}" <target_path> || true

# Path traversal
grep -rn --include="*.py" -E "(open\(|send_file\(|send_from_directory\().*\+(.*input|.*request|.*param)" <target_path> || true

# Debug/development leftovers
grep -rn --include="*.py" -E "(debug\s*=\s*True|app\.run\(.*debug)" <target_path> || true
grep -rn --include="*.py" --include="*.js" -E "(print\(.*password|console\.log\(.*token|console\.log\(.*secret)" <target_path> || true

# Weak cryptography
grep -rn --include="*.py" -E "(md5|sha1)\(" <target_path> || true

# Broad exception handling hiding errors
grep -rn --include="*.py" -E "except\s*(Exception|BaseException)\s*:" <target_path> || true

# Insecure HTTP
grep -rn --include="*.py" --include="*.js" -E "http://" <target_path> | grep -v "localhost\|127\.0\.0\.1\|#\|test" || true
```

## Step 3: Manual Code Analysis

Read each file and analyze for issues that grep cannot catch:

- **Authentication/Authorization**: Missing auth checks on endpoints, privilege escalation paths
- **Input validation**: Unvalidated user input reaching database queries, file operations, or system calls
- **Error handling**: Sensitive data leaked in error messages, stack traces exposed to users
- **Business logic**: Race conditions, TOCTOU bugs, insecure direct object references
- **Configuration**: Permissive CORS, missing security headers, overly broad permissions

### Depth Adjustments

- **quick**: Run Step 2 only. Report grep and bandit findings without manual file analysis.
- **standard**: Run Steps 2 and 3. Analyze key files (routes, auth, database access, config).
- **comprehensive**: Run Steps 2 and 3. Analyze every file. Additionally check: dependency versions for known CVEs, Docker configurations for privilege issues, environment variable handling, logging of sensitive data, and timing attack vectors.

## Step 4: Report Findings

Present findings in this exact format:

```
SECURITY CODE REVIEW
====================
Target: <path reviewed>
Depth:  <quick|standard|comprehensive>
Files:  <count> analyzed

FINDINGS
--------

[CRITICAL] <Title>
  File: <absolute path>:<line number>
  Issue: <one-line description of the vulnerability>
  Evidence: <the offending code snippet>
  Fix: <concrete remediation with code example>

[HIGH] <Title>
  File: <absolute path>:<line number>
  Issue: <description>
  Evidence: <code snippet>
  Fix: <remediation>

[MEDIUM] <Title>
  ...

[LOW] <Title>
  ...

SUMMARY
-------
Critical: <n>  High: <n>  Medium: <n>  Low: <n>

<One paragraph with the most important action items>
```

Severity definitions:
- **CRITICAL**: Exploitable vulnerability (injection, RCE, auth bypass, hardcoded secrets)
- **HIGH**: Likely exploitable or high-impact issue (weak crypto, missing auth, SSRF)
- **MEDIUM**: Defense-in-depth gap (broad exceptions, missing input validation, debug mode)
- **LOW**: Best practice deviation (insecure defaults, minor information disclosure)

If no findings are discovered, state that explicitly. Do not fabricate issues.
