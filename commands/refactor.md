---
name: refactor
description: Intelligent code refactoring with architectural analysis
author: Claude Code Enhanced Setup
version: 1.0
category: refactoring
---

# `/refactor` - Intelligent Code Refactoring

Comprehensive code refactoring with architectural analysis, pattern recognition, and automated improvements.

## Usage
```
/refactor [target] [type] [scope]
```

**Arguments:**
- `target`: Specific file/class/function to refactor (optional, defaults to analysis mode)
- `type`: Refactoring type (extract/inline/rename/restructure/optimize, defaults to analyze)
- `scope`: Refactoring scope (method/class/module/architecture, defaults to smart detection)

## Pre-refactoring Analysis
```bash
!echo "Analyzing code structure for refactoring opportunities..."
!echo "Target: ${1:-entire codebase}"
!echo "Refactoring type: ${2:-comprehensive analysis}"
!find . -name "*.py" -o -name "*.js" -o -name "*.ts" | head -10
```

## Refactoring Strategy

### 1. Code Analysis Phase
**Structural Analysis:**
- Identify code smells and anti-patterns
- Analyze complexity metrics (cyclomatic, cognitive)
- Find duplicated code and logic
- Assess coupling and cohesion
- Evaluate naming conventions

**Architectural Analysis:**
- Review overall system design
- Identify architectural debt
- Analyze dependency relationships
- Evaluate design pattern usage
- Assess scalability concerns

### 2. Refactoring Planning
**Priority Assessment:**
- High-impact, low-risk refactorings first
- Critical path impact analysis
- Testing coverage requirements
- Backward compatibility considerations
- Performance impact evaluation

**Refactoring Roadmap:**
- Break down large refactorings into steps
- Identify dependencies between refactorings
- Plan testing strategy for each step
- Schedule refactoring phases
- Define success criteria

## Refactoring Types

### Extract Method/Function
```python
# Before: Long method with mixed responsibilities
def process_user_data(user_data):
    # validation logic (20 lines)
    # transformation logic (15 lines)
    # persistence logic (10 lines)
    # notification logic (8 lines)

# After: Extracted into focused methods
def process_user_data(user_data):
    validated_data = validate_user_data(user_data)
    transformed_data = transform_user_data(validated_data)
    saved_user = save_user_data(transformed_data)
    notify_user_created(saved_user)
```

### Extract Class
```python
# Before: God class with multiple responsibilities
class UserManager:
    def validate_user(self): pass
    def save_user(self): pass
    def send_email(self): pass
    def generate_report(self): pass

# After: Separated concerns
class UserValidator:
    def validate(self): pass

class UserRepository:
    def save(self): pass

class EmailService:
    def send(self): pass

class ReportGenerator:
    def generate(self): pass
```

### Inline Method
```python
# Before: Unnecessary indirection
def get_user_name(user):
    return extract_name(user)

def extract_name(user):
    return user.name

# After: Direct access
def get_user_name(user):
    return user.name
```

### Rename for Clarity
```python
# Before: Unclear naming
def calc(x, y):
    return x * y * 0.1

# After: Clear intent
def calculate_commission(price, quantity):
    return price * quantity * COMMISSION_RATE
```

### Move Method/Field
```python
# Before: Method in wrong class
class Customer:
    def calculate_shipping_cost(self, order):
        return order.weight * SHIPPING_RATE

# After: Method moved to appropriate class
class ShippingCalculator:
    def calculate_cost(self, order):
        return order.weight * SHIPPING_RATE
```

## Code Quality Improvements

### Design Pattern Implementation
- **Strategy Pattern**: Replace conditional logic
- **Factory Pattern**: Simplify object creation
- **Observer Pattern**: Decouple event handling
- **Command Pattern**: Encapsulate operations
- **Decorator Pattern**: Add behavior dynamically

### SOLID Principles Enforcement
- **Single Responsibility**: One reason to change
- **Open/Closed**: Open for extension, closed for modification
- **Liskov Substitution**: Subclasses must be substitutable
- **Interface Segregation**: Clients shouldn't depend on unused interfaces
- **Dependency Inversion**: Depend on abstractions, not concretions

## Performance Optimizations

### Algorithmic Improvements
- Replace O(n²) algorithms with O(n log n) alternatives
- Implement caching for expensive operations
- Use lazy loading for large datasets
- Optimize database queries and indexing

### Memory Optimizations
- Reduce object creation in loops
- Use generators for large collections
- Implement object pooling for frequent allocations
- Clean up resources properly

### Concurrent Programming
- Identify opportunities for parallelization
- Implement async/await patterns
- Use thread-safe data structures
- Optimize lock contention

## Refactoring Safety

### Testing Strategy
- Ensure comprehensive test coverage before refactoring
- Write characterization tests for legacy code
- Use test-driven refactoring approach
- Implement integration tests for architectural changes

### Incremental Refactoring
- Make small, atomic changes
- Commit frequently with descriptive messages
- Use feature flags for large changes
- Implement rollback strategies

### Code Review Process
- Require peer review for all refactorings
- Document refactoring decisions
- Validate performance impact
- Ensure backward compatibility

## Architecture Refactoring

### Microservices Extraction
- Identify bounded contexts
- Extract services with clear APIs
- Implement service communication patterns
- Handle distributed system concerns

### Modular Monolith
- Create clear module boundaries
- Implement dependency injection
- Use event-driven architecture
- Separate concerns effectively

### Database Refactoring
- Normalize data structures
- Optimize query performance
- Implement caching strategies
- Handle data migration safely

## File References
Analyze these files for refactoring opportunities:
@src/
@lib/
@services/
@models/
@controllers/
@utils/
@tests/

## Refactoring Metrics

### Before/After Comparison
- Cyclomatic complexity reduction
- Code duplication elimination
- Coupling/cohesion improvement
- Performance metrics
- Test coverage increase

### Quality Metrics
- Maintainability index
- Technical debt reduction
- Code readability scores
- Error rate improvements
- Development velocity impact

## Common Refactoring Scenarios

### Legacy Code Modernization
- Replace deprecated APIs
- Update to modern language features
- Improve error handling
- Implement proper logging
- Add comprehensive tests

### Performance Bottlenecks
- Profile code to identify hotspots
- Optimize critical paths
- Implement caching strategies
- Reduce I/O operations
- Parallel processing implementation

### Scalability Improvements
- Horizontal scaling preparation
- Stateless design implementation
- Database scaling strategies
- Caching layer implementation
- Load balancing considerations

## Automation and Tools

### Static Analysis
- Use linters for code quality
- Complexity analysis tools
- Duplicate code detection
- Security vulnerability scanning
- Dependency analysis

### Refactoring Tools
- IDE refactoring capabilities
- Language-specific tools
- Code formatting automation
- Import organization
- Symbol renaming across codebase

## Success Criteria
Refactoring is successful when:
- All existing tests continue to pass
- Code quality metrics improve
- Performance remains stable or improves
- Code becomes more maintainable
- Team productivity increases

**Note**: This command provides intelligent refactoring guidance with safety checks and architectural analysis to ensure successful code improvements.