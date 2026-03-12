# Claude Code Hooks

The `~/.claude/hooks/` directory is reserved for hook scripts that can be configured in `~/.claude/settings.json`.

## Configuration

Hooks are configured in `settings.json` under the `hooks` key:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash(git commit*)",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/pre-commit-quality.sh",
            "timeout": 15000
          }
        ]
      }
    ],
    "PostToolUse": []
  }
}
```

## Current Status

No hook scripts are currently installed. The `hooks` arrays in `settings.json` are empty.

## Adding Hooks

To add a hook:
1. Create the shell script in this directory (e.g., `pre-commit-quality.sh`)
2. Make it executable: `chmod +x ~/.claude/hooks/pre-commit-quality.sh`
3. Add the matcher and command to `settings.json` under `hooks.PreToolUse` or `hooks.PostToolUse`
