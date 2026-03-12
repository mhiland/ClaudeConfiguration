---
name: dependency-check
description: Dependency vulnerability scanning and security analysis
author: Claude Code Enhanced Setup
version: 2.0
category: security
---

# Dependency Vulnerability Scanner

Scan all project dependencies for known security vulnerabilities. Run every tool, report all findings, and provide actionable remediation.

## Step 1: Detect Dependency Files

Search the project for dependency files:
- Python: `requirements.txt`, `backend/requirements.txt`, `frontend/requirements.txt`, `pyproject.toml`
- JavaScript: `package.json`, `package-lock.json`

List all dependency files found before proceeding.

## Step 2: Run Python Scans

Activate the virtual environment, then run both scanners against every requirements file found:

```bash
source .venv/bin/activate

# pip-audit: checks PyPI advisory database
pip-audit -r requirements.txt
pip-audit -r backend/requirements.txt
pip-audit -r frontend/requirements.txt

# safety: checks Safety DB (if installed)
safety check --file requirements.txt --output json
```

Record every vulnerability with: package name, installed version, severity, CVE ID, and fixed version.

## Step 3: Run JavaScript Scans

If `package.json` exists, run:

```bash
npm audit --json
```

Record every vulnerability with: package name, installed version, severity, CVE ID, and fixed version.

## Step 4: Report Findings

Present results in this exact format:

```
DEPENDENCY VULNERABILITY REPORT
================================

Python Vulnerabilities (pip-audit):
  [SEVERITY] package==version -- CVE-XXXX-XXXXX -- Fixed in: version
  ...
  Total: N vulnerabilities

Python Vulnerabilities (safety):
  [SEVERITY] package==version -- CVE-XXXX-XXXXX -- Fixed in: version
  ...
  Total: N vulnerabilities

JavaScript Vulnerabilities (npm audit):
  [SEVERITY] package@version -- CVE-XXXX-XXXXX -- Fixed in: version
  ...
  Total: N vulnerabilities

SUMMARY: N Python + N JavaScript = N total vulnerabilities
```

If a scanner finds zero vulnerabilities, report "No vulnerabilities found" for that section.
If a scanner is not installed or fails, note the error and continue with remaining scanners.

## Step 5: Remediation

For each vulnerability found, provide:

1. The exact command to update the package:
   - Python: `pip install package==fixed_version` and which requirements file to update
   - JavaScript: `npm install package@fixed_version`

2. Check for breaking changes by reviewing the changelog or release notes between the current and fixed versions. Flag any major version bumps.

3. If no fix is available, recommend whether to:
   - Pin to a non-vulnerable version
   - Find an alternative package
   - Accept the risk with justification

Do NOT make any changes to files. Report only.
