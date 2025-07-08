#!/bin/bash
# MCP tool operation logging hook
# Logs all MCP tool operations for debugging and monitoring

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
LOG_FILE="$HOME/.claude/logs/mcp-operations.log"
MAX_LOG_SIZE=5242880  # 5MB
BACKUP_COUNT=3

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Function to rotate logs if they get too large
rotate_log() {
    if [[ -f "$LOG_FILE" ]] && [[ $(stat -c%s "$LOG_FILE" 2>/dev/null || stat -f%z "$LOG_FILE" 2>/dev/null) -gt $MAX_LOG_SIZE ]]; then
        for i in $(seq $((BACKUP_COUNT-1)) -1 1); do
            [[ -f "${LOG_FILE}.$i" ]] && mv "${LOG_FILE}.$i" "${LOG_FILE}.$((i+1))"
        done
        [[ -f "$LOG_FILE" ]] && mv "$LOG_FILE" "${LOG_FILE}.1"
    fi
}

# Parse JSON input to extract MCP tool details
if [[ -n "$CLAUDE_HOOK_INPUT" ]]; then
    # Extract tool information from JSON
    TOOL_NAME=$(echo "$CLAUDE_HOOK_INPUT" | jq -r '.tool_name // "Unknown MCP Tool"' 2>/dev/null || echo "Unknown MCP Tool")
    TOOL_INPUT=$(echo "$CLAUDE_HOOK_INPUT" | jq -c '.tool_input // {}' 2>/dev/null || echo '{}')
    
    # Rotate log if needed
    rotate_log
    
    # Log the MCP operation with timestamp
    {
        echo "=================="
        echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "MCP Tool: $TOOL_NAME"
        echo "Working Directory: $(pwd)"
        echo "User: $(whoami)"
        echo "Tool Input: $TOOL_INPUT"
        echo "Git Branch: $(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'Not in git repo')"
        echo "=================="
    } >> "$LOG_FILE"
    
    # Log specific MCP operations to separate files
    case "$TOOL_NAME" in
        mcp__memory__*)
            echo -e "${BLUE}[MCP-LOGGER] Memory operation: $TOOL_NAME${NC}" >&2
            echo "MEMORY-OP: $(date '+%Y-%m-%d %H:%M:%S'): $TOOL_NAME - $TOOL_INPUT" >> "$HOME/.claude/logs/mcp-memory.log"
            ;;
        mcp__ide__*)
            echo -e "${BLUE}[MCP-LOGGER] IDE operation: $TOOL_NAME${NC}" >&2
            echo "IDE-OP: $(date '+%Y-%m-%d %H:%M:%S'): $TOOL_NAME - $TOOL_INPUT" >> "$HOME/.claude/logs/mcp-ide.log"
            ;;
        mcp__*__write*|mcp__*__edit*|mcp__*__delete*)
            echo -e "${YELLOW}[MCP-LOGGER] Write operation: $TOOL_NAME${NC}" >&2
            echo "WRITE-OP: $(date '+%Y-%m-%d %H:%M:%S'): $TOOL_NAME - $TOOL_INPUT" >> "$HOME/.claude/logs/mcp-write.log"
            ;;
        mcp__*__execute*)
            echo -e "${YELLOW}[MCP-LOGGER] Execute operation: $TOOL_NAME${NC}" >&2
            echo "EXEC-OP: $(date '+%Y-%m-%d %H:%M:%S'): $TOOL_NAME - $TOOL_INPUT" >> "$HOME/.claude/logs/mcp-execute.log"
            ;;
        *)
            echo -e "${GREEN}[MCP-LOGGER] General MCP operation: $TOOL_NAME${NC}" >&2
            ;;
    esac
    
    # Check for potentially sensitive operations
    if echo "$TOOL_NAME" | grep -qE "(delete|remove|clear|reset)"; then
        echo -e "${YELLOW}[MCP-LOGGER] WARNING: Potentially destructive MCP operation${NC}" >&2
        echo "WARNING: Destructive MCP operation at $(date '+%Y-%m-%d %H:%M:%S'): $TOOL_NAME" >> "$LOG_FILE"
    fi
    
    echo -e "${GREEN}[MCP-LOGGER] MCP operation logged: $TOOL_NAME${NC}" >&2
else
    echo -e "${RED}[MCP-LOGGER] No input provided${NC}" >&2
fi

# Always allow the operation to proceed
exit 0