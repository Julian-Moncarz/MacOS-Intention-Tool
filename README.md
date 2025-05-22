# Intention Tool

## Quick Install (macOS)

Install with a single command (no Git required):

```bash
curl -L https://raw.githubusercontent.com/Julian-Moncarz/MacOS-Intention-Tool/main/install.sh | bash
```

This will set up everything automatically, including a Launch Agent to start the tool when your system boots.

---

A productivity tool that helps you track, manage, and analyze your focus sessions. This tool allows you to set intentions for work sessions, record your activities, and gain valuable insights about your productivity patterns through data visualization and AI-powered analysis.

## Features

- **Focus Session Management**: Start and track dedicated work sessions with clear intentions
- **Activity Logging**: Record what you're working on and for how long
- **Data Analysis**: Analyze your focus session data from logs
- **Visualization**: Generate charts and graphs to visualize your productivity patterns
- **AI Insights**: Get AI-powered insights about your work habits using Google's Gemini API
- **Reporting**: View results in a clean, responsive HTML report
- **Seamless Experience**: Automatically opens the report in your default web browser

## Requirements

- Python 3.9+
- Required packages are listed in `requirements.txt`

## Setup

### Option 1: Easy One-Line Install (Recommended)

Run this single command in Terminal to set up everything automatically:

```bash
curl -L https://raw.githubusercontent.com/Julian-Moncarz/MacOS-Intention-Tool/main/install.sh | bash
```

This will:
1. Download all necessary files
2. Set up a Python virtual environment
3. Install required dependencies
4. Configure a Launch Agent for automatic startup
5. Make all scripts executable

### Uninstallation

To completely remove the Intention Tool and all its components, run:

```bash
curl -sSL https://raw.githubusercontent.com/Julian-Moncarz/MacOS-Intention-Tool/main/uninstall.sh | bash
```

This will:
1. Stop and unload the Launch Agent
2. Remove all application files and directories
3. Clean up temporary files and logs

### Option 2: Manual Setup

If you prefer to set things up manually:

1. Clone this repository
2. Create a virtual environment:
   ```
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```
3. Install dependencies:
   ```
   pip install -r requirements.txt
   ```
4. Follow the Launch Agent setup instructions below if you want the tool to start automatically

## Usage

### Starting a Focus Session

```
./focus_session.sh
```

This will:
1. Prompt you to set an intention for your work session
2. Start tracking your focus session
3. Log your activities and time spent

### Setting Up a Launch Agent (macOS)

To have the focus session script run automatically on system startup, you can set up a macOS Launch Agent:

1. Create a Launch Agent plist file in your user's LaunchAgents directory:

```bash
mkdir -p ~/Library/LaunchAgents
touch ~/Library/LaunchAgents/com.julianmoncarz.focussession.plist
```

2. Edit the plist file with the following content (replace the path if necessary):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.julianmoncarz.focussession</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Users/julianmoncarz/intention_tool/focus_session.sh</string>
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
```

3. Load the Launch Agent:

```bash
launchctl load ~/Library/LaunchAgents/com.julianmoncarz.focussession.plist
```

The script will now run automatically each time your system starts up, prompting you to set your intention for the day. The script is designed to restart itself after each session completes, but if you manually terminate it, the Launch Agent won't automatically restart it until the next system startup.

### Analyzing Your Focus Sessions

```
python show_analysis.py
```

This will:
1. Process your focus session logs
2. Generate visualizations of your productivity patterns
3. Create AI-powered insights about your work habits
4. Display everything in an HTML report
5. Automatically open the report in your default browser

## Files

- `focus_session.sh`: Shell script for starting and managing focus sessions
- `show_analysis.py`: Main script that generates and displays the HTML report
- `visualize_logs.py`: Handles data processing and visualization generation
- `logs.csv`: Stores your focus session data
- `focus_insights/`: Directory containing AI-generated insights
- `requirements.txt`: List of Python dependencies
- `~/Library/LaunchAgents/com.user.intentionTool.plist`: Launch Agent configuration file (after setup)

## License

MIT
