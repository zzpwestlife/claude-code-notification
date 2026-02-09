# Claude Bench (Hooks Version)

A precision timing tool for Claude Code interactions using native Hooks.

## Features
- **Native Integration**: Uses Claude Code's `UserPromptSubmit` and `Notification` hooks for accurate start/end detection.
- **Zero Overhead**: No wrapper scripts or pty simulation. Works directly with your normal `claude` command.
- **Visualization**: Generates HTML reports with response time trends.

## Installation

```bash
cd tools/claude-bench
chmod +x install.sh
./install.sh
```

This will:
1. Register hooks in your `.claude/settings.json`.
2. Setup the logging scripts.

## Usage

1. **Just use Claude**:
   Run `claude` as you normally would. The hooks will automatically record the time for each interaction.
   
   > Note: Time is measured from "User Hits Enter" (`UserPromptSubmit`) to "Claude is Ready for Next Input" (`Notification`).

2. **View Report**:
   ```bash
   ./tools/claude-bench/view_report.sh
   ```
   This will generate `claude_bench_report.html` and attempt to open it in your default browser.

## Data Storage
- Logs are stored in `claude_bench.jsonl` in your project root.
- Temporary timestamps are stored in `.claude/tmp/bench_start.txt`.
