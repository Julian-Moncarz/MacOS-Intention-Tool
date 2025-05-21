#!/bin/bash

# Test script for validating the Launch Agent configuration
# This script checks if the Launch Agent plist file is correctly formatted
# and contains the expected settings

echo "=== Launch Agent Configuration Test ==="

# Create a temporary directory for testing
TEST_DIR=$(mktemp -d)
echo "Created temporary test directory: $TEST_DIR"

# Copy the install script to the test directory
cp /Users/julianmoncarz/intention_tool/install.sh "$TEST_DIR/"

# Extract the Launch Agent configuration from the install script
echo "Extracting Launch Agent configuration from install.sh..."
PLIST_CONTENT=$(grep -A 20 "cat > ~/Library/LaunchAgents/com.user.focussession.plist" "$TEST_DIR/install.sh" | 
                grep -v "cat >" | 
                grep -v "EOL" | 
                grep -v "^$")

# Write the extracted plist content to a file
echo "Writing extracted plist to test file..."
echo "$PLIST_CONTENT" > "$TEST_DIR/extracted_plist.xml"

# Validate the plist file using plutil
echo "Validating plist file format..."
if plutil -lint "$TEST_DIR/extracted_plist.xml"; then
    echo "✅ Plist file format is valid"
else
    echo "❌ Plist file format is invalid"
    exit 1
fi

# Check for required keys in the plist file
echo "Checking for required keys in the plist file..."
REQUIRED_KEYS=("Label" "ProgramArguments" "RunAtLoad" "KeepAlive" "StandardOutPath" "StandardErrorPath")
MISSING_KEYS=()

for key in "${REQUIRED_KEYS[@]}"; do
    if ! grep -q "<key>$key</key>" "$TEST_DIR/extracted_plist.xml"; then
        MISSING_KEYS+=("$key")
    fi
done

if [ ${#MISSING_KEYS[@]} -eq 0 ]; then
    echo "✅ All required keys are present in the plist file"
else
    echo "❌ Missing required keys in the plist file: ${MISSING_KEYS[*]}"
    exit 1
fi

# Check if KeepAlive is set to false (as per memory)
if grep -q "<key>KeepAlive</key>" "$TEST_DIR/extracted_plist.xml" && 
   grep -A 1 "<key>KeepAlive</key>" "$TEST_DIR/extracted_plist.xml" | grep -q "<false/>"; then
    echo "✅ KeepAlive is correctly set to false"
else
    echo "❌ KeepAlive is not set to false"
    exit 1
fi

# Check if RunAtLoad is set to true
if grep -q "<key>RunAtLoad</key>" "$TEST_DIR/extracted_plist.xml" && 
   grep -A 1 "<key>RunAtLoad</key>" "$TEST_DIR/extracted_plist.xml" | grep -q "<true/>"; then
    echo "✅ RunAtLoad is correctly set to true"
else
    echo "❌ RunAtLoad is not set to true"
    exit 1
fi

# Check if the program arguments point to the correct script
if grep -q "<string>\$HOME/intention_tool/focus_session.sh</string>" "$TEST_DIR/extracted_plist.xml"; then
    echo "✅ Program arguments correctly point to focus_session.sh"
else
    echo "❌ Program arguments do not point to the correct script"
    exit 1
fi

# Cleanup
echo "Cleaning up test directory..."
rm -rf "$TEST_DIR"

echo ""
echo "✅ Launch Agent configuration test completed successfully!"
echo "The Launch Agent is correctly configured to:"
echo "  - Run at system startup (RunAtLoad = true)"
echo "  - Not restart automatically if terminated (KeepAlive = false)"
echo "  - Execute the focus_session.sh script"
echo ""
echo "This configuration prevents multiple instances from running simultaneously,"
echo "as mentioned in the project memory."
