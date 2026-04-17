@echo off
chcp 65001 >nul
REM =============================================================================
REM Work Log Journal - Windows Build Script
REM 產生 WorkLog.exe（Windows 獨立執行檔）
REM =============================================================================

setlocal enabledelayedexpansion

REM 讀取版本號
set /p VERSION=<VERSION
set DIST_NAME=WorkLog_v%VERSION%_Windows
set ARCHIVE_NAME=%DIST_NAME%.zip

echo ============================================
echo  Work Log Journal v%VERSION% - Windows Build
echo ============================================
echo.

REM ── 1. 確認 Python 環境 ────────────────────────────────────────────────────
echo [1/5] 確認 Python 環境...
python --version 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo 錯誤：找不到 python，請確認已安裝 Python 並加入 PATH
    pause
    exit /b 1
)

REM ── 2. 安裝/確認依賴套件 ───────────────────────────────────────────────────
echo [2/5] 安裝依賴套件...
pip install -r requirements.txt --quiet
pip install pyinstaller --quiet

REM ── 3. 清除舊的建置目錄 ────────────────────────────────────────────────────
echo [3/5] 清除舊的建置目錄...
python clean_build.py

REM ── 4. 執行 PyInstaller 建置 ─────────────────────────────────────────────────
echo [4/5] 建置 WorkLog.exe...
pyinstaller --clean worklog.spec
if %ERRORLEVEL% NEQ 0 (
    echo 錯誤：PyInstaller 建置失敗
    pause
    exit /b 1
)

REM ── 5. 封裝成 zip（方便分發）────────────────────────────────────────────────
echo [5/5] 封裝成 %ARCHIVE_NAME%...
powershell -command "Compress-Archive -Path 'dist\WorkLog' -DestinationPath '%ARCHIVE_NAME%' -Force"

echo.
echo ============================================
echo  建置完成！
echo   執行檔:  dist\WorkLog\WorkLog.exe
echo   封裝檔:  %ARCHIVE_NAME%
echo ============================================
echo.
pause
