#!/bin/bash
# Claude Code Pre-commit Quality Check Hook
# Runs quality checks on staged files before git commit
# Returns exit code 2 to block commit if quality issues found

set -e

# Source shared quality library
source ~/.claude/hooks/quality-lib.sh

# Configuration
LOG_LEVEL=${CLAUDE_LOG_LEVEL:-error}
BYPASS_HOOKS=${CLAUDE_HOOK_BYPASS:-false}

# Early exit if hooks are bypassed
if should_bypass_hooks; then
    debug "Hook bypassed by CLAUDE_HOOK_BYPASS"
    exit 0
fi

# Read hook input from stdin
if [[ -t 0 ]]; then
    # No stdin input, exit
    exit 0
fi

HOOK_INPUT=$(cat)
if [[ -z "$HOOK_INPUT" ]]; then
    exit 0
fi

# Parse JSON to check if this is a git commit command
if ! echo "$HOOK_INPUT" | jq . >/dev/null 2>&1; then
    exit 0
fi

TOOL_NAME=$(echo "$HOOK_INPUT" | jq -r '.tool_name // ""' 2>/dev/null || echo "")
COMMAND=$(echo "$HOOK_INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null || echo "")

if [[ "$TOOL_NAME" != "Bash" || ! "$COMMAND" =~ ^git[[:space:]]+commit ]]; then
    # Not a git commit command, allow through
    exit 0
fi

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${YELLOW}Not in a git repository, skipping quality checks${NC}"
    exit 0
fi

# Get staged files
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null)

if [[ -z "$STAGED_FILES" ]]; then
    echo -e "${YELLOW}No staged files to check${NC}"
    exit 0
fi

echo -e "${YELLOW}Running pre-commit quality checks on staged files...${NC}"

# Track failures
QUALITY_FAILED=false
declare -a FAILED_FILES
declare -a QUALITY_ISSUES
declare -a FIX_COMMANDS

# Check each staged file using shared quality library
for file in $STAGED_FILES; do
    log "Checking staged file: $file"
    
    # Use shared quality check function
    if ! check_file_quality "$file" QUALITY_ISSUES FIX_COMMANDS; then
        QUALITY_FAILED=true
        FAILED_FILES+=("$file")
    fi
done

if [[ "$QUALITY_FAILED" == "true" ]]; then
    error "Quality checks failed! Blocking commit."
    echo "Fix these issues and try again:"
    for cmd in "${FIX_COMMANDS[@]}"; do
        echo "  $cmd"
    done
    exit 2
fi

success "Quality checks passed!"
exit 0