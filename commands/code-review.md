---
name: code-review
description: Security-focused code review with best practices analysis
author: Claude Code Enhanced Setup
version: 1.0
category: security
---

# `/code-review` - Security-Focused Code Review

Perform comprehensive security code review analyzing best practices, vulnerabilities, and secure coding patterns.

## Usage
```
/code-review [file/directory] [language] [depth]
```

**Arguments:**
- `file/directory`: Target to review (optional, defaults to current directory)
- `language`: Programming language (python/javascript/java/csharp/auto, defaults to auto)
- `depth`: Review depth (quick/standard/comprehensive, defaults to standard)

## Review Depth Levels

### Quick Review
Fast security scan focusing on:
- Input validation patterns
- Authentication mechanisms
- Critical security best practices
- High-risk vulnerability patterns

### Standard Review (Default)
Comprehensive analysis including:
- All quick review areas
- Authorization and access control
- Cryptography implementation
- Error handling and logging
- Session management
- Data protection

### Comprehensive Review
Deep security analysis covering:
- All standard review areas
- Business logic security
- Advanced threat scenarios
- Compliance considerations
- Architecture security patterns
- Performance security implications

## Security Focus Areas

### Input Validation & Sanitization
- User input validation patterns
- Data sanitization techniques
- Injection prevention measures
- File upload security
- API input validation

### Authentication & Authorization
- Authentication mechanism security
- Password handling best practices
- Session management patterns
- Authorization control implementation
- Multi-factor authentication

### Cryptography & Data Protection
- Encryption implementation
- Key management practices
- Hashing algorithm usage
- Certificate validation
- Data storage security

### Error Handling & Logging
- Secure error message patterns
- Exception handling security
- Security event logging
- Information disclosure prevention
- Audit trail implementation

### Session Management
- Session token security
- Session lifecycle management
- Session fixation prevention
- Cross-site request forgery (CSRF) protection
- Secure cookie implementation

## Language-Specific Security Patterns

### Python Security Analysis
```python
# Secure patterns detected:
# ✓ Parameterized queries
cursor.execute("SELECT * FROM users WHERE id = ?", (user_id,))

# ✓ Secure subprocess usage
subprocess.run(['ping', user_input], check=True)

# ✓ Proper exception handling
try:
    process_data(user_input)
except ValidationError as e:
    log_security_event(e)
    return generic_error_response()
```

### JavaScript Security Analysis
```javascript
// Secure patterns detected:
// ✓ Safe DOM manipulation
element.textContent = userInput;

// ✓ Proper JSON handling
const data = JSON.parse(sanitizedInput);

// ✓ Secure HTTP headers
res.setHeader('Content-Security-Policy', 'default-src \'self\'');
```

### Java Security Analysis
```java
// Secure patterns detected:
// ✓ Prepared statements
String sql = "SELECT * FROM users WHERE name = ?";
PreparedStatement stmt = connection.prepareStatement(sql);
stmt.setString(1, userName);

// ✓ Input validation
if (validator.isValid(userInput)) {
    processInput(userInput);
}
```

## Code Review Categories

### Security Vulnerabilities
- OWASP Top 10 compliance
- Common weakness enumeration (CWE) patterns
- Security anti-patterns
- Vulnerability risk assessment

### Best Practices Adherence
- Secure coding standards
- Industry security guidelines
- Framework security features
- Security design patterns

### Architecture Security
- Security-by-design principles
- Threat model alignment
- Security control implementation
- Defense-in-depth strategies

### Compliance & Standards
- Regulatory compliance patterns
- Security standard adherence
- Policy implementation
- Audit trail requirements

## Review Output

### Security Score
- Overall security rating (0-100)
- Category-specific scores
- Improvement recommendations
- Risk assessment summary

### Findings Classification
- **Critical**: Immediate security risks requiring urgent fixes
- **High**: Significant security concerns needing prompt attention
- **Medium**: Security improvements recommended
- **Low**: Best practice enhancements
- **Info**: Security information and recommendations

### Remediation Guidance
- Specific fix recommendations
- Secure code examples
- Best practice references
- Implementation priorities

## Integration with MCP Server

This command leverages the MCP OWASP Security Server:
- Uses the `code-review` tool for multi-language analysis
- Provides structured security assessment
- Includes detailed remediation guidance
- Supports configurable review depth

## Security Metrics

### Code Security Health
- Secure pattern usage percentage
- Vulnerability density metrics
- Security debt assessment
- Compliance score tracking

### Improvement Tracking
- Security issue resolution rate
- Best practice adoption metrics
- Risk reduction measurement
- Code quality trend analysis

## Usage Examples

```bash
# Standard security review of current directory
/code-review

# Quick review of specific file
/code-review src/auth.py python quick

# Comprehensive review of frontend code
/code-review frontend/ javascript comprehensive

# Review Java authentication module
/code-review auth/ java standard
```

## Security Review Checklist

### Pre-Review Setup
- [ ] Identify sensitive data flows
- [ ] Map authentication/authorization points
- [ ] Document security requirements
- [ ] Review threat model alignment

### During Review
- [ ] Validate input sanitization
- [ ] Check authentication mechanisms
- [ ] Verify authorization controls
- [ ] Assess cryptographic usage
- [ ] Review error handling
- [ ] Evaluate logging practices

### Post-Review Actions
- [ ] Prioritize security findings
- [ ] Create remediation plan
- [ ] Update security documentation
- [ ] Schedule follow-up reviews
- [ ] Track security improvements

## Continuous Security Integration

- **Pre-commit Reviews**: Automated security checks before code commits
- **CI/CD Integration**: Security review gates in deployment pipelines
- **Regular Audits**: Scheduled comprehensive security reviews
- **Training Integration**: Developer security awareness enhancement

This security-focused code review provides comprehensive analysis to identify vulnerabilities, ensure best practices, and maintain high security standards throughout the development lifecycle.