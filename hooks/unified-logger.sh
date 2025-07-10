#!/bin/bash
# Unified Logger Hook - Single logging system for all Claude Code operations
# Replaces: bash-logger.sh, smart-logger.sh, mcp-logger.sh, monitor.sh

set -e

# Configuration from settings.json
BYPASS_HOOKS=${CLAUDE_HOOK_BYPASS:-false}
LOG_LEVEL=${CLAUDE_LOG_LEVEL:-error}  # error, warn, info, debug
UNIFIED_LOG="$HOME/.claude/logs/unified.jsonl"
MAX_LOG_SIZE=10485760  # 10MB
BACKUP_COUNT=3

# Early exit if hooks are bypassed or logging is disabled
[[ "$BYPASS_HOOKS" == "true" ]] && exit 0
[[ "$LOG_LEVEL" == "off" ]] && exit 0

# Ensure log directory exists
mkdir -p "$(dirname "$UNIFIED_LOG")"

# Simple log rotation
rotate_log() {
    if [[ -f "$UNIFIED_LOG" ]]; then
        log_size=$(stat -c%s "$UNIFIED_LOG" 2>/dev/null || stat -f%z "$UNIFIED_LOG" 2>/dev/null || echo 0)
        if [[ $log_size -gt $MAX_LOG_SIZE ]]; then
            for i in $(seq $((BACKUP_COUNT-1)) -1 1); do
                [[ -f "${UNIFIED_LOG}.$i" ]] && mv "${UNIFIED_LOG}.$i" "${UNIFIED_LOG}.$((i+1))"
            done
            [[ -f "$UNIFIED_LOG" ]] && mv "$UNIFIED_LOG" "${UNIFIED_LOG}.1"
        fi
    fi
}

# Determine if we should log based on level
should_log() {
    local event_level="$1"
    case "$LOG_LEVEL" in
        error) [[ "$event_level" == "error" ]] ;;
        warn) [[ "$event_level" =~ ^(error|warn)$ ]] ;;
        info) [[ "$event_level" =~ ^(error|warn|info)$ ]] ;;
        debug) true ;;
        *) false ;;
    esac
}

# Parse hook input
if [[ -n "$CLAUDE_HOOK_INPUT" ]]; then
    TOOL_NAME=$(echo "$CLAUDE_HOOK_INPUT" | jq -r '.tool_name // "unknown"' 2>/dev/null || echo "unknown")
    TOOL_INPUT=$(echo "$CLAUDE_HOOK_INPUT" | jq -c '.tool_input // {}' 2>/dev/null || echo '{}')
    
    # Determine event classification
    EVENT_LEVEL="info"
    EVENT_DETAILS="{}"
    RISK_LEVEL="low"
    
    case "$TOOL_NAME" in
        Bash)
            COMMAND=$(echo "$TOOL_INPUT" | jq -r '.command // ""' 2>/dev/null || echo "")
            EVENT_DETAILS=$(jq -n --arg cmd "$COMMAND" '{command: $cmd}' 2>/dev/null || echo '{}')
            
            # Risk assessment
            if [[ "$COMMAND" =~ (rm -rf|sudo|dd if=|mkfs|fdisk|parted|chmod 777|> /dev/) ]]; then
                EVENT_LEVEL="warn"
                RISK_LEVEL="high"
            elif [[ "$COMMAND" =~ (git push|git reset --hard|docker|kubectl|terraform) ]]; then
                RISK_LEVEL="medium"
            fi
            ;;
            
        Write|Edit|MultiEdit)
            FILE_PATH=$(echo "$TOOL_INPUT" | jq -r '.file_path // ""' 2>/dev/null || echo "")
            EVENT_DETAILS=$(jq -n --arg path "$FILE_PATH" '{file_path: $path}' 2>/dev/null || echo '{}')
            
            # Check for sensitive files
            if [[ "$FILE_PATH" =~ (\.env|secrets|credentials|\.key|\.pem|\.ssh|authorized_keys) ]]; then
                EVENT_LEVEL="warn"
                RISK_LEVEL="high"
            fi
            ;;
            
        mcp__*)
            EVENT_DETAILS="$TOOL_INPUT"
            if [[ "$TOOL_NAME" =~ (delete|remove|clear|reset|execute) ]]; then
                EVENT_LEVEL="warn"
                RISK_LEVEL="medium"
            fi
            ;;
            
        *)
            EVENT_LEVEL="debug"
            ;;
    esac
    
    # Only log if level matches configuration
    if should_log "$EVENT_LEVEL"; then
        rotate_log
        
        # Create single unified log entry
        TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
        LOG_ENTRY=$(jq -n \
            --arg ts "$TIMESTAMP" \
            --arg tool "$TOOL_NAME" \
            --arg level "$EVENT_LEVEL" \
            --arg risk "$RISK_LEVEL" \
            --argjson details "$EVENT_DETAILS" \
            --arg pwd "$(pwd)" \
            --arg user "$(whoami)" \
            --arg branch "$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'no-git')" \
            '{
                timestamp: $ts,
                tool: $tool,
                level: $level,
                risk_level: $risk,
                details: $details,
                context: {
                    pwd: $pwd,
                    user: $user,
                    git_branch: $branch
                }
            }' 2>/dev/null)
        
        # Append to single log file
        echo "$LOG_ENTRY" >> "$UNIFIED_LOG" 2>/dev/null || true
        
        # Minimal output based on risk level
        case "$RISK_LEVEL" in
            high)
                echo -e "\033[0;31m[LOG] HIGH RISK: $TOOL_NAME\033[0m" >&2
                ;;
            medium)
                [[ "$LOG_LEVEL" != "error" ]] && echo -e "\033[0;33m[LOG] MEDIUM RISK: $TOOL_NAME\033[0m" >&2 || true
                ;;
            *)
                [[ "$LOG_LEVEL" == "debug" ]] && echo -e "\033[0;34m[LOG] $TOOL_NAME\033[0m" >&2 || true
                ;;
        esac
    fi
fi

# Always succeed - logging should never block operations
exit 0