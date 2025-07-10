#!/bin/bash
# Claude Code Quality Library - Simplified Version
# Common quality checking functions without eval statements and complex abstractions

# Configuration and Standards - Load from JSON
STANDARDS_FILE="$HOME/.claude/quality-standards.json"

# Load quality standards from JSON file
load_quality_standards() {
    if [[ ! -f "$STANDARDS_FILE" ]]; then
        echo "[ERROR] Quality standards file not found: $STANDARDS_FILE" >&2
        return 1
    fi
    
    # Load pylint thresholds  
    declare -gA PYLINT_THRESHOLDS
    PYLINT_THRESHOLDS["backend"]=$(jq -r '.python.pylint_thresholds.backend' "$STANDARDS_FILE")
    PYLINT_THRESHOLDS["frontend"]=$(jq -r '.python.pylint_thresholds.frontend' "$STANDARDS_FILE") 
    PYLINT_THRESHOLDS["general"]=$(jq -r '.python.pylint_thresholds.general' "$STANDARDS_FILE")
    
    # Load other standards
    declare -gA QUALITY_STANDARDS
    QUALITY_STANDARDS["python_line_length"]=$(jq -r '.python.line_length' "$STANDARDS_FILE")
    QUALITY_STANDARDS["flake8_ignore"]=$(jq -r '.python.flake8.ignore | join(",")' "$STANDARDS_FILE")
    QUALITY_STANDARDS["autopep8_args"]="--max-line-length=$(jq -r '.python.autopep8.max_line_length' "$STANDARDS_FILE")"
}

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging functions - use CLAUDE_LOG_LEVEL from settings.json
LOG_LEVEL=${CLAUDE_LOG_LEVEL:-error}

log() {
    [[ "$LOG_LEVEL" =~ ^(info|debug)$ ]] && echo -e "${BLUE}[$(date '+%H:%M:%S')] $1${NC}" >&2 || true
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

# Initialize standards after logging functions are defined
load_quality_standards

# Global arrays for issues and fixes - no eval needed
declare -ga QUALITY_ISSUES
declare -ga QUALITY_FIXES

# Simple functions to add issues and fixes
add_issue() {
    QUALITY_ISSUES+=("$1")
}

add_fix() {
    QUALITY_FIXES+=("$1")
}

clear_results() {
    QUALITY_ISSUES=()
    QUALITY_FIXES=()
}

# Check if tools are available
check_tool_available() {
    command -v "$1" &> /dev/null
}

# Simple file type detection
get_file_type() {
    local file="$1"
    case "$file" in
        *.py) echo "python" ;;
        *.js) echo "javascript" ;;
        *.html) echo "html" ;;
        *.sh) echo "shell" ;;
        *) echo "other" ;;
    esac
}

# Simplified Python checks - direct tool invocation
check_python_file() {
    local file="$1"
    [[ ! -f "$file" ]] && return 0
    
    local failed=0
    
    # Pylint check
    if check_tool_available "pylint"; then
        local threshold="${PYLINT_THRESHOLDS[general]}"
        local score=$(pylint "$file" 2>/dev/null | grep "Your code has been rated" | grep -oE "[0-9]+\.[0-9]+" || echo "0.0")
        if (( $(echo "$score < $threshold" | bc -l) )); then
            add_issue "pylint:$file:Score $score below $threshold"
            add_fix "pylint $file"
            failed=1
        fi
    fi
    
    # Flake8 check
    if check_tool_available "flake8"; then
        local line_length="${QUALITY_STANDARDS[python_line_length]}"
        local ignore="${QUALITY_STANDARDS[flake8_ignore]}"
        if ! flake8 --max-line-length="$line_length" --ignore="$ignore" "$file" 2>/dev/null; then
            add_issue "flake8:$file:Style violations"
            add_fix "flake8 --max-line-length=$line_length --ignore=$ignore $file"
            failed=1
        fi
    fi
    
    # Autopep8 check
    if check_tool_available "autopep8"; then
        local args="${QUALITY_STANDARDS[autopep8_args]}"
        if ! autopep8 --diff $args "$file" | grep -q "^$"; then
            add_issue "autopep8:$file:Formatting issues"
            add_fix "autopep8 --in-place $args $file"
            failed=1
        fi
    fi
    
    return $failed
}

# Simplified JavaScript check
check_javascript_file() {
    local file="$1"
    [[ ! -f "$file" ]] && return 0
    
    if check_tool_available "jshint" && ! jshint "$file" 2>/dev/null; then
        add_issue "jshint:$file:Quality issues"
        add_fix "jshint $file"
        return 1
    fi
    return 0
}

# Simplified HTML check
check_html_file() {
    local file="$1"
    [[ ! -f "$file" ]] && return 0
    
    if check_tool_available "python3" && python3 -c "import html5lib" 2>/dev/null; then
        if ! python3 -c "import html5lib; html5lib.parse(open('$file').read())" 2>/dev/null; then
            add_issue "html5:$file:Validation failed"
            add_fix "# Manual HTML fix required for $file"
            return 1
        fi
    fi
    return 0
}

# Simplified shell check
check_shell_file() {
    local file="$1"
    [[ ! -f "$file" ]] && return 0
    
    local failed=0
    
    if check_tool_available "shellcheck" && ! shellcheck "$file" 2>/dev/null; then
        add_issue "shellcheck:$file:Quality issues"
        add_fix "shellcheck $file"
        failed=1
    fi
    
    if check_tool_available "shfmt" && ! shfmt -d -i 2 -ci "$file" 2>/dev/null | grep -q "^$"; then
        add_issue "shfmt:$file:Formatting issues"
        add_fix "shfmt -w -i 2 -ci $file"
        failed=1
    fi
    
    return $failed
}

# Main quality check function - simplified interface
check_file_quality() {
    local file="$1"
    clear_results
    
    local file_type=$(get_file_type "$file")
    case "$file_type" in
        "python") check_python_file "$file" ;;
        "javascript") check_javascript_file "$file" ;;
        "html") check_html_file "$file" ;;
        "shell") check_shell_file "$file" ;;
        *) debug "No quality checks for file type: $file" ;;
    esac
}

# Simplified JSON output without eval
generate_quality_json() {
    local file_path="$1"
    local status="$2"
    
    local issues_json=""
    for issue in "${QUALITY_ISSUES[@]}"; do
        IFS=':' read -r type file details <<< "$issue"
        [[ -n "$issues_json" ]] && issues_json+=","
        issues_json+="{\"type\":\"$type\",\"file\":\"$file\",\"details\":\"$details\"}"
    done
    
    local fixes_json=""
    for i in "${!QUALITY_FIXES[@]}"; do
        [[ -n "$fixes_json" ]] && fixes_json+=","
        fixes_json+="{\"command\":\"${QUALITY_FIXES[$i]}\",\"order\":$((i+1))}"
    done
    
    cat << EOF
{
  "hook": "quality-check",
  "timestamp": "$(date -Iseconds)",
  "file": "$file_path",
  "status": "$status",
  "issues": [$issues_json],
  "fixes": [$fixes_json],
  "issue_count": ${#QUALITY_ISSUES[@]},
  "fix_count": ${#QUALITY_FIXES[@]}
}
EOF
}

# Security check function
check_security() {
    if check_tool_available "pip-audit"; then
        if ! pip-audit 2>/dev/null; then
            add_issue "security:project:Vulnerabilities detected"
            add_fix "pip-audit --fix"
            return 1
        fi
    fi
    return 0
}

# Check if hooks should be bypassed
should_bypass_hooks() {
    [[ "${CLAUDE_HOOK_BYPASS:-false}" == "true" ]]
}

# Check if quality mode is off
is_quality_mode_off() {
    [[ "${CLAUDE_QUALITY_MODE:-file}" == "off" ]]
}