# Raspberry Pi 5 架設 PostgreSQL + WorkLogApp 雲端資料庫完整指南

---

## 一、環境需求

- Raspberry Pi 5（建議至少 4GB RAM）
- Raspberry Pi OS (64-bit) Bookworm 或更新版
- 固定 IP 位址（區域網路內）
- 網路連線

---

## 二、在 Raspberry Pi 上安裝 PostgreSQL

### 2.1 更新系統套件

```bash
sudo apt update && sudo apt upgrade -y
```

### 2.2 安裝 PostgreSQL

```bash
sudo apt install -y postgresql postgresql-client
```

### 2.3 確認安裝成功

```bash
sudo systemctl status postgresql
```

看到 `active (running)` 表示成功。

### 2.4 設定開機自動啟動

```bash
sudo systemctl enable postgresql
```

---

## 三、建立資料庫與使用者

### 3.1 進入 PostgreSQL 管理介面

```bash
sudo -u postgres psql
```

### 3.2 建立專用使用者（請替換密碼）

```sql
CREATE USER worklog_user WITH PASSWORD '你的安全密碼';
```

### 3.3 建立資料庫

```sql
CREATE DATABASE worklogdb OWNER worklog_user;
```

### 3.4 賦予權限

```sql
GRANT ALL PRIVILEGES ON DATABASE worklogdb TO worklog_user;
\c worklogdb
GRANT ALL ON SCHEMA public TO worklog_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO worklog_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO worklog_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO worklog_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO worklog_user;
```

### 3.5 離開 psql

```sql
\q
```

---

## 四、建立 WorkLogApp 資料表

### 4.1 複製 schema.sql 到 Pi（在你的電腦上執行）

```bash
scp /path/to/WorkLogApp/schema.sql pi@<Pi的IP位址>:/home/pi/
```

### 4.2 回到 Pi，執行 Schema

```bash
psql -U worklog_user -d worklogdb -h localhost -f /home/pi/schema.sql
```

輸入密碼後，會自動建立 `worklog` 資料表及索引。

### 4.3 驗證資料表建立成功

```bash
psql -U worklog_user -d worklogdb -h localhost -c "\dt"
```

應看到 `worklog` 資料表。

---

## 五、設定 PostgreSQL 允許遠端連線

### 5.1 修改 postgresql.conf（允許監聽所有 IP）

```bash
sudo nano /etc/postgresql/*/main/postgresql.conf
```

找到並修改這行（移除 `#` 並改值）：

```
listen_addresses = '*'
```

### 5.2 修改 pg_hba.conf（允許區域網路連線）

```bash
sudo nano /etc/postgresql/*/main/pg_hba.conf
```

在檔案末尾加入（依你的區域網路設定調整，例如 `192.168.1.0/24`）：

```
# 允許區域網路連線（請依實際網段修改）
host    worklogdb    worklog_user    192.168.1.0/24    scram-sha-256
```

> 如果只在本機使用，這步可略過。

### 5.3 重新啟動 PostgreSQL

```bash
sudo systemctl restart postgresql
```

### 5.4 （選用）開放防火牆

```bash
sudo ufw allow from 192.168.1.0/24 to any port 5432
sudo ufw reload
```

---

## 六、設定 WorkLogApp 連線

### 6.1 在 WorkLogApp 的 `.env` 檔案中設定連線字串

開啟 WorkLogApp 目錄下的 `.env` 檔案，加入以下設定：

```env
# PostgreSQL 連線設定（格式：postgresql://使用者:密碼@主機IP:埠/資料庫名）
POSTGRES_URL=postgresql://worklog_user:你的安全密碼@192.168.1.xxx:5432/worklogdb

# 保留 PocketBase 設定（若已不使用可留空）
POCKETBASE_URL=
POCKETBASE_TOKEN=
```

> 將 `192.168.1.xxx` 替換為你的 Raspberry Pi 實際 IP 位址。

### 6.2 查詢 Pi 的 IP 位址

在 Pi 上執行：

```bash
hostname -I
```

---

## 七、驗證連線是否正常

### 7.1 從你的電腦測試連線

```bash
psql -U worklog_user -d worklogdb -h 192.168.1.xxx -p 5432
```

能成功登入即表示連線正常。

### 7.2 啟動 WorkLogApp 測試

**使用打包後的 WorkLog.app（macOS）：**
直接開啟 `WorkLog.app`，launcher 控制視窗會自動顯示實際網址並開啟瀏覽器。

> macOS 的 AirPlay Receiver 預設佔用 5000 port，launcher 會自動改用 5001 或其他可用 port（範圍 5000–5020），實際 port 以控制視窗上顯示的為準，或直接點「🌐 Open Browser」按鈕。

**使用 Python 原始碼執行：**
```bash
# 在 WorkLogApp 目錄下
python launcher.py
```

點選同步按鈕確認雲端資料庫狀態顯示為 `PostgreSQL ☁` 即表示連線正常。

---

## 八、安全性建議

| 項目 | 建議 |
|------|------|
| 密碼強度 | 至少 16 字元，含大小寫、數字、符號 |
| 網路存取 | 僅開放區域網路 IP，不要對外網開放 5432 埠 |
| 定期備份 | 使用 `pg_dump` 排程備份（見下方） |
| 系統更新 | 定期 `sudo apt update && sudo apt upgrade` |

### 設定每日自動備份（選用）

```bash
# 建立備份腳本
nano /home/pi/backup_worklog.sh
```

貼入以下內容：

```bash
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR=/home/pi/backups
mkdir -p $BACKUP_DIR
pg_dump -U worklog_user -d worklogdb -h localhost > $BACKUP_DIR/worklog_$DATE.sql
# 只保留最近 30 份備份
ls -t $BACKUP_DIR/worklog_*.sql | tail -n +31 | xargs -r rm
```

```bash
chmod +x /home/pi/backup_worklog.sh

# 設定每日凌晨 2 點自動備份
crontab -e
# 加入這行：
0 2 * * * /home/pi/backup_worklog.sh
```

---

## 九、常見問題排除

**Q: 連線被拒（Connection refused）**
- 確認 `listen_addresses = '*'` 已設定並重啟 PostgreSQL
- 確認防火牆已開放 5432 埠

**Q: 驗證失敗（Authentication failed）**
- 確認 `.env` 中的密碼與建立使用者時的密碼一致
- 確認 `pg_hba.conf` 的網段設定包含你的電腦 IP

**Q: 資料表不存在**
- 重新執行 `schema.sql`：`psql -U worklog_user -d worklogdb -h localhost -f schema.sql`

**Q: WorkLogApp 顯示離線（不使用雲端）**
- 檢查 `.env` 中 `POSTGRES_URL` 是否正確填寫
- 確認 Pi 已開機且 PostgreSQL 服務運行中

---

## 十、架設完成確認清單

- [ ] PostgreSQL 已安裝並啟動
- [ ] `worklog_user` 使用者已建立
- [ ] `worklogdb` 資料庫已建立
- [ ] `schema.sql` 已成功執行（`worklog` 資料表存在）
- [ ] 遠端連線設定完成（`postgresql.conf` + `pg_hba.conf`）
- [ ] WorkLogApp `.env` 已設定 `POSTGRES_URL`
- [ ] 從電腦可成功連線至 Pi 的 PostgreSQL
- [ ] WorkLogApp 啟動後雲端同步正常
