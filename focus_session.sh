#!/usr/bin/env bash

# ~/.focus_tools/focus_session.sh

# Simple lockfile mechanism
LOCKFILE="/tmp/focus_session.lock"

# Main execution loop
while true; do
    # Check if another instance is running
    if [ -e "$LOCKFILE" ]; then
        # Check if the process is still running
        LOCK_PID=$(cat "$LOCKFILE" 2>/dev/null)
        if [ -n "$LOCK_PID" ] && ps -p "$LOCK_PID" >/dev/null 2>&1; then
            # Show a notification if another instance is running
            osascript -e 'display notification "A focus session is already running" with title "Focus Session"'
            exit 1
        else
            # Stale lock file from crashed process, remove it
            rm -f "$LOCKFILE"
        fi
    fi

    # Create lock file with our PID
    echo $$ > "$LOCKFILE"

    # Clean up the lock file on exit
    cleanup() {
        rm -f "$LOCKFILE"
    }

    # Set up trap to ensure cleanup happens on script exit
    trap cleanup EXIT

    # Cold Turkey Blocker CLI
    CT_BIN="/Applications/Cold Turkey Blocker.app/Contents/MacOS/Cold Turkey Blocker"
    # Check if Cold Turkey is installed
    if [ ! -f "$CT_BIN" ]; then
        osascript -e 'display dialog "Cold Turkey Blocker not found. Website blocking will be disabled." buttons {"OK"} default button "OK" with title "Warning"'
        CT_BIN=":"  # no-op command if Cold Turkey not found
    fi

    # Define an input function with timeout and retry capability
    get_input() {
      local prompt="$1" 
      local default="$2"
      local timeout_seconds=90  # 1.5 minutes
      local max_attempts=10     # Maximum retries before giving up entirely
      local attempt=1
      
      while [ $attempt -le $max_attempts ]; do
        # Add attempt number to prompt if retrying
        local display_prompt="$prompt"
        if [ $attempt -gt 1 ]; then
          display_prompt="[Attempt $attempt] $prompt"
        fi
        
        # Run the dialog and capture the full result
        local result=$(osascript <<EOF
tell application "System Events"
  activate
  set dialogResult to display dialog "$display_prompt" default answer "$default" buttons {"OK"} default button "OK" with title "Focus Session" giving up after $timeout_seconds
  
  if gave up of dialogResult then
    return "TIMEOUT:true"
  else
    return "RESULT:" & text returned of dialogResult
  end if
end tell
EOF
        )
        
        # Check if dialog timed out
        if [[ "$result" == "TIMEOUT:true" ]]; then
          echo "Dialog timed out (attempt $attempt/$max_attempts). Showing again..." >&2
          
          # Show notification that dialog timed out
          osascript -e 'display notification "Your focus session dialog timed out and will reappear" with title "Focus Session" sound name "Glass"'
          
          # Brief pause before showing again
          sleep 2
          
          ((attempt++))
        elif [[ "$result" == RESULT:* ]]; then
          # User responded, extract the actual text
          echo "${result#RESULT:}"
          return 0
        else
          # Some other error occurred
          echo ""
          return 1
        fi
      done
      
      # Max attempts reached
      echo "Dialog timed out too many times. Exiting." >&2
      echo ""
      return 1
    }

    # Initial prompts
    intent=$(get_input "What's your intention right now? (Type 'analysis please' to view your focus stats - it will take a sec to load)" "")

    # Check if the user wants to run analysis
    if [[ "$intent" == *"analysis please"* ]]; then
        echo "Generating your focus session analysis..."
        
        # Start the Python script in background
        python3 "$(dirname "$0")/show_analysis.py" > /tmp/focus_analysis.log 2>&1 &
        ANALYSIS_PID=$!
        
        echo "Analysis started in background (PID: $ANALYSIS_PID). Check your browser for results shortly."
        echo "Monitor progress with: tail -f /tmp/focus_analysis.log"
        
        # Clean up lock file before continuing the loop
        rm -f "$LOCKFILE"
        
        # Continue to next iteration of the main loop
        continue
    fi

    # Get duration and validate it's a positive number and not greater than 60
    duration=$(get_input "How long will it take? (minutes, whole numbers only, max 60 minutes)" "")
    # Validate duration is a number
    if ! [[ "$duration" =~ ^[0-9]+$ ]]; then
      echo "Invalid duration. Setting to default of 5 minutes."
      duration=5
    fi
    # Ensure duration is positive and not greater than 60
    if [ "$duration" -le 0 ]; then
      echo "Duration must be positive. Setting to 5 minutes."
      duration=5
    elif [ "$duration" -gt 60 ]; then
      echo "Duration capped at 60 minutes."
      duration=60
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

    # Extension option - only one extension allowed, max 30 minutes
    total_duration=$duration
    # Flag to track if we've already extended
    extension_used=false

    if [ "$extension_used" = false ]; then
      extension=$(get_input "Would you like to extend your session? (Enter minutes to extend, max 30 minutes, or leave empty to finish)" "")
      
      # If empty, skip extension
      if [[ -z "$extension" ]]; then
        echo "No extension requested."
      else
        # Validate extension is a number
        if ! [[ "$extension" =~ ^[0-9]+$ ]]; then
          echo "Invalid extension time. No extension applied."
        else
          # Ensure extension is positive and not greater than 30
          if [ "$extension" -le 0 ]; then
            echo "Extension time must be positive. No extension applied."
          else
            # Cap extension at 30 minutes
            if [ "$extension" -gt 30 ]; then
              echo "Extension time capped at 30 minutes."
              extension=30
            fi
            
            # Extend session
            echo "Extending session by $extension minutes..."
            total_duration=$((total_duration + extension))
            extension_used=true
            
            # Sleep for the extension duration
            sleep $((extension * 60))
          fi
        fi
      fi
    fi

    # Stop the Cold Turkey block only after user is done with all extensions
    "$CT_BIN" -stop "Focus-Session"

    # Debrief prompts
    done_what=$(get_input "What did you get done? Your original intention was: $intent" "")
    learned=$(get_input "What did you learn?"    "")
    lessons=$(get_input "How can you act on that?"           "")

    # Ensure logs.csv exists with header and is writable
    LOGFILE="$(dirname "$0")/logs.csv"
    LOGFILE_DIR=$(dirname "$LOGFILE")

    # Ensure directory exists
    mkdir -p "$LOGFILE_DIR"

    # Check if we can write to the log file
    if ! touch "$LOGFILE" 2>/dev/null; then
        osascript -e 'display dialog "Cannot write to log file. Check permissions." buttons {"OK"} with title "Error"'
        exit 1
    fi

    # Add header if file is empty or doesn't exist
    if [ ! -s "$LOGFILE" ]; then
        echo "Intent,Duration(min),Websites,Start,Done,Learned,Actions" > "$LOGFILE" || {
            osascript -e 'display dialog "Failed to write to log file." buttons {"OK"} with title "Error"'
            exit 1
        }
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

    # Clean up lock file before continuing the loop
    rm -f "$LOCKFILE"
    
    # Loop will automatically restart here
done
