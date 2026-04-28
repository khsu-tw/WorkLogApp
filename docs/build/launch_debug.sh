#!/bin/bash
# Work Log Journal - Debug Launcher for Linux/macOS
# This launcher shows console output and error messages

echo "===================================="
echo " Work Log Journal - Debug Mode"
echo "===================================="
echo ""
echo "Starting application..."
echo "If you see any errors, please report them at:"
echo "https://github.com/khsu-tw/WorkLogApp/issues"
echo ""
echo "Press Ctrl+C to stop the application"
echo "===================================="
echo ""

# Determine the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Run the executable
if [ -f "$SCRIPT_DIR/WorkLog" ]; then
    "$SCRIPT_DIR/WorkLog"
elif [ -f "$SCRIPT_DIR/WorkLogServer" ]; then
    "$SCRIPT_DIR/WorkLogServer"
elif [ -d "$SCRIPT_DIR/WorkLog.app" ]; then
    "$SCRIPT_DIR/WorkLog.app/Contents/MacOS/WorkLog"
else
    echo "ERROR: WorkLog/WorkLogServer executable not found!"
    echo ""
fi

echo ""
echo "===================================="
echo " Application closed"
echo "===================================="
echo ""
read -p "Press Enter to exit..."
