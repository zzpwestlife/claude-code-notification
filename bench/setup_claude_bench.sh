#!/bin/bash
set -e

# Configuration
USER_HOME="$HOME"
CLAUDE_DIR="$USER_HOME/.claude"
TOOLS_DIR="$CLAUDE_DIR/tools/claude-bench"
BENCH_DIR="$CLAUDE_DIR/bench"
REPO_TOOLS_DIR="$(dirname "$0")/tools/claude-bench"

echo "Setting up Claude Bench..."

# 1. Create Directories
echo "Creating directories..."
mkdir -p "$TOOLS_DIR"
mkdir -p "$BENCH_DIR"

# 2. Copy Tools
echo "Copying scripts..."
# Assuming we are running from the repo root
if [ -d "tools/claude-bench" ]; then
    cp tools/claude-bench/bench_hook.py "$TOOLS_DIR/"
    cp tools/claude-bench/reporter.py "$TOOLS_DIR/"
    cp tools/claude-bench/setup_hooks.py "$TOOLS_DIR/"
    cp tools/claude-bench/view_report.sh "$TOOLS_DIR/"
    cp tools/claude-bench/webhook.json.example "$BENCH_DIR/"
    chmod +x "$TOOLS_DIR/view_report.sh"
else
    echo "Error: tools/claude-bench directory not found in current path."
    echo "Please run this script from the root of the learn-claude-code repository."
    exit 1
fi

# 3. Setup Hooks
echo "Configuring Claude Code hooks..."
if command -v python3 &> /dev/null; then
    python3 "$TOOLS_DIR/setup_hooks.py"
else
    echo "Error: python3 not found. Please install Python 3."
    exit 1
fi

echo "========================================"
echo "Claude Bench Setup Complete!"
echo "========================================"
echo "1. Webhook Configuration (Optional):"
echo "   Rename $BENCH_DIR/webhook.json.example to webhook.json"
echo "   and add your IM bot URL to enable notifications."
echo ""
echo "2. Usage:"
echo "   Just use Claude Code normally."
echo "   - Timing starts when you submit a prompt."
echo "   - Timing ends when Claude finishes responding."
echo ""
echo "3. View Report:"
echo "   Run: bash $TOOLS_DIR/view_report.sh"
echo "========================================"
