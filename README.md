## Quick Start

```bash
# Install with one command
curl -L https://raw.githubusercontent.com/Julian-Moncarz/MacOS-Intention-Tool/main/install.sh | bash

# To uninstall
curl -sSL https://raw.githubusercontent.com/Julian-Moncarz/MacOS-Intention-Tool/main/uninstall.sh | bash
```

## Updating

Keep your Intention Tool up to date with new features and bug fixes:

```bash
# Update to latest version (one command)
curl -sSL https://raw.githubusercontent.com/Julian-Moncarz/MacOS-Intention-Tool/main/update.sh | bash
```

The update script will:
- ✅ Download the latest version from GitHub
- ✅ Preserve all your data (logs, insights, virtual environment)
- ✅ Update only the code files and dependencies
- ✅ Restart the service automatically

Your productivity data, custom configurations, and generated insights remain completely intact during updates.

## What to Expect

1. **First Run**: The tool will start automatically after running the installation command
2. **Set Your Intention**: Enter what you plan to focus on
3. **Set Duration**: Input how long it will take you (default 25 mins)
4. **Block Distractions**: Say which websites you will need (all others are blocked with Cold Turkey Blocker if you have it installed)
5. **Do**: Focus on your intention until the timer ends
6. **Extend**: If you need a bit more time to finish your intention, enter the time you need to extend by
7. **Reflect**: After each session, record what you got done, what you learned and how you act on what you learned


## Viewing Your Stats

To see analysis of your intentions at any time:
1. When asked "What's your intention right now?", type: `analysis please`
2. Wait a moment while it processes your data
3. A detailed report will open in your browser

The analysis includes:
- An AI report on your intentions, key lessons you have learnt and key action items
- A report on patterns in your intention setting
- Visual charts of your progress

## Manual Installation (Advanced)

1. Clone the repository:
   ```bash
   git clone https://github.com/Julian-Moncarz/MacOS-Intention-Tool.git ~/intention_tool
   cd ~/intention_tool
   ```

2. Set up the environment:
   ```bash
   python3 -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt
   chmod +x focus_session.sh
   ```

3. (Optional) Set up auto-start:
   ```bash
   mkdir -p ~/Library/LaunchAgents
   cat > ~/Library/LaunchAgents/com.user.focussession.plist << 'EOL'
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
           <string>rm -f /tmp/focus_session.lock; exec \"$HOME/intention_tool/focus_session.sh\"</string>
       </array>
       <key>RunAtLoad</key>
       <true/>
       <key>KeepAlive</key>
       <false/>
   </dict>
   </plist>
   EOL
   launchctl load ~/Library/LaunchAgents/com.user.focussession.plist

   > **Note:** The Launch Agent now always removes any stale lock file before starting, so you never get stuck after a shutdown or crash.
   ```

## Files Overview

- `focus_session.sh` - Main script that manages focus sessions
- `show_analysis.py` - Generates productivity reports from your session data
- `logs.csv` - Stores all your focus session data (created automatically)
- `install.sh` / `uninstall.sh` / `update.sh` - Setup, removal, and update scripts
- `requirements.txt` - Python dependencies

## Requirements
- macOS
- Python 3.9+
- Cold Turkey Blocker (optional, for website blocking)

## License

MIT
