#!/bin/bash
#
# WorkLogServer 自動更新腳本
# ========================================
# 功能：
#   - 備份舊版本
#   - 停止 systemd 服務
#   - 覆蓋更新執行檔
#   - 保護配置文件（.env, *.db）
#   - 重啟服務並驗證
#   - 失敗時自動回滾
#
# 使用方法：
#   ./update_worklog_server.sh
#
# 或指定來源目錄：
#   ./update_worklog_server.sh /path/to/new/WorkLogServer
#

set -e  # 遇到錯誤立即退出

# ── 配置區 ──────────────────────────────────────────────────────────────

# 腳本所在目錄（用於計算相對路徑）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 目標目錄（systemd 服務指向的位置）
TARGET_DIR="/home/khsu/worklog-server"

# 來源目錄（新版本位置）
# v1.0.5: 修正 - 使用腳本所在目錄而非 $HOME，避免 sudo 時路徑錯誤
SOURCE_DIR="${1:-${SCRIPT_DIR}/dist/WorkLogServer}"

# 服務名稱
SERVICE_NAME="worklog.service"

# 備份目錄
BACKUP_DIR="/home/khsu/worklog-server-backups"

# 需要保護的文件（不會被覆蓋）
PROTECTED_FILES=(
    ".env"
    "*.db"
    "*.db-shm"
    "*.db-wal"
    "*.sqlite"
    "config.json"
)

# 顏色輸出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ── 函數定義 ──────────────────────────────────────────────────────────────

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 檢查前置條件
check_prerequisites() {
    log_info "檢查前置條件..."

    # 檢查來源目錄是否存在
    if [ ! -d "$SOURCE_DIR" ]; then
        log_error "來源目錄不存在: $SOURCE_DIR"
        exit 1
    fi

    # 檢查來源目錄是否有 WorkLogServer 執行檔
    if [ ! -f "$SOURCE_DIR/WorkLogServer" ]; then
        log_error "找不到執行檔: $SOURCE_DIR/WorkLogServer"
        exit 1
    fi

    # 檢查目標目錄是否存在
    if [ ! -d "$TARGET_DIR" ]; then
        log_error "目標目錄不存在: $TARGET_DIR"
        exit 1
    fi

    # 檢查 systemd 服務是否存在
    if ! systemctl list-unit-files | grep -q "^${SERVICE_NAME}"; then
        log_warning "找不到服務: $SERVICE_NAME"
        log_warning "將繼續執行但不會操作 systemd 服務"
        SERVICE_EXISTS=false
    else
        SERVICE_EXISTS=true
    fi

    log_success "前置條件檢查完成"
}

# 創建備份
create_backup() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_path="$BACKUP_DIR/worklog-server.$timestamp"

    log_info "創建備份到: $backup_path"

    # 創建備份目錄
    mkdir -p "$BACKUP_DIR"

    # 複製整個目錄
    cp -r "$TARGET_DIR" "$backup_path"

    # 保存備份路徑供回滾使用
    LAST_BACKUP="$backup_path"

    log_success "備份完成"

    # 清理舊備份（保留最近 5 個）
    log_info "清理舊備份..."
    cd "$BACKUP_DIR"
    ls -t | tail -n +6 | xargs -r rm -rf
    log_success "保留最近 5 個備份"
}

# 停止服務
stop_service() {
    if [ "$SERVICE_EXISTS" = true ]; then
        log_info "停止服務: $SERVICE_NAME"
        sudo systemctl stop "$SERVICE_NAME"

        # 等待服務完全停止
        sleep 2

        if systemctl is-active --quiet "$SERVICE_NAME"; then
            log_error "服務停止失敗"
            exit 1
        fi

        log_success "服務已停止"
    else
        log_warning "跳過服務停止（服務不存在）"
    fi
}

# 備份受保護的文件
backup_protected_files() {
    log_info "備份受保護的文件..."

    TEMP_PROTECTED_DIR=$(mktemp -d)

    for pattern in "${PROTECTED_FILES[@]}"; do
        # 使用 find 而不是 glob 來避免 nullglob 問題
        while IFS= read -r file; do
            if [ -f "$TARGET_DIR/$file" ]; then
                local dir_path=$(dirname "$file")
                mkdir -p "$TEMP_PROTECTED_DIR/$dir_path"
                cp -p "$TARGET_DIR/$file" "$TEMP_PROTECTED_DIR/$file"
                log_info "  已備份: $file"
            fi
        done < <(cd "$TARGET_DIR" && find . -name "$pattern" -type f | sed 's|^\./||')
    done

    log_success "受保護文件已備份到臨時目錄"
}

# 恢復受保護的文件
restore_protected_files() {
    log_info "恢復受保護的文件..."

    if [ -d "$TEMP_PROTECTED_DIR" ]; then
        cp -rp "$TEMP_PROTECTED_DIR/"* "$TARGET_DIR/" 2>/dev/null || true
        rm -rf "$TEMP_PROTECTED_DIR"
        log_success "受保護文件已恢復"
    fi
}

# 複製新版本
copy_new_version() {
    log_info "複製新版本..."
    log_info "  來源: $SOURCE_DIR"
    log_info "  目標: $TARGET_DIR"

    # 複製所有文件
    cp -r "$SOURCE_DIR/"* "$TARGET_DIR/"

    # 設置執行權限
    chmod +x "$TARGET_DIR/WorkLogServer"

    # 確保所有者正確
    sudo chown -R khsu:khsu "$TARGET_DIR"

    log_success "新版本已複製"
}

# 啟動服務
start_service() {
    if [ "$SERVICE_EXISTS" = true ]; then
        log_info "啟動服務: $SERVICE_NAME"
        sudo systemctl start "$SERVICE_NAME"

        # 等待服務啟動
        sleep 3

        log_success "服務已啟動"
    else
        log_warning "跳過服務啟動（服務不存在）"
    fi
}

# 驗證服務
verify_service() {
    log_info "驗證服務狀態..."

    if [ "$SERVICE_EXISTS" = true ]; then
        # 檢查服務狀態
        if systemctl is-active --quiet "$SERVICE_NAME"; then
            log_success "服務運行正常"

            # 顯示服務狀態
            sudo systemctl status "$SERVICE_NAME" --no-pager -l | head -15

            # 檢查 port 5000
            sleep 2
            if curl -s http://localhost:5000 > /dev/null 2>&1; then
                log_success "HTTP 端點響應正常 (http://localhost:5000)"
                return 0
            else
                log_warning "HTTP 端點無響應，但服務已啟動"
                return 0
            fi
        else
            log_error "服務啟動失敗"

            # 顯示錯誤日誌
            log_error "最近的錯誤日誌:"
            sudo journalctl -u "$SERVICE_NAME" -n 20 --no-pager

            return 1
        fi
    else
        log_warning "跳過服務驗證（服務不存在）"
        return 0
    fi
}

# 回滾到上一個版本
rollback() {
    log_error "更新失敗，開始回滾..."

    if [ -z "$LAST_BACKUP" ]; then
        log_error "找不到備份，無法回滾"
        exit 1
    fi

    # 停止服務
    if [ "$SERVICE_EXISTS" = true ]; then
        sudo systemctl stop "$SERVICE_NAME" 2>/dev/null || true
    fi

    # 恢復備份
    log_info "恢復備份: $LAST_BACKUP"
    rm -rf "$TARGET_DIR"
    cp -r "$LAST_BACKUP" "$TARGET_DIR"

    # 重啟服務
    if [ "$SERVICE_EXISTS" = true ]; then
        sudo systemctl start "$SERVICE_NAME"
        log_success "已回滾到上一個版本"
    fi

    exit 1
}

# 顯示版本信息
show_version_info() {
    log_info "檢查版本信息..."

    # 嘗試從服務日誌獲取版本
    if [ "$SERVICE_EXISTS" = true ]; then
        local version=$(sudo journalctl -u "$SERVICE_NAME" -n 50 --no-pager | grep -i "Work Log Journal v" | tail -1)
        if [ -n "$version" ]; then
            log_success "當前版本: $version"
        fi
    fi
}

# ── 主程序 ──────────────────────────────────────────────────────────────

main() {
    echo ""
    echo "=========================================="
    echo "  WorkLogServer 自動更新腳本"
    echo "=========================================="
    echo ""

    # 檢查前置條件
    check_prerequisites

    echo ""
    log_info "準備更新..."
    log_info "  來源目錄: $SOURCE_DIR"
    log_info "  目標目錄: $TARGET_DIR"
    log_info "  服務名稱: $SERVICE_NAME"
    echo ""

    # 詢問確認
    read -p "確定要繼續更新嗎? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_warning "更新已取消"
        exit 0
    fi

    echo ""

    # 設置錯誤處理：任何失敗都執行回滾
    trap rollback ERR

    # 執行更新流程
    create_backup
    stop_service
    backup_protected_files
    copy_new_version
    restore_protected_files
    start_service

    # 驗證
    if verify_service; then
        echo ""
        log_success "=========================================="
        log_success "  更新成功完成!"
        log_success "=========================================="
        echo ""
        show_version_info
        echo ""
        log_info "訪問地址:"
        log_info "  本機: http://localhost:5000"
        log_info "  區網: http://$(hostname -I | awk '{print $1}'):5000"
        echo ""
        log_info "備份位置: $LAST_BACKUP"
        echo ""
    else
        rollback
    fi
}

# 執行主程序
main "$@"
