# 项目迁移与配置指南

本文档旨在帮助开发者在新设备上快速复现 `claude-code-notification` 项目环境，并完成飞书通知的接入。

## 1. 环境准备

### 1.1 系统要求
- **操作系统**: macOS (推荐), Linux, Windows 10/11
- **Node.js**: v14.0.0 或更高版本
- **Git**: 最新版本

### 1.2 自动化环境安装
我们提供了一个自动化脚本，用于检测并安装必要的依赖（Git, Node.js）。

**macOS / Linux 用户:**
在终端中执行以下命令：

```bash
# 赋予脚本执行权限
chmod +x setup_env.sh

# 运行安装脚本
./setup_env.sh
```

**Windows 用户:**
请前往 [Node.js 官网](https://nodejs.org/) 下载并安装 LTS 版本，Git 请前往 [Git 官网](https://git-scm.com/) 下载。

## 2. 代码与密钥迁移

### 2.1 获取代码
从 Git 仓库克隆项目到本地：

```bash
# 克隆仓库 (请替换为实际仓库地址)
git clone <your-repository-url> claude-code-notification

# 进入项目目录
cd claude-code-notification
```

### 2.2 密钥配置
本项目使用 `.env` 文件管理敏感配置。由于该文件不应包含在版本控制中，你需要手动创建或迁移它。

**方式 A: 使用配置向导 (推荐)**
```bash
node setup-wizard.js
```
按照提示输入飞书 Webhook 地址即可自动生成配置。

**方式 B: 手动创建**
复制示例文件并编辑：
```bash
cp .env.example .env
```
编辑 `.env` 文件，填入你的密钥：
```ini
FEISHU_WEBHOOK_URL=https://open.feishu.cn/open-apis/bot/v2/hook/xxxxxxxx
NOTIFICATION_ENABLED=true
SOUND_ENABLED=true
```

## 3. 依赖安装

执行以下命令安装项目依赖：

```bash
# 安装 Node.js 依赖
npm install
```

*注意：本项目为纯 Node.js 项目，无需编译步骤。*

## 4. 数据库与缓存
本项目主要依赖本地文件系统和第三方 API（飞书、Telegram），**不需要** 配置本地数据库或 Redis 缓存。

## 5. 本地配置验证

在正式使用前，请按顺序执行以下验证步骤：

### 5.1 端口与服务检查
本项目运行为一次性脚本，不占用后台端口（如 80/3000 等），因此无需检查端口占用。

### 5.2 功能测试
运行以下命令验证核心功能是否正常：

```bash
# 发送一条测试通知
node notify-system.js --task "环境迁移测试：功能验证"
```

**预期结果：**
1. 终端输出：`✅ 消息已发送到飞书` (如已配置)
2. 终端输出：`🔊 播放通知声音...` (如已开启声音)
3. 你的飞书/手机/手环应收到推送消息。

## 6. 飞书通知接入

### 6.1 获取 Webhook 地址
1. 在飞书群组中点击设置 -> 群机器人 -> 添加机器人 -> 自定义机器人。
2. 复制生成的 Webhook 地址（格式如 `https://open.feishu.cn/open-apis/bot/v2/hook/...`）。

### 6.2 调试与日常使用

**手动触发测试消息：**
你可以使用以下命令模拟 Claude 任务完成后的通知：

```bash
# 直接运行脚本测试
node notify-system.js --task "测试任务执行完毕"

# 或者使用 Claude CLI 触发 (如果你已安装 Claude CLI)
claude -p "run node notify-system.js --task '通过 Claude CLI 触发的测试'"
```

**集成到 Claude Code (示例):**
为了在日常使用中自动触发，建议在你的 shell 配置文件 (如 `.zshrc` 或 `.bashrc`) 中添加 alias，或者在执行长命令后手动追加：

```bash
# 示例：执行某项任务并在完成后通知
npm install && node notify-system.js --task "依赖安装完成"
```
