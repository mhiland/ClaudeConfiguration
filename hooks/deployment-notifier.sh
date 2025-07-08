#!/bin/bash
# Deployment notification hook
# Sends notifications for deployment-related operations

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NOTIFICATION_LOG="$HOME/.claude/logs/deployment-notifications.log"
DEPLOYMENT_COMMANDS=(
    "docker build"
    "docker push"
    "docker deploy"
    "kubectl apply"
    "kubectl create"
    "kubectl delete"
    "helm install"
    "helm upgrade"
    "terraform apply"
    "terraform destroy"
    "aws deploy"
    "gcloud deploy"
    "heroku deploy"
    "git push.*origin.*main"
    "git push.*origin.*master"
    "git push.*origin.*prod"
    "npm run build"
    "npm run deploy"
    "yarn deploy"
    "make deploy"
    "./deploy"
)

# Ensure log directory exists
mkdir -p "$(dirname "$NOTIFICATION_LOG")"

# Function to log notifications
log_notification() {
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
        echo "Git Commit: $(git rev-parse --short HEAD 2>/dev/null || echo 'Not in git repo')"
        echo "=================="
    } >> "$NOTIFICATION_LOG"
}

# Function to send desktop notification (if available)
send_desktop_notification() {
    local title="$1"
    local message="$2"
    local urgency="$3"
    
    if command -v notify-send &> /dev/null; then
        notify-send -u "$urgency" "$title" "$message"
    elif command -v osascript &> /dev/null; then
        # macOS notification
        osascript -e "display notification \"$message\" with title \"$title\""
    fi
}

# Function to send Slack notification (if configured)
send_slack_notification() {
    local message="$1"
    local webhook_url="$SLACK_WEBHOOK_URL"
    
    if [[ -n "$webhook_url" ]]; then
        curl -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"$message\"}" \
            "$webhook_url" 2>/dev/null || true
    fi
}

# Function to send email notification (if configured)
send_email_notification() {
    local subject="$1"
    local body="$2"
    local email="$NOTIFICATION_EMAIL"
    
    if [[ -n "$email" ]] && command -v mail &> /dev/null; then
        echo "$body" | mail -s "$subject" "$email" 2>/dev/null || true
    fi
}

# Function to check if command is deployment-related
is_deployment_command() {
    local command="$1"
    for pattern in "${DEPLOYMENT_COMMANDS[@]}"; do
        if [[ "$command" =~ $pattern ]]; then
            return 0
        fi
    done
    return 1
}

# Parse JSON input to extract command details
if [[ -n "$CLAUDE_HOOK_INPUT" ]]; then
    TOOL_NAME=$(echo "$CLAUDE_HOOK_INPUT" | jq -r '.tool_name // "Unknown"' 2>/dev/null || echo "Unknown")
    
    if [[ "$TOOL_NAME" == "Bash" ]]; then
        COMMAND=$(echo "$CLAUDE_HOOK_INPUT" | jq -r '.tool_input.command // "No command"' 2>/dev/null || echo "No command")
        DESCRIPTION=$(echo "$CLAUDE_HOOK_INPUT" | jq -r '.tool_input.description // "No description"' 2>/dev/null || echo "No description")
        
        # Check if this is a deployment-related command
        if is_deployment_command "$COMMAND"; then
            CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
            CURRENT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
            PROJECT_NAME=$(basename "$(pwd)")
            
            # Log the deployment operation
            log_notification "DEPLOYMENT" "Deployment operation detected" "$COMMAND"
            
            # Create notification message
            NOTIFICATION_TITLE="🚀 Deployment Operation"
            NOTIFICATION_MESSAGE="Project: $PROJECT_NAME
Branch: $CURRENT_BRANCH
Commit: $CURRENT_COMMIT
Command: $COMMAND
Description: $DESCRIPTION
User: $(whoami)
Time: $(date '+%Y-%m-%d %H:%M:%S')"
            
            # Determine urgency based on branch
            URGENCY="normal"
            if [[ "$CURRENT_BRANCH" =~ (main|master|prod|production) ]]; then
                URGENCY="critical"
                NOTIFICATION_TITLE="🔴 PRODUCTION DEPLOYMENT"
            elif [[ "$CURRENT_BRANCH" =~ (staging|stage) ]]; then
                URGENCY="normal"
                NOTIFICATION_TITLE="🟡 STAGING DEPLOYMENT"
            else
                URGENCY="low"
                NOTIFICATION_TITLE="🟢 DEVELOPMENT DEPLOYMENT"
            fi
            
            # Send notifications
            echo -e "${BLUE}[DEPLOYMENT-NOTIFIER] 📢 Deployment operation detected${NC}" >&2
            echo -e "${BLUE}Project: $PROJECT_NAME${NC}" >&2
            echo -e "${BLUE}Branch: $CURRENT_BRANCH${NC}" >&2
            echo -e "${BLUE}Command: $COMMAND${NC}" >&2
            
            # Send desktop notification
            send_desktop_notification "$NOTIFICATION_TITLE" "$NOTIFICATION_MESSAGE" "$URGENCY"
            
            # Send Slack notification if configured
            if [[ -n "$SLACK_WEBHOOK_URL" ]]; then
                SLACK_MESSAGE="$NOTIFICATION_TITLE
$NOTIFICATION_MESSAGE"
                send_slack_notification "$SLACK_MESSAGE"
                echo -e "${GREEN}[DEPLOYMENT-NOTIFIER] 📱 Slack notification sent${NC}" >&2
            fi
            
            # Send email notification if configured
            if [[ -n "$NOTIFICATION_EMAIL" ]]; then
                send_email_notification "$NOTIFICATION_TITLE" "$NOTIFICATION_MESSAGE"
                echo -e "${GREEN}[DEPLOYMENT-NOTIFIER] 📧 Email notification sent${NC}" >&2
            fi
            
            # Log to deployment history
            echo "$(date '+%Y-%m-%d %H:%M:%S') | $PROJECT_NAME | $CURRENT_BRANCH | $CURRENT_COMMIT | $COMMAND" >> "$HOME/.claude/logs/deployment-history.log"
            
        else
            echo -e "${GREEN}[DEPLOYMENT-NOTIFIER] ℹ️  Non-deployment command, no notification sent${NC}" >&2
        fi
    else
        echo -e "${GREEN}[DEPLOYMENT-NOTIFIER] ℹ️  Non-bash tool, no notification sent${NC}" >&2
    fi
else
    echo -e "${RED}[DEPLOYMENT-NOTIFIER] No input provided${NC}" >&2
fi

# Always allow the operation to proceed
exit 0