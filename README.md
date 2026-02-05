# Claude Code 任务完成提醒系统

这是一个智能提醒系统，用于在 Claude Code 完成任务时通过飞书提醒你，让你可以不用频繁检查任务状态。

## 🎯 功能特点

- ✅ **飞书通知推送**：任务完成时自动发送飞书消息到手机
- ✅ **智能项目识别**：自动识别项目名称（package.json > git 仓库名 > 目录名）
- ✅ **精简消息格式**：项目名：任务信息，适配移动端显示
- ✅ **配置灵活**：支持环境变量和配置文件
- ✅ **安全可靠**：使用官方 API，安全稳定

## 📁 项目结构

详细的项目结构请参考 [PROJECT_STRUCTURE.md](./PROJECT_STRUCTURE.md)。

```
claude-code-notification/
├── assets/                  # 静态资源
├── config/                  # 配置文件
├── docs/                    # 项目文档
├── scripts/                 # 工具脚本
├── src/                     # 源代码
│   ├── modules/             # 功能模块
│   └── shared/              # 共享代码
├── tests/                   # 测试文件
└── README.md                # 项目说明
```

## 🛠 安装和配置

### 🚀 一键安装（最推荐）

一行命令完成所有配置（自动安装依赖、配置环境变量、写入 Claude 配置文件）：

**Linux / macOS:**
```bash
curl -sSL https://raw.githubusercontent.com/joeyzou/claude-code-notification/main/quick-install.sh | bash
```

**Windows (PowerShell):**
下载 `quick-install.bat` 并双击运行，或在 PowerShell 中运行：
```powershell
& {Start-Process PowerShell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File "quick-install.bat"' -Verb RunAs}
```

**支持环境：**
- **macOS**: 支持 TUI 弹窗 (osascript)，无需额外依赖。
- **Linux**: 依赖 `whiptail` 或 `dialog` (Ubuntu/Debian 自带或 `apt install whiptail`)。
- **Windows**: 需要 PowerShell 5.1+ (Windows 10/11 自带)。
- **Node.js**: 需要 Node.js 14+。

---

### ⚡ 手动安装（备选方式）

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
npm run setup
```
向导会自动帮你配置所有设置，包括安全存储 webhook 地址。

#### 验证配置 ✅
```bash
# 测试完整通知系统
node src/index.js --message "测试消息"
# 或使用脚本
./scripts/dev.sh --message "测试消息"
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
            "command": "node /path/to/claude-code-notification/src/index.js",
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
            "command": "node /path/to/claude-code-notification/src/index.js --title 'Claude Code' --message '需要权限审批'"
          }
        ]
      },
      {
        "matcher": "idle_prompt",
        "hooks": [
          {
            "type": "command",
            "command": "node /path/to/claude-code-notification/src/index.js --title 'Claude Code' --message '等待你的输入'"
          }
        ]
      }
    ]
  }
}
```

**⚠️ 注意**：
1. 请将 `/path/to/node` 替换为你机器上的实际 Node 路径（终端输入 `which node` 获取，例如 `/usr/local/bin/node`）。
2. 如果未使用一键安装脚本，请确保项目路径正确（示例中假设为 `~/code/claude-code-notification`）。

该配置实现：
- ✅ **任务完成**：自动发送通知
- ✅ **权限请求**：当 Claude 需要确认执行命令时通知你
- ✅ **等待输入**：当 Claude 等待你下一步指示时通知你

## 🎯 使用效果

配置完成后，当 Claude Code 完成任务时，你的飞书 APP 会收到任务完成消息。
