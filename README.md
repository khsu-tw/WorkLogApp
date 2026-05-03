# 📋 Work Log Journal

Cross-platform offline-first work log app.
Runs on **Windows · macOS · iOS (PWA) · Android**.

---

## 🚀 Quick Start

```bash
# 1. Create virtual environment
python -m venv .venv
.venv\Scripts\activate      # Windows
# source .venv/bin/activate  # macOS/Linux

# 2. Install dependencies
pip install -r requirements.txt

# 3. Configure (optional — skip to use local SQLite)
cp .env.example .env
# Edit .env → configure PostgreSQL connection if needed

# 4a. Run with setup wizard GUI
python launcher.py

# 4b. Or run Flask directly
python app.py
```

Open **http://localhost:5000** in your browser.

---

## ☁️ Cloud Database (PostgreSQL)

See [docs/RASPBERRY_PI_POSTGRES_SETUP.md](docs/RASPBERRY_PI_POSTGRES_SETUP.md) for complete setup guide.

Quick setup:
1. Install PostgreSQL on your server/VPS
2. Create database: `CREATE DATABASE worklog;`
3. Run schema: `psql -U postgres -d worklog -f schema.sql`
4. Configure connection in `.env` or setup wizard

---

## 🖥️ Headless Server 部署 (Linux / Raspberry Pi)

將 WorkLogServer 以 systemd 服務形式常駐（例如 Raspberry Pi），由以下三個腳本協作：

### 三個腳本的關係

| 腳本 | 功能 | 使用時機 |
|---|---|---|
| **`build_server.sh`** | 編譯產生 `WorkLogServer` 執行檔和 tarball | 每次更新程式碼後 |
| **`setup_worklog_server_autostart.sh`** | **首次安裝** — 建立 systemd service、設定開機啟動、檢查 port | 只跑一次 |
| **`update_worklog_server.sh`** | **後續更新** — 備份舊版、停服務、替換執行檔、保護 `.env` / `*.db`、重啟、失敗時回滾 | 每次升級版本 |

### 一鍵完整部署（推薦）

`build_server.sh` 支援 `--deploy` 旗標，會自動偵測安裝狀態並呼叫對應腳本：

```bash
git pull                                       # 更新程式碼
sudo bash build_server.sh --deploy             # 編譯 + 安裝（或升級）
```

`--deploy` 的判斷邏輯：
- **首次安裝** → 複製執行檔到 `/home/khsu/worklog-server/`，呼叫 `setup_worklog_server_autostart.sh`
- **已安裝過** → 呼叫 `update_worklog_server.sh`（自動確認；含備份與回滾）

自動執行三層安全檢查：
1. **編譯前** — 若 local `HEAD` 與 `origin/main` 不一致會警告（避免 build 到舊程式碼）
2. **編譯後** — 驗證 bundle 內的 `VERSION` 等於原始碼 `VERSION`（抓出 PyInstaller cache 問題）
3. **部署後** — 用 `curl http://localhost:5000/api/config` 驗證實際運行的 server 版本符合預期

### 獨立使用（各腳本仍可單獨執行）

```bash
bash build_server.sh                           # 只編譯
sudo bash setup_worklog_server_autostart.sh    # 只安裝（首次）
sudo bash update_worklog_server.sh             # 只升級
sudo bash diagnose_worklog.sh                  # 健康檢查 / 疑難排解
```

### 部署決策表

| 機器狀態 | `build_server.sh --deploy` 的行為 |
|---|---|
| 全新機器（無 service、無 target 資料夾） | build → setup（首次安裝） |
| `worklog.service` 和 `/home/khsu/worklog-server/WorkLogServer` 都存在 | build → update（含備份與回滾） |
| service 存在但 binary 遺失 | build → setup（視為全新） |

### 疑難排解

部署後瀏覽器仍顯示舊版：

1. **強制重新載入**：Ctrl+F5（PWA / Service Worker 可能仍快取舊 HTML）
2. **確認運行中的版本**：`curl http://<pi-ip>:5000/api/config | python3 -m json.tool | grep version`
3. **檢查 git 狀態**：本地修改可能阻擋 `git pull`，先執行 `git status`
4. **完整診斷**：`sudo bash diagnose_worklog.sh`（檢查服務、port、防火牆、日誌）

---

## 📱 iOS — Add to Home Screen (PWA)

1. Run on your computer (same WiFi as iPhone)
2. Safari → `http://<computer-ip>:5000`
3. Share → **Add to Home Screen**

---

## ✨ Features

- **Offline-first**: all reads/writes go to local SQLite; syncs to PostgreSQL in background
- **Auto sync**: every 30 s when online; queues changes when offline
- **Conflict resolution**: side-by-side diff when both sides edited the same record offline
- **Worklogs**: timestamped journal with Markdown, nested lists, images (paste/drag/upload)
- **Word export**: weekly report with Task Summary, Worklogs, images
- **Dark/Light/System** theme
- **Filters**: Customer, Project, Status, Category, Archive

---

## 📁 Structure

```
WorkLogApp/
├── app.py              ← Flask app (backend + frontend)
├── launcher.py         ← GUI setup wizard + server control
├── server.py           ← Headless server entry point (no GUI)
├── requirements.txt    ← Python dependencies
├── .env.example        ← Credential template
│
├── build_win.bat       ← Windows build (GUI client)
├── build_linux.sh      ← Linux build (GUI client)
├── build_mac.sh        ← macOS build (GUI client)
├── build_server.sh     ← Universal headless server build (+ optional --deploy)
├── clean_build.py      ← Clean build directories
│
├── setup_worklog_server_autostart.sh  ← First-time systemd install
├── update_worklog_server.sh           ← Safe version upgrade (backup + rollback)
├── diagnose_worklog.sh                ← Server health check / troubleshooting
└── VERSION             ← Single source of truth for the version string

Build files (docs/build/):
├── worklog.spec              ← Windows PyInstaller spec (GUI)
├── worklog_linux.spec        ← Linux PyInstaller spec (GUI)
├── worklog_mac.spec          ← macOS PyInstaller spec (GUI)
├── worklog_server_linux.spec ← Headless server PyInstaller spec
├── worklog_server_mac.spec   ← Headless server (macOS) spec
└── schema.sql                ← PostgreSQL table schema
```

---

## 📚 Documentation

See [docs/](docs/) directory for:
- Database schema (schema.sql)
- Build configurations (.spec files)
- Setup guides (archived)

**Note:** docs/ and backup/ directories are excluded from Git repository.