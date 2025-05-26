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
      local is_first_in_phase="$3"  # New parameter to indicate if this is the first prompt in a phase
      local timeout_seconds=90  # 1.5 minutes
      local max_attempts=10000    # Maximum retries before giving up entirely (never give up!) this is so hacked
      local attempt=1
      
      # Add back instruction to prompt if not the first prompt in the phase
      if [ "$is_first_in_phase" != "true" ]; then
        prompt="$prompt (Type 'back' to go to previous question)"
      fi
      
      while [ $attempt -le $max_attempts ]; do
        
        # Run the dialog and capture the full result
        local result=$(osascript <<EOF
tell application "System Events"
  activate
  set dialogResult to display dialog "$prompt" default answer "$default" buttons {"OK"} default button "OK" with title "Focus Session" giving up after $timeout_seconds
  
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
          echo "Refocus. Recentering dialog..." >&2
          
          # Show notification that dialog timed out only on first attempts
          if [ $attempt -lt 3 ]; then
            osascript -e 'display notification "Your focus session dialog timed out and will reappear" with title "Focus Session" sound name "Glass"'
          fi
          
          # Brief pause before showing again
          sleep 0.3
          
          ((attempt++))
        elif [[ "$result" == RESULT:* ]]; then
          # User responded, extract the actual text
          local user_input="${result#RESULT:}"
          
          # Check if user typed "back" and this isn't the first prompt in the phase
          if [ "$user_input" = "back" ] && [ "$is_first_in_phase" != "true" ]; then
            echo "BACK_REQUESTED"
            return 0
          else
            echo "$user_input"
            return 0
          fi
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

    # Setup phase - handle back navigation within this phase
    while true; do
        # Initial prompts
        intent=$(get_input "What's your intention right now? (Type 'analysis please' to view your focus stats - it will take a sec to load)" "${intent:-}" "true")
        
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
            continue 2  # Continue the outer while loop
        fi
        
        # Duration prompt
        while true; do
            duration_input=$(get_input "How many minutes do you want to focus? (Enter a whole number up to 60 minutes)" "${duration:-25}")
            
            if [ "$duration_input" = "BACK_REQUESTED" ]; then
                break  # Go back to intention prompt
            fi
            
            # Only update duration if not going back
            duration="$duration_input"
            
            # Validate duration is a number
            if ! [[ "$duration" =~ ^[0-9]+$ ]]; then
              echo "Input must be a whole number. Setting to 5 minutes."
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
            
            # Sites prompt
            while true; do
                sites_input=$(get_input "Comma-separated list of sites you'll need (e.g. ex.com)" "${sites:-}")
                
                if [ "$sites_input" = "BACK_REQUESTED" ]; then
                    break  # Go back to duration prompt
                fi
                
                # Only update sites if not going back
                sites="$sites_input"
                
                # If we got here, all setup prompts completed successfully
                break 3  # Break out of all three nested loops
            done
        done
    done

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

    # Stop the Cold Turkey block only after user is done with all extensions
    "$CT_BIN" -stop "Focus-Session"

    # Debrief/Reflection phase - handle back navigation within this phase
    while true; do
        # Extension prompt - only if not already used
        if [ "$extension_used" = false ]; then
            extension_input=$(get_input "Would you like to extend your session? (Enter minutes to extend, max 30 minutes, or leave empty to finish)" "${extension:-}" "true")
            
            # Only update extension if not BACK_REQUESTED
            if [ "$extension_input" != "BACK_REQUESTED" ]; then
                extension="$extension_input"
            fi
            
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
                        
                        # Extend session - restart Cold Turkey and sleep
                        echo "Extending session by $extension minutes..."
                        "$CT_BIN" -start "Focus-Session"
                        
                        # Re-apply whitelist exceptions
                        IFS=',' read -ra DOMAIN_ARRAY <<< "$sites"
                        for domain in "${DOMAIN_ARRAY[@]}"; do
                            trimmed=$(echo "$domain" | xargs)
                            [ -n "$trimmed" ] && "$CT_BIN" -add "Focus-Session" -exception "$trimmed"
                        done
                        
                        total_duration=$((total_duration + extension))
                        extension_used=true
                        
                        # Sleep for the extension duration
                        sleep $((extension * 60))
                        
                        # Stop Cold Turkey again after extension
                        "$CT_BIN" -stop "Focus-Session"
                    fi
                fi
            fi
        fi
        
        while true; do
            # Determine if this is the first prompt in reflection phase
            # It's only first if extension was already used (so extension prompt wasn't shown)
            local is_first_reflection="false"
            if [ "$extension_used" = true ]; then
                is_first_reflection="true"
            fi
            
            done_what_input=$(get_input "What did you get done? Your original intention was: $intent" "${done_what:-}" "$is_first_reflection")
            
            # Handle back navigation
            if [ "$done_what_input" = "BACK_REQUESTED" ]; then
                # Can only go back if extension wasn't used
                if [ "$extension_used" = false ]; then
                    # Clear the extension variable and go back to extension prompt
                    extension=""
                    break  # Go back to extension prompt
                else
                    # Extension was already used, can't go back
                    continue  # Stay on this prompt
                fi
            fi
            
            # Only update done_what if not going back
            done_what="$done_what_input"
            
            while true; do
                learned_input=$(get_input "What did you learn?" "${learned:-}")
                
                if [ "$learned_input" = "BACK_REQUESTED" ]; then
                    break  # Go back to done_what prompt
                fi
                
                # Only update learned if not going back
                learned="$learned_input"
                
                while true; do
                    lessons_input=$(get_input "How can you act on that?" "${lessons:-}")
                    
                    if [ "$lessons_input" = "BACK_REQUESTED" ]; then
                        break  # Go back to learned prompt
                    fi
                    
                    # Only update lessons if not going back
                    lessons="$lessons_input"
                    
                    # If we got here, all reflection prompts completed successfully
                    break 4  # Break out of all loops
                done
            done
        done
    done

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
