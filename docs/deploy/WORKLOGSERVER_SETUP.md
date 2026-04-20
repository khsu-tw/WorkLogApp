# WorkLogServer 安裝說明 / Installation Guide

**WorkLogServer** 是 Work Log Journal 的無介面（Headless）伺服器版本，不需要桌面環境，適合在 Raspberry Pi 或 Linux 伺服器上作為背景服務執行。

**WorkLogServer** is the headless server edition of Work Log Journal. It requires no desktop environment and is designed to run as a background service on Raspberry Pi or any Linux server.

---

## 目錄 / Table of Contents

- [系統需求 / Requirements](#系統需求--requirements)
- [安裝步驟 / Installation](#安裝步驟--installation)
- [設定資料庫 / Database Configuration](#設定資料庫--database-configuration)
- [手動執行 / Manual Run](#手動執行--manual-run)
- [設定為系統服務 / Running as a systemd Service](#設定為系統服務--running-as-a-systemd-service)
- [從 iPad / iPhone 存取 / Accessing from iPad or iPhone](#從-ipad--iphone-存取--accessing-from-ipad-or-iphone)
- [常見問題 / Troubleshooting](#常見問題--troubleshooting)

---

## 系統需求 / Requirements

| 項目 | 需求 |
|------|------|
| 作業系統 | Linux（Ubuntu 20.04+、Raspberry Pi OS）|
| 架構 | x86_64 或 aarch64（ARM64）|
| 磁碟空間 | 至少 200 MB |
| 網路 | 區域網路（LAN）或外網 IP |

| Item | Requirement |
|------|-------------|
| OS | Linux (Ubuntu 20.04+, Raspberry Pi OS) |
| Architecture | x86_64 or aarch64 (ARM64) |
| Disk space | At least 200 MB |
| Network | LAN or public IP |

---

## 安裝步驟 / Installation

### 1. 下載並解壓縮 / Download and Extract

```bash
# 解壓縮 / Extract
tar -xzf WorkLogServer_v1.0.1_Linux.tar.gz

# 進入目錄 / Enter directory
cd WorkLogServer
```

### 2. 賦予執行權限 / Grant Execute Permission

```bash
chmod +x WorkLogServer
```

---

## 設定資料庫 / Database Configuration

WorkLogServer 透過 `.env` 檔案讀取資料庫設定。首次執行前請先建立此檔案。

WorkLogServer reads database settings from a `.env` file. Create it before the first run.

### 僅使用本機 SQLite（預設）/ Local SQLite Only (Default)

```bash
# 不需要建立 .env，直接執行即可
# No .env needed — just run the executable
./WorkLogServer
```

資料庫檔案會自動建立在同目錄下的 `WorkLog.db`。
The database file `WorkLog.db` will be created automatically in the same directory.

---

### 使用 PocketBase 雲端同步 / Using PocketBase Cloud Sync

```bash
cat > .env << 'EOF'
POCKETBASE_URL=http://127.0.0.1:8090
POCKETBASE_TOKEN=your_api_token_here
EOF
```

> PocketBase Token 可在 PocketBase Admin UI → Settings → API Keys 取得。
> Get the token from PocketBase Admin UI → Settings → API Keys.

---

### 使用 PostgreSQL / Using PostgreSQL

```bash
cat > .env << 'EOF'
POSTGRES_URL=postgresql://worklog_user:password@localhost:5432/worklogdb
EOF
```

> PostgreSQL 完整安裝說明請參閱 [RASPBERRY_PI_POSTGRES_SETUP.md](RASPBERRY_PI_POSTGRES_SETUP.md)。
> For full PostgreSQL setup, see [RASPBERRY_PI_POSTGRES_SETUP.md](RASPBERRY_PI_POSTGRES_SETUP.md).

---

### 執行後透過瀏覽器修改設定 / Change Settings via Browser

啟動後，開啟瀏覽器前往 `http://<Pi IP>:5000`，點擊右上角 **⚙ DB** 按鈕即可在線修改資料庫設定，無需重啟服務。

After starting, open a browser at `http://<Pi IP>:5000` and click the **⚙ DB** button in the top-right corner to update database settings without restarting.

---

## 手動執行 / Manual Run

```bash
# 預設 port 5000 / Default port 5000
./WorkLogServer

# 自訂 port / Custom port
PORT=8080 ./WorkLogServer
```

啟動後終端機會顯示存取網址：
On startup, the terminal prints the access URLs:

```
==================================================
 Work Log Journal — Server
==================================================
  Local:  http://localhost:5000
  LAN:    http://192.168.1.100:5000
  Sync:   PocketBase → http://127.0.0.1:8090
==================================================
  Press Ctrl+C to stop
```

按 `Ctrl+C` 可停止伺服器。
Press `Ctrl+C` to stop the server.

---

## 設定為系統服務 / Running as a systemd Service

設定後，Raspberry Pi 開機時會自動啟動 WorkLogServer，不需要手動執行。

After setup, WorkLogServer will start automatically on boot — no manual intervention needed.

### 1. 建立 Service 檔案 / Create Service File

將 `WorkLogServer` 目錄複製到 `/opt/WorkLogServer`，然後建立服務檔：

Copy the `WorkLogServer` directory to `/opt/WorkLogServer`, then create the service file:

```bash
sudo cp -r WorkLogServer /opt/WorkLogServer
```

```bash
sudo tee /etc/systemd/system/worklog.service << 'EOF'
[Unit]
Description=Work Log Journal Server
After=network.target

[Service]
Type=simple
User=pi
WorkingDirectory=/opt/WorkLogServer
ExecStart=/opt/WorkLogServer/WorkLogServer
Restart=on-failure
RestartSec=5
Environment=PORT=5000

[Install]
WantedBy=multi-user.target
EOF
```

> 若使用者名稱不是 `pi`，請將 `User=pi` 改為實際使用者名稱。
> If your username is not `pi`, replace `User=pi` with your actual username.

### 2. 啟用並啟動服務 / Enable and Start the Service

```bash
# 重新載入 systemd 設定 / Reload systemd
sudo systemctl daemon-reload

# 開機自動啟動 / Enable autostart on boot
sudo systemctl enable worklog

# 立即啟動 / Start now
sudo systemctl start worklog

# 確認狀態 / Check status
sudo systemctl status worklog
```

### 3. 常用管理指令 / Common Management Commands

```bash
# 查看即時 log / View live logs
sudo journalctl -u worklog -f

# 停止服務 / Stop service
sudo systemctl stop worklog

# 重啟服務 / Restart service
sudo systemctl restart worklog

# 停用開機自啟 / Disable autostart
sudo systemctl disable worklog
```

---

## 從 iPad / iPhone 存取 / Accessing from iPad or iPhone

### 區域網路（LAN）/ Local Network

確保 iPad / iPhone 與 Raspberry Pi 連接到**同一個 Wi-Fi**，然後在 Safari 開啟：

Make sure iPad/iPhone and the Raspberry Pi are on the **same Wi-Fi**, then open Safari and go to:

```
http://192.168.1.xxx:5000
```

（將 `192.168.1.xxx` 替換為 Pi 的實際 LAN IP，可從終端機輸出或路由器管理頁面查詢。）
(Replace `192.168.1.xxx` with the Pi's actual LAN IP, shown in the terminal on startup or found in your router's admin page.)

### 安裝為 PWA / Install as PWA

在 Safari 中點擊 **分享 → 加入主畫面**，即可將 Work Log Journal 安裝為 App，之後從主畫面開啟即可直接使用。

In Safari, tap **Share → Add to Home Screen** to install Work Log Journal as an app. It will appear on your Home Screen like a native app.

> **注意**：PWA 仍需連線到 Pi 才能正常使用，Pi 必須持續執行 WorkLogServer。
> **Note**: The PWA still requires a connection to the Pi. WorkLogServer must be running.

---

## 常見問題 / Troubleshooting

### 無法連線 / Cannot Connect

1. 確認 WorkLogServer 正在執行：`sudo systemctl status worklog`
2. 確認 port 未被佔用：`ss -tlnp | grep 5000`
3. 確認防火牆允許該 port：`sudo ufw allow 5000`

1. Verify WorkLogServer is running: `sudo systemctl status worklog`
2. Check the port is not in use: `ss -tlnp | grep 5000`
3. Allow the port in the firewall: `sudo ufw allow 5000`

---

### 更換 port 後服務未更新 / Port Change Not Taking Effect

編輯 service 檔案中的 `Environment=PORT=5000` 改為新的 port，然後重新載入：

Edit `Environment=PORT=5000` in the service file to the new port, then reload:

```bash
sudo systemctl daemon-reload && sudo systemctl restart worklog
```

---

### 資料庫設定遺失 / Database Settings Lost After Restart

`.env` 檔案必須放在與 `WorkLogServer` 執行檔**相同的目錄**下（預設為 `/opt/WorkLogServer/.env`）。

The `.env` file must be in the **same directory** as the `WorkLogServer` executable (default: `/opt/WorkLogServer/.env`).

---

### 查看錯誤訊息 / View Error Messages

```bash
sudo journalctl -u worklog --since "10 minutes ago"
```

---

## 相關文件 / Related Documentation

- [PocketBase 設定指南](POCKETBASE_SETUP.md) / [PocketBase Setup Guide](POCKETBASE_SETUP.md)
- [PostgreSQL on Raspberry Pi](RASPBERRY_PI_POSTGRES_SETUP.md)
- [Linux 建置說明](BUILD_LINUX.md) / [Linux Build Instructions](BUILD_LINUX.md)
