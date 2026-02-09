# Claude Code 自动计时与通知系统部署指南

本文档将指导您在一个全新的电脑环境中，配置 Claude Code 的自动计时、报告生成及 IM 通知系统。

## 1. 系统要求

- **操作系统**: macOS 或 Linux
- **依赖软件**: 
  - Python 3.x
  - Claude Code (已安装并登录)

## 2. 快速部署

我们提供了一键安装脚本，可以自动完成所有配置。

### 步骤 1: 获取代码

如果您还没有下载本仓库，请先克隆：

```bash
git clone https://github.com/your-repo/learn-claude-code.git
cd learn-claude-code
```

### 步骤 2: 运行安装脚本

在仓库根目录下执行：

```bash
bash setup_claude_bench.sh
```

**脚本执行内容：**
1. 创建 `~/.claude/tools/claude-bench` 目录。
2. 部署核心脚本 (`bench_hook.py`, `reporter.py`)。
3. 自动修改 `~/.claude/settings.json`，注册 `UserPromptSubmit` (开始计时) 和 `Stop` (结束计时) 事件钩子。

## 3. 配置 IM 通知 (可选)

如果您希望在每次问答结束后，自动向钉钉、飞书、企业微信或 Slack 发送通知，请执行以下操作：

1. **获取 Webhook URL**: 在您的 IM 软件中创建一个自定义机器人，并复制其 Webhook 地址。
2. **配置 URL**:

```bash
# 复制示例配置
cp ~/.claude/bench/webhook.json.example ~/.claude/bench/webhook.json

# 编辑文件填入您的 URL
nano ~/.claude/bench/webhook.json
```

**配置示例 (`webhook.json`):**
```json
{
  "url": "https://oapi.dingtalk.com/robot/send?access_token=xxxxxx"
}
```

## 4. 使用说明

### 自动计时
无需任何额外操作。正常使用 `claude` 命令进行对话即可。
- **开始**: 当您输入 Prompt 并回车时。
- **结束**: 当 Claude 完成所有思考、工具调用并输出最终回复时。

### 查看报告
系统会自动生成并更新 HTML 可视化报告。您可以通过以下命令打开：

```bash
bash ~/.claude/tools/claude-bench/view_report.sh
```

或者直接在浏览器中收藏该文件路径：
`file:///Users/您的用户名/.claude/bench/report.html`

## 5. 故障排查

- **报告中显示 "(No prompt captured)"**: 
  - 确保您使用的是最新版本的脚本（v1.2+）。
  - 只有新产生的对话记录会被捕获 Prompt，旧记录无法追溯。

- **没有收到 IM 通知**:
  - 检查 `~/.claude/bench/webhook.json` 中的 URL 是否正确。
  - 检查网络是否通畅。脚本会自动忽略网络错误，以免阻塞主流程。

## 6. 目录结构说明

- `~/.claude/tools/claude-bench/`: 存放工具脚本
  - `bench_hook.py`: 核心 Hook 逻辑
  - `reporter.py`: HTML 报告生成器
- `~/.claude/bench/`: 存放数据和日志
  - `claude_bench.jsonl`: 所有历史交互日志
  - `report.html`: 可视化报告
  - `webhook.json`: 通知配置
