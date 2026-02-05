# Claude Code 任务完成提醒系统

这是一个智能提醒系统，用于在 Claude Code 完成任务时通过飞书提醒你，让你可以不用频繁检查任务状态。

## 🎯 功能特点

- ✅ **飞书通知推送**：任务完成时自动发送飞书消息到手机
- ✅ **智能项目识别**：自动识别项目名称（package.json > git 仓库名 > 目录名）
- ✅ **精简消息格式**：项目名：任务信息，适配移动端显示
- ✅ **配置灵活**：支持环境变量和配置文件
- ✅ **安全可靠**：使用官方 API，安全稳定

## 📁 项目结构

```
claude-code-notification/
├── notify-system.js           # 主通知系统（集成所有功能）
├── notification-manager.js    # 通知管理器（统一接口管理）
├── env-config.js             # 环境变量配置管理（统一环境变量）
├── feishu-notify.js          # 飞书通知模块
├── setup-wizard.js           # 一键配置向导
├── .env                     # 环境变量配置（包含敏感信息，已 git 忽略）
├── .env.example            # 环境变量模板文件
├── .gitignore              # Git 忽略文件配置
├── config.json             # 传统配置文件（可选）
├── package.json            # NPM项目配置
└── README.md               # 项目说明文档
```

## 🛠 安装和配置

### ⚡ 快速开始（推荐方式）

下载项目, 从 github 克隆到本地

```bash
git clone https://github.com/yourusername/claude-code-notification.git
cd claude-code-notification
```
执行安装, npm 安装依赖

```bash
npm install
```

运行配置向导

```bash
node setup-wizard.js
```
向导会自动帮你配置所有设置，包括安全存储 webhook 地址。

#### 验证配置 ✅
```bash
# 测试完整通知系统
node notify-system.js --message "测试消息"
```

#### 步骤 3：重启 Claude Code 🔄
重启 Claude Code 使配置生效，然后正常使用即可！

### 🔧 Claude Code Hook 配置

在 `~/.claude/settings.json` 中配置 hook，实现全自动化通知：

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

**⚠️ 注意**：请将 `/absolute/path/to/claude-code-notification/` 替换为你实际的项目绝对路径。

该配置实现：
- ✅ **任务完成**：自动发送通知
- ✅ **权限请求**：当 Claude 需要确认执行命令时通知你
- ✅ **等待输入**：当 Claude 等待你下一步指示时通知你

## 🎯 使用效果

配置完成后，当 Claude Code 完成任务时，你的飞书 APP 会收到任务完成消息。
