# Early Session End with Cmd+E+S Hotkey

The Intention Tool now supports ending your focus session early using the Cmd+E+S hotkey combination.

## How it Works

1. **Session Start**: When you start a focus session, you'll see a notification that tells you the session has started and that you can press Cmd+E+S to end early.

2. **During Session**: The session runs normally, but now also monitors for an early-end trigger.

3. **Early End**: When you press Cmd+E+S (or run the trigger manually), the session:
   - Calculates the actual time spent
   - Skips the extension option (goes directly to reflection)
   - Shows a notification confirming the early end
   - Proceeds to the reflection questions

## Setup Instructions

### Option 1: Automatic Setup (Recommended)
```bash
./setup_hotkey.sh
```

This creates an AppleScript app that can be assigned to Cmd+E+S.

### Option 2: Manual Hotkey Assignment

1. **Open System Settings** (or System Preferences on older macOS)
2. **Go to Keyboard → Keyboard Shortcuts**
3. **Click 'App Shortcuts'** in the left sidebar
4. **Click the '+' button** to add a new shortcut
5. **Set these values:**
   - Application: All Applications
   - Menu Title: End Focus Session Early
   - Keyboard Shortcut: Press Cmd+E+S
6. **Click 'Add'**

### Option 3: Using Third-Party Tools

If you use tools like BetterTouchTool, Karabiner-Elements, or Alfred:
- Set Cmd+E+S to run: `open '$HOME/Applications/End Focus Session Early.app'`

### Option 4: Manual Trigger (For Testing)

You can manually end a session early by running:
```bash
 open "$HOME/Applications/End Focus Session Early.app"
```

Or from Spotlight: Press Cmd+Space and type "End Focus Session Early"

## Features

- **Session Start Notification**: Clearly indicates when the session starts and how to end early
- **Smart Duration Calculation**: Accurately tracks actual time spent during early-ended sessions
- **Skip Extension**: Early-ended sessions bypass the extension option and go directly to reflection
- **Clean Logging**: Early-ended sessions are properly logged with actual duration
- **Visual Feedback**: Notifications confirm when the session ends early

## Testing

1. Start a focus session with any intention and duration
2. Wait a few seconds, then press Cmd+E+S (or run the app manually)
3. You should see a notification that the session ended early
4. The reflection questions should appear immediately
5. Check the logs.csv file to confirm the actual duration was recorded

## Troubleshooting

- **Hotkey not working**: Make sure you've assigned it correctly in System Settings
- **No active session**: The hotkey only works when a focus session is running
- **Permission issues**: The AppleScript may need accessibility permissions for some features

## Technical Details

The feature works by:
1. Creating a unique trigger file for each session (includes process ID)
2. Monitoring for this trigger file during the session timing loop
3. When the trigger file is detected, calculating elapsed time and ending early
4. Cleaning up all temporary files when the session ends

* question == answer
