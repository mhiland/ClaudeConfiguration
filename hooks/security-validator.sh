#!/bin/bash
# Consolidated Security Validator Hook
# Combines file-validator.sh and danger-check.sh to eliminate duplication
# Single-pass validation for all security concerns

set -e

# Source debounce utility
source ~/.claude/hooks/debounce.sh

# Check if hook should run (debounce)
if ! should_run_hook "security-validator"; then
    exit 0
fi

# Trap for debugging silent failures
trap 'echo "[SECURITY] Script failed at line $LINENO" >&2' ERR

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BYPASS_HOOKS=${CLAUDE_HOOK_BYPASS:-false}
LOG_LEVEL=${CLAUDE_LOG_LEVEL:-error}  # error, warn, info, debug
SECURITY_LOG="$HOME/.claude/logs/security.json"
SECURITY_MODE=${CLAUDE_SECURITY_MODE:-balanced}  # off, balanced, paranoid

# Early exit if hooks are bypassed
if [[ "$BYPASS_HOOKS" == "true" ]]; then
    [[ "$LOG_LEVEL" == "debug" ]] && echo -e "${BLUE}[SECURITY] Hook bypassed by CLAUDE_HOOK_BYPASS${NC}" >&2
    exit 0
fi

# Early exit if security is off
if [[ "$SECURITY_MODE" == "off" ]]; then
    [[ "$LOG_LEVEL" == "debug" ]] && echo -e "${BLUE}[SECURITY] Security checks disabled${NC}" >&2
    exit 0
fi

# Sensitive paths (combined from both original scripts)
SENSITIVE_PATHS=(
    "^/etc/"
    "^/root/"
    "^/sys/"
    "^/proc/"
    "/\.ssh/"
    "/\.aws/"
    "/\.gcp/"
    "/\.kube/"
    "\.env$"
    "\.env\."
    "secrets"
    "credentials"
    "password"
    "\.key$"
    "\.pem$"
    "\.crt$"
    "\.p12$"
    "\.jks$"
)

# Dangerous commands
ULTRA_DANGEROUS_COMMANDS=(
    "rm -rf /"
    ":(){ :|:& };:"
    "dd if=/dev/zero of=/"
    "mkfs\."
    "fdisk /dev/"
)

DANGEROUS_COMMANDS=(
    "rm -rf"
    "chmod 777"
    "> /dev/"
    "iptables -F"
    "git push --force.*main"
    "git push --force.*master"
    "git reset --hard"
)

# Safe file extensions
SAFE_EXTENSIONS=(
    "\.py$"
    "\.js$"
    "\.ts$"
    "\.jsx$"
    "\.tsx$"
    "\.html$"
    "\.css$"
    "\.scss$"
    "\.md$"
    "\.txt$"
    "\.json$"
    "\.yaml$"
    "\.yml$"
    "\.xml$"
    "\.csv$"
    "\.log$"
    "\.sh$"
    "\.bash$"
)

# Executable extensions to block
DANGEROUS_EXTENSIONS=(
    "\.exe$"
    "\.bat$"
    "\.cmd$"
    "\.com$"
    "\.scr$"
    "\.vbs$"
    "\.jar$"
    "\.deb$"
    "\.rpm$"
    "\.msi$"
    "\.dmg$"
    "\.pkg$"
)

# Logging function
log_security_event() {
    local level="$1"
    local event_type="$2"
    local message="$3"
    local details="$4"
    
    if [[ "$LOG_LEVEL" == "error" && "$level" != "error" ]]; then
        return
    fi
    
    # Ensure log directory exists
    mkdir -p "$(dirname "$SECURITY_LOG")"
    
    # Create JSON log entry
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    log_entry=$(jq -n \
        --arg ts "$timestamp" \
        --arg lvl "$level" \
        --arg type "$event_type" \
        --arg msg "$message" \
        --arg det "$details" \
        --arg pwd "$(pwd)" \
        --arg user "$(whoami)" \
        --arg branch "$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'no-git')" \
        '{timestamp: $ts, level: $lvl, event_type: $type, message: $msg, details: $det, context: {pwd: $pwd, user: $user, branch: $branch}}')
    
    if ! echo "$log_entry" >> "$SECURITY_LOG" 2>/dev/null; then
        echo "[SECURITY] Logging failed: $message" >&2
    fi
}

# Display functions
error() {
    echo -e "${RED}[SECURITY-ERROR] $1${NC}" >&2
    log_security_event "error" "$2" "$1" "$3"
}

warn() {
    [[ "$LOG_LEVEL" != "error" ]] && echo -e "${YELLOW}[SECURITY-WARN] $1${NC}" >&2
    log_security_event "warn" "$2" "$1" "$3"
}

info() {
    [[ "$LOG_LEVEL" == "info" || "$LOG_LEVEL" == "debug" ]] && echo -e "${BLUE}[SECURITY-INFO] $1${NC}" >&2
    log_security_event "info" "$2" "$1" "$3"
}

debug() {
    [[ "$LOG_LEVEL" == "debug" ]] && echo -e "${BLUE}[SECURITY-DEBUG] $1${NC}" >&2 || true
}

# Function to check if path is sensitive
is_sensitive_path() {
    local path="$1"
    for pattern in "${SENSITIVE_PATHS[@]}"; do
        if [[ "$path" =~ $pattern ]]; then
            return 0
        fi
    done
    return 1
}

# Function to check if extension is dangerous
is_dangerous_extension() {
    local file="$1"
    for ext in "${DANGEROUS_EXTENSIONS[@]}"; do
        if [[ "$file" =~ $ext ]]; then
            return 0
        fi
    done
    return 1
}

# Function to check if extension is safe
is_safe_extension() {
    local file="$1"
    for ext in "${SAFE_EXTENSIONS[@]}"; do
        if [[ "$file" =~ $ext ]]; then
            return 0
        fi
    done
    return 1
}

# Parse input and determine check type
# Read JSON input from stdin
if [[ -t 0 ]]; then
    # No stdin input (running interactively)
    debug "No stdin input provided - likely running in test mode"
    exit 0
fi

# Read all stdin input
HOOK_INPUT=$(cat)

if [[ -n "$HOOK_INPUT" ]]; then
    # Validate JSON input first
    if ! echo "$HOOK_INPUT" | jq . >/dev/null 2>&1; then
        debug "Invalid JSON input: $HOOK_INPUT"
        exit 0
    fi
    
    TOOL_NAME=$(echo "$HOOK_INPUT" | jq -r '.tool_name // ""' 2>/dev/null || echo "")
    
    case "$TOOL_NAME" in
        Write|Edit|MultiEdit|Read)
            # File operation checks
            FILE_PATH=$(echo "$HOOK_INPUT" | jq -r '.tool_input.file_path // ""' 2>/dev/null || echo "")
            if [[ -z "$FILE_PATH" ]]; then
                debug "No file path provided for file operation"
                exit 0
            fi
            if [[ "$TOOL_NAME" == "Read" ]]; then
                OPERATION="read"
            else
                OPERATION="write"
            fi
            
            if [[ -n "$FILE_PATH" ]]; then
                # Normalize path
                [[ "$FILE_PATH" != /* ]] && FILE_PATH="$(pwd)/$FILE_PATH"
                FILE_PATH=$(realpath "$FILE_PATH" 2>/dev/null || python3 -c "import os; print(os.path.abspath('$FILE_PATH'))" 2>/dev/null || echo "$FILE_PATH")
                
                debug "Checking file operation: $OPERATION on $FILE_PATH"
                
                # Path traversal check
                if [[ "$FILE_PATH" =~ \.\./|\.\.\\ ]]; then
                    error "❌ BLOCKED: Path traversal attempt" "path_traversal" "$FILE_PATH"
                    exit 1
                fi
                
                # Sensitive path check
                if is_sensitive_path "$FILE_PATH"; then
                    if [[ "$SECURITY_MODE" == "paranoid" ]] || [[ "$OPERATION" == "write" ]]; then
                        error "❌ BLOCKED: Access to sensitive path" "sensitive_path" "$FILE_PATH"
                        exit 1
                    else
                        warn "⚠️  WARNING: Reading sensitive path" "sensitive_path_read" "$FILE_PATH"
                    fi
                fi
                
                # Dangerous extension check for writes
                if [[ "$OPERATION" == "write" ]] && is_dangerous_extension "$FILE_PATH"; then
                    error "❌ BLOCKED: Writing to dangerous file type" "dangerous_extension" "$FILE_PATH"
                    exit 1
                fi
                
                # Warn for non-standard extensions
                if [[ "$OPERATION" == "write" ]] && ! is_safe_extension "$FILE_PATH" && ! is_dangerous_extension "$FILE_PATH"; then
                    warn "⚠️  WARNING: Writing to non-standard file type" "unknown_extension" "$FILE_PATH"
                fi
                
                # Check file size for reads
                if [[ "$OPERATION" == "read" && -f "$FILE_PATH" ]]; then
                    file_size=$(stat -c%s "$FILE_PATH" 2>/dev/null || stat -f%z "$FILE_PATH" 2>/dev/null || echo 0)
                    if [[ $file_size -gt 10485760 ]]; then  # 10MB
                        warn "⚠️  WARNING: Reading large file ($(($file_size/1048576))MB)" "large_file" "$FILE_PATH"
                    fi
                fi
                
                info "✅ File operation validated" "file_validated" "$FILE_PATH"
            fi
            ;;
            
        Bash)
            # Command execution checks
            COMMAND=$(echo "$HOOK_INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null || echo "")
            if [[ -z "$COMMAND" ]]; then
                debug "No command provided for bash operation"
                exit 0
            fi
            
            if [[ -n "$COMMAND" ]]; then
                debug "Checking bash command: $COMMAND"
                
                # Ultra-dangerous command check
                for pattern in "${ULTRA_DANGEROUS_COMMANDS[@]}"; do
                    if [[ "$COMMAND" =~ $pattern ]]; then
                        error "❌ BLOCKED: Ultra-dangerous command" "ultra_dangerous_command" "$COMMAND"
                        exit 1
                    fi
                done
                
                # Dangerous command check
                for pattern in "${DANGEROUS_COMMANDS[@]}"; do
                    if [[ "$COMMAND" =~ $pattern ]]; then
                        if [[ "$SECURITY_MODE" == "paranoid" ]]; then
                            error "❌ BLOCKED: Dangerous command (paranoid mode)" "dangerous_command" "$COMMAND"
                            exit 1
                        else
                            # Check if in production branch
                            branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
                            if [[ "$branch" =~ (main|master|prod|production) ]]; then
                                error "❌ BLOCKED: Dangerous command in production branch" "dangerous_command_prod" "$COMMAND"
                                exit 1
                            else
                                warn "⚠️  WARNING: Dangerous command detected" "dangerous_command" "$COMMAND"
                            fi
                        fi
                    fi
                done
                
                # System path operation check
                if [[ "$COMMAND" =~ (/etc/|/root/|/usr/bin/|/usr/sbin/|/var/lib/) ]]; then
                    if [[ "$COMMAND" =~ (>|rm|chmod|chown) ]]; then
                        error "❌ BLOCKED: Modification of system files" "system_modification" "$COMMAND"
                        exit 1
                    else
                        warn "⚠️  WARNING: Operation on system path" "system_operation" "$COMMAND"
                    fi
                fi
                
                info "✅ Command validated" "command_validated" "${COMMAND:0:50}..."
            fi
            ;;
            
        *)
            debug "No security checks for tool: $TOOL_NAME"
            ;;
    esac
else
    # If no input provided, this is likely a PreToolUse hook without context
    # Just exit successfully since there's nothing to validate
    debug "No input provided to security validator - likely PreToolUse without context"
    exit 0
fi

# Success - allow operation
exit 0