---
name: security-review
description: Comprehensive security analysis and vulnerability assessment
author: Claude Code Enhanced Setup
version: 1.0
category: security
---

# `/security-review` - Comprehensive Security Analysis

Perform in-depth security analysis covering OWASP Top 10, secure coding practices, and vulnerability assessment.

## Usage
```
/security-review [target] [depth]
```

**Arguments:**
- `target`: Specific file/directory to analyze (optional, defaults to entire codebase)
- `depth`: Analysis depth (quick/standard/comprehensive, defaults to standard)

## Pre-analysis Security Setup
```bash
!echo "Starting security analysis for: ${1:-entire codebase}"
!echo "Analysis depth: ${2:-standard}"
!find . -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.java" | head -10
```

## Security Analysis Framework

### 1. OWASP Top 10 Assessment

**A01: Broken Access Control**
- Authentication bypass vulnerabilities
- Privilege escalation opportunities
- Missing authorization checks
- Insecure direct object references
- Cross-origin resource sharing (CORS) misconfigurations

**A02: Cryptographic Failures**
- Weak encryption algorithms
- Hardcoded secrets and keys
- Insecure random number generation
- Missing encryption for sensitive data
- Improper certificate validation

**A03: Injection Attacks**
- SQL injection vulnerabilities
- Command injection risks
- LDAP injection possibilities
- NoSQL injection vectors
- OS command injection

**A04: Insecure Design**
- Missing security controls
- Inadequate threat modeling
- Insufficient security architecture
- Business logic vulnerabilities
- Lack of security-by-design principles

**A05: Security Misconfiguration**
- Default credentials usage
- Unnecessary services enabled
- Verbose error messages
- Missing security headers
- Outdated software versions

**A06: Vulnerable Components**
- Outdated dependencies
- Known security vulnerabilities
- Unpatched security issues
- Unnecessary components
- Supply chain risks

**A07: Authentication Failures**
- Weak password policies
- Session management flaws
- Missing multi-factor authentication
- Account enumeration vulnerabilities
- Brute force attack vectors

**A08: Software and Data Integrity**
- Unsigned code execution
- Insecure CI/CD pipelines
- Compromised update mechanisms
- Tampering risks
- Integrity verification failures

**A09: Logging and Monitoring**
- Insufficient logging
- Missing security monitoring
- Inadequate incident response
- Log injection vulnerabilities
- Sensitive data in logs

**A10: Server-Side Request Forgery**
- SSRF vulnerabilities
- Internal service exposure
- Cloud metadata access
- Network segmentation bypass
- URL validation bypass

### 2. Secure Coding Practices Review

**Input Validation:**
- Validate all user inputs
- Sanitize data before processing
- Use parameterized queries
- Implement proper encoding
- Check file upload restrictions

**Output Encoding:**
- Context-aware encoding
- XSS prevention measures
- Content Security Policy (CSP)
- HTML entity encoding
- URL encoding practices

**Error Handling:**
- Secure error messages
- Proper exception handling
- Information disclosure prevention
- Logging security events
- Fail-safe defaults

**Session Management:**
- Secure session tokens
- Session timeout policies
- Session fixation prevention
- Cross-site request forgery (CSRF) protection
- Secure cookie attributes

### 3. Language-Specific Security Issues

**Python Security:**
```python
# Insecure: SQL injection risk
cursor.execute("SELECT * FROM users WHERE id = " + user_id)

# Secure: Parameterized query
cursor.execute("SELECT * FROM users WHERE id = ?", (user_id,))

# Insecure: Command injection
os.system("ping " + user_input)

# Secure: Subprocess with shell=False
subprocess.run(["ping", user_input], check=True)
```

**JavaScript Security:**
```javascript
// Insecure: XSS vulnerability
element.innerHTML = userInput;

// Secure: Safe text content
element.textContent = userInput;

// Insecure: Eval usage
eval(userCode);

// Secure: JSON parsing
JSON.parse(userData);
```

**Java Security:**
```java
// Insecure: SQL injection
String query = "SELECT * FROM users WHERE name = '" + userName + "'";

// Secure: Prepared statement
String query = "SELECT * FROM users WHERE name = ?";
PreparedStatement stmt = connection.prepareStatement(query);
stmt.setString(1, userName);
```

### 4. Infrastructure Security

**Container Security:**
- Base image vulnerabilities
- Privileged container usage
- Resource limitations
- Network security policies
- Secrets management

**Cloud Security:**
- IAM permissions review
- Network security groups
- Encryption at rest/transit
- API security configurations
- Compliance requirements

**Database Security:**
- Access control policies
- Encryption implementation
- Audit logging
- Backup security
- Network isolation

### 5. Dependency Security

**Vulnerability Scanning:**
- Known CVE identification
- Dependency tree analysis
- License compliance check
- End-of-life component detection
- Security advisory monitoring

**Supply Chain Security:**
- Package integrity verification
- Dependency pinning
- Private registry usage
- Build reproducibility
- Code signing validation

## Security Testing Integration

### Static Analysis Security Testing (SAST)
```bash
# Python security scanning
bandit -r . -f json -o security_report.json

# JavaScript security scanning
npm audit

# Generic security patterns
grep -r "password\|secret\|token" --include="*.py" --include="*.js" .
```

### Dynamic Analysis Security Testing (DAST)
- Penetration testing strategies
- Vulnerability scanning
- Security regression testing
- Fuzz testing implementation
- Runtime security monitoring

### Interactive Application Security Testing (IAST)
- Real-time vulnerability detection
- Code coverage-based testing
- Runtime security analysis
- Performance impact assessment
- Continuous security monitoring

## Threat Modeling

### Asset Identification
- Sensitive data classification
- System component mapping
- Trust boundary definition
- Attack surface analysis
- Business impact assessment

### Threat Identification
- STRIDE threat modeling
- Attack tree construction
- Threat actor profiling
- Attack vector analysis
- Risk likelihood assessment

### Vulnerability Assessment
- Security control effectiveness
- Exploit probability evaluation
- Impact severity analysis
- Risk prioritization
- Mitigation strategy development

## Security Compliance

### Industry Standards
- OWASP ASVS compliance
- NIST Cybersecurity Framework
- ISO 27001 requirements
- PCI DSS standards
- GDPR privacy requirements

### Regulatory Compliance
- HIPAA security rules
- SOX compliance requirements
- FERPA privacy standards
- CCPA data protection
- Industry-specific regulations

## File References
Analyze these files for security issues:
@config/
@src/
@api/
@auth/
@database/
@deployment/
@secrets/
@certificates/

## Security Metrics and Reporting

### Vulnerability Metrics
- Critical/High/Medium/Low severity counts
- Time to remediation tracking
- Vulnerability trend analysis
- Security debt quantification
- Fix verification status

### Security Posture Assessment
- Security control coverage
- Risk exposure evaluation
- Compliance gap analysis
- Security maturity assessment
- Continuous improvement tracking

## Remediation Guidance

### Immediate Actions
- Fix critical vulnerabilities
- Remove hardcoded secrets
- Update vulnerable dependencies
- Implement input validation
- Add security headers

### Long-term Improvements
- Implement security architecture
- Enhance monitoring capabilities
- Establish security processes
- Provide security training
- Regular security assessments

## Integration with Development Workflow

### Pre-commit Security Checks
```bash
# Security linting
pre-commit run --all-files

# Dependency vulnerability check
safety check

# Secret scanning
detect-secrets scan --all-files
```

### CI/CD Security Integration
- Security testing in pipelines
- Vulnerability scanning automation
- Security gate enforcement
- Compliance reporting
- Risk-based deployment decisions

## Success Criteria
Security review is successful when:
- All critical vulnerabilities identified and prioritized
- Secure coding practices documented
- Compliance requirements validated
- Risk assessment completed
- Remediation plan established

**Note**: This command provides comprehensive security analysis following industry best practices and regulatory requirements.
