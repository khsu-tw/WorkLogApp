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
├── requirements.txt    ← Python dependencies
├── .env.example        ← Credential template
├── build_win.bat       ← Windows build script
├── build_linux.sh      ← Linux build script
├── build_mac.sh        ← macOS build script
└── clean_build.py      ← Clean build directories

Build files (docs/build/):
├── worklog.spec        ← Windows PyInstaller spec
├── worklog_linux.spec  ← Linux PyInstaller spec
├── worklog_mac.spec    ← macOS PyInstaller spec
└── schema.sql          ← PostgreSQL table schema
```

---

## 📚 Documentation

See [docs/](docs/) directory for:
- Database schema (schema.sql)
- Build configurations (.spec files)
- Setup guides (archived)

**Note:** docs/ and backup/ directories are excluded from Git repository.
