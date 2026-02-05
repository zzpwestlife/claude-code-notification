# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

claude-code-notification (Claude Code 任务完成提醒系统) is a notification system for Claude Code. It sends notifications when tasks complete via Feishu/Lark.

## Architecture

### Layered Design

```
notify-system.js (CLI entry point)
    ↓
NotificationManager (unified interface)
    ↓
Feishu Notifier (feishu-notify.js)
```

### Core Components

- **notify-system.js** - Main CLI entry point; parses arguments, detects project name, orchestrates notifications
- **notification-manager.js** - `NotificationManager` class that initializes and coordinates notification
- **env-config.js** - Loads configuration from `.env` (highest priority) and `config.json` (fallback)
- **feishu-notify.js** - Feishu/Lark webhook integration with rich text post format

### Configuration Priority

Environment variables (`.env`) → `config.json` → defaults

The `.env` file is gitignored and should contain all sensitive credentials (webhook URLs).

### Project Name Detection

The system auto-detects project names in this order:
1. `package.json` name field
2. Git repository basename
3. Current directory basename

This is implemented in `notify-system.js` and passed to notifiers.

### Notification Format

Feishu uses `msg_type: "post"` with structured content arrays (one array per line). Each element has a `tag: "text"` field. The API does NOT support markdown—special syntax like `**bold**` or `` `code` `` must be stripped/converted to plain text.

### Key Functions

**feishu-notify.js:**
- `notifyTaskCompletion(taskInfo, webhookUrl, projectName, options)` - Main function
- `options.title` - Custom title (overrides default "项目名: 任务信息")
- `options.startTime` - Task start time (Date/timestamp/ISO string) for duration calculation
- `options.tokens` - Token usage: `{ input, output, total, cacheRead, cacheWrite }`
- `options.status` - "success" | "error" | "warning"
- `options.description` - Task description

### Git Integration

`feishu-notify.js` includes git info in notifications via `getGitInfo()`:
- Current branch
- Latest commit (short hash + message)
- Author and date
- Working directory status (modified/staged/untracked counts)
- Unpushed commits

## Common Commands

```bash
# Run setup wizard
node setup-wizard.js

# Test notification system
node notify-system.js --message "测试消息"
node notify-system.js --title "自定义标题" --message "测试消息"

# Test feishu notifier directly
node feishu-notify.js --message "测试" --status success --description "描述"

# Install dependencies
npm install
```

## Integration with Claude Code

Add to `~/.claude/settings.json`:

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "command": "node /path/to/claude-code-notification/notify-system.js",
            "type": "command"
          }
        ]
      }
    ],
    "Notification": [
      {
        "matcher": "permission_prompt",
        "hooks": [
          {
            "type": "command",
            "command": "node /path/to/claude-code-notification/notify-system.js --title 'Claude Code' --message '需要权限审批'"
          }
        ]
      },
      {
        "matcher": "idle_prompt",
        "hooks": [
          {
            "type": "command",
            "command": "node /path/to/claude-code-notification/notify-system.js --title 'Claude Code' --message '等待你的输入'"
          }
        ]
      }
    ]
  }
}
```

- **Stop hook**: Triggers on task completion
- **Notification hook**: Triggers for permission prompts (`permission_prompt`) and idle prompts (`idle_prompt`)
- The system automatically detects project name from wherever Claude Code is running
- Use `--title` to override default title (default: "项目名: 任务信息")

## Important Implementation Notes

1. **Feishu Rich Text Format**: Each line is a separate array in `content.post.zh_cn.content`. Do NOT include `\n` in text elements—use line breaks via array separation instead.

2. **Markdown Stripping**: Feishu doesn't support markdown. The `_parseMarkdownToFeishu()` method removes `**` and `` ` `` markers.

3. **Duration Formatting**: The `formatDuration()` function converts milliseconds to "X小时X分X秒" format.

4. **Title Override**: Use `--title` parameter to customize the notification title instead of the default "项目名: 任务信息" format. This is useful for hook scenarios like permission prompts.
