#!/usr/bin/env python3
# v1.1 - Added prompt capture support
import os
import sys
import time
import json
from datetime import datetime

# Configuration - User Level
USER_HOME = os.path.expanduser('~')
CLAUDE_BASE = os.path.join(USER_HOME, '.claude')
BENCH_DIR = os.path.join(CLAUDE_BASE, 'bench')
LOG_FILE = os.path.join(BENCH_DIR, 'claude_bench.jsonl')
START_FILE = os.path.join(BENCH_DIR, 'bench_start.json') # Changed extension to .json

def ensure_dirs():
    if not os.path.exists(BENCH_DIR):
        os.makedirs(BENCH_DIR, exist_ok=True)

def get_stdin_data():
    """Attempt to read JSON from stdin."""
    try:
        # Check if there is data on stdin
        if not sys.stdin.isatty():
            content = sys.stdin.read().strip()
            if content:
                # Try to parse as JSON
                try:
                    return json.loads(content)
                except json.JSONDecodeError:
                    # If not JSON, return as raw text wrapped in dict
                    return {"raw_text": content}
    except Exception:
        pass
    return {}

def log_event(data):
    try:
        with open(LOG_FILE, 'a') as f:
            f.write(json.dumps(data) + '\n')
    except Exception:
        pass

def handle_start():
    ensure_dirs()
    now = time.time()
    
    # Capture payload from hook
    payload = get_stdin_data()
    
    # Debug: Save last payload
    try:
        with open(os.path.join(BENCH_DIR, 'last_start_payload.json'), 'w') as f:
            json.dump(payload, f, indent=2)
    except:
        pass
        
    # Extract prompt
    # Note: Structure depends on the hook event. 
    # For UserPromptSubmit, it might be the prompt string or an object.
    prompt = ""
    if isinstance(payload, dict):
        prompt = payload.get('prompt', payload.get('text', payload.get('raw_text', '')))
    elif isinstance(payload, str):
        prompt = payload
        
    start_data = {
        'timestamp': now,
        'prompt': str(prompt)
    }
    
    try:
        with open(START_FILE, 'w') as f:
            json.dump(start_data, f)
    except Exception as e:
        sys.stderr.write(f"Error writing start file: {e}\n")

def handle_stop():
    if not os.path.exists(START_FILE):
        # Try checking for old txt file for backward compatibility (optional)
        old_file = os.path.join(BENCH_DIR, 'bench_start.txt')
        if os.path.exists(old_file):
            try:
                with open(old_file, 'r') as f:
                    ts = float(f.read().strip())
                    start_data = {'timestamp': ts, 'prompt': ''}
                os.remove(old_file)
            except:
                return
        else:
            return
    else:
        try:
            with open(START_FILE, 'r') as f:
                start_data = json.load(f)
        except Exception:
            return

    end_time = time.time()
    start_time = start_data.get('timestamp', 0.0)
    prompt = start_data.get('prompt', '')
    
    if start_time == 0.0:
        return

    # Calculate duration
    duration_ms = (end_time - start_time) * 1000
    
    # Log
    event = {
        'timestamp': end_time,
        'datetime': datetime.fromtimestamp(end_time).isoformat(),
        'type': 'INTERACTION',
        'data': {
            'start_ts': start_time,
            'end_ts': end_time,
            'total_ms': duration_ms,
            'prompt': prompt  # Include prompt in the log
        }
    }
    log_event(event)
    
    # Clean up
    # try:
    #     os.remove(START_FILE)
    # except:
    #     pass

def main():
    if len(sys.argv) < 2:
        sys.exit(1)

    command = sys.argv[1]
    
    if command == 'start':
        handle_start()
    elif command == 'stop':
        handle_stop()

if __name__ == '__main__':
    main()
