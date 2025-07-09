#!/bin/bash
# Claude Code Quality Check Hook - OPTIMIZED VERSION
# Checks only edited files by default, with option for full project scan
# Includes bypass mechanism to prevent circular loops

set -e

# Source utilities
source ~/.claude/hooks/debounce.sh
source ~/.claude/hooks/monitor.sh
source ~/.claude/hooks/quality-lib.sh

# Check if hook should run (debounce)
if ! should_run_hook "quality-check"; then
    exit 0
fi

# Check emergency brake
if is_emergency_brake_active "quality-check"; then
    warn "Emergency brake active for quality-check hook"
    log_hook_event "quality-check" "brake" "" 0 "Emergency brake prevented execution"
    exit 0
fi

# Trap for debugging silent failures
trap 'echo "[QUALITY] Script failed at line $LINENO" >&2' ERR

# Color output (from quality-lib.sh)
# RED, GREEN, YELLOW, BLUE, NC are defined in quality-lib.sh

# Configuration
VERBOSE=${CLAUDE_HOOK_VERBOSE:-false}
BYPASS_HOOKS=${CLAUDE_HOOK_BYPASS:-false}
QUALITY_MODE=${CLAUDE_QUALITY_MODE:-file}  # file, project, off
OPERATION_CONTEXT=${CLAUDE_OPERATION_CONTEXT:-edit}  # edit, check, batch
AUTO_FIX=${CLAUDE_AUTO_FIX:-true}  # Enable automatic fix suggestions
OUTPUT_FORMAT=${CLAUDE_HOOK_OUTPUT_FORMAT:-mixed}  # human, json, mixed

# Early exit if hooks are bypassed
if should_bypass_hooks; then
    debug "Hook bypassed by CLAUDE_HOOK_BYPASS"
    exit 0
fi

# Early exit if quality checks are off
if is_quality_mode_off; then
    debug "Quality checks disabled"
    exit 0
fi

# Logging functions are now provided by quality-lib.sh

# Extract edited file from hook input via stdin
EDITED_FILE=""
if [[ -t 0 ]]; then
    # No stdin input (running interactively)
    debug "No stdin input - running interactively"
    exit 0
fi

# Read all stdin input
HOOK_INPUT=$(cat)

if [[ -z "$HOOK_INPUT" ]]; then
    debug "No hook input received"
    exit 0
fi

# Validate JSON input
if ! echo "$HOOK_INPUT" | jq . >/dev/null 2>&1; then
    debug "Invalid JSON input received"
    exit 0
fi

TOOL_NAME=$(echo "$HOOK_INPUT" | jq -r '.tool_name // ""' 2>/dev/null || echo "")
if [[ "$TOOL_NAME" =~ ^(Write|Edit|MultiEdit)$ ]]; then
    EDITED_FILE=$(echo "$HOOK_INPUT" | jq -r '.tool_input.file_path // ""' 2>/dev/null || echo "")
    debug "Extracted edited file: $EDITED_FILE"
else
    debug "Tool $TOOL_NAME not relevant for quality checks"
    exit 0
fi

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    warn "Not in a git repository, skipping quality checks"
    exit 0
fi

# Track if any checks failed
CHECKS_FAILED=false
declare -a QUALITY_ISSUES
declare -a FIX_COMMANDS

# Function to add quality issue
add_quality_issue() {
    local issue_type="$1"
    local file_path="$2"
    local details="$3"
    local fix_command="$4"
    
    QUALITY_ISSUES+=("$issue_type:$file_path:$details")
    [[ -n "$fix_command" ]] && FIX_COMMANDS+=("$fix_command")
}

# Function to generate JSON output
generate_json_output() {
    local file_path="$1"
    local status="$2"
    
    cat << EOF
{
  "hook": "quality-check",
  "timestamp": "$(date -Iseconds)",
  "file": "$file_path",
  "status": "$status",
  "issues": [
$(for issue in "${QUALITY_ISSUES[@]}"; do
    IFS=':' read -r type file details <<< "$issue"
    echo "    {\"type\": \"$type\", \"file\": \"$file\", \"details\": \"$details\"}"
    [[ "$issue" != "${QUALITY_ISSUES[-1]}" ]] && echo ","
done)
  ],
  "fixes": [
$(for i in "${!FIX_COMMANDS[@]}"; do
    echo "    {\"command\": \"${FIX_COMMANDS[$i]}\", \"order\": $((i+1))}"
    [[ $i -lt $((${#FIX_COMMANDS[@]}-1)) ]] && echo ","
done)
  ],
  "auto_fix_enabled": $AUTO_FIX,
  "operation_context": "$OPERATION_CONTEXT"
}
EOF
}

# Python file checking is now handled by quality-lib.sh

# JavaScript and HTML file checking is now handled by quality-lib.sh

# Function to run full project checks (original behavior)
run_project_checks() {
    log "Running full project quality checks..."
    
    # For now, skip project-wide checks in normal operation
    # This would contain the full project scanning logic
    log "Project-wide checks skipped (not implemented yet)"
    return 0
}

# Start monitoring
start_monitoring "quality-check" "$EDITED_FILE"

# Main logic
if [[ "$QUALITY_MODE" == "project" ]]; then
    # Full project mode explicitly requested
    log "Running in project mode"
    run_project_checks
elif [[ -z "$EDITED_FILE" && "$QUALITY_MODE" == "file" ]]; then
    # No file to check in file mode - this is normal for some operations
    debug "No specific file to check, skipping quality checks"
    end_monitoring "quality-check" "" "bypass" "No file to check"
    exit 0
elif [[ -n "$EDITED_FILE" && "$QUALITY_MODE" == "file" ]]; then
    # File-specific mode
    log "Running quality checks on edited file: $EDITED_FILE"
    
    # Skip checks for non-code files
    if [[ "$EDITED_FILE" =~ \.(md|txt|json|yml|yaml|cfg|ini|conf|lock)$ ]]; then
        log "Skipping quality checks for non-code file: $EDITED_FILE"
        end_monitoring "quality-check" "$EDITED_FILE" "bypass" "Non-code file type"
        exit 0
    fi
    
    # Use shared quality check function
    check_file_quality "$EDITED_FILE" QUALITY_ISSUES FIX_COMMANDS || CHECKS_FAILED=true
    
    # Security checks only in project mode or during check operations
    if [[ "$OPERATION_CONTEXT" == "check" ]]; then
        check_security QUALITY_ISSUES FIX_COMMANDS || CHECKS_FAILED=true
    fi
fi

# Final result
if [[ "$CHECKS_FAILED" == "true" ]]; then
    error "Quality checks failed for $EDITED_FILE"
    
    # Record failure for emergency brake tracking
    record_hook_failure "quality-check"
    
    # Generate structured output based on format preference
    if [[ "$OUTPUT_FORMAT" == "json" ]]; then
        generate_quality_json "$EDITED_FILE" "failed" QUALITY_ISSUES FIX_COMMANDS
    elif [[ "$OUTPUT_FORMAT" == "mixed" ]]; then
        # Human-readable section
        echo ""
        echo "CLAUDE CODE: Fix the following issues immediately:"
        for i in "${!FIX_COMMANDS[@]}"; do
            echo "$((i+1)). Run: ${FIX_COMMANDS[$i]}"
        done
        echo "$((${#FIX_COMMANDS[@]}+1)). Re-run the tool that triggered this hook"
        echo ""
        
        # Machine-readable section
        echo "=== HOOK_OUTPUT_JSON ==="
        generate_quality_json "$EDITED_FILE" "failed" QUALITY_ISSUES FIX_COMMANDS
        echo "=== END_HOOK_OUTPUT_JSON ==="
    else
        # Human-readable only
        echo ""
        echo "CLAUDE CODE: Fix the following issues immediately:"
        for i in "${!FIX_COMMANDS[@]}"; do
            echo "$((i+1)). Run: ${FIX_COMMANDS[$i]}"
        done
        echo "$((${#FIX_COMMANDS[@]}+1)). Re-run the tool that triggered this hook"
        echo ""
    fi
    
    # In check mode, we might want to continue despite failures
    if [[ "$OPERATION_CONTEXT" == "check" ]]; then
        warn "Continuing despite failures (check mode)"
        end_monitoring "quality-check" "$EDITED_FILE" "failure" "Check mode - continuing despite failures"
        exit 0
    else
        echo "[QUALITY] CLAUDE CODE MUST FIX THESE ISSUES BEFORE PROCEEDING" >&2
        end_monitoring "quality-check" "$EDITED_FILE" "failure" "Quality checks failed - ${#QUALITY_ISSUES[@]} issues found"
        exit 1
    fi
else
    # Record success to reset failure count
    record_hook_success "quality-check"
    
    if [[ "$OUTPUT_FORMAT" == "json" || "$OUTPUT_FORMAT" == "mixed" ]]; then
        generate_quality_json "$EDITED_FILE" "passed" QUALITY_ISSUES FIX_COMMANDS
    fi
    success "Quality checks passed!"
    end_monitoring "quality-check" "$EDITED_FILE" "success" "All quality checks passed"
    exit 0
fi