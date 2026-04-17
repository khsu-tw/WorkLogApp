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
# Edit .env → paste SUPABASE_URL and SUPABASE_KEY

# 4a. Run with setup wizard GUI
python launcher.py

# 4b. Or run Flask directly
python app.py
```

Open **http://localhost:5000** in your browser.

---

## ☁️ Cloud Database (Supabase)

1. [supabase.com](https://supabase.com) → New project
2. SQL Editor → paste `schema.sql` → Run
3. Project Settings → API → copy **Project URL** and **anon key**
4. Paste into `.env` or enter in the setup wizard

---

## 📱 iOS — Add to Home Screen (PWA)

1. Run on your computer (same WiFi as iPhone)
2. Safari → `http://<computer-ip>:5000`
3. Share → **Add to Home Screen**

---

## ✨ Features

- **Offline-first**: all reads/writes go to local SQLite; syncs to Supabase in background
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
├── requirements.txt
├── schema.sql          ← Supabase table schema
├── .env.example        ← Credential template
├── docs/               ← Documentation
│   ├── BUILD_LINUX.md
│   ├── POCKETBASE_SETUP.md
│   ├── RASPBERRY_PI_POSTGRES_SETUP.md
│   └── archive/        ← Legacy docs (v0.9.8)
├── backup/             ← Version backups (.zip)
└── dist/               ← Built executables
```

---

## 📚 Documentation

- [CHANGELOG.md](CHANGELOG.md) - Version history and updates
- [docs/BUILD_LINUX.md](docs/BUILD_LINUX.md) - Linux build instructions
- [docs/POCKETBASE_SETUP.md](docs/POCKETBASE_SETUP.md) - PocketBase setup guide (legacy)
- [docs/RASPBERRY_PI_POSTGRES_SETUP.md](docs/RASPBERRY_PI_POSTGRES_SETUP.md) - PostgreSQL on Raspberry Pi setup
- [docs/archive/](docs/archive/) - Legacy v0.9.8 migration guides
