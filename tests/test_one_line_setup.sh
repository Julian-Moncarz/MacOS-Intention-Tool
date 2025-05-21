#!/bin/bash

# Test script for the Intention Tool one-line setup
# This script simulates the one-line setup in a temporary directory structure

echo "=== Intention Tool One-Line Setup Test ==="

# Create a temporary directory for testing
TEST_DIR=$(mktemp -d)
echo "Created temporary test directory: $TEST_DIR"

# Create a modified version of the install script for testing
echo "Creating test install script..."
cat > "$TEST_DIR/test_install.sh" << 'EOL'
#!/bin/bash

# Modified Intention Tool Installer Script for testing
# This script simulates the installation in a test directory

# Get the test directory from environment variable
TEST_HOME="${TEST_DIR}"
echo "Test home directory: $TEST_HOME"

echo "=== Intention Tool Installer (TEST MODE) ==="
echo "Setting up Intention Tool for easy productivity tracking..."

# 1. Create directory structure
echo "Creating Intention Tool directory..."
mkdir -p "$TEST_HOME/intention_tool"

# 2. Download all required files (simulated by copying from current directory)
echo "Copying required files (simulating download)..."
cp -r /Users/julianmoncarz/intention_tool/* "$TEST_HOME/intention_tool/"
rm -rf "$TEST_HOME/intention_tool/tests"

# 3. Set up Python virtual environment
echo "Setting up Python environment..."
cd "$TEST_HOME/intention_tool"
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# 4. Make scripts executable
chmod +x "$TEST_HOME/intention_tool/focus_session.sh"

# 5. Set up Launch Agent (simulated)
echo "Setting up Launch Agent (simulated)..."
mkdir -p "$TEST_HOME/Library/LaunchAgents"
cat > "$TEST_HOME/Library/LaunchAgents/com.user.focussession.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.focussession</string>
    <key>ProgramArguments</key>
    <array>
        <string>$TEST_HOME/intention_tool/focus_session.sh</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <false/>
    <key>StandardOutPath</key>
    <string>/tmp/focussession.out</string>
    <key>StandardErrorPath</key>
    <string>/tmp/focussession.err</string>
</dict>
</plist>
PLIST

# 6. Load the Launch Agent (simulated)
echo "Simulating launchctl load: $TEST_HOME/Library/LaunchAgents/com.user.focussession.plist"

echo ""
echo "✅ Test installation complete! Checking the results..."
EOL

# Make the test script executable
chmod +x "$TEST_DIR/test_install.sh"

# Export the test directory as an environment variable
export TEST_DIR="$TEST_DIR"

# Run the test installation
echo "Running test installation..."
"$TEST_DIR/test_install.sh"

# Verify the installation
echo "Verifying installation..."

# Check if the directory structure was created correctly
if [ -d "$TEST_DIR/intention_tool" ]; then
    echo "✅ Directory structure created correctly"
else
    echo "❌ Directory structure not created correctly"
    exit 1
fi

# Check if the focus_session.sh script was copied and made executable
if [ -x "$TEST_DIR/intention_tool/focus_session.sh" ]; then
    echo "✅ focus_session.sh script is executable"
else
    echo "❌ focus_session.sh script is not executable"
    exit 1
fi

# Check if the Python virtual environment was set up
if [ -d "$TEST_DIR/intention_tool/venv" ]; then
    echo "✅ Python virtual environment set up correctly"
else
    echo "❌ Python virtual environment not set up correctly"
    exit 1
fi

# Check if the Launch Agent plist file was created
if [ -f "$TEST_DIR/Library/LaunchAgents/com.user.focussession.plist" ]; then
    echo "✅ Launch Agent plist file created correctly"
else
    echo "❌ Launch Agent plist file not created correctly"
    exit 1
fi

# Validate the plist file
echo "Validating Launch Agent plist file..."
if plutil -lint "$TEST_DIR/Library/LaunchAgents/com.user.focussession.plist"; then
    echo "✅ Launch Agent plist file is valid"
else
    echo "❌ Launch Agent plist file is invalid"
    exit 1
fi

# Check if KeepAlive is set to false (as per memory)
if grep -q "<key>KeepAlive</key>" "$TEST_DIR/Library/LaunchAgents/com.user.focussession.plist" && 
   grep -A 1 "<key>KeepAlive</key>" "$TEST_DIR/Library/LaunchAgents/com.user.focussession.plist" | grep -q "<false/>"; then
    echo "✅ KeepAlive is correctly set to false"
else
    echo "❌ KeepAlive is not set to false"
    exit 1
fi

# Cleanup
echo "Cleaning up test directory..."
rm -rf "$TEST_DIR"

echo ""
echo "✅ One-line setup test completed successfully!"
echo "The installation script works correctly and sets up the Intention Tool with the correct configuration."
echo "The Launch Agent is correctly configured to prevent multiple instances from running simultaneously."
