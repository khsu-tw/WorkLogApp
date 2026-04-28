# Port 5000 占用問題排查與解決

## 問題描述

在 Raspberry Pi 上啟動 WorkLogServer 時遇到 port 5000 被占用的錯誤：

```bash
khsu@krpi5:~/Documents/Github/WorkLogApp/dist/WorkLogServer $ PORT=5000 ./WorkLogServer 
==================================================
 Work Log Journal v1.0.4 — Server
==================================================
  Local:  http://localhost:5000
  LAN:    http://192.168.0.105:5000
  Sync:   SQLite (local only)
==================================================
  Press Ctrl+C to stop

 * Serving Flask app 'app'
 * Debug mode: off
Address already in use
Port 5000 is in use by another program. Either identify and stop that program, or start the server with a different port.
```

## 症狀

- 使用 `kill -9 <PID>` 強制停止程序後，該程序會自動重啟
- 表示有服務管理器在監控並自動重啟該程序

## 診斷步驟

### 1. 查找占用 port 5000 的程序

```bash
PID=$(sudo lsof -ti :5000)
echo "PID: $PID"
ps -fp $PID
sudo systemctl status $PID
```

### 2. 診斷結果

```
PID: 31299
UID          PID    PPID  C STIME TTY          TIME CMD
khsu       31299       1  1 02:58 ?        00:00:00 /home/khsu/worklog-server/WorkLogServer

● worklog.service - WorkLog Server
     Loaded: loaded (/etc/systemd/system/worklog.service; enabled; preset: enabled)
     Active: active (running) since Wed 2026-04-29 02:58:40 CST; 1min 26s ago
   Main PID: 31299 (WorkLogServer)
      Tasks: 2 (limit: 9568)
     CGroup: /system.slice/worklog.service
             └─31299 /home/khsu/worklog-server/WorkLogServer
```

### 3. 問題根源

- 有一個 systemd 服務 `worklog.service` 正在運行
- 服務已啟用開機自動啟動 (`enabled`)
- 服務配置為自動重啟 (`Scheduled restart job`)
- 舊服務路徑：`/home/khsu/worklog-server/WorkLogServer`
- 新服務路徑：`~/Documents/Github/WorkLogApp/dist/WorkLogServer`

## 解決方案

### 方案 1: 停止並禁用舊服務（推薦）

適用於想要手動啟動 WorkLogServer 的情況：

```bash
# 停止服務
sudo systemctl stop worklog.service

# 禁用開機自動啟動
sudo systemctl disable worklog.service

# 確認已停止
sudo systemctl status worklog.service

# 現在可以手動啟動新版本
cd ~/Documents/Github/WorkLogApp/dist/WorkLogServer
PORT=5000 ./WorkLogServer
```

### 方案 2: 更新服務配置指向新位置

適用於想要保留 systemd 服務自動管理的情況：

```bash
# 編輯服務配置
sudo nano /etc/systemd/system/worklog.service

# 修改 ExecStart 路徑指向新位置
# ExecStart=/home/khsu/Documents/Github/WorkLogApp/dist/WorkLogServer/WorkLogServer

# 重新載入配置
sudo systemctl daemon-reload

# 重啟服務
sudo systemctl restart worklog.service

# 確認狀態
sudo systemctl status worklog.service
```

### 方案 2A: 覆蓋更新舊位置的 WorkLogServer（推薦）

適用於保留現有 systemd 服務配置，只更新執行檔到新版本的情況：

#### 步驟 1: 備份舊版本

```bash
# 備份舊版本（建議）
sudo cp -r /home/khsu/worklog-server /home/khsu/worklog-server.backup.$(date +%Y%m%d)

# 確認備份
ls -la /home/khsu/ | grep worklog
```

#### 步驟 2: 停止服務並覆蓋檔案

```bash
# 停止服務
sudo systemctl stop worklog.service

# 複製新版本的 WorkLogServer 執行檔及相關檔案
cp -r ~/Documents/Github/WorkLogApp/dist/WorkLogServer/* /home/khsu/worklog-server/

# 設置執行權限
chmod +x /home/khsu/worklog-server/WorkLogServer

# 確認檔案已更新
ls -lh /home/khsu/worklog-server/WorkLogServer
```

#### 步驟 3: 重啟服務並驗證

```bash
# 重新啟動服務
sudo systemctl start worklog.service

# 確認服務狀態
sudo systemctl status worklog.service

# 查看日誌確認版本
sudo journalctl -u worklog.service -n 20

# 檢查 port 5000 是否正常監聽
curl http://localhost:5000
```

#### 一鍵更新腳本

創建自動更新腳本方便日後使用：

```bash
cat > /tmp/update_worklog.sh << 'EOF'
#!/bin/bash
set -e

echo "==> 備份舊版本..."
sudo cp -r /home/khsu/worklog-server /home/khsu/worklog-server.backup.$(date +%Y%m%d_%H%M%S)

echo "==> 停止服務..."
sudo systemctl stop worklog.service

echo "==> 複製新版本..."
cp -r ~/Documents/Github/WorkLogApp/dist/WorkLogServer/* /home/khsu/worklog-server/
chmod +x /home/khsu/worklog-server/WorkLogServer

echo "==> 重啟服務..."
sudo systemctl start worklog.service

echo "==> 等待服務啟動..."
sleep 3

echo "==> 檢查服務狀態..."
sudo systemctl status worklog.service --no-pager

echo "==> 完成! 服務已更新到新版本"
echo "訪問: http://192.168.0.105:5000"
EOF

chmod +x /tmp/update_worklog.sh
/tmp/update_worklog.sh
```

#### 注意事項

1. **配置檔案保留**：如果 `/home/khsu/worklog-server/` 有 `.env` 等配置檔案，複製時會被覆蓋，建議先備份
2. **資料庫檔案**：SQLite 資料庫檔案（`.db` 檔）會被覆蓋，務必先備份資料
3. **權限問題**：確保檔案所有者正確：
   ```bash
   sudo chown -R khsu:khsu /home/khsu/worklog-server/
   ```
4. **選擇性複製**：如果只想更新執行檔，使用：
   ```bash
   cp ~/Documents/Github/WorkLogApp/dist/WorkLogServer/WorkLogServer /home/khsu/worklog-server/WorkLogServer
   ```

#### 驗證更新成功

```bash
# 查看啟動日誌中的版本號
sudo journalctl -u worklog.service -n 50 | grep -i "version\|v1.0"

# 或直接訪問網頁查看版本
curl -s http://localhost:5000 | grep -i version
```

### 方案 3: 修改服務使用不同 port

適用於想要同時運行新舊版本的情況：

```bash
# 編輯服務配置
sudo nano /etc/systemd/system/worklog.service
```

在 `[Service]` 區段加入環境變數：

```ini
[Service]
Environment="PORT=5001"
ExecStart=/home/khsu/worklog-server/WorkLogServer
```

重新載入並重啟：

```bash
sudo systemctl daemon-reload
sudo systemctl restart worklog.service
```

### 方案 4: 完全移除舊服務

適用於確定不再需要舊版本的情況：

```bash
# 停止服務
sudo systemctl stop worklog.service

# 禁用服務
sudo systemctl disable worklog.service

# 刪除服務文件
sudo rm /etc/systemd/system/worklog.service

# 重新載入 systemd
sudo systemctl daemon-reload

# 確認已移除
sudo systemctl list-units --type=service | grep worklog
```

## 臨時解決方法

如果只是想快速測試，可以使用不同的 port：

```bash
# 使用 port 5001
PORT=5001 ./WorkLogServer

# 或使用 port 8080
PORT=8080 ./WorkLogServer
```

創建 `.env` 文件永久設定 port：

```bash
cd ~/Documents/Github/WorkLogApp/dist/WorkLogServer
echo "PORT=5001" > .env
./WorkLogServer
```

## 常用診斷指令

```bash
# 查看所有正在監聽的 port
sudo netstat -tulpn

# 查看特定 port 的使用情況
sudo lsof -i :5000

# 查看所有 systemd 服務
sudo systemctl list-units --type=service

# 查看服務配置文件
sudo systemctl cat worklog.service

# 查看服務日誌
sudo journalctl -u worklog.service -f
```

## 預防措施

1. **使用 systemd 服務管理**：建議使用 systemd 統一管理服務，避免手動啟動與服務管理器衝突
2. **使用不同 port**：開發和生產環境使用不同 port，避免衝突
3. **記錄服務配置**：在專案中保留 systemd service 文件範本
4. **版本控制**：更新版本時先停止舊服務

## 相關資源

- [systemd 服務管理](https://www.freedesktop.org/software/systemd/man/systemctl.html)
- [Flask 部署指南](https://flask.palletsprojects.com/en/latest/deploying/)
- WorkLogServer 版本：v1.0.4
