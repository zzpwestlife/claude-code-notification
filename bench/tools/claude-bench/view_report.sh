#!/bin/bash
USER_HOME="$HOME"
LOG_FILE="$USER_HOME/.claude/bench/claude_bench.jsonl"
REPORT_FILE="$USER_HOME/.claude/bench/report.html"
TOOLS_DIR="$USER_HOME/.claude/tools/claude-bench"

if [ ! -f "$LOG_FILE" ]; then
    echo "No log file found at $LOG_FILE"
    echo "Have you used Claude Code since installing the benchmark tool?"
    exit 1
fi

python3 "$TOOLS_DIR/reporter.py" "$LOG_FILE" -o "$REPORT_FILE"

if command -v open > /dev/null; then
    open "$REPORT_FILE"
elif command -v xdg-open > /dev/null; then
    xdg-open "$REPORT_FILE"
else
    echo "Report generated at $REPORT_FILE. Please open it in your browser."
fi
