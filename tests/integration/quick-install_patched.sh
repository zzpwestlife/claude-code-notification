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
    log "INFO" "Detecting Operating System..."
    local uname_out="$(uname -s)"
    case "${uname_out}" in
        Linux*)     OS_TYPE="Linux";;
        Darwin*)    OS_TYPE="macOS";;
        CYGWIN*)    OS_TYPE="Windows";;
        MINGW*)     OS_TYPE="Windows";;
        MSYS*)      OS_TYPE="Windows";;
        *)          OS_TYPE="Unknown";;
    esac
    log "INFO" "Detected OS: $OS_TYPE"
}

check_dependency() {
    log "INFO" "Checking required tools..."
    
    local missing_tools=()
    for tool in git node npm curl; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done

    if [ ${#missing_tools[@]} -ne 0 ]; then
        log "ERROR" "Missing required tools: ${missing_tools[*]}"
        log "INFO" "Please install them and retry."
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
    log "INFO" "Using TUI tool: $TUI_TOOL"
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
            show_msg "Error" "$error_msg"
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

show_progress() {
    local title="$1"
    local msg="$2"
    local percent="$3"
    
    # Simple progress for now as proper gauge is complex across tools
    log "INFO" "Progress ${percent}%: $msg"
}

# ==========================================
# 3. Core Logic
# ==========================================

DEFAULT_INSTALL_DIR="/Users/joeyzou/code/claude-code-notification_test"
INSTALL_DIR=""
REPO_URL="/Users/joeyzou/Code/OpenSource/claude-code-notification"

download_package() {
    log "INFO" "Preparing installation directory..."
    
    if [ -d "$INSTALL_DIR" ]; then
        log "WARN" "Directory exists: $INSTALL_DIR"
        # Ideally ask to update or overwrite, for now just git pull if it's a git repo
        if [ -d "$INSTALL_DIR/.git" ]; then
            log "INFO" "Updating existing repository..."
            cd "$INSTALL_DIR"
            git pull
        else
            log "ERROR" "Target directory exists and is not a git repo. Aborting to avoid data loss."
            show_msg "Error" "Directory $INSTALL_DIR exists and is not a git repo."
            exit 1
        fi
    else
        log "INFO" "Cloning repository..."
        mkdir -p "$(dirname "$INSTALL_DIR")"
        git clone "$REPO_URL" "$INSTALL_DIR"
        cd "$INSTALL_DIR"
    fi
    
    log "INFO" "Installing dependencies..."
    npm install
}

write_config() {
    local webhook_url="$1"
    local secret="$2"
    
    log "INFO" "Writing configuration..."
    
    # Write .env
    cat > "$INSTALL_DIR/.env" <<EOL
# Feishu Webhook Configuration
FEISHU_WEBHOOK_URL=$webhook_url
FEISHU_SECRET=$secret
EOL

    # Configure Claude Code Settings
    local claude_dir="$HOME/.claude"
    local claude_settings="$claude_dir/settings.json"
    local node_path=$(which node)
    local notify_script="$INSTALL_DIR/src/index.js"
    
    log "INFO" "Detected node path: $node_path"
    
    if [ ! -f "$claude_settings" ]; then
        log "WARN" "Claude settings file not found at $claude_settings. Creating new one."
        mkdir -p "$(dirname "$claude_settings")"
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
    log "INFO" "🚀 Starting One-Click Installation..."
    
    detect_os
    check_dependency
    
    # 1. Collect Input
    show_msg "Welcome" "Welcome to Claude Code Notification Setup!"
    
    INSTALL_DIR=$(get_input "Configuration" "Install Directory:" "$DEFAULT_INSTALL_DIR" "^/.*" "Path must be absolute (start with /)")
    if [ -z "$INSTALL_DIR" ]; then log "WARN" "Cancelled by user"; exit 0; fi

    WEBHOOK_URL=$(get_input "Configuration" "Please enter your Feishu Webhook URL:" "" "^https://open.feishu.cn/open-apis/bot/v2/hook/.*$" "Invalid Webhook URL! Must start with https://open.feishu.cn/open-apis/bot/v2/hook/")
    if [ -z "$WEBHOOK_URL" ]; then log "WARN" "Cancelled by user"; exit 0; fi
    
    SECRET=$(get_input "Configuration" "Please enter your Feishu Secret (Optional, leave empty if none):" "" "" "")
    
    # 2. Install
    show_progress "Installation" "Downloading and installing..." 10
    download_package
    show_progress "Installation" "Dependencies installed." 50
    
    # 3. Configure
    write_config "$WEBHOOK_URL" "$SECRET"
    show_progress "Configuration" "Configuration written." 90
    
    # 4. Finish
    show_msg "Success" "Installation Complete! \n\nLog saved to: $PWD/$LOG_FILE"
    log "SUCCESS" "Installation finished successfully."
}

main
