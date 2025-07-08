#!/bin/bash
# Hook debounce utility - prevents concurrent hook executions
# Usage: source debounce.sh

DEBOUNCE_DIR="/tmp/.claude_hooks"
DEBOUNCE_TIMEOUT=2

# Create debounce directory
mkdir -p "$DEBOUNCE_DIR"

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

# Function to cleanup old lock files
cleanup_old_locks() {
    find "$DEBOUNCE_DIR" -name "*.lock" -mmin +5 -delete 2>/dev/null || true
}

# Cleanup on script start
cleanup_old_locks