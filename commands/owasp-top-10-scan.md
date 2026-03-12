---
name: owasp-top-10-scan
description: OWASP Top 10 vulnerability scanning for code analysis
author: Claude Code Enhanced Setup
version: 1.0
category: security
---

# `/owasp-top-10-scan` - OWASP Top 10 Vulnerability Scanner

Scan code for OWASP Top 10 web application security vulnerabilities using pattern-based detection.

## Usage
```
/owasp-top-10-scan [file/directory] [language]
```

**Arguments:**
- `file/directory`: Target to scan (optional, defaults to current directory)
- `language`: Programming language (python/javascript/auto, defaults to auto)

## OWASP Top 10 Coverage

This scanner detects vulnerabilities across all OWASP Top 10 2021 categories:

### A01: Broken Access Control
- Missing authorization checks on routes/endpoints
- Insecure direct object references
- Privilege escalation vulnerabilities
- Cross-origin resource sharing (CORS) misconfigurations

### A02: Cryptographic Failures
- Hardcoded secrets, API keys, passwords
- Weak cryptographic algorithms (MD5, SHA1, DES, RC4)
- Missing encryption for sensitive data
- Improper certificate validation

### A03: Injection
- SQL injection via string concatenation/f-strings
- Command injection through os.system, subprocess
- NoSQL injection patterns
- LDAP injection vectors

### A04: Insecure Design
- Missing security controls in business logic
- Inadequate input validation patterns
- Insufficient security architecture

### A05: Security Misconfiguration
- Debug mode enabled in production
- Verbose error messages leaking information
- Default credentials usage
- Missing security headers

### A06: Vulnerable and Outdated Components
- Outdated dependency patterns
- Known vulnerability signatures
- Insecure library usage

### A07: Identification and Authentication Failures
- Weak authentication patterns
- Session management flaws
- Missing multi-factor authentication
- Brute force vulnerabilities

### A08: Software and Data Integrity Failures
- Unsigned code execution patterns
- Insecure update mechanisms
- Missing integrity checks

### A09: Security Logging and Monitoring Failures
- Missing security event logging
- Insufficient monitoring patterns
- Log injection vulnerabilities

### A10: Server-Side Request Forgery (SSRF)
- URL fetching with user input
- Internal service exposure
- Cloud metadata access patterns

## Scan Implementation

The scanner uses multiple detection methods:

1. **Pattern Matching**: Regex patterns for common vulnerability signatures
2. **Context Analysis**: Multi-line code context for complex vulnerabilities
3. **Language-Specific Detection**: Tailored patterns for Python and JavaScript
4. **CWE Mapping**: Each finding includes relevant CWE (Common Weakness Enumeration) ID

## Output Format

Scan results include:
- **Vulnerability Type**: OWASP category and specific issue
- **Severity**: Critical/High/Medium/Low risk assessment
- **Location**: File path, line number, and column
- **CWE ID**: Common Weakness Enumeration identifier
- **Remediation**: Specific fix recommendations
- **Code Snippet**: Problematic code context

## Example Vulnerabilities Detected

### Python Examples
```python
# A02: Cryptographic Failures
password = "hardcoded_secret"  # DETECTED: Hardcoded secret

# A03: Injection
cursor.execute(f"SELECT * FROM users WHERE id = {user_id}")  # DETECTED: SQL injection

# A05: Security Misconfiguration
app.run(debug=True)  # DETECTED: Debug mode enabled
```

### JavaScript Examples
```javascript
// A03: Injection
db.query("SELECT * FROM users WHERE name = '" + userName + "'");  // DETECTED: SQL injection

// A10: SSRF
fetch(userProvidedURL);  // DETECTED: SSRF vulnerability
```

## Integration with MCP Server

This command integrates with the MCP OWASP Security Server:
- Uses the `owasp-scan` tool for comprehensive analysis
- Leverages production-ready vulnerability detection patterns
- Provides structured scan results with detailed remediation guidance

## Scan Performance

- **Speed**: Pattern-based detection for fast analysis
- **Coverage**: Comprehensive OWASP Top 10 vulnerability detection
- **Accuracy**: Minimizes false positives through context-aware patterns
- **Scalability**: Handles large codebases efficiently

## Usage Examples

```bash
# Scan current directory with auto language detection
/owasp-top-10-scan

# Scan specific file
/owasp-top-10-scan src/auth.py python

# Scan directory with language specification
/owasp-top-10-scan frontend/ javascript
```

## Security Best Practices

After scanning, prioritize fixes based on:
1. **Critical**: Injection, hardcoded secrets, crypto failures
2. **High**: Access control, authentication issues
3. **Medium**: Misconfigurations, logging failures
4. **Low**: Information disclosure, monitoring gaps

## Continuous Security

Integrate scanning into development workflow:
- Pre-commit hooks for vulnerability detection
- CI/CD pipeline security gates
- Regular security scans on production code
- Developer training on secure coding practices

This scanner provides the foundation for secure development by identifying OWASP Top 10 vulnerabilities early in the development lifecycle.