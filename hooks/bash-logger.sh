#!/bin/bash
# Bash command logging hook for debugging and audit trail
# Logs all bash commands with timestamps for debugging and security auditing

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
LOG_FILE="$HOME/.claude/logs/bash-commands.log"
MAX_LOG_SIZE=10485760  # 10MB
BACKUP_COUNT=5

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

# Parse JSON input to extract bash command details
if [[ -n "$CLAUDE_HOOK_INPUT" ]]; then
    # Extract command and description from JSON
    COMMAND=$(echo "$CLAUDE_HOOK_INPUT" | jq -r '.tool_input.command // "No command"' 2>/dev/null || echo "No command")
    DESCRIPTION=$(echo "$CLAUDE_HOOK_INPUT" | jq -r '.tool_input.description // "No description"' 2>/dev/null || echo "No description")
    TOOL_NAME=$(echo "$CLAUDE_HOOK_INPUT" | jq -r '.tool_name // "Unknown"' 2>/dev/null || echo "Unknown")
    
    # Rotate log if needed
    rotate_log
    
    # Log the command with timestamp
    {
        echo "=================="
        echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "Tool: $TOOL_NAME"
        echo "Description: $DESCRIPTION"
        echo "Command: $COMMAND"
        echo "Working Directory: $(pwd)"
        echo "User: $(whoami)"
        echo "Git Branch: $(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'Not in git repo')"
        echo "=================="
    } >> "$LOG_FILE"
    
    # Check for potentially dangerous commands
    if echo "$COMMAND" | grep -qE "(rm -rf|sudo|chmod 777|> /dev/|dd if=|mkfs|fdisk|parted)"; then
        echo -e "${YELLOW}[BASH-LOGGER] WARNING: Potentially dangerous command detected${NC}" >&2
        echo "WARNING: Dangerous command at $(date '+%Y-%m-%d %H:%M:%S'): $COMMAND" >> "$LOG_FILE"
    fi
    
    # Log git operations separately
    if echo "$COMMAND" | grep -qE "^git\s+(push|pull|merge|rebase|reset --hard|clean -fd)"; then
        echo -e "${BLUE}[BASH-LOGGER] Git operation logged${NC}" >&2
        echo "GIT-OP: $(date '+%Y-%m-%d %H:%M:%S'): $COMMAND" >> "$HOME/.claude/logs/git-operations.log"
    fi
    
    # Log system operations
    if echo "$COMMAND" | grep -qE "(systemctl|service|mount|umount|iptables|ufw)"; then
        echo -e "${BLUE}[BASH-LOGGER] System operation logged${NC}" >&2
        echo "SYS-OP: $(date '+%Y-%m-%d %H:%M:%S'): $COMMAND" >> "$HOME/.claude/logs/system-operations.log"
    fi
    
    echo -e "${GREEN}[BASH-LOGGER] Command logged: $(echo "$COMMAND" | cut -c1-50)...${NC}" >&2
else
    echo -e "${RED}[BASH-LOGGER] No input provided${NC}" >&2
fi

# Always allow the command to proceed
exit 0