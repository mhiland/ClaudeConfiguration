---
name: dependency-check
description: Dependency vulnerability scanning and security analysis
author: Claude Code Enhanced Setup
version: 1.0
category: security
---

# `/dependency-check` - Dependency Vulnerability Scanner

Scan project dependencies for known security vulnerabilities across multiple package ecosystems.

## Usage
```
/dependency-check [file/directory] [ecosystem]
```

**Arguments:**
- `file/directory`: Target dependency file or directory (optional, defaults to current directory)
- `ecosystem`: Package ecosystem (npm/pip/maven/gradle/auto, defaults to auto)

## Supported Ecosystems

### npm (Node.js)
- **Files**: `package.json`, `package-lock.json`, `yarn.lock`
- **Registry**: npm registry vulnerability database
- **Analysis**: Direct and transitive dependency vulnerabilities

### pip (Python)
- **Files**: `requirements.txt`, `Pipfile`, `poetry.lock`, `pyproject.toml`
- **Registry**: PyPI security advisory database
- **Analysis**: Package version vulnerability mapping

### Maven (Java)
- **Files**: `pom.xml`, `maven-dependencies.txt`
- **Registry**: Maven Central security database
- **Analysis**: JAR dependency security assessment

### Gradle (Java/Android)
- **Files**: `build.gradle`, `gradle.lockfile`
- **Registry**: Gradle dependency vulnerability database
- **Analysis**: Build dependency security analysis

## Vulnerability Detection

### CVE Integration
- Common Vulnerabilities and Exposures (CVE) database
- National Vulnerability Database (NVD) integration
- Security advisory aggregation
- Real-time vulnerability updates

### Risk Assessment
- **Critical**: Remote code execution, authentication bypass
- **High**: Privilege escalation, data exposure
- **Medium**: Denial of service, information disclosure
- **Low**: Minor security issues, best practice violations

### Dependency Analysis
- **Direct Dependencies**: Explicitly declared packages
- **Transitive Dependencies**: Sub-dependencies and their chains
- **Development Dependencies**: Build-time security considerations
- **Runtime Dependencies**: Production deployment vulnerabilities

## Scan Coverage

### Security Vulnerability Types
- Remote code execution (RCE)
- Cross-site scripting (XSS)
- SQL injection enablers
- Authentication bypass
- Privilege escalation
- Data exposure risks
- Denial of service (DoS)
- Cryptographic weaknesses

### Dependency Metadata
- Version analysis and comparison
- License compliance checking
- Maintenance status assessment
- End-of-life dependency detection
- Security patch availability

## Vulnerability Reporting

### Detailed Findings
- **Package Information**: Name, version, ecosystem
- **Vulnerability Details**: CVE ID, CVSS score, description
- **Affected Versions**: Version ranges and specific vulnerable versions
- **Remediation**: Update recommendations and fix versions
- **Exploit Information**: Known exploits and attack vectors

### Risk Prioritization
- CVSS score-based ranking
- Exploit availability assessment
- Business impact consideration
- Patch availability evaluation
- Dependency usage analysis

## Remediation Guidance

### Update Strategies
- **Immediate Updates**: Critical vulnerabilities requiring urgent fixes
- **Scheduled Updates**: High/medium risk vulnerabilities
- **Monitoring**: Low-risk vulnerabilities for future updates
- **Alternative Packages**: Replacement recommendations for abandoned packages

### Version Management
- Minimum secure version identification
- Breaking change impact assessment
- Compatibility verification
- Rollback planning strategies

## Example Vulnerability Scenarios

### npm Package Vulnerabilities
```json
{
  "package": "lodash",
  "version": "4.17.15",
  "vulnerability": "CVE-2020-8203",
  "severity": "high",
  "description": "Prototype pollution vulnerability",
  "fixVersion": "4.17.19"
}
```

### Python Package Vulnerabilities
```python
# requirements.txt
django==2.2.0  # VULNERABLE: CVE-2019-14232, CVE-2019-14233
# Recommendation: Update to django>=2.2.4
```

### Java Dependency Vulnerabilities
```xml
<!-- pom.xml -->
<dependency>
    <groupId>org.springframework</groupId>
    <artifactId>spring-web</artifactId>
    <version>5.2.0.RELEASE</version> <!-- VULNERABLE: CVE-2020-5398 -->
</dependency>
```

## Integration with MCP Server

This command integrates with the MCP OWASP Security Server:
- Uses the `dependency-check` tool for multi-ecosystem analysis
- Provides structured vulnerability assessment
- Includes detailed remediation recommendations
- Supports automated scanning workflows

## Security Metrics

### Vulnerability Metrics
- Total vulnerabilities by severity
- Time to remediation tracking
- Vulnerability introduction rate
- Security debt quantification

### Dependency Health
- Outdated dependency percentage
- Security patch compliance
- Maintenance status overview
- License compliance status

## Usage Examples

```bash
# Scan current directory for all dependency files
/dependency-check

# Scan specific package.json file
/dependency-check package.json npm

# Scan Python requirements
/dependency-check requirements.txt pip

# Scan Java Maven project
/dependency-check pom.xml maven
```

## Continuous Security Monitoring

### Automated Scanning
- CI/CD pipeline integration
- Scheduled vulnerability scans
- Real-time security alerts
- Dependency update notifications

### Security Policies
- Vulnerability threshold enforcement
- Acceptable risk level definitions
- Security gate implementation
- Compliance requirement tracking

## Best Practices

### Dependency Management
- Regular dependency updates
- Security-first package selection
- Minimal dependency principle
- Dependency pinning strategies

### Vulnerability Response
- Immediate critical vulnerability fixes
- Structured update scheduling
- Impact assessment procedures
- Rollback contingency planning

### Supply Chain Security
- Package integrity verification
- Trusted registry usage
- Developer key validation
- Build reproducibility

## Remediation Workflow

1. **Scan**: Identify vulnerable dependencies
2. **Assess**: Evaluate risk and business impact
3. **Plan**: Develop update strategy
4. **Test**: Verify fixes in staging environment
5. **Deploy**: Apply updates to production
6. **Monitor**: Track for new vulnerabilities

This dependency vulnerability scanner provides comprehensive security analysis across multiple package ecosystems, enabling proactive identification and remediation of supply chain security risks.