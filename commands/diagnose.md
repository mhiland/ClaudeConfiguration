---
allowed-tools: ["Bash", "Read", "LS"]
description: Diagnose Claude Code configuration and hook issues
---

# Diagnose Claude Code Setup

Analyze the current Claude Code configuration for potential issues and provide recommendations.

## Current Environment Analysis

**System Information:**
- Current directory: !`pwd`
- User: !`whoami`
- Shell: !`echo $SHELL`
- Claude Code version: !`claude --version 2>/dev/null || echo "Claude CLI not found in PATH"`

**Git Repository Status:**
- Repository root: !`git rev-parse --show-toplevel 2>/dev/null || echo "Not in git repository"`
- Current branch: !`git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "No git"`
- Working tree status: !`git status --porcelain 2>/dev/null | wc -l | xargs echo "Modified files:"`

## Claude Code Configuration Analysis

**Configuration Files:**
- Settings file: @.claude/settings.json
- CLAUDE.md exists: !`test -f CLAUDE.md && echo "✅ Found" || echo "❌ Missing"`
- Commands directory: !`ls -la .claude/commands/ 2>/dev/null | wc -l | xargs echo "Commands available:"`
- Hooks directory: !`ls -la .claude/hooks/ 2>/dev/null | wc -l | xargs echo "Hooks available:"`

**Hook Validation:**
- Security validator: !`test -x .claude/hooks/security-validator.sh && echo "✅ Executable" || echo "❌ Missing or not executable"`
- Quality checker: !`test -x .claude/hooks/quality-check.sh && echo "✅ Executable" || echo "❌ Missing or not executable"`
- Smart logger: !`test -x .claude/hooks/smart-logger.sh && echo "✅ Executable" || echo "❌ Missing or not executable"`

**Dependencies Check:**
- jq available: !`command -v jq >/dev/null && echo "✅ Found at $(which jq)" || echo "❌ Missing (required for JSON parsing)"`
- Python available: !`python3 --version 2>/dev/null || echo "❌ Python3 not found"`
- Git available: !`git --version 2>/dev/null || echo "❌ Git not found"`

**Log Directory Status:**
- Logs directory: !`ls -la .claude/logs/ 2>/dev/null || echo "No logs directory found"`

## Quick Test

**Hook Test:**
Run a simple test to verify hooks are working:
!`echo '{"session_id":"test","transcript_path":"/tmp/test","hook_event_name":"PreToolUse","tool_name":"Read","tool_input":{"file_path":"/tmp/test"}}' | .claude/hooks/security-validator.sh 2>&1 && echo "✅ Security hook working" || echo "❌ Security hook failed"`

## Diagnostic Summary

Based on the analysis above, identify any configuration issues and provide specific recommendations for:

1. **Missing dependencies** - Install any required tools
2. **File permissions** - Fix executable permissions on hooks
3. **Configuration errors** - Validate settings.json structure
4. **Hook functionality** - Test and debug hook execution
5. **Environment issues** - Resolve path or shell problems

## Recommended Actions

If issues are found, provide step-by-step instructions to resolve them using the specific error information from the diagnostic output above.