---
name: test
description: Run appropriate tests based on project type detection
author: Claude Code Enhanced Setup
version: 1.0
category: testing
---

# `/test` - Intelligent Test Runner

Automatically detect project type and run appropriate tests with comprehensive coverage.

## Usage
```
/test [type] [pattern]
```

**Arguments:**
- `type`: Test type (unit/integration/all, defaults to all)
- `pattern`: Test pattern or specific test file (optional)

## Pre-execution Environment Setup
```bash
!echo "Detecting project type and test framework..."
!if [[ -f "requirements.txt" || -f "pyproject.toml" ]]; then echo "Python project"; fi
!if [[ -f "package.json" ]]; then echo "Node.js project"; fi
!if [[ -f "Cargo.toml" ]]; then echo "Rust project"; fi
!if [[ -f "go.mod" ]]; then echo "Go project"; fi
```

## Test Strategy by Project Type

### Python Projects
**Framework Detection:**
- pytest (preferred)
- unittest
- nose2
- tox for multi-environment testing

**Test Commands:**
```bash
# Unit tests (fast, no external dependencies)
pytest tests/unit/ -v --tb=short

# Integration tests (database, network, etc.)
APP_ENV=test pytest tests/integration/ -v --tb=short

# All tests with coverage
pytest --cov=. --cov-report=html --cov-report=term-missing

# Performance tests
pytest tests/performance/ -v --benchmark-only
```

### Node.js Projects
**Framework Detection:**
- Jest
- Mocha
- Cypress (E2E)
- Playwright

**Test Commands:**
```bash
# Unit tests
npm test

# Integration tests
npm run test:integration

# E2E tests
npm run test:e2e

# Coverage
npm run test:coverage
```

### Go Projects
**Test Commands:**
```bash
# All tests
go test ./...

# Verbose output
go test -v ./...

# Coverage
go test -cover ./...

# Benchmarks
go test -bench=.
```

### Rust Projects
**Test Commands:**
```bash
# All tests
cargo test

# Specific test
cargo test $ARGUMENTS

# Release mode tests
cargo test --release
```

## Test Execution Logic

### 1. Environment Validation
- Check for active virtual environment (Python)
- Verify dependencies are installed
- Validate database connections (integration tests)
- Check test configuration files

### 2. Test Discovery
- Scan for test directories and files
- Identify test frameworks and runners
- Categorize tests by type (unit/integration/e2e)
- Check for test configuration files

### 3. Test Execution
- Run tests in appropriate order (unit → integration → e2e)
- Capture and format test output
- Generate coverage reports
- Save test artifacts

### 4. Result Analysis
- Identify failed tests and reasons
- Suggest fixes for common test failures
- Performance regression detection
- Coverage analysis and recommendations

## Advanced Features

### Test Environment Management
- Automatic test database setup/teardown
- Mock service configuration
- Test data generation and cleanup
- Parallel test execution optimization

### CI/CD Integration
- Generate test reports in CI-friendly formats
- Export test results for build systems
- Integration with quality gates
- Performance benchmarking

## File References
Monitor these files for test-related changes:
@tests/
@test/
@__tests__/
@spec/
@pytest.ini
@jest.config.js
@package.json
@requirements.txt

## Common Test Patterns

### Python Testing
```python
# pytest fixture usage
@pytest.fixture
def client():
    return TestClient()

# Parametrized tests
@pytest.mark.parametrize("input,expected", [
    ("test", "result"),
])
def test_function(input, expected):
    assert function(input) == expected
```

### JavaScript Testing
```javascript
// Jest test structure
describe('Component', () => {
  test('should behave correctly', () => {
    expect(component.method()).toBe(expected);
  });
});
```

## Error Handling
- Detect and report test environment issues
- Provide specific error messages for common failures
- Suggest fixes for dependency issues
- Guide through test configuration problems

**Note**: This command intelligently adapts to your project's testing setup and provides comprehensive test execution with detailed reporting.