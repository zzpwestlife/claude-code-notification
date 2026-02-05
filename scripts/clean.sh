#!/bin/bash
# clean.sh - Clean project artifacts

set -e

echo "Cleaning project..."

# Remove node_modules
if [ -d "node_modules" ]; then
    rm -rf node_modules
    echo "Removed node_modules"
fi

# Remove coverage
if [ -d "coverage" ]; then
    rm -rf coverage
    echo "Removed coverage"
fi

# Remove logs
rm -f *.log
echo "Removed logs"

echo "Clean complete."
