#!/bin/bash
# Claude Code Quality Library - Shared Functions
# Common quality checking functions used across all quality tools

# Configuration and Standards
declare -A PYLINT_THRESHOLDS=(
    ["backend"]="10.0"
    ["frontend"]="7.0"
    ["general"]="8.0"
)

declare -A QUALITY_STANDARDS=(
    ["python_line_length"]="120"
    ["flake8_ignore"]="E501,W503,W504"
    ["autopep8_args"]="--max-line-length=120"
)

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging functions
log() {
    [[ "$LOG_LEVEL" == "info" || "$LOG_LEVEL" == "debug" ]] && echo -e "${BLUE}[$(date '+%H:%M:%S')] $1${NC}" >&2 || true
}

error() {
    echo -e "${RED}[ERROR] $1${NC}" >&2
}

success() {
    [[ "$LOG_LEVEL" != "error" ]] && echo -e "${GREEN}[SUCCESS] $1${NC}" >&2 || true
}

warn() {
    [[ "$LOG_LEVEL" != "error" ]] && echo -e "${YELLOW}[WARN] $1${NC}" >&2 || true
}

debug() {
    [[ "$LOG_LEVEL" == "debug" ]] && echo -e "${BLUE}[DEBUG] $1${NC}" >&2 || true
}

# Check if tools are available
check_tool_available() {
    local tool="$1"
    command -v "$tool" &> /dev/null
}

# Determine file type for quality checking
get_file_type() {
    local file="$1"
    
    if [[ "$file" =~ \.py$ ]]; then
        echo "python"
    elif [[ "$file" =~ \.js$ ]]; then
        echo "javascript"
    elif [[ "$file" =~ \.ts$ ]]; then
        echo "typescript"
    elif [[ "$file" =~ \.html$ ]]; then
        echo "html"
    elif [[ "$file" =~ \.(md|txt|json|yml|yaml|cfg|ini|conf|lock)$ ]]; then
        echo "non-code"
    else
        echo "unknown"
    fi
}

# Determine pylint threshold based on file location
get_pylint_threshold() {
    local file="$1"
    
    if [[ "$file" =~ backend/ ]]; then
        echo "${PYLINT_THRESHOLDS[backend]}"
    elif [[ "$file" =~ frontend/ ]]; then
        echo "${PYLINT_THRESHOLDS[frontend]}"
    else
        echo "${PYLINT_THRESHOLDS[general]}"
    fi
}

# Get pylint arguments based on file location
get_pylint_args() {
    local file="$1"
    
    if [[ "$file" =~ frontend/ ]]; then
        echo "--disable=C0114,C0115,C0116"
    else
        echo ""
    fi
}

# Check Python file with pylint
check_python_pylint() {
    local file="$1"
    local issues_array="$2"
    local fix_commands_array="$3"
    
    if ! check_tool_available "pylint"; then
        debug "pylint not available, skipping"
        return 0
    fi
    
    local threshold=$(get_pylint_threshold "$file")
    local args=$(get_pylint_args "$file")
    
    log "Running pylint on $file (threshold: $threshold)"
    
    if ! pylint ${args:+$args} --fail-under=$threshold "$file" 2>/dev/null; then
        error "Pylint issues in $file (threshold: $threshold)"
        eval "$issues_array+=(\"pylint:$file:Score below $threshold\")"
        eval "$fix_commands_array+=(\"pylint $file\")"
        return 1
    else
        success "Pylint passed for $file"
        return 0
    fi
}

# Check Python file with flake8
check_python_flake8() {
    local file="$1"
    local issues_array="$2"
    local fix_commands_array="$3"
    
    if ! check_tool_available "flake8"; then
        debug "flake8 not available, skipping"
        return 0
    fi
    
    local line_length="${QUALITY_STANDARDS[python_line_length]}"
    local ignore="${QUALITY_STANDARDS[flake8_ignore]}"
    
    log "Running flake8 on $file"
    
    if ! flake8 --max-line-length=$line_length --ignore=$ignore "$file" 2>/dev/null; then
        error "Flake8 issues in $file"
        eval "$issues_array+=(\"flake8:$file:Style violations detected\")"
        eval "$fix_commands_array+=(\"flake8 --max-line-length=$line_length --ignore=$ignore $file\")"
        return 1
    else
        success "Flake8 passed for $file"
        return 0
    fi
}

# Check Python file formatting with autopep8
check_python_formatting() {
    local file="$1"
    local issues_array="$2"
    local fix_commands_array="$3"
    
    if ! check_tool_available "autopep8"; then
        debug "autopep8 not available, skipping"
        return 0
    fi
    
    local args="${QUALITY_STANDARDS[autopep8_args]}"
    
    log "Checking formatting for $file"
    
    if autopep8 --diff $args "$file" | grep -q .; then
        error "Formatting issues in $file"
        eval "$issues_array+=(\"formatting:$file:Code formatting issues detected\")"
        eval "$fix_commands_array+=(\"autopep8 --in-place $args $file\")"
        return 1
    else
        success "Formatting correct for $file"
        return 0
    fi
}

# Comprehensive Python file check
check_python_file() {
    local file="$1"
    local issues_array="$2"
    local fix_commands_array="$3"
    
    # Skip if not a Python file
    [[ ! "$file" =~ \.py$ ]] && return 0
    
    # Skip if file doesn't exist
    [[ ! -f "$file" ]] && return 0
    
    debug "Checking Python file: $file"
    
    local failed=0
    
    # Run all Python checks
    check_python_pylint "$file" "$issues_array" "$fix_commands_array" || failed=1
    check_python_flake8 "$file" "$issues_array" "$fix_commands_array" || failed=1
    check_python_formatting "$file" "$issues_array" "$fix_commands_array" || failed=1
    
    return $failed
}

# Check JavaScript file with JSHint
check_javascript_file() {
    local file="$1"
    local issues_array="$2"
    local fix_commands_array="$3"
    
    # Skip if not a JavaScript file
    [[ ! "$file" =~ \.js$ ]] && return 0
    
    # Skip if file doesn't exist
    [[ ! -f "$file" ]] && return 0
    
    debug "Checking JavaScript file: $file"
    
    if ! check_tool_available "jshint"; then
        debug "jshint not available, skipping"
        return 0
    fi
    
    log "Running JSHint on $file"
    
    if ! jshint "$file" 2>/dev/null; then
        warn "JSHint issues in $file"
        eval "$issues_array+=(\"jshint:$file:JavaScript quality issues\")"
        eval "$fix_commands_array+=(\"jshint $file\")"
        return 1
    else
        success "JSHint passed for $file"
        return 0
    fi
}

# Check HTML file validation
check_html_file() {
    local file="$1"
    local issues_array="$2"
    local fix_commands_array="$3"
    
    # Skip if not an HTML file
    [[ ! "$file" =~ \.html$ ]] && return 0
    
    # Skip if file doesn't exist
    [[ ! -f "$file" ]] && return 0
    
    debug "Checking HTML file: $file"
    
    if ! check_tool_available "python3"; then
        debug "python3 not available, skipping HTML validation"
        return 0
    fi
    
    if ! python3 -c "import html5lib" 2>/dev/null; then
        debug "html5lib not available, skipping HTML validation"
        return 0
    fi
    
    log "Validating HTML in $file"
    
    if python3 -c "import html5lib; html5lib.parse(open('$file').read())" 2>/dev/null; then
        success "HTML5 validation passed for $file"
        return 0
    else
        warn "HTML5 validation failed for $file"
        eval "$issues_array+=(\"html5:$file:HTML5 validation failed\")"
        eval "$fix_commands_array+=(\"# Manual HTML fix required for $file\")"
        return 1
    fi
}

# Run security audit with pip-audit
check_security() {
    local issues_array="$1"
    local fix_commands_array="$2"
    
    if ! check_tool_available "pip-audit"; then
        debug "pip-audit not available, skipping security check"
        return 0
    fi
    
    log "Running security audit with pip-audit"
    
    if ! pip-audit 2>/dev/null; then
        error "pip-audit found security vulnerabilities"
        eval "$issues_array+=(\"security:project:Security vulnerabilities detected\")"
        eval "$fix_commands_array+=(\"pip-audit --fix\")"
        return 1
    else
        success "Security audit passed"
        return 0
    fi
}

# Main quality check function for a single file
check_file_quality() {
    local file="$1"
    local issues_array="$2"
    local fix_commands_array="$3"
    
    local file_type=$(get_file_type "$file")
    local failed=0
    
    case "$file_type" in
        "python")
            check_python_file "$file" "$issues_array" "$fix_commands_array" || failed=1
            ;;
        "javascript")
            check_javascript_file "$file" "$issues_array" "$fix_commands_array" || failed=1
            ;;
        "html")
            check_html_file "$file" "$issues_array" "$fix_commands_array" || failed=1
            ;;
        "non-code")
            debug "Skipping quality checks for non-code file: $file"
            ;;
        *)
            debug "No specific quality checks for file type: $file"
            ;;
    esac
    
    return $failed
}

# Check if hooks should be bypassed
should_bypass_hooks() {
    [[ "${CLAUDE_HOOK_BYPASS:-false}" == "true" ]]
}

# Check if we're in quality mode
is_quality_mode_off() {
    [[ "${CLAUDE_QUALITY_MODE:-file}" == "off" ]]
}

# Generate standard JSON output
generate_quality_json() {
    local file_path="$1"
    local status="$2"
    local issues_array="$3"
    local fix_commands_array="$4"
    
    cat << EOF
{
  "hook": "quality-check",
  "timestamp": "$(date -Iseconds)",
  "file": "$file_path",
  "status": "$status",
  "issues": [
$(eval "local issues=(\"\${$issues_array[@]}\")")
$(for issue in "${issues[@]}"; do
    IFS=':' read -r type file details <<< "$issue"
    echo "    {\"type\": \"$type\", \"file\": \"$file\", \"details\": \"$details\"}"
    [[ "$issue" != "${issues[-1]}" ]] && echo ","
done)
  ],
  "fixes": [
$(eval "local fixes=(\"\${$fix_commands_array[@]}\")")
$(for i in "${!fixes[@]}"; do
    echo "    {\"command\": \"${fixes[$i]}\", \"order\": $((i+1))}"
    [[ $i -lt $((${#fixes[@]}-1)) ]] && echo ","
done)
  ],
  "standards": {
    "pylint_thresholds": {
      "backend": "${PYLINT_THRESHOLDS[backend]}",
      "frontend": "${PYLINT_THRESHOLDS[frontend]}",
      "general": "${PYLINT_THRESHOLDS[general]}"
    },
    "python_line_length": "${QUALITY_STANDARDS[python_line_length]}"
  }
}
EOF
}

# Export functions for use in other scripts
export -f check_tool_available
export -f get_file_type
export -f get_pylint_threshold
export -f get_pylint_args
export -f check_python_file
export -f check_javascript_file
export -f check_html_file
export -f check_security
export -f check_file_quality
export -f should_bypass_hooks
export -f is_quality_mode_off
export -f generate_quality_json
export -f log error success warn debug