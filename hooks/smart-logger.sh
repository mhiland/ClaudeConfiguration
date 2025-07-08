#!/bin/bash
# Smart Logger Hook - Unified JSON logging with minimal overhead
# Replaces multiple log files with single structured log

set -e

# Configuration
BYPASS_HOOKS=${CLAUDE_HOOK_BYPASS:-false}
LOG_LEVEL=${CLAUDE_LOG_LEVEL:-error}  # error, warn, info, debug
UNIFIED_LOG="$HOME/.claude/logs/unified.json"
MAX_LOG_SIZE=10485760  # 10MB
BACKUP_COUNT=3

# Early exit if hooks are bypassed
if [[ "$BYPASS_HOOKS" == "true" ]]; then
    exit 0
fi

# Early exit if logging is disabled
if [[ "$LOG_LEVEL" == "off" ]]; then
    exit 0
fi

# Ensure log directory exists
mkdir -p "$(dirname "$UNIFIED_LOG")"

# Function to rotate logs if needed
rotate_log() {
    if [[ -f "$UNIFIED_LOG" ]]; then
        local log_size=$(stat -c%s "$UNIFIED_LOG" 2>/dev/null || stat -f%z "$UNIFIED_LOG" 2>/dev/null || echo 0)
        if [[ $log_size -gt $MAX_LOG_SIZE ]]; then
            for i in $(seq $((BACKUP_COUNT-1)) -1 1); do
                [[ -f "${UNIFIED_LOG}.$i" ]] && mv "${UNIFIED_LOG}.$i" "${UNIFIED_LOG}.$((i+1))"
            done
            [[ -f "$UNIFIED_LOG" ]] && mv "$UNIFIED_LOG" "${UNIFIED_LOG}.1"
        fi
    fi
}

# Function to determine if we should log based on level
should_log() {
    local event_level="$1"
    case "$LOG_LEVEL" in
        error)
            [[ "$event_level" == "error" ]]
            ;;
        warn)
            [[ "$event_level" == "error" || "$event_level" == "warn" ]]
            ;;
        info)
            [[ "$event_level" == "error" || "$event_level" == "warn" || "$event_level" == "info" ]]
            ;;
        debug)
            true
            ;;
        *)
            false
            ;;
    esac
}

# Parse input
if [[ -n "$CLAUDE_HOOK_INPUT" ]]; then
    TOOL_NAME=$(echo "$CLAUDE_HOOK_INPUT" | jq -r '.tool_name // "unknown"')
    TOOL_INPUT=$(echo "$CLAUDE_HOOK_INPUT" | jq -c '.tool_input // {}')
    
    # Determine event type and level based on tool
    EVENT_TYPE="tool_use"
    EVENT_LEVEL="info"
    EVENT_DETAILS="{}"
    
    case "$TOOL_NAME" in
        Bash)
            COMMAND=$(echo "$TOOL_INPUT" | jq -r '.command // ""')
            DESCRIPTION=$(echo "$TOOL_INPUT" | jq -r '.description // ""')
            EVENT_DETAILS=$(jq -n --arg cmd "$COMMAND" --arg desc "$DESCRIPTION" '{command: $cmd, description: $desc}')
            
            # Determine level based on command
            if [[ "$COMMAND" =~ (rm -rf|sudo|dd if=|mkfs|fdisk) ]]; then
                EVENT_LEVEL="warn"
                EVENT_TYPE="dangerous_command"
            elif [[ "$COMMAND" =~ ^git ]]; then
                EVENT_TYPE="git_operation"
            elif [[ "$COMMAND" =~ (docker|kubectl|helm|terraform) ]]; then
                EVENT_TYPE="deployment_operation"
                EVENT_LEVEL="info"
            fi
            ;;
            
        Write|Edit|MultiEdit)
            FILE_PATH=$(echo "$TOOL_INPUT" | jq -r '.file_path // ""')
            EVENT_DETAILS=$(jq -n --arg path "$FILE_PATH" '{file_path: $path}')
            EVENT_TYPE="file_write"
            
            # Check for sensitive files
            if [[ "$FILE_PATH" =~ (\.env|secrets|credentials|\.key|\.pem) ]]; then
                EVENT_LEVEL="warn"
                EVENT_TYPE="sensitive_file_write"
            fi
            ;;
            
        Read)
            FILE_PATH=$(echo "$TOOL_INPUT" | jq -r '.file_path // ""')
            EVENT_DETAILS=$(jq -n --arg path "$FILE_PATH" '{file_path: $path}')
            EVENT_TYPE="file_read"
            EVENT_LEVEL="debug"  # Reads are low priority
            ;;
            
        mcp__*)
            EVENT_TYPE="mcp_operation"
            EVENT_DETAILS="$TOOL_INPUT"
            ;;
            
        *)
            EVENT_TYPE="other_operation"
            EVENT_LEVEL="debug"
            ;;
    esac
    
    # Only log if level matches configuration
    if should_log "$EVENT_LEVEL"; then
        # Rotate log if needed
        rotate_log
        
        # Create unified log entry
        TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
        LOG_ENTRY=$(jq -n \
            --arg ts "$TIMESTAMP" \
            --arg tool "$TOOL_NAME" \
            --arg type "$EVENT_TYPE" \
            --arg level "$EVENT_LEVEL" \
            --argjson details "$EVENT_DETAILS" \
            --arg pwd "$(pwd)" \
            --arg user "$(whoami)" \
            --arg branch "$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'no-git')" \
            --arg commit "$(git rev-parse --short HEAD 2>/dev/null || echo 'no-git')" \
            '{
                timestamp: $ts,
                tool: $tool,
                event_type: $type,
                level: $level,
                details: $details,
                context: {
                    pwd: $pwd,
                    user: $user,
                    git_branch: $branch,
                    git_commit: $commit
                }
            }')
        
        # Append to log file
        echo "$LOG_ENTRY" >> "$UNIFIED_LOG"
        
        # Output minimal feedback based on log level
        if [[ "$LOG_LEVEL" == "debug" ]]; then
            echo -e "\033[0;34m[LOG] $EVENT_TYPE: $TOOL_NAME\033[0m" >&2
        fi
    fi
fi

# Always succeed - logging should never block operations
exit 0