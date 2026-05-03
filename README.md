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

## 🖥️ Headless Server Deployment (Linux / Raspberry Pi)

For a persistent WorkLogServer running as a systemd service (e.g. on a Raspberry Pi), three scripts work together:

| Script | Purpose | When to run |
|---|---|---|
| **`build_server.sh`** | Compiles `WorkLogServer` executable and packages it as a `.tar.gz` | Every time after pulling new code |
| **`setup_worklog_server_autostart.sh`** | **First-time install** — creates `worklog.service`, enables auto-start on boot, checks port availability | Once per machine |
| **`update_worklog_server.sh`** | **Subsequent updates** — backs up current version → stops service → replaces binary → preserves `.env` / `*.db` → restarts → auto-rollback on failure | Every version upgrade |

### Unified one-command flow (recommended)

`build_server.sh` supports a `--deploy` flag that auto-detects install state and invokes the correct script:

```bash
git pull                                       # fetch latest code
sudo bash build_server.sh --deploy             # build + install (or update)
```

The `--deploy` flag detects:
- **First install** → copies binary to `/home/khsu/worklog-server/`, then runs `setup_worklog_server_autostart.sh`
- **Already installed** → runs `update_worklog_server.sh` (with auto-confirm; full backup + rollback)

Three safety checks are performed automatically:
1. **Before build** — warns if local `HEAD` differs from `origin/main` (prevents stale builds)
2. **After build** — verifies bundled `VERSION` matches source `VERSION` (catches PyInstaller cache issues)
3. **After deploy** — curls `http://localhost:5000/api/config` to confirm the running server reports the expected version

### Standalone usage (scripts still work individually)

```bash
bash build_server.sh                           # build only, no deploy
sudo bash setup_worklog_server_autostart.sh    # first install only
sudo bash update_worklog_server.sh             # update only
sudo bash diagnose_worklog.sh                  # full health check / troubleshooting
```

### Deployment decision table

| State on machine | `build_server.sh --deploy` does… |
|---|---|
| Fresh machine (no service, no target dir) | build → setup (first install) |
| `worklog.service` + `/home/khsu/worklog-server/WorkLogServer` both exist | build → update (with backup & rollback) |
| Service exists but binary missing | build → setup (treated as fresh) |

### Troubleshooting

If the browser still shows an old version after deploy:

1. **Force browser reload**: Ctrl+F5 (PWA/Service Worker may cache old HTML)
2. **Verify running version**: `curl http://<pi-ip>:5000/api/config | python3 -m json.tool | grep version`
3. **Check git state**: local modifications may block `git pull`; run `git status` to see
4. **Full diagnostic**: `sudo bash diagnose_worklog.sh` checks service, port, firewall, logs

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

