#!/bin/bash

echo "Configuring daily automatic updates"

# Get the absolute path of the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UPDATE_SCRIPT="${SCRIPT_DIR}/update.sh"

# Load .env.local if available (one level up)
if [ -f "${SCRIPT_DIR}/../.env.local" ]; then
    # shellcheck disable=SC1091
    source "${SCRIPT_DIR}/../.env.local"
fi

# Check that the update script exists
if [ ! -f "${UPDATE_SCRIPT}" ]; then
    echo "✗ Error: Script ${UPDATE_SCRIPT} does not exist"
    exit 1
fi

# Make the update script executable
chmod +x "${UPDATE_SCRIPT}"

# Detect operating system
OS="$(uname -s)"
case "${OS}" in
    Linux*)     MACHINE=Linux;;
    Darwin*)    MACHINE=Mac;;
    CYGWIN*)    MACHINE=Windows;;
    MINGW*)     MACHINE=Windows;;
    MSYS*)      MACHINE=Windows;;
    *)          MACHINE="UNKNOWN:${OS}"
esac

echo "Detected system: ${MACHINE}"

# Schedule time defaults (can be overridden in .env.local)
AUTO_UPDATE_HOUR=${AUTO_UPDATE_HOUR:-21}
AUTO_UPDATE_MINUTE=${AUTO_UPDATE_MINUTE:-0}

# Formatted time strings
SCHEDULE_HHMM=$(printf "%02d:%02d" "${AUTO_UPDATE_HOUR}" "${AUTO_UPDATE_MINUTE}")

if [ "${MACHINE}" = "Mac" ]; then
    echo "Configuring launchd for macOS..."
    
    PLIST_FILE="$HOME/Library/LaunchAgents/com.user.packages.update.plist"
    
    # Create directory if needed
    mkdir -p "$HOME/Library/LaunchAgents"
    
    # Create the plist file
    cat > "${PLIST_FILE}" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.packages.update</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>${UPDATE_SCRIPT}</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>${AUTO_UPDATE_HOUR}</integer>
        <key>Minute</key>
        <integer>${AUTO_UPDATE_MINUTE}</integer>
    </dict>
    <key>StandardOutPath</key>
    <string>${SCRIPT_DIR}/update.log</string>
    <key>StandardErrorPath</key>
    <string>${SCRIPT_DIR}/update_error.log</string>
</dict>
</plist>
EOF

    # Load the service
    launchctl unload "${PLIST_FILE}" 2>/dev/null || true
    launchctl load "${PLIST_FILE}"
    
    echo "✓ Scheduled task created: ${PLIST_FILE}"
    echo "✓ Updates will run daily at ${SCHEDULE_HHMM}"
    echo "  Logs: ${SCRIPT_DIR}/update.log"
    echo ""
    echo "To disable: launchctl unload ${PLIST_FILE}"
    echo "To enable: launchctl load ${PLIST_FILE}"

elif [ "${MACHINE}" = "Windows" ]; then
    echo "Configuring Task Scheduler for Windows..."
    
    # Create a scheduled task with schtasks
    TASK_NAME="PackagesAutoUpdate"
    
    # Remove the task if it already exists
    schtasks.exe //Delete //TN "${TASK_NAME}" //F 2>/dev/null || true
    
    # Create the new task
    schtasks.exe //Create //TN "${TASK_NAME}" \
        //TR "\"C:\\Program Files\\Git\\bin\\bash.exe\" \"${UPDATE_SCRIPT}\"" \
        //SC DAILY //ST ${SCHEDULE_HHMM} //F
    
    echo "✓ Scheduled task created: ${TASK_NAME}"
    echo "✓ Updates will run daily at ${SCHEDULE_HHMM}"
    echo ""
    echo "To disable: schtasks //Change //TN \"${TASK_NAME}\" //DISABLE"
    echo "To enable: schtasks //Change //TN \"${TASK_NAME}\" //ENABLE"
    echo "To delete: schtasks //Delete //TN \"${TASK_NAME}\" //F"

elif [ "${MACHINE}" = "Linux" ]; then
    echo "Configuring cron for Linux..."
    
    # Create a cron line
    CRON_LINE="${AUTO_UPDATE_MINUTE} ${AUTO_UPDATE_HOUR} * * * ${UPDATE_SCRIPT} >> ${SCRIPT_DIR}/update.log 2>&1"
    
    # Check if the line already exists
    (crontab -l 2>/dev/null | grep -v "${UPDATE_SCRIPT}"; echo "${CRON_LINE}") | crontab -
    
    echo "✓ Cron job created"
    echo "✓ Updates will run daily at ${SCHEDULE_HHMM}"
    echo "  Logs: ${SCRIPT_DIR}/update.log"
    echo ""
    echo "To view cron jobs: crontab -l"
    echo "To edit: crontab -e"

else
    echo "✗ Unsupported operating system: ${MACHINE}"
    exit 1
fi

echo ""
echo "Configuration completed successfully!"
echo "You can test manually with: bash ${UPDATE_SCRIPT}"
