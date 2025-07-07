#!/bin/bash
# Claude Code Quality Check Hook
# Auto-detects project type and runs appropriate quality checks
# Based on base-config.md linting standards

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
VERBOSE=${CLAUDE_HOOK_VERBOSE:-false}
FAST_MODE=${CLAUDE_HOOK_FAST:-false}

log() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

success() {
    echo -e "${GREEN}[SUCCESS] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[WARN] $1${NC}"
}

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    warn "Not in a git repository, skipping quality checks"
    exit 0
fi

log "Running Claude Code quality checks..."

# Track if any checks failed
CHECKS_FAILED=false

# Python projects
if [[ -f "requirements.txt" || -f "pyproject.toml" || -f "setup.py" || -f "Pipfile" ]]; then
    log "Python project detected"
    
    # Check for virtual environment
    if [[ -z "$VIRTUAL_ENV" ]]; then
        warn "No virtual environment active. Consider running: source .venv/bin/activate"
    fi
    
    # Determine if backend or frontend based on directory structure
    if [[ -d "backend" ]]; then
        # Backend linting (strict)
        log "Running strict backend Python linting..."
        if command -v pylint &> /dev/null; then
            log "Running pylint on backend/ (must achieve 10.0/10)..."
            if ! pylint --fail-under=10.0 backend/ 2>/dev/null; then
                error "Pylint backend issues found (must score 10.0/10)"
                CHECKS_FAILED=true
            fi
        fi
        
        if command -v flake8 &> /dev/null; then
            log "Running flake8 on backend/..."
            if ! flake8 --max-line-length=120 --ignore=E501,W503,W504 backend/ 2>/dev/null; then
                error "Flake8 backend issues found"
                CHECKS_FAILED=true
            fi
        fi
        
        if command -v autopep8 &> /dev/null; then
            log "Checking backend code formatting..."
            if autopep8 --diff --recursive --max-line-length=120 backend/ | grep -q .; then
                error "Backend formatting issues found"
                echo "Fix with: autopep8 --in-place --recursive --max-line-length=120 backend/"
                CHECKS_FAILED=true
            fi
        fi
    fi
    
    if [[ -d "frontend" ]]; then
        # Frontend linting (lenient)
        log "Running lenient frontend Python linting..."
        if command -v pylint &> /dev/null; then
            log "Running pylint on frontend/ (lenient due to Flask templates)..."
            if ! pylint --disable=C0114,C0115,C0116 --fail-under=7.0 frontend/ 2>/dev/null; then
                warn "Pylint frontend issues found (lenient threshold)"
            fi
        fi
        
        if command -v flake8 &> /dev/null; then
            log "Running flake8 on frontend/..."
            flake8 --max-line-length=120 --ignore=E501,W503,W504 frontend/ 2>/dev/null || warn "Flake8 frontend issues found"
        fi
        
        if command -v autopep8 &> /dev/null; then
            log "Checking frontend code formatting..."
            if autopep8 --diff --recursive --max-line-length=120 frontend/ | grep -q .; then
                warn "Frontend formatting issues found"
                echo "Consider: autopep8 --in-place --recursive --max-line-length=120 frontend/"
            fi
        fi
    fi
    
    # If no backend/frontend structure, apply general linting
    if [[ ! -d "backend" && ! -d "frontend" ]]; then
        log "Running general Python linting..."
        if command -v pylint &> /dev/null; then
            log "Running pylint..."
            if ! pylint --fail-under=8.0 . 2>/dev/null; then
                error "Pylint issues found"
                CHECKS_FAILED=true
            fi
        fi
        
        if command -v flake8 &> /dev/null; then
            log "Running flake8..."
            if ! flake8 --max-line-length=120 --ignore=E501,W503,W504 . 2>/dev/null; then
                error "Flake8 issues found"
                CHECKS_FAILED=true
            fi
        fi
        
        if command -v autopep8 &> /dev/null; then
            log "Checking code formatting..."
            if autopep8 --diff --recursive --max-line-length=120 . | grep -q .; then
                error "Formatting issues found"
                echo "Fix with: autopep8 --in-place --recursive --max-line-length=120 ."
                CHECKS_FAILED=true
            fi
        fi
    fi
    
    # Security checks
    if command -v pip-audit &> /dev/null; then
        log "Running pip-audit security scan..."
        if ! pip-audit 2>/dev/null; then
            error "pip-audit found security vulnerabilities"
            CHECKS_FAILED=true
        fi
    fi
    
    if command -v bandit &> /dev/null; then
        log "Running bandit security scan..."
        if ! bandit -r . -f json -o /tmp/bandit_report.json 2>/dev/null; then
            warn "Bandit security issues found (secondary check)"
        fi
    fi
fi

# JavaScript projects
if [[ -f "package.json" ]] || find . -name "*.js" -type f | head -1 | grep -q .; then
    log "JavaScript project detected"
    
    # JSHint (your standard tool)
    if command -v jshint &> /dev/null; then
        log "Running JSHint linter..."
        if find . -name "*.js" -type f | grep -q .; then
            if ! find . -name "*.js" -type f -exec jshint {} \; 2>/dev/null; then
                warn "JSHint issues found"
            fi
        fi
    else
        log "JSHint not available, checking for frontend/static/js..."
        if [[ -d "frontend/static/js" ]]; then
            log "Found frontend/static/js directory"
            if find frontend/static/js -name "*.js" -type f | grep -q .; then
                warn "JavaScript files found but JSHint not available for linting"
            fi
        fi
    fi
    
    # TypeScript (if present)
    if command -v npx &> /dev/null && npx tsc --version &> /dev/null && [[ -f "tsconfig.json" ]]; then
        log "Running TypeScript compiler check..."
        if ! npx tsc --noEmit 2>/dev/null; then
            error "TypeScript compilation issues found"
            CHECKS_FAILED=true
        fi
    fi
fi

# HTML Template validation
if [[ -d "frontend/templates" ]] || find . -name "*.html" -type f | head -1 | grep -q .; then
    log "HTML templates detected"
    
    if command -v python3 &> /dev/null; then
        log "Validating HTML templates with html5lib..."
        # Check if html5lib is available
        if python3 -c "import html5lib" 2>/dev/null; then
            # Find and validate HTML templates
            if [[ -d "frontend/templates" ]]; then
                for template in frontend/templates/*.html; do
                    if [[ -f "$template" ]]; then
                        log "Checking $template..."
                        if python3 -c "import html5lib; html5lib.parse(open('$template').read())" 2>/dev/null; then
                            log "✓ $template: Valid HTML5"
                        else
                            warn "✗ $template: HTML5 validation failed"
                        fi
                    fi
                done
            else
                # Check any HTML files in project
                find . -name "*.html" -type f | while read -r htmlfile; do
                    log "Checking $htmlfile..."
                    if python3 -c "import html5lib; html5lib.parse(open('$htmlfile').read())" 2>/dev/null; then
                        log "✓ $htmlfile: Valid HTML5"
                    else
                        warn "✗ $htmlfile: HTML5 validation failed"
                    fi
                done
            fi
        else
            warn "html5lib not available for HTML validation (install with: pip install html5lib)"
        fi
    fi
fi


# Generic checks for all projects
log "Running generic quality checks..."

# Check for common issues
if grep -r "TODO\|FIXME\|XXX\|HACK" --include="*.py" --include="*.js" --include="*.ts" . 2>/dev/null; then
    warn "Found TODO/FIXME/XXX/HACK comments - consider addressing before committing"
fi

# Check for potential secrets
if grep -r -i "password\|secret\|token\|key" --include="*.py" --include="*.js" --include="*.ts" . 2>/dev/null | grep -v "test" | grep -v ".git"; then
    warn "Found potential secrets in code - review carefully"
fi

# Final result
if [[ "$CHECKS_FAILED" == "true" ]]; then
    error "Quality checks failed! Please fix the issues above before proceeding."
    exit 1
else
    success "All quality checks passed!"
    exit 0
fi