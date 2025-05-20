#!/usr/bin/env bash

# ~/.focus_tools/focus_session.sh

# 1. Lockfile guard
LOCKFILE=/tmp/focus_session.lock
if [ -e "$LOCKFILE" ]; then
  pid=$(<"$LOCKFILE")
  if kill -0 "$pid" 2>/dev/null; then
    echo "focus_session.sh is already running (PID $pid)" >&2
    exit 1
  else
    rm -f "$LOCKFILE"
  fi
fi
echo $$ > "$LOCKFILE"

# 2. Cold Turkey Blocker CLI
CT_BIN="/Applications/Cold Turkey Blocker.app/Contents/MacOS/Cold Turkey Blocker"

# Define input function using a simpler AppleScript approach
get_input() {
  local prompt="$1" default="$2"
  local result
  
  # Create a temporary AppleScript file for better reliability
  local tmp_script=$(mktemp)
  
  # Write the AppleScript to the temporary file
  cat > "$tmp_script" << EOT
tell application "System Events"
  activate
  set theResponse to display dialog "$prompt" default answer "$default" buttons {"OK"} default button "OK"
  set theText to text returned of theResponse
  return theText
end tell
EOT
  
  # Execute the AppleScript file
  result=$(osascript "$tmp_script" 2>/dev/null || echo "")
  local status=$?
  
  # Clean up the temporary file
  rm -f "$tmp_script"
  
  # If we got a result, return it
  if [ -n "$result" ]; then
    echo "$result"
    return 0
  fi
  
  # Return empty string for canceled dialogs
  echo ""
  return 0
}

# 3. Initial prompts
intent=$(get_input "What's your intention right now? (Type 'analysis please' to view your focus stats)" "")

# Check if the user wants to run analysis
if [[ "$intent" == *"analysis please"* ]]; then
    echo "Generating your focus session analysis..."
    # Run the analysis script
    python3 "$(dirname "$0")/show_analysis.py"
    echo "Analysis complete! Check your browser for the results."
    exit 0
fi

duration=$(get_input "How long will it take? (minutes)"                          "")
sites=$(get_input "Comma-separated list of sites you'll need (e.g. ex.com)"     "")

# 4. Timestamp
start_ts=$(date '+%Y-%m-%d %H:%M:%S')

# 5. Start the Cold Turkey block
"$CT_BIN" -start "Focus-Session"

# 6. Whitelist exceptions
IFS=',' read -ra DOMAIN_ARRAY <<< "$sites"
for domain in "${DOMAIN_ARRAY[@]}"; do
  trimmed=$(echo "$domain" | xargs)
  [ -n "$trimmed" ] && "$CT_BIN" -add "Focus-Session" -exception "$trimmed"
done

# 7. Wait out the timer
sleep $(( duration * 60 ))

# 8. Extension option
total_duration=$duration
while true; do
  extension=$(get_input "Would you like to extend your session? (Enter minutes to extend, or leave empty to finish)" "")
  
  # If empty or not a number, break the loop
  if [[ -z "$extension" ]] || ! [[ "$extension" =~ ^[0-9]+$ ]]; then
    break
  fi
  
  # Extend session
  echo "Extending session by $extension minutes..."
  total_duration=$((total_duration + extension))
  
  # Sleep for the extension duration
  sleep $((extension * 60))
done

# 9. Stop the Cold Turkey block only after user is done with all extensions
"$CT_BIN" -stop "Focus-Session"

# 10. Debrief prompts
done_what=$(get_input "What did you get done? Your original intention was: $intent" "")
learned=$(get_input "What did you learn?"    "")
lessons=$(get_input "How can you act on that?"           "")

# 11. Ensure logs.csv exists with header
LOGFILE="$(dirname "$0")/logs.csv"
if [ ! -f "$LOGFILE" ]; then
  echo "Intent,Duration(min),Websites,Start,Done,Learned,Actions" >> "$LOGFILE"
fi

# 12. Append this session
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

# 13. Cleanup lockfile
rm -f "$LOCKFILE"

# 14. Restart the script
  exec "$0"
