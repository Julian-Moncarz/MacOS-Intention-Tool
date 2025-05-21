#!/bin/bash

# Test script for the Intention Tool one-line setup command
# This script simulates the one-line setup command in a controlled environment

echo "=== Intention Tool One-Line Command Test ==="

# Create a temporary directory for testing
TEST_DIR=$(mktemp -d)
echo "Created temporary test directory: $TEST_DIR"

# Create a temporary HOME directory for testing
mkdir -p "$TEST_DIR/home"
TEST_HOME="$TEST_DIR/home"
echo "Created temporary HOME directory: $TEST_HOME"

# Create a modified version of the install script for testing
echo "Creating test environment..."

# Copy the original install script to the test directory
cp /Users/julianmoncarz/intention_tool/install.sh "$TEST_DIR/install.sh"

# Modify the install script to use the test HOME directory
sed -i.bak "s|~/intention_tool|$TEST_HOME/intention_tool|g" "$TEST_DIR/install.sh"
sed -i.bak "s|~/Library/LaunchAgents|$TEST_HOME/Library/LaunchAgents|g" "$TEST_DIR/install.sh"

# Comment out the actual launchctl command to prevent it from affecting the real system
sed -i.bak "s|launchctl load|# launchctl load|g" "$TEST_DIR/install.sh"

# Create a simple HTTP server to serve the install script
echo "Starting HTTP server to serve the install script..."
cd "$TEST_DIR"
python3 -m http.server 8000 &
HTTP_SERVER_PID=$!

# Wait for the HTTP server to start
sleep 2

# Simulate the one-line setup command
echo "Simulating one-line setup command..."
curl -s http://localhost:8000/install.sh | HOME="$TEST_HOME" bash

# Stop the HTTP server
echo "Stopping HTTP server..."
kill $HTTP_SERVER_PID

# Verify the installation
echo "Verifying installation..."

# Check if the directory structure was created correctly
if [ -d "$TEST_HOME/intention_tool" ]; then
    echo "✅ Directory structure created correctly"
else
    echo "❌ Directory structure not created correctly"
    exit 1
fi

# Check if the focus_session.sh script was copied and made executable
if [ -x "$TEST_HOME/intention_tool/focus_session.sh" ]; then
    echo "✅ focus_session.sh script is executable"
else
    echo "❌ focus_session.sh script is not executable"
    exit 1
fi

# Check if the Python virtual environment was set up
if [ -d "$TEST_HOME/intention_tool/venv" ]; then
    echo "✅ Python virtual environment set up correctly"
else
    echo "❌ Python virtual environment not set up correctly"
    exit 1
fi

# Check if the Launch Agent plist file was created
if [ -f "$TEST_HOME/Library/LaunchAgents/com.user.focussession.plist" ]; then
    echo "✅ Launch Agent plist file created correctly"
else
    echo "❌ Launch Agent plist file not created correctly"
    exit 1
fi

# Validate the plist file
echo "Validating Launch Agent plist file..."
if plutil -lint "$TEST_HOME/Library/LaunchAgents/com.user.focussession.plist"; then
    echo "✅ Launch Agent plist file is valid"
else
    echo "❌ Launch Agent plist file is invalid"
    exit 1
fi

# Check if KeepAlive is set to false (as per memory)
if grep -q "<key>KeepAlive</key>" "$TEST_HOME/Library/LaunchAgents/com.user.focussession.plist" && 
   grep -A 1 "<key>KeepAlive</key>" "$TEST_HOME/Library/LaunchAgents/com.user.focussession.plist" | grep -q "<false/>"; then
    echo "✅ KeepAlive is correctly set to false"
else
    echo "❌ KeepAlive is not set to false"
    exit 1
fi

# Cleanup
echo "Cleaning up test directory..."
rm -rf "$TEST_DIR"

echo ""
echo "✅ One-line command test completed successfully!"
echo "The one-line setup command works correctly and sets up the Intention Tool with the correct configuration."
echo "The Launch Agent is correctly configured to prevent multiple instances from running simultaneously."
