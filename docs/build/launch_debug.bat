@echo off
REM Work Log Journal - Debug Launcher for Windows
REM This launcher shows console output and error messages

echo ====================================
echo Work Log Journal - Debug Mode
echo ====================================
echo.
echo Starting application...
echo If you see any errors, please take a screenshot
echo and report them at: https://github.com/khsu-tw/WorkLogApp/issues
echo.
echo Press Ctrl+C to stop the application
echo ====================================
echo.

REM Run the executable and keep console open
WorkLog.exe

echo.
echo ====================================
echo Application closed
echo ====================================
echo.
pause
