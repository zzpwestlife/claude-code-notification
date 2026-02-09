#!/bin/bash

# ==========================================
# Claude Code Notification Quick Install Script
# Usage: curl -sSL ... | bash
# ==========================================

set -e

# ==========================================
# 0. Global Configuration & Logging
# ==========================================

# Format: TYPE:VALUE (TYPE=OUTPUT or EXIT)

# Debug: Print args to a file to verify mock call
# echo "$@" >> /tmp/whiptail_args.log

SEQ_FILE="/tmp/whiptail_sequence"

# Colors (Reused from install.sh)
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

LOG_FILE="install_quick.log"
touch "$LOG_FILE"

log() {
    local level="$1"
    local msg="$2"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    # Strip color codes for log file
    local clean_msg=$(echo -e "$msg" | sed 's/\x1b\[[0-9;]*m//g')
    echo "[$timestamp] [$level] $clean_msg" >> "$LOG_FILE"
    
    # Print to console with color
    case "$level" in
        "INFO") echo -e "${BLUE}[INFO]${NC} $msg" ;;
        "SUCCESS") echo -e "${GREEN}[SUCCESS]${NC} $msg" ;;
        "WARN") echo -e "${YELLOW}[WARN]${NC} $msg" ;;
        "ERROR") echo -e "${RED}[ERROR]${NC} $msg" ;;
        *) echo -e "$msg" ;;
    esac
}

# ==========================================
# 1. OS Detection & Tool Abstraction
# ==========================================

OS_TYPE=""
TUI_TOOL=""

detect_os() {
    log "INFO" "正在检测操作系统..."
    local uname_out="$(uname -s)"
    case "${uname_out}" in
        Linux*)     OS_TYPE="Linux";;
        Darwin*)    OS_TYPE="macOS";;
        CYGWIN*)    OS_TYPE="Windows";;
        MINGW*)     OS_TYPE="Windows";;
        MSYS*)      OS_TYPE="Windows";;
        *)          OS_TYPE="Unknown";;
    esac
    log "INFO" "检测到操作系统: $OS_TYPE"
}

check_dependency() {
    log "INFO" "正在检查必要工具..."
    
    local missing_tools=()
    for tool in git node npm curl; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done

    if [ ${#missing_tools[@]} -ne 0 ]; then
        log "ERROR" "缺少必要工具: ${missing_tools[*]}"
        show_msg "错误" "缺少必要工具: ${missing_tools[*]}
请安装它们并重试。"
        exit 1
    fi

    # Check for TUI tools
    if command -v whiptail &> /dev/null; then
        TUI_TOOL="whiptail"
    elif command -v dialog &> /dev/null; then
        TUI_TOOL="dialog"
    else
        TUI_TOOL="none"
        if [[ "$OS_TYPE" == "macOS" ]]; then
            TUI_TOOL="osascript"
        fi
    fi
    log "INFO" "使用 TUI 工具: $TUI_TOOL"
}

# ==========================================
# 2. UI Abstraction
# ==========================================

# Input with validation
# Usage: get_input "Title" "Prompt" "Default" "ValidatorRegex" "ErrorMsg"
get_input() {
    local title="$1"
    local prompt="$2"
    local default_val="$3"
    local regex="$4"
    local error_msg="$5"
    local result=""
    
    # Limit loop to prevent infinite loop during testing if mock fails
    local loop_count=0
    while [ $loop_count -lt 10 ]; do
        ((loop_count++))
        
        if [[ "$TUI_TOOL" == "whiptail" ]]; then
            result=$(whiptail --title "$title" --inputbox "$prompt" 10 60 "$default_val" 3>&1 1>&2 2>&3)
            exit_code=$?
            if [ $exit_code -ne 0 ]; then return 1; fi # User cancelled
        elif [[ "$TUI_TOOL" == "dialog" ]]; then
            result=$(dialog --title "$title" --inputbox "$prompt" 10 60 "$default_val" 3>&1 1>&2 2>&3)
            exit_code=$?
            if [ $exit_code -ne 0 ]; then return 1; fi
        elif [[ "$TUI_TOOL" == "osascript" ]]; then
             result=$(osascript -e "display dialog \"$prompt\" default answer \"$default_val\" with title \"$title\" buttons {\"Cancel\", \"OK\"} default button \"OK\"" -e "text returned of result" 2>/dev/null)
             if [ $? -ne 0 ]; then return 1; fi
        else
            # Fallback
            echo -e "${YELLOW}$title${NC}"
            echo -e "$prompt [Default: $default_val]: "
            read -r input
            result="${input:-$default_val}"
        fi

        # Validation
        if [[ -n "$regex" ]] && [[ ! "$result" =~ $regex ]]; then
            show_msg "错误" "$error_msg"
        else
            echo "$result"
            return 0
        fi
    done
}

show_msg() {
    local title="$1"
    local msg="$2"
    
    if [[ "$TUI_TOOL" == "whiptail" ]]; then
        whiptail --title "$title" --msgbox "$msg" 10 60
    elif [[ "$TUI_TOOL" == "dialog" ]]; then
        dialog --title "$title" --msgbox "$msg" 10 60
    elif [[ "$TUI_TOOL" == "osascript" ]]; then
        osascript -e "display dialog \"$msg\" with title \"$title\" buttons {\"OK\"} default button \"OK\"" >/dev/null
    else
        echo -e "${BLUE}[$title]${NC} $msg"
    fi
}

# Select directory with fallback
get_install_dir() {
    local default_parent="$1"
    local selected_dir=""

    if [[ "$TUI_TOOL" == "osascript" ]]; then
        # Use AppleScript to choose folder
        # We use a small script to allow choosing a folder
        selected_dir=$(osascript -e "set selectedFolder to choose folder with prompt \"请选择安装位置 (将在该目录下创建 claude-code-notification 文件夹):\" default location \"$default_parent\"" -e "POSIX path of selectedFolder" 2>/dev/null)
        
        if [ $? -ne 0 ] || [ -z "$selected_dir" ]; then 
            return 1 
        fi
    else
        # Fallback to text input
        selected_dir=$(get_input "配置" "请输入安装位置的父目录 (将在该目录下创建 claude-code-notification):" "$default_parent" "^/.*" "路径必须是绝对路径")
        if [ -z "$selected_dir" ]; then return 1; fi
    fi
    
    # Remove trailing slash and append project name
    selected_dir=${selected_dir%/}
    echo "$selected_dir/claude-code-notification"
    return 0
}

show_progress() {
    local title="$1"
    local msg="$2"
    local percent="$3"
    
    # Simple progress for now as proper gauge is complex across tools
    log "INFO" "进度 ${percent}%: $msg"
}

# ==========================================
# 3. Core Logic
# ==========================================

# Auto-detect current directory if it looks like the project
if [ -f "package.json" ] && grep -q "\"name\": \"claude-code-notification\"" "package.json"; then
    DEFAULT_INSTALL_DIR="$PWD"
else
    DEFAULT_INSTALL_DIR="$HOME/code/claude-code-notification"
fi
INSTALL_DIR=""
REPO_URL="https://github.com/zzpwestlife/claude-code-notification.git" # Placeholder, user should replace

download_package() {
    log "INFO" "正在准备安装目录..."
    
    if [ -d "$INSTALL_DIR" ]; then
        log "WARN" "目录已存在: $INSTALL_DIR"
        # Ideally ask to update or overwrite, for now just git pull if it's a git repo
        if [ -d "$INSTALL_DIR/.git" ]; then
            log "INFO" "正在更新现有仓库..."
            cd "$INSTALL_DIR"
            # Try git pull but allow failure (e.g. if repo is suspended or offline)
            git pull || log "WARN" "Git pull failed. Continuing with local files..."
        else
            log "WARN" "目录存在但不是 Git 仓库。正在跳过 git 更新。"
        fi
    else
        log "INFO" "正在克隆仓库..."
        mkdir -p "$(dirname "$INSTALL_DIR")"
        git clone "$REPO_URL" "$INSTALL_DIR"
        cd "$INSTALL_DIR"
    fi
    
    log "INFO" "正在安装依赖..."
    npm install
}

write_config() {
    local webhook_url="$1"
    
    log "INFO" "正在写入配置..."
    
    # Write .env
    cat > "$INSTALL_DIR/.env" <<EOL
# Feishu Webhook Configuration
FEISHU_WEBHOOK_URL=$webhook_url
EOL

    # Configure Claude Code Settings
    local claude_dir="$HOME/.claude"
    local claude_settings="$claude_dir/settings.json"
    local node_path=$(which node)
    local notify_script="$INSTALL_DIR/src/index.js"
    
    log "INFO" "检测到 node 路径: $node_path"

    # Ensure settings.json exists
    if [ ! -f "$claude_settings" ]; then
        log "WARN" "未在 $claude_settings 找到 Claude 配置文件。正在创建新文件。"
        mkdir -p "$claude_dir"
        echo "{ \"hooks\": {} }" > "$claude_settings"
    fi
    
    # Backup settings
    cp "$claude_settings" "${claude_settings}.bak.$(date +%Y%m%d%H%M%S)"
    
    # We use a temporary node script to merge the JSON to ensure correctness
    # This avoids complex sed/awk logic for JSON
    
    cat > "$INSTALL_DIR/update_settings.js" <<JS
const fs = require('fs');
// Allow input and output paths to be passed as arguments
// Usage: node update_settings.js [inputPath] [outputPath]
// Defaults to updating the same file if outputPath is not provided
const inputPath = process.argv[2];
const outputPath = process.argv[3] || inputPath;

if (!inputPath) {
    console.error('Error: No input file path provided');
    process.exit(1);
}

try {
    const settings = JSON.parse(fs.readFileSync(inputPath, 'utf8'));
    
    if (!settings.hooks) settings.hooks = {};
    
    // Define the hooks to add
    const stopHook = {
        "hooks": [{
            "command": "${node_path} ${notify_script}",
            "type": "command"
        }]
    };
    
    const notificationHooks = [
        {
            "matcher": "permission_prompt",
            "hooks": [{
                "type": "command",
                "command": "${node_path} ${notify_script} --title 'Claude Code' --message '需要权限审批'"
            }]
        },
        {
            "matcher": "idle_prompt",
            "hooks": [{
                "type": "command",
                "command": "${node_path} ${notify_script} --title 'Claude Code' --message '等待你的输入'"
            }]
        }
    ];

    // Merge Stop Hook
    if (!settings.hooks.Stop) settings.hooks.Stop = [];
    // Remove existing identical hooks to avoid duplicates (simplistic check)
    settings.hooks.Stop = settings.hooks.Stop.filter(h => !h.hooks.some(sub => sub.command.includes('claude-code-notification')));
    settings.hooks.Stop.push(stopHook);

    // Merge Notification Hook
    if (!settings.hooks.Notification) settings.hooks.Notification = [];
    settings.hooks.Notification = settings.hooks.Notification.filter(h => 
        !h.hooks.some(sub => sub.command.includes('claude-code-notification'))
    );
    settings.hooks.Notification.push(...notificationHooks);

    fs.writeFileSync(outputPath, JSON.stringify(settings, null, 2));
    console.log('Settings updated successfully: ' + outputPath);
} catch (e) {
    console.error('Failed to update settings:', e);
    process.exit(1);
}
JS

    log "INFO" "Updating $claude_settings..."
    node "$INSTALL_DIR/update_settings.js" "$claude_settings"
    
    # Check for ft-claude.json and generate ft-settings.json if it exists
    local ft_claude="$claude_dir/ft-claude.json"
    local ft_settings="$claude_dir/ft-settings.json"
    
    if [ -f "$ft_claude" ]; then
        log "INFO" "Detected ft-claude.json at $ft_claude"
        log "INFO" "Generating $ft_settings..."
        node "$INSTALL_DIR/update_settings.js" "$ft_claude" "$ft_settings"
    fi
    
    rm "$INSTALL_DIR/update_settings.js"
}

# ==========================================
# 4. Main Execution
# ==========================================

main() {
    log "INFO" "🚀 开始一键安装..."
    
    detect_os
    check_dependency
    
    # 1. Collect Input
    
    # Try to detect clipboard for Webhook
    local default_webhook=""
    if [[ "$OS_TYPE" == "macOS" ]] && command -v pbpaste &> /dev/null; then
        local clipboard_content=$(pbpaste)
        # Check if clipboard content looks like a Feishu Webhook URL
        if [[ "$clipboard_content" =~ ^https://open.feishu.cn/open-apis/bot/v2/hook/.*$ ]]; then
            # If using osascript, show a confirmation dialog with FULL URL
            if [[ "$TUI_TOOL" == "osascript" ]]; then
                local choice=$(osascript -e "display dialog \"检测到剪贴板包含飞书 Webhook 地址：\n\n$clipboard_content\n\n是否直接使用？\" with title \"配置\" buttons {\"手动输入\", \"使用此地址\"} default button \"使用此地址\"" -e "button returned of result" 2>/dev/null)
                if [[ "$choice" == "使用此地址" ]]; then
                    WEBHOOK_URL="$clipboard_content"
                else
                    default_webhook="$clipboard_content"
                fi
            else
                default_webhook="$clipboard_content"
            fi
        fi
    fi

    # Directory Selection
    INSTALL_DIR=$(get_install_dir "$HOME/code")
    if [ $? -ne 0 ] || [ -z "$INSTALL_DIR" ]; then log "WARN" "用户已取消"; exit 0; fi

    if [ -z "$WEBHOOK_URL" ]; then
        WEBHOOK_URL=$(get_input "配置" "请输入您的飞书 Webhook 地址 (已自动尝试读取剪贴板):" "$default_webhook" "^https://open.feishu.cn/open-apis/bot/v2/hook/.*$" "Webhook 地址无效！必须以 https://open.feishu.cn/open-apis/bot/v2/hook/ 开头")
        if [ -z "$WEBHOOK_URL" ]; then log "WARN" "用户已取消"; exit 0; fi
    fi
    
    # 2. Install
    show_progress "安装中" "正在下载并安装..." 10
    download_package
    show_progress "安装中" "依赖已安装。" 50
    
    # 3. Configure
    write_config "$WEBHOOK_URL" "$SECRET"
    
    # 3.5 Install Bench Tools
    log "INFO" "Installing Claude Bench tools..."
    local bench_src="$INSTALL_DIR/bench/tools/claude-bench"
    local bench_dest="$HOME/.claude/tools/claude-bench"
    
    if [ -d "$bench_src" ]; then
        mkdir -p "$bench_dest"
        cp "$bench_src"/*.py "$bench_dest/"
        cp "$bench_src"/*.sh "$bench_dest/"
        chmod +x "$bench_dest"/*.py
        chmod +x "$bench_dest"/*.sh
        
        # Run setup hooks for bench
        log "INFO" "Configuring Bench hooks..."
        if python3 "$bench_dest/setup_hooks.py"; then
            log "SUCCESS" "Claude Bench installed and hooks configured."
        else
            log "WARN" "Failed to configure Bench hooks."
        fi
    else
        log "WARN" "Bench tools source not found at $bench_src. Skipping."
    fi

    show_progress "Configuration" "Configuration written." 90
    
    # 4. Finish
    show_msg "成功" "安装完成！ \n\n日志已保存至: $PWD/$LOG_FILE"
    log "SUCCESS" "安装成功完成。"
}

main
