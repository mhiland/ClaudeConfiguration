#!/bin/bash
# Hook debounce utility - prevents concurrent hook executions and tracks failures
# Usage: source debounce.sh

DEBOUNCE_DIR="/tmp/.claude_hooks"
DEBOUNCE_TIMEOUT=2
FAILURE_TRACKING_DIR="$HOME/.claude/hooks/failures"
MAX_CONSECUTIVE_FAILURES=${CLAUDE_HOOK_MAX_FAILURES:-5}
COOLDOWN_MINUTES=${CLAUDE_HOOK_COOLDOWN:-10}

# Create directories
mkdir -p "$DEBOUNCE_DIR" "$FAILURE_TRACKING_DIR"

# Function to check if hook should run
should_run_hook() {
    local hook_name="$1"
    local lock_file="$DEBOUNCE_DIR/${hook_name}.lock"
    
    # Check if lock file exists and is recent
    if [[ -f "$lock_file" ]]; then
        local last_run=$(stat -c%Y "$lock_file" 2>/dev/null || echo 0)
        local current_time=$(date +%s)
        
        if (( current_time - last_run < DEBOUNCE_TIMEOUT )); then
            return 1  # Should not run
        fi
    fi
    
    # Create/update lock file
    touch "$lock_file"
    return 0  # Should run
}

# Function to record hook failure
record_hook_failure() {
    local hook_name="$1"
    local failure_file="$FAILURE_TRACKING_DIR/$hook_name.failures"
    local current_time=$(date +%s)
    
    # Read existing failures
    local consecutive_failures=0
    if [[ -f "$failure_file" ]]; then
        consecutive_failures=$(jq -r '.consecutive_failures // 0' "$failure_file" 2>/dev/null || echo "0")
    fi
    
    # Increment failure count
    consecutive_failures=$((consecutive_failures + 1))
    
    # Create failure record
    cat > "$failure_file" << EOF
{
  "consecutive_failures": $consecutive_failures,
  "last_failure": $current_time,
  "emergency_brake_active": $([ $consecutive_failures -ge $MAX_CONSECUTIVE_FAILURES ] && echo "true" || echo "false"),
  "brake_until": $([ $consecutive_failures -ge $MAX_CONSECUTIVE_FAILURES ] && echo "$((current_time + COOLDOWN_MINUTES * 60))" || echo "null")
}
EOF
    
    # Log the failure
    echo "[DEBOUNCE] Recorded failure for $hook_name (consecutive: $consecutive_failures)" >&2
}

# Function to record hook success
record_hook_success() {
    local hook_name="$1"
    local failure_file="$FAILURE_TRACKING_DIR/$hook_name.failures"
    
    # Reset failure count on success
    rm -f "$failure_file"
    echo "[DEBOUNCE] Reset failure count for $hook_name" >&2
}

# Function to check if emergency brake is active
is_emergency_brake_active() {
    local hook_name="$1"
    local failure_file="$FAILURE_TRACKING_DIR/$hook_name.failures"
    
    if [[ ! -f "$failure_file" ]]; then
        return 1
    fi
    
    local brake_active=$(jq -r '.emergency_brake_active // false' "$failure_file" 2>/dev/null || echo "false")
    local brake_until=$(jq -r '.brake_until // null' "$failure_file" 2>/dev/null || echo "null")
    local current_time=$(date +%s)
    
    if [[ "$brake_active" == "true" && "$brake_until" != "null" ]]; then
        if [[ $current_time -lt $brake_until ]]; then
            return 0  # Brake is active
        else
            # Brake expired, reset
            rm -f "$failure_file"
            return 1
        fi
    fi
    
    return 1
}

# Function to cleanup old lock files
cleanup_old_locks() {
    find "$DEBOUNCE_DIR" -name "*.lock" -mmin +5 -delete 2>/dev/null || true
}

# Cleanup on script start
cleanup_old_locks