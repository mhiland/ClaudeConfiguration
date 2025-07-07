#!/bin/bash
# Danger check hook - blocks potentially dangerous operations
# Provides safety checks for destructive commands

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DANGER_LOG="$HOME/.claude/logs/danger-blocks.log"
ALLOWED_USERS=("$(whoami)")  # Add usernames that can bypass some checks
PRODUCTION_INDICATORS=("prod" "production" "live" "master" "main")

# Ensure log directory exists
mkdir -p "$(dirname "$DANGER_LOG")"

# Function to log dangerous operations
log_danger() {
    local level="$1"
    local message="$2"
    local command="$3"
    
    {
        echo "=================="
        echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "Level: $level"
        echo "Message: $message"
        echo "Command: $command"
        echo "Working Directory: $(pwd)"
        echo "User: $(whoami)"
        echo "Git Branch: $(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'Not in git repo')"
        echo "=================="
    } >> "$DANGER_LOG"
}

# Parse JSON input to extract bash command details
if [[ -n "$CLAUDE_HOOK_INPUT" ]]; then
    COMMAND=$(echo "$CLAUDE_HOOK_INPUT" | jq -r '.tool_input.command // "No command"')
    DESCRIPTION=$(echo "$CLAUDE_HOOK_INPUT" | jq -r '.tool_input.description // "No description"')
    
    # Check current git branch for production indicators
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
    IS_PRODUCTION=false
    for indicator in "${PRODUCTION_INDICATORS[@]}"; do
        if [[ "$CURRENT_BRANCH" == *"$indicator"* ]]; then
            IS_PRODUCTION=true
            break
        fi
    done
    
    # Ultra-dangerous commands that should never be allowed
    if echo "$COMMAND" | grep -qE "(rm -rf /|sudo rm -rf /|dd if=/dev/zero of=/|mkfs\.|fdisk /dev/|parted /dev/|:(){ :|:& };:|sudo shutdown|sudo reboot|sudo halt)"; then
        log_danger "BLOCKED" "Ultra-dangerous command blocked" "$COMMAND"
        echo -e "${RED}[DANGER-CHECK] ❌ BLOCKED: Ultra-dangerous command detected${NC}" >&2
        echo -e "${RED}Command: $COMMAND${NC}" >&2
        echo -e "${RED}This command could cause system damage and has been blocked.${NC}" >&2
        exit 1
    fi
    
    # Dangerous commands that require extra caution
    if echo "$COMMAND" | grep -qE "(rm -rf|sudo|chmod 777|> /dev/|dd if=|mkfs|fdisk|parted|iptables -F|ufw --force-enable)"; then
        log_danger "WARNING" "Dangerous command detected" "$COMMAND"
        echo -e "${YELLOW}[DANGER-CHECK] ⚠️  WARNING: Dangerous command detected${NC}" >&2
        echo -e "${YELLOW}Command: $COMMAND${NC}" >&2
        echo -e "${YELLOW}Description: $DESCRIPTION${NC}" >&2
        
        # Block dangerous commands in production branches
        if [[ "$IS_PRODUCTION" == true ]]; then
            log_danger "BLOCKED" "Dangerous command blocked in production branch" "$COMMAND"
            echo -e "${RED}[DANGER-CHECK] ❌ BLOCKED: Dangerous command in production branch '$CURRENT_BRANCH'${NC}" >&2
            exit 1
        fi
        
        # Allow with warning for non-production
        echo -e "${YELLOW}[DANGER-CHECK] ⚠️  Allowing with warning (non-production branch)${NC}" >&2
    fi
    
    # Git operations that could cause data loss
    if echo "$COMMAND" | grep -qE "git (push --force|reset --hard|clean -fd|branch -D|tag -d)"; then
        log_danger "WARNING" "Potentially destructive git operation" "$COMMAND"
        echo -e "${YELLOW}[DANGER-CHECK] ⚠️  WARNING: Potentially destructive git operation${NC}" >&2
        echo -e "${YELLOW}Command: $COMMAND${NC}" >&2
        
        # Block force push to production branches
        if [[ "$IS_PRODUCTION" == true ]] && echo "$COMMAND" | grep -qE "git push.*--force"; then
            log_danger "BLOCKED" "Force push blocked in production branch" "$COMMAND"
            echo -e "${RED}[DANGER-CHECK] ❌ BLOCKED: Force push to production branch '$CURRENT_BRANCH'${NC}" >&2
            exit 1
        fi
    fi
    
    # Check for operations on sensitive files
    if echo "$COMMAND" | grep -qE "(/etc/|/root/|/home/[^/]+/\.ssh/|/usr/bin/|/usr/sbin/|/var/lib/|/proc/|/sys/)"; then
        log_danger "WARNING" "Operation on sensitive system path" "$COMMAND"
        echo -e "${YELLOW}[DANGER-CHECK] ⚠️  WARNING: Operation on sensitive system path${NC}" >&2
        echo -e "${YELLOW}Command: $COMMAND${NC}" >&2
        
        # Block modifications to critical system files
        if echo "$COMMAND" | grep -qE "(> /etc/|rm.*(/etc/|/root/|/usr/bin/|/usr/sbin/)|chmod.*(/etc/|/root/|/usr/bin/|/usr/sbin/))"; then
            log_danger "BLOCKED" "Modification of critical system files blocked" "$COMMAND"
            echo -e "${RED}[DANGER-CHECK] ❌ BLOCKED: Modification of critical system files${NC}" >&2
            exit 1
        fi
    fi
    
    # Check for network operations that could expose services
    if echo "$COMMAND" | grep -qE "(nc -l|python.*-m.*http\.server|python.*-m.*SimpleHTTPServer|php -S|ruby -run.*httpd|node.*express)"; then
        log_danger "INFO" "Network service startup detected" "$COMMAND"
        echo -e "${BLUE}[DANGER-CHECK] ℹ️  INFO: Network service startup detected${NC}" >&2
        echo -e "${BLUE}Command: $COMMAND${NC}" >&2
        echo -e "${BLUE}Ensure this is intentional and secure${NC}" >&2
    fi
    
    # Check for package manager operations
    if echo "$COMMAND" | grep -qE "(sudo.*apt|sudo.*yum|sudo.*dnf|sudo.*pacman|sudo.*zypper|sudo.*brew|pip install|npm install.*-g)"; then
        log_danger "INFO" "Package installation detected" "$COMMAND"
        echo -e "${BLUE}[DANGER-CHECK] ℹ️  INFO: Package installation detected${NC}" >&2
        echo -e "${BLUE}Command: $COMMAND${NC}" >&2
    fi
    
    # Log safe operations for audit trail
    log_danger "ALLOWED" "Command allowed after safety checks" "$COMMAND"
    echo -e "${GREEN}[DANGER-CHECK] ✅ Safety checks passed${NC}" >&2
    
else
    echo -e "${RED}[DANGER-CHECK] No input provided${NC}" >&2
fi

# Allow the command to proceed if we reach here
exit 0