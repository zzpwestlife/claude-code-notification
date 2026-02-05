#!/bin/bash
# Test script for quick-install.sh

set -e

# Setup environment
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$TEST_DIR")"
MOCK_BIN="$TEST_DIR/mock_bin"
mkdir -p "$MOCK_BIN"
export PATH="$MOCK_BIN:$PATH"

# Cleanup function
cleanup() {
    rm -rf "$MOCK_BIN"
    rm -rf "$HOME/code/claude-code-notification_test" # Clean test install dir
}
trap cleanup EXIT

# Mock configuration
export INSTALL_DIR="$HOME/code/claude-code-notification_test"
# We need to sed the install script to use our test dir instead of the hardcoded one
# Or we can just patch it temporarily
cp "$ROOT_DIR/quick-install.sh" "$TEST_DIR/quick-install_patched.sh"
# Patch install dir
sed -i.bak "s|INSTALL_DIR=\"\$HOME/code/claude-code-notification\"|INSTALL_DIR=\"$INSTALL_DIR\"|g" "$TEST_DIR/quick-install_patched.sh"
# Patch Repo URL to local path to avoid network in tests and speed up
sed -i.bak "s|REPO_URL=.*|REPO_URL=\"$ROOT_DIR\"|g" "$TEST_DIR/quick-install_patched.sh"
chmod +x "$TEST_DIR/quick-install_patched.sh"

log() {
    echo -e "\033[0;34m[TEST]\033[0m $1"
}

create_mocks() {
    # Mock whiptail
    cat > "$MOCK_BIN/whiptail" <<'EOF'
#!/bin/bash
# Mock whiptail
# Reads from input_sequence.txt to decide output
# Format: TYPE:VALUE (TYPE=OUTPUT or EXIT)

SEQ_FILE="/tmp/whiptail_sequence"

if [ ! -f "$SEQ_FILE" ]; then
    echo "No sequence file" >&2
    exit 1
fi

# Get next instruction
LINE=$(head -n 1 "$SEQ_FILE")
# Remove first line
tail -n +2 "$SEQ_FILE" > "$SEQ_FILE.tmp" && mv "$SEQ_FILE.tmp" "$SEQ_FILE"

TYPE=$(echo "$LINE" | cut -d':' -f1)
VALUE=$(echo "$LINE" | cut -d':' -f2-)

if [[ "$@" == *"--inputbox"* ]]; then
    if [ "$TYPE" == "OUTPUT" ]; then
        echo "$VALUE" >&2 # whiptail outputs to stderr
        exit 0
    elif [ "$TYPE" == "EXIT" ]; then
        exit "$VALUE"
    fi
elif [[ "$@" == *"--msgbox"* ]]; then
    # Message box just waits for OK
    exit 0
else
    exit 0
fi
EOF
    chmod +x "$MOCK_BIN/whiptail"

    # Mock npm to avoid slow install
    cat > "$MOCK_BIN/npm" <<'EOF'
#!/bin/bash
echo "Mock npm installed"
EOF
    chmod +x "$MOCK_BIN/npm"
    
    # Mock node to just run the script (we need node for the config update script)
    # Actually we should use the real node, but ensuring it's in path.
    # If we put MOCK_BIN in front, we hide real node if we create a mock 'node'.
    # We won't mock node.
}

test_happy_path() {
    log "Running Happy Path Test..."
    
    # Define sequence:
    # 1. Install Dir -> Valid
    # 2. Webhook URL Input -> Valid URL
    # 3. Secret Input -> Empty (Optional)
    echo "OUTPUT:$INSTALL_DIR" > /tmp/whiptail_sequence
    echo "OUTPUT:https://open.feishu.cn/open-apis/bot/v2/hook/12345" >> /tmp/whiptail_sequence
    echo "OUTPUT:" >> /tmp/whiptail_sequence
    
    "$TEST_DIR/quick-install_patched.sh"
    
    if [ -f "$INSTALL_DIR/.env" ]; then
        log "✅ Happy Path: .env created"
        if grep -q "hook/12345" "$INSTALL_DIR/.env"; then
            log "✅ Happy Path: Content verified"
        else
            log "❌ Happy Path: Content mismatch"
            exit 1
        fi
    else
        log "❌ Happy Path: .env not found"
        exit 1
    fi
}

test_validation_retry() {
    log "Running Validation Retry Test..."
    rm -rf "$INSTALL_DIR"
    
    # Define sequence:
    # 0. Install Dir -> Valid (Added)
    # 1. Webhook URL -> Invalid (bad format)
    # 2. Error Msg -> OK
    # 3. Webhook URL -> Invalid (still bad)
    # 4. Error Msg -> OK
    # 5. Webhook URL -> Valid
    # 6. Secret -> valid
    
    # Note: My script calls show_msg (msgbox) on error.
    # The mock handles msgbox by just exiting 0.
    
    echo "OUTPUT:$INSTALL_DIR" > /tmp/whiptail_sequence
    echo "OUTPUT:invalid_url" >> /tmp/whiptail_sequence
    echo "OUTPUT:still_invalid" >> /tmp/whiptail_sequence
    echo "OUTPUT:https://open.feishu.cn/open-apis/bot/v2/hook/retry_success" >> /tmp/whiptail_sequence
    echo "OUTPUT:secret_key" >> /tmp/whiptail_sequence
    
    "$TEST_DIR/quick-install_patched.sh"
    
    if grep -q "retry_success" "$INSTALL_DIR/.env"; then
        log "✅ Validation Retry: Verified"
    else
        log "❌ Validation Retry: Failed"
        exit 1
    fi
}

# Setup
create_mocks

# Run Tests
test_happy_path
test_validation_retry

log "🎉 All tests passed!"
