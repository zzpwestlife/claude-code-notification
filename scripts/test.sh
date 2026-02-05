#!/bin/bash
# test.sh - Run tests

set -e

echo "Running tests..."
if [ -d "tests" ]; then
    # Run integration tests
    if [ -f "tests/integration/quick-install.test.sh" ]; then
        bash tests/integration/quick-install.test.sh
    fi
else
    echo "No tests found."
fi
