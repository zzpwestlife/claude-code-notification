#!/bin/bash
# Claude Bench Installation Script (User Level)

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USER_TOOLS_DIR="$HOME/.claude/tools/claude-bench"

log "Installing Claude Bench to $USER_TOOLS_DIR..."

# 1. Copy files to user directory
mkdir -p "$USER_TOOLS_DIR"
cp "$SOURCE_DIR/bench_hook.py" "$USER_TOOLS_DIR/"
cp "$SOURCE_DIR/reporter.py" "$USER_TOOLS_DIR/"
cp "$SOURCE_DIR/setup_hooks.py" "$USER_TOOLS_DIR/"
cp "$SOURCE_DIR/view_report.sh" "$USER_TOOLS_DIR/"
chmod +x "$USER_TOOLS_DIR/"*.py
chmod +x "$USER_TOOLS_DIR/"*.sh

# 2. Setup Hooks (User Level)
log "Configuring User Hooks..."
if python3 "$USER_TOOLS_DIR/setup_hooks.py"; then
    echo -e "${GREEN}[SUCCESS] Hooks configured in ~/.claude/settings.json${NC}"
else
    echo -e "${RED}[ERROR] Failed to configure hooks${NC}"
    exit 1
fi

# 3. Cleanup Project Level Config (Optional)
PROJECT_SETTINGS=".claude/settings.json"
if [ -f "$PROJECT_SETTINGS" ]; then
    log "Cleaning up project-level hooks..."
    # Simple python script to remove bench hooks from project settings
    python3 -c "
import json
import os

path = '$PROJECT_SETTINGS'
if os.path.exists(path):
    with open(path, 'r') as f:
        data = json.load(f)
    
    changed = False
    if 'hooks' in data:
        for event in ['UserPromptSubmit', 'Notification']:
            if event in data['hooks']:
                # Filter out hooks containing 'bench_hook.py'
                new_list = []
                for item in data['hooks'][event]:
                    is_bench = False
                    if isinstance(item, dict) and 'hooks' in item:
                        for h in item['hooks']:
                            if 'bench_hook.py' in h.get('command', ''):
                                is_bench = True
                    if not is_bench:
                        new_list.append(item)
                
                if len(new_list) != len(data['hooks'][event]):
                    data['hooks'][event] = new_list
                    changed = True
                    
    if changed:
        with open(path, 'w') as f:
            json.dump(data, f, indent=2)
        print('Removed bench hooks from project settings.')
"
fi

echo -e "\n${GREEN}Installation Complete!${NC}"
echo "Tools installed to: $USER_TOOLS_DIR"
echo "Logs will be stored in: ~/.claude/bench/"
echo "To view report: $USER_TOOLS_DIR/view_report.sh"
