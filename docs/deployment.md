# Deployment Guide

## Prerequisites
- Node.js (v14 or higher)
- npm (v6 or higher)
- A Feishu/Lark Webhook URL

## Installation

### One-Click Installation
We provide one-click installation scripts for supported platforms:

- **macOS/Linux**:
  ```bash
  ./quick-install.sh
  ```

- **Windows**:
  ```powershell
  .\quick-install.bat
  ```

### Manual Installation
1.  Clone the repository.
2.  Install dependencies:
    ```bash
    npm install
    ```
3.  Run the setup wizard:
    ```bash
    npm run setup
    ```

## Configuration

### Environment Variables
The application uses `.env` files for configuration.
- `config/.env.dev`: Development environment
- `config/.env.staging`: Staging environment
- `config/.env.prod`: Production environment

Key variables:
- `FEISHU_WEBHOOK_URL`: The webhook URL for your Feishu bot.

### Claude Code Integration
Add the following to your `~/.claude/settings.json`:

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "command": "node /path/to/claude-code-notification/src/index.js",
            "type": "command"
          }
        ]
      }
    ]
  }
}
```

## Updates
To update the notification system:
1.  Pull the latest changes from git.
2.  Run `npm install` to update dependencies.
