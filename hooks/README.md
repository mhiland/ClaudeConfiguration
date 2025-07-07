# Claude Code Hooks Documentation

This directory contains comprehensive hooks for Claude Code that provide security, logging, and notification capabilities.

## Hook Overview

### Security Hooks
- **`danger-check.sh`** - Blocks dangerous operations and provides safety checks
- **`file-validator.sh`** - Validates file operations and prevents access to sensitive files

### Logging Hooks
- **`bash-logger.sh`** - Logs all bash commands with timestamps for debugging
- **`mcp-logger.sh`** - Logs MCP tool operations for monitoring
- **`deployment-notifier.sh`** - Sends notifications for deployment operations

### Environment Hooks
- **`env-check.sh`** - Validates environment setup before operations
- **`quality-check.sh`** - Runs quality checks after file modifications

## Configuration

The hooks are configured in `~/.claude/settings.json` with the following structure:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [{"type": "command", "command": "~/.claude/hooks/bash-logger.sh"}]
      },
      {
        "matcher": "Write|Edit|MultiEdit|Read",
        "hooks": [{"type": "command", "command": "~/.claude/hooks/file-validator.sh"}]
      },
      {
        "matcher": "Write|Edit|MultiEdit",
        "hooks": [{"type": "command", "command": "~/.claude/hooks/env-check.sh"}]
      },
      {
        "matcher": "mcp__.*",
        "hooks": [{"type": "command", "command": "~/.claude/hooks/mcp-logger.sh"}]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write|Edit|MultiEdit",
        "hooks": [{"type": "command", "command": "~/.claude/hooks/quality-check.sh"}]
      },
      {
        "matcher": "Bash",
        "hooks": [{"type": "command", "command": "~/.claude/hooks/deployment-notifier.sh"}]
      }
    ],
    "Stop": [
      {
        "matcher": "Bash",
        "hooks": [{"type": "command", "command": "~/.claude/hooks/danger-check.sh"}]
      }
    ]
  }
}
```

## Log Files

Hooks generate various log files in `~/.claude/logs/`:

- `bash-commands.log` - All bash commands with timestamps
- `mcp-operations.log` - MCP tool operations
- `file-validation.log` - File operation validation events
- `danger-blocks.log` - Dangerous operations blocked/warned
- `deployment-notifications.log` - Deployment operations
- `deployment-history.log` - Deployment history timeline

## Environment Variables

Configure optional notifications:

```bash
# Slack notifications
export SLACK_WEBHOOK_URL="https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK"

# Email notifications
export NOTIFICATION_EMAIL="your-email@example.com"
```

## Safety Features

### Danger Check Hook
- Blocks ultra-dangerous commands (rm -rf /, dd, etc.)
- Warns about dangerous operations
- Blocks dangerous commands in production branches
- Prevents modification of system files

### File Validator Hook
- Blocks path traversal attempts
- Restricts access to sensitive files
- Validates file extensions
- Checks for binary files and large files

### Deployment Notifier Hook
- Detects deployment commands
- Sends desktop notifications
- Supports Slack and email notifications
- Logs deployment history

## Usage Examples

### Testing Hooks
```bash
# Test bash logging
echo "test command"

# Test file validation
cat /etc/passwd  # Should be blocked

# Test deployment notification
docker build -t myapp .  # Should trigger notification
```

### Viewing Logs
```bash
# View recent bash commands
tail -f ~/.claude/logs/bash-commands.log

# View deployment history
cat ~/.claude/logs/deployment-history.log

# View blocked operations
grep "BLOCKED" ~/.claude/logs/danger-blocks.log
```

### Customization
Each hook can be customized by modifying the respective shell script:

- Add new dangerous command patterns
- Modify sensitive file paths
- Adjust notification settings
- Configure logging levels

## Troubleshooting

### Hook Not Executing
1. Check file permissions: `ls -la ~/.claude/hooks/`
2. Ensure scripts are executable: `chmod +x ~/.claude/hooks/*.sh`
3. Verify JSON syntax in settings.json
4. Check hook logs for errors

### Notification Issues
1. Verify environment variables are set
2. Test notification commands manually
3. Check network connectivity for Slack/email
4. Ensure notification dependencies are installed

### Log Rotation
Logs automatically rotate when they exceed size limits:
- bash-commands.log: 10MB (5 backups)
- mcp-operations.log: 5MB (3 backups)
- Other logs: No automatic rotation

## Security Considerations

1. **Hook Scripts**: Keep hooks secure and regularly review
2. **Log Files**: May contain sensitive information, secure appropriately
3. **Environment Variables**: Store webhook URLs and credentials securely
4. **File Permissions**: Ensure hooks are only writable by owner

## Best Practices

1. **Regular Maintenance**: Review and clean up old logs
2. **Monitor Notifications**: Ensure critical notifications are received
3. **Test Hooks**: Regularly test hook functionality
4. **Backup Configuration**: Keep settings.json backed up
5. **Review Logs**: Regularly review security and operation logs