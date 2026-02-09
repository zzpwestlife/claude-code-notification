const fs = require('fs');
const path = require('path');
const os = require('os');

const settingsPath = path.join(os.homedir(), '.claude/settings.json');

try {
    const settings = JSON.parse(fs.readFileSync(settingsPath, 'utf8'));
    
    if (!settings.hooks) {
        console.log('No hooks found');
        process.exit(0);
    }

    // Helper to score commands (prefer absolute paths)
    const scoreCommand = (cmd) => {
        if (cmd.includes('/opt/homebrew')) return 2;
        if (cmd.startsWith('/')) return 1;
        return 0;
    };

    // Helper to clean and merge hooks
    const processHookType = (hookName, commandFilter) => {
        if (!settings.hooks[hookName]) return;

        const allHooks = settings.hooks[hookName];
        const uniqueCommands = new Map();

        // Extract all commands
        allHooks.forEach(hookEntry => {
            if (hookEntry.hooks) {
                hookEntry.hooks.forEach(h => {
                    if (h.type === 'command') {
                        // Identify "logical" command (e.g., bench_hook start)
                        let key = h.command;
                        // Simplistic key generation to identify duplicates with different paths
                        if (h.command.includes('bench_hook.py')) {
                            const action = h.command.includes('start') ? 'start' : 'stop';
                            key = `bench_hook_${action}`;
                        } else if (h.command.includes('claude-code-notification')) {
                            key = 'notification';
                        }
                        
                        if (!uniqueCommands.has(key) || scoreCommand(h.command) > scoreCommand(uniqueCommands.get(key).command)) {
                            uniqueCommands.set(key, h);
                        }
                    }
                });
            }
        });

        // Convert map values to array and sort if necessary
        // For Stop, we need bench_hook (stop) BEFORE notification
        let finalCommands = Array.from(uniqueCommands.values());
        
        if (hookName === 'Stop') {
            finalCommands.sort((a, b) => {
                const isBenchA = a.command.includes('bench_hook.py');
                const isBenchB = b.command.includes('bench_hook.py');
                if (isBenchA && !isBenchB) return -1; // Bench first
                if (!isBenchA && isBenchB) return 1;
                return 0;
            });
        }

        // Create single merged hook entry
        settings.hooks[hookName] = [
            {
                "hooks": finalCommands
            }
        ];
    };

    processHookType('UserPromptSubmit');
    processHookType('Stop');

    // Write back
    fs.writeFileSync(settingsPath, JSON.stringify(settings, null, 2));
    console.log('Successfully optimized hooks in settings.json');

} catch (error) {
    console.error('Error processing settings.json:', error);
    process.exit(1);
}
