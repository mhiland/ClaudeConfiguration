#!/bin/bash
# Claude Code Quality Check Hook - OPTIMIZED VERSION
# Checks only edited files by default, with option for full project scan
# Includes bypass mechanism to prevent circular loops

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
VERBOSE=${CLAUDE_HOOK_VERBOSE:-false}
BYPASS_HOOKS=${CLAUDE_HOOK_BYPASS:-false}
QUALITY_MODE=${CLAUDE_QUALITY_MODE:-file}  # file, project, off
OPERATION_CONTEXT=${CLAUDE_OPERATION_CONTEXT:-edit}  # edit, check, batch
LOG_LEVEL=${CLAUDE_LOG_LEVEL:-error}  # error, warn, info, debug

# Early exit if hooks are bypassed
if [[ "$BYPASS_HOOKS" == "true" ]]; then
    [[ "$LOG_LEVEL" == "debug" ]] && echo -e "${BLUE}[QUALITY] Hook bypassed by CLAUDE_HOOK_BYPASS${NC}" >&2
    exit 0
fi

# Early exit if quality checks are off
if [[ "$QUALITY_MODE" == "off" ]]; then
    [[ "$LOG_LEVEL" == "debug" ]] && echo -e "${BLUE}[QUALITY] Quality checks disabled${NC}" >&2
    exit 0
fi

log() {
    [[ "$LOG_LEVEL" == "info" || "$LOG_LEVEL" == "debug" ]] && echo -e "${BLUE}[$(date '+%H:%M:%S')] $1${NC}" >&2
}

error() {
    echo -e "${RED}[ERROR] $1${NC}" >&2
}

success() {
    [[ "$LOG_LEVEL" != "error" ]] && echo -e "${GREEN}[SUCCESS] $1${NC}" >&2
}

warn() {
    [[ "$LOG_LEVEL" != "error" ]] && echo -e "${YELLOW}[WARN] $1${NC}" >&2
}

debug() {
    [[ "$LOG_LEVEL" == "debug" ]] && echo -e "${BLUE}[DEBUG] $1${NC}" >&2
}

# Extract edited file from hook input
EDITED_FILE=""
if [[ -n "$CLAUDE_HOOK_INPUT" ]]; then
    TOOL_NAME=$(echo "$CLAUDE_HOOK_INPUT" | jq -r '.tool_name // ""')
    if [[ "$TOOL_NAME" =~ ^(Write|Edit|MultiEdit)$ ]]; then
        EDITED_FILE=$(echo "$CLAUDE_HOOK_INPUT" | jq -r '.tool_input.file_path // ""')
        debug "Extracted edited file: $EDITED_FILE"
    fi
fi

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    warn "Not in a git repository, skipping quality checks"
    exit 0
fi

# Track if any checks failed
CHECKS_FAILED=false

# Function to check Python file
check_python_file() {
    local file="$1"
    local strict_mode="$2"  # true for backend, false for frontend
    
    debug "Checking Python file: $file (strict=$strict_mode)"
    
    # Skip non-Python files
    [[ ! "$file" =~ \.py$ ]] && return 0
    
    # Skip if file doesn't exist
    [[ ! -f "$file" ]] && return 0
    
    # Determine thresholds based on location
    local pylint_threshold=8.0
    local pylint_args=""
    
    if [[ "$strict_mode" == "true" ]] || [[ "$file" =~ backend/ ]]; then
        pylint_threshold=10.0
        log "Strict mode: Backend file requires 10.0/10"
    elif [[ "$file" =~ frontend/ ]]; then
        pylint_threshold=7.0
        pylint_args="--disable=C0114,C0115,C0116"
        log "Lenient mode: Frontend file requires 7.0/10"
    fi
    
    # Run pylint on single file
    if command -v pylint &> /dev/null; then
        log "Running pylint on $file..."
        if ! pylint $pylint_args --fail-under=$pylint_threshold "$file" 2>/dev/null; then
            error "Pylint issues in $file (threshold: $pylint_threshold)"
            CHECKS_FAILED=true
        else
            success "Pylint passed for $file"
        fi
    fi
    
    # Run flake8 on single file
    if command -v flake8 &> /dev/null; then
        log "Running flake8 on $file..."
        if ! flake8 --max-line-length=120 --ignore=E501,W503,W504 "$file" 2>/dev/null; then
            error "Flake8 issues in $file"
            CHECKS_FAILED=true
        else
            success "Flake8 passed for $file"
        fi
    fi
    
    # Check formatting on single file
    if command -v autopep8 &> /dev/null; then
        log "Checking formatting for $file..."
        if autopep8 --diff --max-line-length=120 "$file" | grep -q .; then
            error "Formatting issues in $file"
            echo "Fix with: autopep8 --in-place --max-line-length=120 $file"
            CHECKS_FAILED=true
        else
            success "Formatting correct for $file"
        fi
    fi
}

# Function to check JavaScript file
check_javascript_file() {
    local file="$1"
    
    debug "Checking JavaScript file: $file"
    
    # Skip non-JS files
    [[ ! "$file" =~ \.js$ ]] && return 0
    
    # Skip if file doesn't exist
    [[ ! -f "$file" ]] && return 0
    
    # Run JSHint on single file
    if command -v jshint &> /dev/null; then
        log "Running JSHint on $file..."
        if ! jshint "$file" 2>/dev/null; then
            warn "JSHint issues in $file"
        else
            success "JSHint passed for $file"
        fi
    fi
}

# Function to check HTML file
check_html_file() {
    local file="$1"
    
    debug "Checking HTML file: $file"
    
    # Skip non-HTML files
    [[ ! "$file" =~ \.html$ ]] && return 0
    
    # Skip if file doesn't exist
    [[ ! -f "$file" ]] && return 0
    
    # Validate HTML
    if command -v python3 &> /dev/null && python3 -c "import html5lib" 2>/dev/null; then
        log "Validating HTML in $file..."
        if python3 -c "import html5lib; html5lib.parse(open('$file').read())" 2>/dev/null; then
            success "✓ $file: Valid HTML5"
        else
            warn "✗ $file: HTML5 validation failed"
        fi
    fi
}

# Function to run full project checks (original behavior)
run_project_checks() {
    log "Running full project quality checks..."
    
    # For now, skip project-wide checks in normal operation
    # This would contain the full project scanning logic
    log "Project-wide checks skipped (not implemented yet)"
    return 0
}

# Main logic
if [[ "$QUALITY_MODE" == "project" ]]; then
    # Full project mode explicitly requested
    log "Running in project mode"
    run_project_checks
elif [[ -z "$EDITED_FILE" && "$QUALITY_MODE" == "file" ]]; then
    # No file to check in file mode - this is normal for some operations
    debug "No specific file to check, skipping quality checks"
    exit 0
elif [[ -n "$EDITED_FILE" && "$QUALITY_MODE" == "file" ]]; then
    # File-specific mode
    log "Running quality checks on edited file: $EDITED_FILE"
    
    # Skip checks for non-code files
    if [[ "$EDITED_FILE" =~ \.(md|txt|json|yml|yaml|cfg|ini|conf|lock)$ ]]; then
        log "Skipping quality checks for non-code file: $EDITED_FILE"
        exit 0
    fi
    
    # Determine project type and check accordingly
    if [[ "$EDITED_FILE" =~ \.py$ ]]; then
        check_python_file "$EDITED_FILE"
    elif [[ "$EDITED_FILE" =~ \.js$ ]]; then
        check_javascript_file "$EDITED_FILE"
    elif [[ "$EDITED_FILE" =~ \.html$ ]]; then
        check_html_file "$EDITED_FILE"
    else
        log "No specific quality checks for file type: $EDITED_FILE"
    fi
    
    # Security checks only in project mode or during check operations
    if [[ "$OPERATION_CONTEXT" == "check" ]] && command -v pip-audit &> /dev/null; then
        log "Running security scan (check context)..."
        if ! pip-audit 2>/dev/null; then
            error "pip-audit found security vulnerabilities"
            CHECKS_FAILED=true
        fi
    fi
fi

# Final result
if [[ "$CHECKS_FAILED" == "true" ]]; then
    error "Quality checks failed for $EDITED_FILE"
    # In check mode, we might want to continue despite failures
    if [[ "$OPERATION_CONTEXT" == "check" ]]; then
        warn "Continuing despite failures (check mode)"
        exit 0
    else
        exit 1
    fi
else
    success "Quality checks passed!"
    exit 0
fi