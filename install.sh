#!/bin/bash

# Intention Tool Installer Script
# This script sets up the Intention Tool on macOS with a Launch Agent

echo "=== Intention Tool Installer ==="
echo "Setting up Intention Tool for easy productivity tracking..."

# 1. Create directory structure
echo "Creating Intention Tool directory..."
mkdir -p ~/intention_tool

# 2. Download all required files
echo "Downloading required files..."
curl -L https://github.com/Julian-Moncarz/MacOS-Intention-Tool/archive/main.zip -o ~/intention_tool/main.zip
unzip ~/intention_tool/main.zip -d ~/intention_tool
mv ~/intention_tool/MacOS-Intention-Tool-main/* ~/intention_tool/
rm -rf ~/intention_tool/MacOS-Intention-Tool-main ~/intention_tool/main.zip

# 3. Set up Python virtual environment
echo "Setting up Python environment..."
cd ~/intention_tool
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# 4. Make scripts executable
chmod +x ~/intention_tool/focus_session.sh

# 5. Set up Launch Agent
echo "Setting up Launch Agent..."
mkdir -p ~/Library/LaunchAgents
cat > ~/Library/LaunchAgents/com.user.focussession.plist << EOL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.focussession</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>-c</string>
        <string>rm -f /tmp/focus_session.lock; exec $HOME/intention_tool/focus_session.sh</string>
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
EOL

# 6. Load the Launch Agent
launchctl load ~/Library/LaunchAgents/com.user.focussession.plist

echo ""
echo "✅ Setup complete! The Intention Tool will start automatically on system startup."
echo "To start it now, run: ~/intention_tool/focus_session.sh"
echo ""
echo "Enjoy your productive focus sessions!"
