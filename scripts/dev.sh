#!/bin/bash
# dev.sh - Development run script

set -e

# Load environment variables from config/.env.dev if present
if [ -f "config/.env.dev" ]; then
    export $(grep -v '^#' config/.env.dev | xargs)
fi

echo "Running in development mode..."
node src/index.js "$@"
