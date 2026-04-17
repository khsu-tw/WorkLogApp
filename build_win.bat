@echo off
chcp 65001 >nul
REM =============================================================================
REM Work Log Journal - Windows Build Script
REM Generates WorkLog.exe (Windows standalone executable)
REM =============================================================================

setlocal enabledelayedexpansion

REM Read version number
set /p VERSION=<VERSION
set DIST_NAME=WorkLog_v%VERSION%_Windows
set ARCHIVE_NAME=%DIST_NAME%.zip

echo ============================================
echo  Work Log Journal v%VERSION% - Windows Build
echo ============================================
echo.

REM ── 1. Check Python Environment ─────────────────────────────────────────────
echo [1/5] Checking Python environment...
python --version 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo Error: Python not found. Please install Python and add to PATH
    pause
    exit /b 1
)

REM ── 2. Install/Check Dependencies ───────────────────────────────────────────
echo [2/5] Installing dependencies...
pip install -r requirements.txt --quiet
pip install pyinstaller --quiet

REM ── 3. Clean Old Build Directories ──────────────────────────────────────────
echo [3/5] Cleaning old build directories...
python clean_build.py

REM ── 4. Run PyInstaller Build ─────────────────────────────────────────────────
echo [4/5] Building WorkLog.exe...
pyinstaller --clean worklog.spec
if %ERRORLEVEL% NEQ 0 (
    echo Error: PyInstaller build failed
    pause
    exit /b 1
)

REM ── 5. Package as zip (for distribution) ────────────────────────────────────
echo [5/5] Packaging as %ARCHIVE_NAME%...
powershell -command "Compress-Archive -Path 'dist\WorkLog' -DestinationPath '%ARCHIVE_NAME%' -Force"

echo.
echo ============================================
echo  Build completed!
echo   Executable:  dist\WorkLog\WorkLog.exe
echo   Package:     %ARCHIVE_NAME%
echo ============================================
echo.
pause
