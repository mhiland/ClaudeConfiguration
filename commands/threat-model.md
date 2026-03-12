---
name: threat-model
description: STRIDE-based threat modeling and security architecture analysis
author: Claude Code Enhanced Setup
version: 1.0
category: security
---

# `/threat-model` - STRIDE-Based Threat Modeling

Perform comprehensive threat modeling analysis using STRIDE methodology for security architecture assessment.

## Usage
```
/threat-model [description] [components] [data-flows]
```

**Arguments:**
- `description`: System description (optional, will prompt if not provided)
- `components`: System components (optional, will analyze codebase if not provided)
- `data-flows`: Data flow descriptions (optional, will infer from code if not provided)

## STRIDE Threat Categories

### Spoofing (S)
**Identity and Authentication Threats**
- User identity spoofing
- Service impersonation
- Certificate spoofing
- Session hijacking
- Man-in-the-middle attacks

**Common Scenarios:**
- Weak authentication mechanisms
- Missing certificate validation
- Insufficient session management
- Replay attack vulnerabilities

### Tampering (T)
**Data Integrity Threats**
- Data modification attacks
- Code injection vulnerabilities
- Configuration tampering
- Message alteration
- Database corruption

**Common Scenarios:**
- Input validation failures
- Insecure data transmission
- Weak access controls
- Missing integrity checks

### Repudiation (R)
**Non-Repudiation Threats**
- Action denial capabilities
- Insufficient audit logging
- Log tampering possibilities
- Weak digital signatures
- Missing accountability

**Common Scenarios:**
- Inadequate logging systems
- Missing audit trails
- Weak authentication logs
- Insecure log storage

### Information Disclosure (I)
**Data Confidentiality Threats**
- Unauthorized data access
- Information leakage
- Privacy violations
- Metadata exposure
- Side-channel attacks

**Common Scenarios:**
- Weak encryption implementation
- Insufficient access controls
- Error message information leakage
- Unsecured data storage

### Denial of Service (D)
**Availability Threats**
- Resource exhaustion attacks
- System overload scenarios
- Service disruption
- Performance degradation
- Resource locking

**Common Scenarios:**
- Uncontrolled resource consumption
- Missing rate limiting
- Algorithmic complexity attacks
- Memory exhaustion

### Elevation of Privilege (E)
**Authorization Threats**
- Privilege escalation
- Authorization bypass
- Access control failures
- Administrative takeover
- Unauthorized functionality access

**Common Scenarios:**
- Insufficient authorization checks
- Privilege boundary violations
- Administrative interface exposure
- Weak role-based access control

## Threat Modeling Process

### 1. System Decomposition
- **Assets**: Identify valuable data and resources
- **Entry Points**: Map attack surfaces and interfaces
- **Trust Boundaries**: Define security perimeters
- **Data Flows**: Trace sensitive information movement

### 2. Threat Identification
- **STRIDE Analysis**: Apply each category systematically
- **Attack Trees**: Model potential attack paths
- **Threat Actors**: Consider adversary capabilities
- **Attack Vectors**: Identify exploitation methods

### 3. Vulnerability Assessment
- **Weakness Mapping**: Link threats to system weaknesses
- **Exploitability**: Assess attack feasibility
- **Impact Analysis**: Evaluate business consequences
- **Risk Calculation**: Combine likelihood and impact

### 4. Mitigation Strategy
- **Controls**: Implement security countermeasures
- **Monitoring**: Deploy detection mechanisms
- **Response**: Plan incident response procedures
- **Recovery**: Establish business continuity

## System Analysis Components

### Architecture Elements
- **Web Applications**: Frontend and backend services
- **APIs**: RESTful and GraphQL endpoints
- **Databases**: Data storage and access patterns
- **Authentication**: User identity management
- **Authorization**: Access control mechanisms
- **Network**: Communication protocols and topology

### Data Flow Analysis
- **Input Validation**: User data entry points
- **Data Processing**: Transformation and business logic
- **Data Storage**: Persistence and retrieval
- **Output Generation**: Response and reporting
- **Integration**: External system communication

## Risk Assessment Matrix

### Threat Likelihood
- **High**: Easily exploitable, common attack vectors
- **Medium**: Moderate skill required, some barriers
- **Low**: Difficult to exploit, significant barriers

### Impact Severity
- **Critical**: System compromise, data breach
- **High**: Service disruption, significant data loss
- **Medium**: Limited functionality impact
- **Low**: Minor inconvenience, minimal impact

### Risk Prioritization
- **Critical Risk**: High likelihood + Critical impact
- **High Risk**: High likelihood + High impact, Medium likelihood + Critical impact
- **Medium Risk**: Medium likelihood + Medium impact
- **Low Risk**: Low likelihood + Low impact

## Threat Model Deliverables

### Threat Assessment Report
- **Executive Summary**: High-level security posture
- **Threat Landscape**: Identified threats and risks
- **Vulnerability Analysis**: System weaknesses
- **Risk Assessment**: Prioritized security risks
- **Mitigation Recommendations**: Security controls

### Security Architecture Review
- **Component Analysis**: Security design evaluation
- **Trust Boundary Validation**: Security perimeter assessment
- **Data Flow Security**: Information protection analysis
- **Attack Surface Mapping**: Exposure point identification

## Integration with MCP Server

This command leverages the MCP OWASP Security Server:
- Uses the `threat-model` tool for STRIDE analysis
- Provides structured threat assessment
- Includes detailed risk evaluation
- Supports comprehensive security architecture review

## Common Threat Scenarios

### Web Application Threats
```
Spoofing: Session token prediction
Tampering: SQL injection attacks
Repudiation: Missing audit logs
Information Disclosure: Error message leakage
Denial of Service: Resource exhaustion
Elevation of Privilege: Authorization bypass
```

### API Security Threats
```
Spoofing: API key theft
Tampering: Request parameter manipulation
Repudiation: Insufficient API logging
Information Disclosure: Excessive data exposure
Denial of Service: Rate limiting bypass
Elevation of Privilege: Broken object level authorization
```

### Database Threats
```
Spoofing: Database user impersonation
Tampering: Direct database manipulation
Repudiation: Database audit bypass
Information Disclosure: Unauthorized data access
Denial of Service: Database resource exhaustion
Elevation of Privilege: Database privilege escalation
```

## Usage Examples

```bash
# Analyze current system with automatic component detection
/threat-model

# Specific system analysis
/threat-model "E-commerce web application with payment processing"

# Comprehensive analysis with components
/threat-model "Banking API system" "web-server,database,payment-gateway"

# Full analysis with data flows
/threat-model "Healthcare system" "app,db,auth" "patient-data,medical-records"
```

## Threat Modeling Best Practices

### Early Integration
- Design phase threat modeling
- Architecture review integration
- Security requirement derivation
- Risk-based design decisions

### Continuous Process
- Regular threat model updates
- New feature threat analysis
- Security architecture evolution
- Threat landscape monitoring

### Stakeholder Involvement
- Security architect participation
- Developer security awareness
- Business stakeholder engagement
- Risk owner identification

## Mitigation Strategies

### Preventive Controls
- Input validation and sanitization
- Authentication and authorization
- Encryption and data protection
- Secure coding practices

### Detective Controls
- Security monitoring and logging
- Intrusion detection systems
- Audit trail analysis
- Anomaly detection

### Responsive Controls
- Incident response procedures
- Security patch management
- Vulnerability remediation
- Business continuity planning

## Integration with Development Lifecycle

### Design Phase
- Security requirements definition
- Architecture security review
- Threat model development
- Risk assessment integration

### Development Phase
- Security control implementation
- Threat model validation
- Security testing integration
- Code review security focus

### Deployment Phase
- Security configuration validation
- Threat model verification
- Security monitoring setup
- Incident response preparation

This STRIDE-based threat modeling provides comprehensive security architecture analysis, enabling proactive identification and mitigation of security threats throughout the system lifecycle.