---
allowed-tools: ["Bash", "Write", "Read", "LS"]
description: Create and manage backups of Claude Code configurations
---

# Backup Claude Code Configuration

Create timestamped backups of your Claude Code configuration and restore from previous backups.

## Usage
- `/backup create` - Create a new backup
- `/backup list` - List available backups  
- `/backup restore <timestamp>` - Restore from backup

## Current Configuration Status

**Active Configuration:**
- Settings: @.claude/settings.json
- CLAUDE.md: @CLAUDE.md
- Commands: !`ls -1 .claude/commands/ 2>/dev/null | wc -l | xargs echo "files"`
- Hooks: !`ls -1 .claude/hooks/ 2>/dev/null | wc -l | xargs echo "files"`

## Backup Operations

### Create Backup
```bash
# Create timestamped backup directory
BACKUP_DIR=".claude/backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Copy configuration files
cp .claude/settings.json "$BACKUP_DIR/" 2>/dev/null || echo "No settings.json"
cp CLAUDE.md "$BACKUP_DIR/" 2>/dev/null || echo "No CLAUDE.md"
cp -r .claude/commands "$BACKUP_DIR/" 2>/dev/null || echo "No commands"
cp -r .claude/hooks "$BACKUP_DIR/" 2>/dev/null || echo "No hooks"

# Create backup manifest
echo "Backup created: $(date)" > "$BACKUP_DIR/manifest.txt"
echo "Git commit: $(git rev-parse HEAD 2>/dev/null || echo 'no-git')" >> "$BACKUP_DIR/manifest.txt"
echo "Working directory: $(pwd)" >> "$BACKUP_DIR/manifest.txt"

echo "✅ Backup created in $BACKUP_DIR"
```

### List Backups
!`ls -la .claude/backups/ 2>/dev/null || echo "No backups directory found"`

### Backup History
**Recent backups:**
!`find .claude/backups -name "manifest.txt" -exec head -1 {} \; 2>/dev/null | head -5 || echo "No backup manifests found"`

## Arguments Processing

$ARGUMENTS

**Action to perform:**
- If `$ARGUMENTS` contains "create": Execute backup creation
- If `$ARGUMENTS` contains "list": Show detailed backup list  
- If `$ARGUMENTS` contains "restore": Restore from specified backup
- If no arguments: Show this help and current status

## Restoration Process

To restore from a backup:
1. Identify backup timestamp from list above
2. Run: `/backup restore YYYYMMDD_HHMMSS`
3. Current config will be backed up automatically before restore
4. Restored files will replace current configuration

**Safety note:** Always commit current changes to git before restoring from backup.

## Recommended Backup Schedule

- Before major configuration changes
- After successful hook implementations  
- Weekly for active development setups
- Before Claude Code updates

Create backups with: `/backup create`