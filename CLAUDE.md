# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

CCDD (Claude Code 任务完成提醒系统) is a multi-channel notification system for Claude Code. It sends notifications when tasks complete via Feishu/Lark, Telegram, and local sound—triggering wearable device vibrations for hands-free monitoring.

## Architecture

### Layered Design

```
notify-system.js (CLI entry point)
    ↓
NotificationManager (unified interface)
    ↓
Specific Notifiers (Feishu, Telegram, Sound)
    ↓
Delivery Services (HTTP webhooks, PowerShell)
```

### Core Components

- **notify-system.js** - Main CLI entry point; parses arguments, detects project name, orchestrates notifications
- **notification-manager.js** - `NotificationManager` class that initializes and coordinates all notifiers in parallel using `Promise.allSettled()`
- **env-config.js** - Loads configuration from `.env` (highest priority) and `config.json` (fallback)
- **feishu-notify.js** - Feishu/Lark webhook integration with rich text post format
- **telegram-notify.js** - Telegram Bot API with HTTP/HTTPS proxy support
- **notify-sound.js** - Windows PowerShell speech synthesis

### Configuration Priority

Environment variables (`.env`) → `config.json` → defaults

The `.env` file is gitignored and should contain all sensitive credentials (webhook URLs, bot tokens).

### Project Name Detection

The system auto-detects project names in this order:
1. `package.json` name field
2. Git repository basename
3. Current directory basename

This is implemented in `notify-system.js` and passed to notifiers.

### Notification Format

Feishu uses `msg_type: "post"` with structured content arrays (one array per line). Each element has a `tag: "text"` field. The API does NOT support markdown—special syntax like `**bold**` or `` `code` `` must be stripped/converted to plain text.

Telegram uses HTML parsing with `<b>`, `<code>`, `<pre>`, `<a>` tags.

### Key Functions

**feishu-notify.js:**
- `notifyTaskCompletion(taskInfo, webhookUrl, projectName, options)` - Main function
- `options.startTime` - Task start time (Date/timestamp/ISO string) for duration calculation
- `options.tokens` - Token usage: `{ input, output, total, cacheRead, cacheWrite }`
- `options.status` - "success" | "error" | "warning"
- `options.description` - Task description

**telegram-notify.js:**
- Similar interface with HTML message formatting

### Git Integration

Both `feishu-notify.js` and `telegram-notify.js` include git info in notifications via `getGitInfo()`:
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

# Test specific notifiers
node feishu-notify.js --message "测试" --status success --description "描述"
node telegram-notify.js --message "测试"

# Install dependencies
npm install
```

## Integration with Claude Code

Add to `~/.claude/settings.json`:

```json
{
  "hooks": {
    "Stop": [{
      "hooks": [{
        "type": "command",
        "command": "node /path/to/ccdd/notify-system.js --message 'Claude Code 任务已完成'"
      }]
    }]
  }
}
```

The hook triggers on task completion. The system automatically detects the project name from wherever Claude Code is running.

## Important Implementation Notes

1. **Feishu Rich Text Format**: Each line is a separate array in `content.post.zh_cn.content`. Do NOT include `\n` in text elements—use line breaks via array separation instead.

2. **Markdown Stripping**: Feishu doesn't support markdown. The `_parseMarkdownToFeishu()` method removes `**` and `` ` `` markers.

3. **Parallel Execution**: `NotificationManager.sendAllNotifications()` uses `Promise.allSettled()` so one failure doesn't block others.

4. **Duration Formatting**: The `formatDuration()` function converts milliseconds to "X小时X分X秒" format.

5. **Proxy Support**: Telegram notifier respects `HTTP_PROXY` and `HTTPS_PROXY` environment variables for restricted network environments.

6. **Title Optimization for Wearables**: Project name is placed at the start of titles for small-screen display on smart bands.
