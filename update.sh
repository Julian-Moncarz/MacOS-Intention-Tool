#!/bin/bash

# Intention Tool Updater Script
# This script updates the Intention Tool to the latest version while preserving user data

echo "=== Intention Tool Updater ==="
echo "Updating Intention Tool to the latest version..."

# Check if we're in the intention_tool directory
if [[ ! -f "focus_session.sh" ]]; then
    echo "❌ Error: Please run this script from the intention_tool directory"
    exit 1
fi

# Create a temporary backup directory for user data
echo "Creating temporary backup of user data..."
BACKUP_DIR="/tmp/intention_tool_backup_$(date +%s)"
mkdir -p "$BACKUP_DIR"

# Backup user-generated content (based on .gitignore patterns)
echo "Backing up user data..."

# Backup virtual environment
if [[ -d "venv" ]]; then
    echo "  - Backing up virtual environment..."
    cp -a venv "$BACKUP_DIR/"
fi

# Backup logs and CSV files
if [[ -f "logs.csv" ]]; then
    echo "  - Backing up logs.csv..."
    cp logs.csv "$BACKUP_DIR/"
fi

# Backup any other CSV files
for csv_file in *.csv; do
    if [[ -f "$csv_file" && "$csv_file" != "logs.csv" ]]; then
        echo "  - Backing up $csv_file..."
        cp "$csv_file" "$BACKUP_DIR/"
    fi
done

# Backup focus insights directory
if [[ -d "focus_insights" ]]; then
    echo "  - Backing up focus_insights directory..."
    cp -r focus_insights "$BACKUP_DIR/"
fi

# Backup focus timeline report directory
if [[ -d "focus_timeline_report" ]]; then
    echo "  - Backing up focus_timeline_report directory..."
    cp -r focus_timeline_report "$BACKUP_DIR/"
fi

# Backup .env file if it exists
if [[ -f ".env" ]]; then
    echo "  - Backing up .env file..."
    cp .env "$BACKUP_DIR/"
fi

# Backup any custom configuration files (if they exist)
for config_file in config.json config.yaml config.yml .config; do
    if [[ -f "$config_file" ]]; then
        echo "  - Backing up $config_file..."
        cp "$config_file" "$BACKUP_DIR/"
    fi
done

# Stop the Launch Agent if it's running
echo "Stopping Launch Agent..."
launchctl unload ~/Library/LaunchAgents/com.user.focussession.plist 2>/dev/null || true

# Download and extract the latest version
echo "Downloading latest version..."
curl -L https://github.com/Julian-Moncarz/MacOS-Intention-Tool/archive/main.zip -o /tmp/intention_tool_update.zip

if [[ $? -ne 0 ]]; then
    echo "❌ Error: Failed to download update. Restoring from backup..."
    # Cleanup and exit
    rm -f /tmp/intention_tool_update.zip
    rm -rf "$BACKUP_DIR"
    exit 1
fi

# Extract to temporary directory
echo "Extracting update..."
TEMP_EXTRACT="/tmp/intention_tool_extract_$(date +%s)"
mkdir -p "$TEMP_EXTRACT"
unzip /tmp/intention_tool_update.zip -d "$TEMP_EXTRACT"

if [[ $? -ne 0 ]]; then
    echo "❌ Error: Failed to extract update. Restoring from backup..."
    rm -f /tmp/intention_tool_update.zip
    rm -rf "$TEMP_EXTRACT"
    rm -rf "$BACKUP_DIR"
    exit 1
fi

# Update repository files (preserve user data)
echo "Updating repository files..."

# Get the current directory
CURRENT_DIR=$(pwd)

# Copy new files, excluding user data directories
cd "$TEMP_EXTRACT/MacOS-Intention-Tool-main"

# Update Python scripts
for py_file in *.py; do
    if [[ -f "$py_file" ]]; then
        echo "  - Updating $py_file..."
        cp "$py_file" "$CURRENT_DIR/"
    fi
done

# Update shell scripts
for sh_file in *.sh; do
    if [[ -f "$sh_file" ]]; then
        echo "  - Updating $sh_file..."
        cp "$sh_file" "$CURRENT_DIR/"
        chmod +x "$CURRENT_DIR/$sh_file"
    fi
done

# Update requirements.txt
if [[ -f "requirements.txt" ]]; then
    echo "  - Updating requirements.txt..."
    cp requirements.txt "$CURRENT_DIR/"
fi

# Update README files
for readme_file in README*.md; do
    if [[ -f "$readme_file" ]]; then
        echo "  - Updating $readme_file..."
        cp "$readme_file" "$CURRENT_DIR/"
    fi
done

# Update LICENSE
if [[ -f "LICENSE" ]]; then
    echo "  - Updating LICENSE..."
    cp LICENSE "$CURRENT_DIR/"
fi

# Update tests directory
if [[ -d "tests" ]]; then
    echo "  - Updating tests directory..."
    rm -rf "$CURRENT_DIR/tests"
    cp -r tests "$CURRENT_DIR/"
fi

# Update .gitignore
if [[ -f ".gitignore" ]]; then
    echo "  - Updating .gitignore..."
    cp .gitignore "$CURRENT_DIR/"
fi

cd "$CURRENT_DIR"

# Restore user data from backup
echo "Restoring user data..."

# Restore virtual environment
if [[ -d "$BACKUP_DIR/venv" ]]; then
    echo "  - Restoring virtual environment..."
    rm -rf venv
    cp -r "$BACKUP_DIR/venv" ./
fi

# Restore logs and CSV files
if [[ -f "$BACKUP_DIR/logs.csv" ]]; then
    echo "  - Restoring logs.csv..."
    cp "$BACKUP_DIR/logs.csv" ./
fi

# Restore other CSV files
for csv_file in "$BACKUP_DIR"/*.csv; do
    if [[ -f "$csv_file" ]]; then
        filename=$(basename "$csv_file")
        if [[ "$filename" != "logs.csv" ]]; then
            echo "  - Restoring $filename..."
            cp "$csv_file" ./
        fi
    fi
done

# Restore focus insights directory
if [[ -d "$BACKUP_DIR/focus_insights" ]]; then
    echo "  - Restoring focus_insights directory..."
    rm -rf focus_insights
    cp -r "$BACKUP_DIR/focus_insights" ./
fi

# Restore focus timeline report directory
if [[ -d "$BACKUP_DIR/focus_timeline_report" ]]; then
    echo "  - Restoring focus_timeline_report directory..."
    rm -rf focus_timeline_report
    cp -r "$BACKUP_DIR/focus_timeline_report" ./
fi

# Restore .env file
if [[ -f "$BACKUP_DIR/.env" ]]; then
    echo "  - Restoring .env file..."
    cp "$BACKUP_DIR/.env" ./
fi

# Restore configuration files
for config_file in "$BACKUP_DIR"/config.* "$BACKUP_DIR"/.config; do
    if [[ -f "$config_file" ]]; then
        filename=$(basename "$config_file")
        echo "  - Restoring $filename..."
        cp "$config_file" ./
    fi
done

# Update Python dependencies (if virtual environment exists)
if [[ -d "venv" ]]; then
    echo "Updating Python dependencies..."
    source venv/bin/activate
    pip install -r requirements.txt --upgrade
    deactivate
fi

# Restart the Launch Agent
echo "Restarting Launch Agent..."
launchctl load ~/Library/LaunchAgents/com.user.focussession.plist

# Cleanup temporary files
echo "Cleaning up temporary files..."
rm -f /tmp/intention_tool_update.zip
rm -rf "$TEMP_EXTRACT"
rm -rf "$BACKUP_DIR"

echo ""
echo "✅ Update complete! Your Intention Tool has been updated to the latest version."
echo "📊 All your user data (logs, insights, virtual environment) has been preserved."
echo "🚀 The tool is now running with the latest updates."
echo ""
echo "To verify the update worked correctly, you can check the latest features in the README files."
