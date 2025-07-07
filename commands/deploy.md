---
name: deploy
description: Project deployment preparation with comprehensive quality checks
author: Claude Code Enhanced Setup
version: 1.0
category: deployment
---

# `/deploy` - Deployment Preparation and Validation

Comprehensive deployment preparation with quality checks, security validation, and environment readiness.

## Usage
```
/deploy [environment] [strategy]
```

**Arguments:**
- `environment`: Target deployment environment (dev/staging/production, defaults to staging)
- `strategy`: Deployment strategy (blue-green/rolling/canary, defaults to rolling)

## Pre-deployment Validation
```bash
!echo "Preparing deployment for environment: ${ARGUMENTS:-staging}"
!echo "Checking deployment readiness..."
!git status --porcelain
!git log --oneline -5
```

## Deployment Checklist

### 1. Code Quality Gates
**Mandatory Quality Checks:**
- All tests must pass (unit, integration, e2e)
- Code coverage above threshold (>80%)
- No critical security vulnerabilities
- Linting and formatting compliance
- Documentation completeness

### 2. Security Validation
**Security Checkpoints:**
- Secrets and credentials audit
- Dependency vulnerability scan
- Container security analysis
- Network security validation
- Access control verification

### 3. Environment Readiness
**Infrastructure Checks:**
- Database migration status
- Environment variable validation
- Service dependencies availability
- Resource allocation verification
- Monitoring and alerting setup

### 4. Performance Validation
**Performance Gates:**
- Load testing results
- Memory usage analysis
- Database query performance
- API response time validation
- Resource utilization checks

## Deployment Strategies

### Blue-Green Deployment
```bash
# Prepare blue environment
!echo "Preparing blue environment..."
# Deploy to blue
# Validate blue environment
# Switch traffic to blue
# Keep green as fallback
```

### Rolling Deployment
```bash
# Gradual instance replacement
!echo "Starting rolling deployment..."
# Deploy to subset of instances
# Validate partial deployment
# Continue with remaining instances
```

### Canary Deployment
```bash
# Deploy to small percentage of traffic
!echo "Starting canary deployment..."
# Monitor canary metrics
# Gradually increase traffic
# Full rollout or rollback based on metrics
```

## Environment-Specific Configurations

### Development Environment
- Fast deployment cycle
- Relaxed quality gates
- Debug mode enabled
- Mock services allowed

### Staging Environment
- Production-like environment
- Full quality gate enforcement
- Performance testing
- Integration testing

### Production Environment
- Maximum security checks
- Zero-downtime deployment
- Comprehensive monitoring
- Automated rollback triggers

## Quality Gate Enforcement

### Critical Gates (Cannot be bypassed)
- All tests passing
- No high/critical security vulnerabilities
- No compilation/build errors
- Database migration validation

### Warning Gates (Can be bypassed with approval)
- Code coverage below threshold
- Documentation gaps
- Performance regression
- Non-critical security issues

## Deployment Automation

### Pre-deployment Tasks
```bash
# Quality checks
pytest tests/ --tb=short
pylint --fail-under=8.0 .
pip-audit

# Build artifacts
docker build -t app:latest .
docker run --rm app:latest python -m pytest

# Database preparation
python manage.py migrate --check
python manage.py collectstatic --noinput
```

### Post-deployment Tasks
```bash
# Health checks
curl -f http://localhost:8000/health

# Smoke tests
python tests/smoke_tests.py

# Performance baseline
python tests/performance_baseline.py
```

## Rollback Strategy

### Automatic Rollback Triggers
- Health check failures
- Error rate spikes
- Performance degradation
- Critical service failures

### Manual Rollback Process
1. Identify rollback point
2. Prepare rollback artifacts
3. Execute rollback procedure
4. Validate rollback success
5. Communicate rollback status

## Monitoring and Alerting

### Deployment Metrics
- Deployment duration
- Success/failure rates
- Rollback frequency
- Performance impact

### Application Metrics
- Response time
- Error rates
- Resource utilization
- Business metrics

## File References
Monitor these files for deployment configuration:
@Dockerfile
@docker-compose.yml
@requirements.txt
@package.json
@deploy/
@.github/workflows/
@terraform/
@kubernetes/

## Integration with CI/CD

### GitHub Actions
```yaml
name: Deploy
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Run deployment
        run: claude /deploy production
```

### GitLab CI
```yaml
deploy:
  stage: deploy
  script:
    - claude /deploy production
  only:
    - main
```

## Common Deployment Issues

### Database Issues
- Migration conflicts
- Connection timeouts
- Data consistency problems
- Performance degradation

### Container Issues
- Image build failures
- Registry authentication
- Resource constraints
- Network connectivity

### Configuration Issues
- Environment variable mismatches
- Secret management problems
- Service discovery failures
- Load balancer configuration

## Success Criteria
Deployment is considered successful when:
- All quality gates pass
- Health checks return green
- Performance metrics within acceptable range
- No critical errors in logs
- Business functionality validated

**Note**: This command provides comprehensive deployment preparation with intelligent quality gates and environment-specific validation.