#!/usr/bin/env python3
import json
import os
import sys

# User-level settings
USER_HOME = os.path.expanduser('~')
SETTINGS_PATH = os.path.join(USER_HOME, '.claude', 'settings.json')
TOOLS_DIR = os.path.join(USER_HOME, '.claude', 'tools', 'claude-bench')

def update_settings():
    # Load existing settings
    if os.path.exists(SETTINGS_PATH):
        try:
            with open(SETTINGS_PATH, 'r') as f:
                settings = json.load(f)
        except json.JSONDecodeError:
            print(f"Error: {SETTINGS_PATH} is not valid JSON.")
            sys.exit(1)
    else:
        settings = {}

    if 'hooks' not in settings:
        settings['hooks'] = {}

    hook_script = os.path.join(TOOLS_DIR, 'bench_hook.py')
    python_executable = sys.executable
    
    start_cmd = f"{python_executable} {hook_script} start"
    stop_cmd = f"{python_executable} {hook_script} stop"

    # Helper to add hook safely
    def add_hook(event, cmd):
        if event not in settings['hooks']:
            settings['hooks'][event] = []
        
        # Check if already exists to avoid duplicates
        for item in settings['hooks'][event]:
            if not isinstance(item, dict): continue
            if 'hooks' in item and isinstance(item['hooks'], list):
                for subhook in item['hooks']:
                    if subhook.get('command') == cmd:
                        print(f"Hook for {event} already exists.")
                        return
                
        # Append new hook with CORRECT structure
        settings['hooks'][event].append({
            "hooks": [{
                "type": "command",
                "command": cmd
            }]
        })
        print(f"Added hook for {event}")

    # Remove old Notification hook if it exists (optional cleanup)
    # But for safety, we just add the new one.
    # Actually, we should probably remove the Notification hook to avoid double triggering if we keep it?
    # Let's just add 'Stop' and keep 'UserPromptSubmit'.
    # We might want to remove 'Notification' if it was added by us.
    
    add_hook('UserPromptSubmit', start_cmd)
    # Switch from Notification to Stop for better accuracy
    add_hook('Stop', stop_cmd)

    # Save back
    try:
        with open(SETTINGS_PATH, 'w') as f:
            json.dump(settings, f, indent=2)
        print(f"Updated {SETTINGS_PATH}")
    except Exception as e:
        print(f"Error saving settings: {e}")
        sys.exit(1)

if __name__ == '__main__':
    update_settings()
