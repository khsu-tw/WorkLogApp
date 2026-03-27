@echo off
REM ============================================================================
REM Work Log Journal - Windows Build Script
REM ============================================================================
REM This script packages the application into a standalone Windows executable.
REM
REM Prerequisites:
REM   1. Python 3.10+ installed
REM   2. Run: pip install -r requirements.txt
REM   3. Run: pip install pyinstaller
REM
REM Usage:
REM   build.bat
REM ============================================================================

echo.
echo ========================================
echo   Work Log Journal - Build Script
echo ========================================
echo.

REM Check if Python is available
python --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Python is not installed or not in PATH.
    pause
    exit /b 1
)

REM Check if PyInstaller is available
python -c "import PyInstaller" >nul 2>&1
if errorlevel 1 (
    echo [INFO] Installing PyInstaller...
    pip install pyinstaller
)

REM Install dependencies
echo [INFO] Installing dependencies...
pip install -r requirements.txt

REM Clean previous build
echo [INFO] Cleaning previous build...
if exist "dist" rmdir /s /q dist
if exist "build" rmdir /s /q build

REM Build the executable
echo [INFO] Building executable...
pyinstaller --clean worklog.spec

if errorlevel 1 (
    echo.
    echo [ERROR] Build failed!
    pause
    exit /b 1
)

echo.
echo ========================================
echo   Build Complete!
echo ========================================
echo.
echo Output: dist\WorkLog\WorkLog.exe
echo.
echo To distribute, copy the entire "dist\WorkLog" folder.
echo.
pause
