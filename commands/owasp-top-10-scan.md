---
name: owasp-top-10-scan
description: OWASP Top 10 vulnerability scanning for code analysis
author: Claude Code Enhanced Setup
version: 2.0
category: security
---

# OWASP Top 10 Vulnerability Scan

Scan the project for OWASP Top 10 (2021) vulnerabilities. Focus on Python and JavaScript files.

## Step 1: Run Bandit (Python)

Run bandit as the primary automated scanner for Python code:

```bash
source .venv/bin/activate
bandit -r backend/ frontend/ -f json -ll 2>/dev/null
```

Review all bandit findings. Bandit covers injection, hardcoded secrets, weak crypto, and misconfiguration automatically. Incorporate its results into the final report.

## Step 2: Manual Pattern Scanning

For each OWASP category below, use Grep to search for the listed patterns across `backend/` and `frontend/`. Record every match with its absolute file path and line number.

### A01: Broken Access Control

Search for API route definitions that lack authentication decorators or middleware:

- Python: `@app.route` or `@router.` definitions -- flag any that lack a corresponding auth dependency, decorator, or middleware on the same function
- JavaScript: Routes registered without auth middleware

### A02: Cryptographic Failures

Grep patterns (case-insensitive where noted):

- `password\s*=\s*["']` -- hardcoded passwords
- `secret\s*=\s*["']` -- hardcoded secrets
- `api_key\s*=\s*["']` or `apikey\s*=\s*["']` -- hardcoded API keys
- `md5\(` or `hashlib.md5` -- weak hash algorithms
- `sha1\(` or `hashlib.sha1` -- weak hash algorithms
- `DES` or `RC4` or `Blowfish` in crypto contexts
- `verify\s*=\s*False` -- disabled TLS certificate verification

### A03: Injection

Grep patterns:

- `execute\s*\(\s*f"` or `execute\s*\(\s*f'` -- f-string SQL injection
- `execute\s*\(.*%s` where `%` formatting is used outside parameterized queries
- `execute\s*\(.*\+` -- string concatenation in SQL
- `os\.system\(` -- command injection
- `shell\s*=\s*True` -- shell injection via subprocess
- `eval\(` or `exec\(` -- code injection
- `innerHTML` or `outerHTML` or `document\.write` -- DOM-based XSS (JavaScript)
- `\$\(.*\.html\(` -- jQuery HTML injection

### A05: Security Misconfiguration

Grep patterns:

- `debug\s*=\s*True` -- debug mode in production
- `DEBUG\s*=\s*True`
- `CORS\(.*origins\s*=\s*["']\*` -- overly permissive CORS
- `allow_origins=\["?\*` -- wildcard CORS
- `expose_stack_trace` or `traceback\.format_exc` returned in responses
- `SECRET_KEY\s*=\s*["']` -- hardcoded Flask/Django secret keys

### A07: Identification and Authentication Failures

Grep patterns:

- `min.*length.*[0-5][^0-9]` in password validation context -- weak password requirements
- `session.*expire` with very large values
- `token.*expire` with very large values
- Missing rate limiting on login/auth endpoints (search for login routes, check for rate limit decorators)

### A10: Server-Side Request Forgery (SSRF)

Grep patterns:

- `requests\.get\(` or `requests\.post\(` where the URL argument comes from user input (request params, query strings, POST body)
- `urllib\.request\.urlopen\(` with variable URLs
- `fetch\(` in JavaScript where the URL is constructed from user-controlled data
- `httpx\.get\(` or `httpx\.post\(` with variable URLs

## Step 3: Known False Positives

Suppress or note as acceptable the following patterns specific to this project:

- `subprocess.run` in `backend/` monitoring/scanning tools (WiFi and Bluetooth monitoring requires system commands -- this is by design)
- `shell=True` if used only in controlled monitoring scripts with no user-supplied input
- `bandit` nosec comments that have been explicitly reviewed
- Test files (`tests/`) are out of scope unless they contain hardcoded production credentials

## Step 4: Report Findings

Produce a single report organized by OWASP category. For each finding:

```
[SEVERITY] A0X: Category Name
  File: /absolute/path/to/file.py:LINE
  Pattern: description of what was found
  Code: the offending line (trimmed)
  Recommendation: specific fix action
```

Severity levels:
- CRITICAL: Injection, hardcoded production secrets, disabled auth
- HIGH: Weak crypto, missing access control, SSRF
- MEDIUM: Debug mode, verbose errors, weak password policy
- LOW: Missing security headers, logging gaps

At the end of the report, include:
- Total findings by severity
- Total findings by OWASP category
- List of files scanned
- Note any categories with zero findings (this is good -- confirm they were checked)

If zero vulnerabilities are found across all categories, state that explicitly with confirmation that all pattern checks were executed.
