#!/bin/bash
# File validation hook for sensitive operations
# Validates file operations to prevent unauthorized access to sensitive files

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
VALIDATION_LOG="$HOME/.claude/logs/file-validation.log"
SENSITIVE_PATHS=(
    "/etc/passwd"
    "/etc/shadow"
    "/etc/sudoers"
    "/root/"
    "/home/*/\.ssh/"
    "/var/lib/docker/"
    "/proc/"
    "/sys/"
    "\.env"
    "\.env\."
    "secrets"
    "credentials"
    "\.key"
    "\.pem"
    "\.crt"
    "\.p12"
    "\.jks"
    "config\.json"
    "\.aws/"
    "\.gcp/"
    "\.kube/"
)

ALLOWED_EXTENSIONS=(
    "\.py"
    "\.js"
    "\.ts"
    "\.html"
    "\.css"
    "\.md"
    "\.txt"
    "\.json"
    "\.yaml"
    "\.yml"
    "\.xml"
    "\.csv"
    "\.log"
)

# Ensure log directory exists
mkdir -p "$(dirname "$VALIDATION_LOG")"

# Function to log validation events
log_validation() {
    local level="$1"
    local message="$2"
    local file_path="$3"
    local operation="$4"
    
    {
        echo "=================="
        echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "Level: $level"
        echo "Message: $message"
        echo "File Path: $file_path"
        echo "Operation: $operation"
        echo "Working Directory: $(pwd)"
        echo "User: $(whoami)"
        echo "Git Branch: $(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'Not in git repo')"
        echo "=================="
    } >> "$VALIDATION_LOG"
}

# Function to check if path is sensitive
is_sensitive_path() {
    local path="$1"
    for sensitive in "${SENSITIVE_PATHS[@]}"; do
        if [[ "$path" =~ $sensitive ]]; then
            return 0
        fi
    done
    return 1
}

# Function to check if file extension is allowed
is_allowed_extension() {
    local file="$1"
    for ext in "${ALLOWED_EXTENSIONS[@]}"; do
        if [[ "$file" =~ $ext$ ]]; then
            return 0
        fi
    done
    return 1
}

# Function to validate file size
validate_file_size() {
    local file_path="$1"
    local max_size=$((10 * 1024 * 1024))  # 10MB
    
    if [[ -f "$file_path" ]]; then
        local file_size=$(stat -c%s "$file_path" 2>/dev/null || stat -f%z "$file_path" 2>/dev/null)
        if [[ $file_size -gt $max_size ]]; then
            return 1
        fi
    fi
    return 0
}

# Function to check for binary files
is_binary_file() {
    local file_path="$1"
    if [[ -f "$file_path" ]]; then
        # Check if file contains null bytes (indicates binary)
        if grep -q $'\0' "$file_path" 2>/dev/null; then
            return 0
        fi
    fi
    return 1
}

# Parse JSON input to extract file operation details
if [[ -n "$CLAUDE_HOOK_INPUT" ]]; then
    TOOL_NAME=$(echo "$CLAUDE_HOOK_INPUT" | jq -r '.tool_name // "Unknown"')
    
    # Extract file path based on tool type
    case "$TOOL_NAME" in
        "Write"|"Edit"|"MultiEdit")
            FILE_PATH=$(echo "$CLAUDE_HOOK_INPUT" | jq -r '.tool_input.file_path // ""')
            OPERATION="write/edit"
            ;;
        "Read")
            FILE_PATH=$(echo "$CLAUDE_HOOK_INPUT" | jq -r '.tool_input.file_path // ""')
            OPERATION="read"
            ;;
        *)
            FILE_PATH=""
            OPERATION="unknown"
            ;;
    esac
    
    if [[ -n "$FILE_PATH" ]]; then
        # Convert to absolute path if relative
        if [[ "$FILE_PATH" != /* ]]; then
            FILE_PATH="$(pwd)/$FILE_PATH"
        fi
        
        # Normalize path (remove .. and . components)
        FILE_PATH=$(realpath -m "$FILE_PATH" 2>/dev/null || echo "$FILE_PATH")
        
        log_validation "INFO" "File operation validation started" "$FILE_PATH" "$OPERATION"
        
        # Check for path traversal attempts
        if [[ "$FILE_PATH" =~ \.\./|\.\.\\ ]]; then
            log_validation "BLOCKED" "Path traversal attempt detected" "$FILE_PATH" "$OPERATION"
            echo -e "${RED}[FILE-VALIDATOR] ❌ BLOCKED: Path traversal attempt detected${NC}" >&2
            echo -e "${RED}File: $FILE_PATH${NC}" >&2
            exit 1
        fi
        
        # Check for sensitive paths
        if is_sensitive_path "$FILE_PATH"; then
            log_validation "BLOCKED" "Access to sensitive file/path blocked" "$FILE_PATH" "$OPERATION"
            echo -e "${RED}[FILE-VALIDATOR] ❌ BLOCKED: Access to sensitive file/path${NC}" >&2
            echo -e "${RED}File: $FILE_PATH${NC}" >&2
            echo -e "${RED}This file contains sensitive information and access is restricted.${NC}" >&2
            exit 1
        fi
        
        # Check if file extension is allowed for write operations
        if [[ "$OPERATION" == "write/edit" ]] && ! is_allowed_extension "$FILE_PATH"; then
            log_validation "WARNING" "Writing to file with potentially dangerous extension" "$FILE_PATH" "$OPERATION"
            echo -e "${YELLOW}[FILE-VALIDATOR] ⚠️  WARNING: Writing to file with potentially dangerous extension${NC}" >&2
            echo -e "${YELLOW}File: $FILE_PATH${NC}" >&2
            
            # Block certain dangerous extensions
            if [[ "$FILE_PATH" =~ \.(exe|bat|cmd|ps1|sh|com|scr|vbs|jar|deb|rpm|msi|dmg|pkg)$ ]]; then
                log_validation "BLOCKED" "Writing to executable file blocked" "$FILE_PATH" "$OPERATION"
                echo -e "${RED}[FILE-VALIDATOR] ❌ BLOCKED: Writing to executable file${NC}" >&2
                exit 1
            fi
        fi
        
        # Check file size for read operations
        if [[ "$OPERATION" == "read" ]] && ! validate_file_size "$FILE_PATH"; then
            log_validation "WARNING" "Reading large file" "$FILE_PATH" "$OPERATION"
            echo -e "${YELLOW}[FILE-VALIDATOR] ⚠️  WARNING: Reading large file (>10MB)${NC}" >&2
            echo -e "${YELLOW}File: $FILE_PATH${NC}" >&2
        fi
        
        # Check for binary files
        if [[ "$OPERATION" == "read" ]] && is_binary_file "$FILE_PATH"; then
            log_validation "WARNING" "Reading binary file" "$FILE_PATH" "$OPERATION"
            echo -e "${YELLOW}[FILE-VALIDATOR] ⚠️  WARNING: Reading binary file${NC}" >&2
            echo -e "${YELLOW}File: $FILE_PATH${NC}" >&2
        fi
        
        # Check for files outside of current project
        CURRENT_DIR=$(pwd)
        if [[ "$FILE_PATH" != "$CURRENT_DIR"* ]]; then
            log_validation "WARNING" "File operation outside current project directory" "$FILE_PATH" "$OPERATION"
            echo -e "${YELLOW}[FILE-VALIDATOR] ⚠️  WARNING: File operation outside current project${NC}" >&2
            echo -e "${YELLOW}File: $FILE_PATH${NC}" >&2
            echo -e "${YELLOW}Current Dir: $CURRENT_DIR${NC}" >&2
        fi
        
        # Check for hidden files that might contain sensitive data
        if [[ "$FILE_PATH" =~ /\.[^/]*$ ]] && [[ "$OPERATION" == "read" ]]; then
            log_validation "INFO" "Reading hidden file" "$FILE_PATH" "$OPERATION"
            echo -e "${BLUE}[FILE-VALIDATOR] ℹ️  INFO: Reading hidden file${NC}" >&2
            echo -e "${BLUE}File: $FILE_PATH${NC}" >&2
        fi
        
        # Log successful validation
        log_validation "ALLOWED" "File operation validated and allowed" "$FILE_PATH" "$OPERATION"
        echo -e "${GREEN}[FILE-VALIDATOR] ✅ File operation validated${NC}" >&2
    else
        echo -e "${BLUE}[FILE-VALIDATOR] ℹ️  INFO: No file path to validate${NC}" >&2
    fi
    
else
    echo -e "${RED}[FILE-VALIDATOR] No input provided${NC}" >&2
fi

# Allow the operation to proceed if we reach here
exit 0