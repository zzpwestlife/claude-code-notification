#!/bin/bash
# setup.sh - Project setup script

set -e

echo "Starting setup..."

# Install dependencies
if [ -f "package.json" ]; then
    echo "Installing dependencies..."
    npm install
else
    echo "Error: package.json not found."
    exit 1
fi

# Run setup wizard
if [ -f "src/scripts/setup-wizard.js" ]; then
    echo "Running setup wizard..."
    node src/scripts/setup-wizard.js
else
    echo "Warning: Setup wizard not found at src/scripts/setup-wizard.js"
fi

echo "Setup complete."
