#!/bin/bash
# =============================================================================
# Work Log Journal - macOS Build Script
# 產生 WorkLog.app（macOS 獨立執行檔）
# =============================================================================

set -e  # 任何指令失敗則立即中止

VERSION=$(cat VERSION)
DIST_NAME="WorkLog_v${VERSION}_macOS"
ARCHIVE_NAME="${DIST_NAME}.zip"

echo "============================================"
echo " Work Log Journal v${VERSION} - macOS Build"
echo "============================================"
echo ""

# ── 1. 確認 Python 環境 ──────────────────────────────────────────────────────
echo "[1/5] 確認 Python 環境..."
python3 --version || { echo "錯誤：找不到 python3"; exit 1; }

# ── 2. 安裝/確認依賴套件 ─────────────────────────────────────────────────────
echo "[2/5] 安裝依賴套件..."
pip3 install -r requirements.txt --quiet
pip3 install pyinstaller --quiet

# ── 3. 清除舊的建置目錄 ──────────────────────────────────────────────────────
echo "[3/5] 清除舊的建置目錄..."
python3 clean_build.py

# ── 4. 執行 PyInstaller 建置 ──────────────────────────────────────────────────
echo "[4/5] 建置 WorkLog.app..."
pyinstaller --clean worklog_mac.spec

# ── 5. 封裝成 zip（方便分發）─────────────────────────────────────────────────
echo "[5/5] 封裝成 ${ARCHIVE_NAME}..."
cd dist
zip -r "../${ARCHIVE_NAME}" "WorkLog.app" --quiet
cd ..

echo ""
echo "============================================"
echo " 建置完成！"
echo "  App:     dist/WorkLog.app"
echo "  封裝檔:  ${ARCHIVE_NAME}"
echo "============================================"
