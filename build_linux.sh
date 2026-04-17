#!/bin/bash
# =============================================================================
# Work Log Journal - Linux/Ubuntu Build Script
# 產生 WorkLog（Linux 獨立執行檔）
# =============================================================================

set -e  # 任何指令失敗則立即中止

VERSION=$(cat VERSION)
DIST_NAME="WorkLog_v${VERSION}_Linux"
ARCHIVE_NAME="${DIST_NAME}.tar.gz"

echo "============================================"
echo " Work Log Journal v${VERSION} - Linux Build"
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
echo "[4/5] 建置 WorkLog..."
pyinstaller --clean worklog_linux.spec

# ── 5. 封裝成 tar.gz（方便分發）──────────────────────────────────────────────
echo "[5/5] 封裝成 ${ARCHIVE_NAME}..."
cd dist
tar -czf "../${ARCHIVE_NAME}" WorkLog
cd ..

echo ""
echo "============================================"
echo " 建置完成！"
echo "  執行檔:   dist/WorkLog/WorkLog"
echo "  封裝檔:   ${ARCHIVE_NAME}"
echo "============================================"
echo ""
echo "使用方式："
echo "  1. 解壓縮: tar -xzf ${ARCHIVE_NAME}"
echo "  2. 執行:   cd WorkLog && ./WorkLog"
echo "============================================"
