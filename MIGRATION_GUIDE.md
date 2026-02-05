## 7. Claude Code 自动化集成 (Hooks)

为了让 Claude Code 在关键时刻（如任务完成、需要权限审批、等待输入时）自动触发通知，你可以配置 Claude Code 的 Hooks。

### 7.1 配置文件位置
编辑 Claude Code 的全局配置文件（通常位于 `~/.claude/config.json` 或项目级配置）。

### 7.2 完整配置示例

将以下内容添加到配置文件的 `"hooks"` 字段中。

> **注意**：请务必将 `/Users/admin/openSource/claude-code-notification/` 替换为你实际的项目路径。

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "command": "node /absolute/path/to/claude-code-notification/notify-system.js",
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
            "command": "node /absolute/path/to/claude-code-notification/notify-system.js --title 'Claude Code' --message '需要权限审批'"
          }
        ]
      },
      {
        "matcher": "idle_prompt",
        "hooks": [
          {
            "type": "command",
            "command": "node /absolute/path/to/claude-code-notification/notify-system.js --title 'Claude Code' --message '等待你的输入'"
          }
        ]
      }
    ]
  }
}
```

### 7.3 配置说明
- **Stop**: 当 Claude Code 完成任务退出或停止时触发。
- **Notification (permission_prompt)**: 当 Claude 需要用户授权执行命令时触发。
- **Notification (idle_prompt)**: 当 Claude 完成一轮思考，等待用户输入指令时触发。
