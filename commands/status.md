---
allowed-tools: ["Bash", "Read"]
description: Show quick status overview of Claude Code setup and project
---

# Claude Code Status Dashboard

Quick overview of your current development environment and Claude Code configuration.

## 🚀 Environment Overview

**Project:** !`basename "$(pwd)"`  
**Location:** !`pwd`  
**Time:** !`date "+%Y-%m-%d %H:%M:%S"`

## 📊 Git Status
!`git status --porcelain | head -10 | wc -l | xargs printf "Modified files: %s\n"`
!`git log --oneline -3 2>/dev/null || echo "No git history"`

## ⚙️ Claude Configuration

**Active Model:** !`jq -r '.model // "default"' .claude/settings.json 2>/dev/null || echo "unknown"`  
**Hook Status:**
- PreToolUse: !`jq -r '.hooks.PreToolUse | length' .claude/settings.json 2>/dev/null || echo "0"` configured
- PostToolUse: !`jq -r '.hooks.PostToolUse | length' .claude/settings.json 2>/dev/null || echo "0"` configured

**Available Commands:** !`ls .claude/commands/ 2>/dev/null | wc -l | xargs echo`

## 🔧 System Resources

**Disk Space:** !`df -h . | tail -1 | awk '{print $4 " available (" $5 " used)"}'`  
**Memory:** !`free -h 2>/dev/null | grep '^Mem:' | awk '{print $7 " available"}' || echo "N/A"`

## 📝 Recent Activity

**Last 3 files modified:**
!`find . -type f -not -path './.*' -not -path './node_modules/*' -not -path './venv/*' -exec ls -lt {} \; | head -3 | awk '{print $9 " (" $6 " " $7 " " $8 ")"}'`

**Hook Logs:**
!`ls -la .claude/logs/ 2>/dev/null | tail -3 || echo "No log files found"`

## 🎯 Quick Actions

Common next steps:
- `/diagnose` - Run configuration diagnostics
- `/backup create` - Create configuration backup  
- `git status` - Check git working tree
- `git log --oneline -5` - Recent commits

**Current directory contents:**
!`ls -la | head -10`

---
*Status generated at $(date)*