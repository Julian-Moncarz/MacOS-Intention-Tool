#!/usr/bin/env bash

# ~/.focus_tools/focus_session.sh

# Check if script is already running (excluding this instance)
if pgrep -f "$(basename "$0")" | grep -v $$ | grep -v "grep" > /dev/null; then
  # Show a notification instead of a dialog to avoid blocking
  osascript -e 'display notification "A focus session is already running" with title "Focus Session"'
  exit 1
fi

# Cold Turkey Blocker CLI
CT_BIN="/Applications/Cold Turkey Blocker.app/Contents/MacOS/Cold Turkey Blocker"

# Define a simple input function using direct AppleScript
get_input() {
  local prompt="$1" default="$2"
  
  # Simple, direct AppleScript call
  osascript -e "tell app \"System Events\" to text returned of (display dialog \"$prompt\" default answer \"$default\" buttons {\"OK\"} default button \"OK\" with title \"Focus Session\")" 2>/dev/null || echo ""
}

# Initial prompts
intent=$(get_input "What's your intention right now? (Type 'analysis please' to view your focus stats)" "")

# Check if the user wants to run analysis
if [[ "$intent" == *"analysis please"* ]]; then
    echo "Generating your focus session analysis..."
    # Run the analysis script
    python3 "$(dirname "$0")/show_analysis.py"
    echo "Analysis complete! Check your browser for the results."
    # Restart the script instead of exiting
    exec "$0"
fi

# Get duration and validate it's a positive number and not greater than 120
duration=$(get_input "How long will it take? (minutes, whole numbers only)" "")
# Validate duration is a number
if ! [[ "$duration" =~ ^[0-9]+$ ]]; then
  echo "Invalid duration. Setting to default of 5 minutes."
  duration=5
fi
# Ensure duration is positive and not greater than 120
if [ "$duration" -le 0 ]; then
  echo "Duration must be positive. Setting to 5 minutes."
  duration=5
elif [ "$duration" -gt 120 ]; then
  echo "Duration capped at 120 minutes."
  duration=120
fi

sites=$(get_input "Comma-separated list of sites you'll need (e.g. ex.com)"     "")

# Timestamp
start_ts=$(date '+%Y-%m-%d %H:%M:%S')

# Start the Cold Turkey block
"$CT_BIN" -start "Focus-Session"

# Whitelist exceptions
IFS=',' read -ra DOMAIN_ARRAY <<< "$sites"
for domain in "${DOMAIN_ARRAY[@]}"; do
  trimmed=$(echo "$domain" | xargs)
  [ -n "$trimmed" ] && "$CT_BIN" -add "Focus-Session" -exception "$trimmed"
done

# Wait out the timer
echo "Focus session started for $duration minutes..."
sleep $(( duration * 60 ))
echo "Focus session timer completed."

# Extension option
total_duration=$duration
while true; do
  extension=$(get_input "Would you like to extend your session? (Enter minutes to extend as whole numbers only, or leave empty to finish)" "")
  
  # If empty, break the loop
  if [[ -z "$extension" ]]; then
    break
  fi
  
  # Validate extension is a number
  if ! [[ "$extension" =~ ^[0-9]+$ ]]; then
    echo "Invalid extension time. Please enter a number."
    continue
  fi
  
  # Ensure extension is positive and not greater than 120
  if [ "$extension" -le 0 ]; then
    echo "Extension time must be positive."
    continue
  elif [ "$extension" -gt 120 ]; then
    echo "Extension time capped at 120 minutes."
    extension=120
  fi
  
  # Extend session
  echo "Extending session by $extension minutes..."
  total_duration=$((total_duration + extension))
  
  # Sleep for the extension duration
  sleep $((extension * 60))
done

# Stop the Cold Turkey block only after user is done with all extensions
"$CT_BIN" -stop "Focus-Session"

# Debrief prompts
done_what=$(get_input "What did you get done? Your original intention was: $intent" "")
learned=$(get_input "What did you learn?"    "")
lessons=$(get_input "How can you act on that?"           "")

# Ensure logs.csv exists with header
LOGFILE="$(dirname "$0")/logs.csv"
if [ ! -f "$LOGFILE" ]; then
  echo "Intent,Duration(min),Websites,Start,Done,Learned,Actions" >> "$LOGFILE"
fi

# Append this session
esc() { printf '%s' "$1" | sed 's/"/""/g'; }

# Only log if there was an actual intention
if [ -n "$intent" ]; then
  echo "Saving session to $LOGFILE"
  printf "\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\"\n" \
    "$(esc "$intent")" \
    "$total_duration" \
    "$(esc "$sites")" \
    "$start_ts" \
    "$(esc "$done_what")" \
    "$(esc "$learned")" \
    "$(esc "$lessons")" \
  >> "$LOGFILE"
else
  echo "No intention provided, not logging this session"
fi

# Restart the script
exec "$0"
