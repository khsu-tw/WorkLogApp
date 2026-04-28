# WorkLogServer 更新指南

本指南說明如何使用自動更新腳本來更新 Raspberry Pi 上運行的 WorkLogServer。

## 📋 目錄

- [快速開始](#快速開始)
- [腳本功能](#腳本功能)
- [使用方法](#使用方法)
- [手動更新](#手動更新)
- [故障排除](#故障排除)
- [回滾操作](#回滾操作)

## 🚀 快速開始

### 1. 複製更新腳本到 Raspberry Pi

```bash
# 從 Windows 複製到 Raspberry Pi（在 Windows PowerShell 執行）
scp update_worklog_server.sh khsu@192.168.0.105:~/

# 或在 Raspberry Pi 上直接下載
wget https://raw.githubusercontent.com/khsu-tw/WorkLogApp/main/update_worklog_server.sh
```

### 2. 設置執行權限

```bash
chmod +x ~/update_worklog_server.sh
```

### 3. 執行更新

```bash
# 使用預設來源目錄
./update_worklog_server.sh

# 或指定自訂來源目錄
./update_worklog_server.sh /path/to/new/WorkLogServer
```

## ✨ 腳本功能

自動更新腳本 (`update_worklog_server.sh`) 包含以下功能：

### 核心功能
- ✅ **自動備份**：更新前自動備份舊版本
- ✅ **服務管理**：自動停止/啟動 systemd 服務
- ✅ **文件保護**：保護配置文件和資料庫不被覆蓋
- ✅ **版本驗證**：更新後自動驗證服務運行狀態
- ✅ **自動回滾**：失敗時自動恢復到上一個版本
- ✅ **備份管理**：自動清理舊備份（保留最近 5 個）

### 受保護的文件
腳本不會覆蓋以下文件：
- `.env` - 環境配置文件
- `*.db` - SQLite 資料庫文件
- `*.sqlite` - SQLite 資料庫文件
- `config.json` - 配置文件

### 安全特性
- 更新前需要手動確認
- 錯誤時自動回滾
- 完整的日誌記錄
- 備份歷史保留

## 📖 使用方法

### 完整更新流程

#### 步驟 1: 構建新版本（在 Windows 開發機）

```bash
# 進入專案目錄
cd c:\Users\A72270\OneDrive - Microchip Technology Inc\Documents\GitHub\WorkLogApp-1

# 構建 WorkLogServer
cd docs/build
bash build_server.sh
```

#### 步驟 2: 複製到 Raspberry Pi

```bash
# 使用 SCP 複製（在 Windows PowerShell）
scp -r docs/build/dist/WorkLogServer khsu@192.168.0.105:~/Documents/Github/WorkLogApp/dist/

# 或使用 rsync（更快，只傳輸變更）
rsync -avz --progress docs/build/dist/WorkLogServer/ khsu@192.168.0.105:~/Documents/Github/WorkLogApp/dist/WorkLogServer/
```

#### 步驟 3: 在 Raspberry Pi 上執行更新

```bash
# SSH 連接到 Raspberry Pi
ssh khsu@192.168.0.105

# 執行更新腳本
cd ~
./update_worklog_server.sh
```

#### 步驟 4: 確認更新成功

腳本會自動驗證，你也可以手動檢查：

```bash
# 查看服務狀態
sudo systemctl status worklog.service

# 查看版本信息
sudo journalctl -u worklog.service -n 50 | grep -i "version\|Work Log Journal"

# 測試 HTTP 端點
curl http://localhost:5000

# 或在瀏覽器訪問
# http://192.168.0.105:5000
```

### 指定自訂來源目錄

如果新版本不在預設位置，可以指定來源目錄：

```bash
./update_worklog_server.sh /custom/path/to/WorkLogServer
```

### 查看腳本配置

編輯腳本可以修改以下配置：

```bash
nano ~/update_worklog_server.sh
```

可配置項目：
- `TARGET_DIR` - 目標目錄（systemd 服務位置）
- `SOURCE_DIR` - 預設來源目錄
- `SERVICE_NAME` - 服務名稱
- `BACKUP_DIR` - 備份目錄
- `PROTECTED_FILES` - 受保護文件列表

## 🔧 手動更新

如果不想使用自動腳本，可以手動更新：

```bash
# 1. 備份
sudo cp -r /home/khsu/worklog-server /home/khsu/worklog-server.backup.$(date +%Y%m%d_%H%M%S)

# 2. 停止服務
sudo systemctl stop worklog.service

# 3. 備份配置和資料庫
cp /home/khsu/worklog-server/.env /tmp/.env.backup 2>/dev/null || true
cp /home/khsu/worklog-server/*.db /tmp/ 2>/dev/null || true

# 4. 複製新版本
cp -r ~/Documents/Github/WorkLogApp/dist/WorkLogServer/* /home/khsu/worklog-server/

# 5. 恢復配置和資料庫
cp /tmp/.env.backup /home/khsu/worklog-server/.env 2>/dev/null || true
cp /tmp/*.db /home/khsu/worklog-server/ 2>/dev/null || true

# 6. 設置權限
chmod +x /home/khsu/worklog-server/WorkLogServer
sudo chown -R khsu:khsu /home/khsu/worklog-server/

# 7. 啟動服務
sudo systemctl start worklog.service

# 8. 驗證
sudo systemctl status worklog.service
```

## 🔍 故障排除

### 更新失敗：服務無法啟動

```bash
# 查看服務狀態
sudo systemctl status worklog.service

# 查看詳細日誌
sudo journalctl -u worklog.service -n 100 --no-pager

# 手動測試執行
cd /home/khsu/worklog-server
PORT=9999 ./WorkLogServer
```

### 更新失敗：權限問題

```bash
# 修正所有者
sudo chown -R khsu:khsu /home/khsu/worklog-server/

# 修正執行權限
chmod +x /home/khsu/worklog-server/WorkLogServer
```

### 更新失敗：配置文件遺失

```bash
# 從備份恢復配置
LAST_BACKUP=$(ls -t /home/khsu/worklog-server-backups/ | head -1)
cp /home/khsu/worklog-server-backups/$LAST_BACKUP/.env /home/khsu/worklog-server/

# 重啟服務
sudo systemctl restart worklog.service
```

### 端口仍然被占用

```bash
# 檢查是否有其他程序占用
sudo lsof -i :5000

# 確認服務狀態
sudo systemctl status worklog.service

# 強制停止所有相關程序
sudo pkill -9 WorkLogServer
```

## ⏮️ 回滾操作

### 自動回滾

腳本在更新失敗時會自動回滾到上一個版本。

### 手動回滾

如果需要手動回滾到之前的版本：

```bash
# 1. 查看可用備份
ls -lth /home/khsu/worklog-server-backups/

# 2. 選擇要恢復的備份（例如：worklog-server.20260429_103045）
BACKUP_VERSION="worklog-server.20260429_103045"

# 3. 停止服務
sudo systemctl stop worklog.service

# 4. 恢復備份
sudo rm -rf /home/khsu/worklog-server
sudo cp -r /home/khsu/worklog-server-backups/$BACKUP_VERSION /home/khsu/worklog-server

# 5. 重啟服務
sudo systemctl start worklog.service

# 6. 驗證
sudo systemctl status worklog.service
```

### 清理舊備份

```bash
# 查看所有備份
ls -lth /home/khsu/worklog-server-backups/

# 手動刪除舊備份
rm -rf /home/khsu/worklog-server-backups/worklog-server.20260401_*

# 或只保留最近 3 個備份
cd /home/khsu/worklog-server-backups/
ls -t | tail -n +4 | xargs rm -rf
```

## 📝 更新檢查清單

更新前檢查清單：

- [ ] 已備份重要資料
- [ ] 確認新版本已成功構建
- [ ] 確認新版本已複製到 Raspberry Pi
- [ ] 確認有足夠磁碟空間（至少 500MB）
- [ ] 確認沒有重要操作正在進行

更新後檢查清單：

- [ ] 服務狀態正常 (`systemctl status worklog.service`)
- [ ] HTTP 端點可訪問 (`curl http://localhost:5000`)
- [ ] 版本號已更新
- [ ] 配置文件完整（`.env`）
- [ ] 資料庫文件完整（`*.db`）
- [ ] 日誌無錯誤訊息

## 🔄 自動化更新（進階）

如果想要完全自動化更新流程，可以結合 GitHub Actions：

### 在 Raspberry Pi 上設置 webhook 接收器

```bash
# 安裝 webhook
sudo apt-get install webhook

# 創建 webhook 配置
cat > ~/webhook-config.json << 'EOF'
[
  {
    "id": "update-worklog",
    "execute-command": "/home/khsu/update_worklog_server.sh",
    "command-working-directory": "/home/khsu"
  }
]
EOF

# 啟動 webhook 服務
webhook -hooks ~/webhook-config.json -verbose
```

### GitHub Actions 觸發更新

在 `.github/workflows/build-executables.yml` 中添加：

```yaml
- name: Trigger Raspberry Pi update
  if: startsWith(github.ref, 'refs/tags/')
  run: |
    curl -X POST http://192.168.0.105:9000/hooks/update-worklog
```

## 📚 相關資源

- [StartPortIssue.md](StartPortIssue.md) - Port 占用問題排查
- [setup_pocketbase_autostart.sh](setup_pocketbase_autostart.sh) - PocketBase 自動啟動設置
- [docs/build/build_server.sh](docs/build/build_server.sh) - 伺服器構建腳本

## 🆘 需要幫助？

如果遇到問題：

1. 查看 [故障排除](#故障排除) 章節
2. 檢查系統日誌：`sudo journalctl -u worklog.service -f`
3. 查看備份位置：`ls -lth /home/khsu/worklog-server-backups/`
4. 在 GitHub 提交 Issue：https://github.com/khsu-tw/WorkLogApp/issues
