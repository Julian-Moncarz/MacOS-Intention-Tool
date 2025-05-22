#!/bin/bash

# Intention Tool Uninstaller
# This script completely removes the Intention Tool and all its components

echo "=== Intention Tool Uninstaller ==="

# 1. Stop and unload the Launch Agent
echo "Stopping and removing Launch Agent..."
launchctl unload ~/Library/LaunchAgents/com.user.focussession.plist 2>/dev/null
rm -f ~/Library/LaunchAgents/com.user.focussession.plist

# 2. Remove the application directory
echo "Removing application files..."
rm -rf ~/intention_tool

# 3. Clean up any temporary files
echo "Cleaning up temporary files..."
rm -f /tmp/focus_session.lock
rm -f /tmp/focussession.out /tmp/focussession.err

echo ""
echo "✅ Uninstall complete! The Intention Tool has been completely removed from your system."
echo ""
