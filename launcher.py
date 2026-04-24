"""
Work Log Journal — Launcher
===========================
Entry point for the packaged application.
• On first run: shows a setup wizard asking for database credentials (PocketBase or PostgreSQL)
• Saves credentials to .env in the app data folder
• Starts the Flask server in a background thread
• Opens the browser automatically
• Shows a minimal system-tray-style control window
"""

import os
import sys
import json
import time
import socket
import threading
import subprocess
import webbrowser
import tkinter as tk
from tkinter import ttk, messagebox
from pathlib import Path
import zipfile
import shutil

# ── Determine data directory (writable even when packaged) ───────────────────
if getattr(sys, 'frozen', False):
    BASE_DIR = Path(sys._MEIPASS)          # bundled files (read-only)
    _exe = Path(sys.executable).resolve()
    # macOS .app bundle: executable is at WorkLog.app/Contents/MacOS/WorkLog
    # Store user data (*.env, *.db) NEXT TO the .app, not inside it —
    # so it survives clean rebuilds and is accessible to the user.
    if (sys.platform == 'darwin'
            and _exe.parent.name == 'MacOS'
            and _exe.parent.parent.name == 'Contents'):
        APP_DIR = _exe.parent.parent.parent.parent  # directory containing WorkLog.app
    else:
        APP_DIR = _exe.parent               # Windows / Linux single-dir bundle
else:
    APP_DIR  = Path(__file__).parent
    BASE_DIR = Path(__file__).parent

APP_VERSION = "1.0.1"
ENV_FILE = APP_DIR / ".env"
VERSION_FILE = APP_DIR / ".last_version"
BACKUP_DIR = APP_DIR / "backups"
PORT     = 5000   # default; _find_free_port() may change this at runtime

# ── Colours ──────────────────────────────────────────────────────────────────
DARK     = "#1E3A5F"
ACCENT   = "#2E75B6"
LIGHT    = "#F7F9FC"   # wizard body background
WHITE    = "#FFFFFF"
GREEN    = "#16A34A"
RED      = "#DC2626"
TEXT     = "#1F2937"   # primary text on light bg
SUBTEXT  = "#6B7280"   # secondary text on light bg
DIM_DARK = "#94A3B8"   # readable text on dark bg (was #64748B — too dim)


# ─────────────────────────────────────────────────────────────────────────────
# SETUP WIZARD
# ─────────────────────────────────────────────────────────────────────────────
class SetupWizard(tk.Toplevel):
    """
    Modal dialog that asks the user for database credentials.
    Supports PostgreSQL, PocketBase, or local-only mode.
    Shown on first launch or when reconfiguring via Settings.
    """
    def __init__(self, parent, existing: dict):
        super().__init__(parent)
        self.title("Work Log — Database Setup")
        self.resizable(False, False)
        self.configure(bg=LIGHT)
        self.grab_set()
        self.result = None
        self._build(existing)
        self._center()

    def _center(self):
        self.update_idletasks()
        # Use reqwidth/reqheight: reflects content-based size, not current window size.
        # More reliable than winfo_width/height after geometry("") on macOS.
        w = self.winfo_reqwidth()
        h = self.winfo_reqheight()
        sw, sh = self.winfo_screenwidth(), self.winfo_screenheight()
        self.geometry(f"{w}x{h}+{(sw-w)//2}+{(sh-h)//2}")

    def _build(self, existing):
        # Header
        hdr = tk.Frame(self, bg=DARK, height=56)
        hdr.pack(fill="x"); hdr.pack_propagate(False)
        tk.Label(hdr, text="  📋  Work Log Journal", font=("Arial", 14, "bold"),
                 bg=DARK, fg=WHITE).pack(side="left", padx=14, pady=10)

        body = tk.Frame(self, bg=WHITE, padx=24, pady=18)
        body.pack(fill="both", expand=True)

        # Intro
        tk.Label(body, text="選擇雲端資料庫類型，或僅使用本機儲存。",
                 font=("Arial", 10), bg=WHITE, fg=TEXT,
                 justify="left", anchor="w").pack(fill="x", pady=(0, 10))

        # ── DB type radio buttons ────────────────────────────────────────────
        # Use tk.Radiobutton with explicit indicator colors so macOS shows them
        if existing.get("POSTGRES_URL"):
            default_mode = "postgres"
        elif existing.get("POCKETBASE_URL"):
            default_mode = "pocketbase"
        else:
            default_mode = "local"

        self._mode = tk.StringVar(value=default_mode)

        radio_frame = tk.Frame(body, bg=WHITE)
        radio_frame.pack(fill="x", pady=(0, 10))

        for val, label in [
            ("postgres",   "PostgreSQL  (Raspberry Pi / VPS)"),
            ("pocketbase", "PocketBase"),
            ("local",      "僅本機儲存（SQLite）"),
        ]:
            tk.Radiobutton(
                radio_frame, text=label, variable=self._mode, value=val,
                command=self._on_mode_change,
                bg=WHITE, fg=TEXT,
                activebackground=WHITE, activeforeground=DARK,
                selectcolor=WHITE,          # macOS: colour of the dot's bg circle
                font=("Arial", 10),
                anchor="w", padx=2,
            ).pack(fill="x", pady=2)

        tk.Frame(body, bg="#D1D5DB", height=1).pack(fill="x", pady=(4, 0))

        # ── Panel container — use grid so switching doesn't break layout order
        self._panel_host = tk.Frame(body, bg=WHITE)
        self._panel_host.pack(fill="x")
        self._panel_host.columnconfigure(0, weight=1)

        # ── PostgreSQL panel ─────────────────────────────────────────────────
        self._pg_frame = tk.Frame(self._panel_host, bg=WHITE, pady=12)
        self._pg_frame.columnconfigure(0, weight=1)

        tk.Label(self._pg_frame, text="PostgreSQL URL",
                 font=("Arial", 10, "bold"), bg=WHITE, fg=TEXT,
                 anchor="w").grid(row=0, column=0, sticky="w")
        self._pg_url = ttk.Entry(self._pg_frame, font=("Arial", 10), width=54)
        self._pg_url.insert(0, existing.get("POSTGRES_URL",
                            "postgresql://worklog_user:密碼@192.168.1.xxx:5432/worklogdb"))
        self._pg_url.grid(row=1, column=0, sticky="ew", pady=(4, 2))
        tk.Label(self._pg_frame,
                 text="格式：postgresql://使用者:密碼@主機IP:5432/資料庫名",
                 font=("Arial", 9), bg=WHITE, fg=SUBTEXT,
                 anchor="w").grid(row=2, column=0, sticky="w")

        # ── PocketBase panel ─────────────────────────────────────────────────
        self._pb_frame = tk.Frame(self._panel_host, bg=WHITE, pady=12)
        self._pb_frame.columnconfigure(0, weight=1)

        tk.Label(self._pb_frame, text="PocketBase URL",
                 font=("Arial", 10, "bold"), bg=WHITE, fg=TEXT,
                 anchor="w").grid(row=0, column=0, sticky="w")
        self._pb_url = ttk.Entry(self._pb_frame, font=("Arial", 10), width=54)
        self._pb_url.insert(0, existing.get("POCKETBASE_URL", "http://127.0.0.1:8090"))
        self._pb_url.grid(row=1, column=0, sticky="ew", pady=(4, 2))
        tk.Label(self._pb_frame,
                 text="e.g. http://127.0.0.1:8090 or https://your-pocketbase-server.com",
                 font=("Arial", 9), bg=WHITE, fg=SUBTEXT,
                 anchor="w").grid(row=2, column=0, sticky="w")

        tk.Label(self._pb_frame, text="PocketBase Token（選填）",
                 font=("Arial", 10, "bold"), bg=WHITE, fg=TEXT,
                 anchor="w").grid(row=3, column=0, sticky="w", pady=(14, 0))
        self._pb_token = ttk.Entry(self._pb_frame, font=("Arial", 10), width=54, show="•")
        self._pb_token.insert(0, existing.get("POCKETBASE_TOKEN", ""))
        self._pb_token.grid(row=4, column=0, sticky="ew", pady=(4, 2))
        tk.Label(self._pb_frame,
                 text="PocketBase Admin UI → Settings → API Keys",
                 font=("Arial", 9), bg=WHITE, fg=SUBTEXT,
                 anchor="w").grid(row=5, column=0, sticky="w")
        self._show_token = tk.BooleanVar(value=False)
        tk.Checkbutton(self._pb_frame, text="顯示 Token", variable=self._show_token,
                       command=self._toggle_token,
                       bg=WHITE, fg=TEXT, activebackground=WHITE,
                       selectcolor=WHITE, font=("Arial", 9),
                       ).grid(row=6, column=0, sticky="w", pady=(6, 0))

        # ── Local panel ──────────────────────────────────────────────────────
        self._local_frame = tk.Frame(self._panel_host, bg=WHITE, pady=12)
        tk.Label(self._local_frame,
                 text="所有資料儲存在本機 SQLite 資料庫，無需任何外部服務。",
                 font=("Arial", 10), bg=WHITE, fg=TEXT, justify="left").pack(anchor="w")

        # All panels in same grid cell — show/hide with grid()/grid_remove()
        for f in (self._pg_frame, self._pb_frame, self._local_frame):
            f.grid(row=0, column=0, sticky="ew")
            f.grid_remove()

        # Show default panel
        self._on_mode_change()

        # Separator + button
        tk.Frame(body, bg="#D1D5DB", height=1).pack(fill="x", pady=(0, 14))
        btn_row = tk.Frame(body, bg=WHITE)
        btn_row.pack(fill="x")
        ttk.Button(btn_row, text="▶  Start App", command=self._save,
                   ).pack(side="right")

    def _on_mode_change(self):
        """Switch visible panel, then auto-resize the window to fit."""
        self._pg_frame.grid_remove()
        self._pb_frame.grid_remove()
        self._local_frame.grid_remove()
        mode = self._mode.get()
        if mode == "postgres":
            self._pg_frame.grid()
        elif mode == "pocketbase":
            self._pb_frame.grid()
        else:
            self._local_frame.grid()
        # Two update_idletasks() passes: first propagates grid changes,
        # second processes the geometry("") auto-size request.
        self.update_idletasks()
        self.geometry("")
        self.update_idletasks()
        self._center()

    def _toggle_token(self):
        self._pb_token.config(show="" if self._show_token.get() else "•")

    def _save(self):
        mode = self._mode.get()
        if mode == "postgres":
            self.result = {
                "POSTGRES_URL":    self._pg_url.get().strip(),
                "POCKETBASE_URL":  "",
                "POCKETBASE_TOKEN": "",
            }
        elif mode == "pocketbase":
            self.result = {
                "POSTGRES_URL":    "",
                "POCKETBASE_URL":  self._pb_url.get().strip(),
                "POCKETBASE_TOKEN": self._pb_token.get().strip(),
            }
        else:
            self.result = {
                "POSTGRES_URL":    "",
                "POCKETBASE_URL":  "",
                "POCKETBASE_TOKEN": "",
            }
        self.destroy()


# ─────────────────────────────────────────────────────────────────────────────
# CONTROL WINDOW (shown while app is running)
# ─────────────────────────────────────────────────────────────────────────────
class ControlWindow(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title(f"Work Log Journal  v{APP_VERSION}")
        self.resizable(False, False)
        self.configure(bg=DARK)
        self.protocol("WM_DELETE_WINDOW", self._on_close)
        self._server_thread = None
        self._server_started = False
        self._build()
        self._center()
        self._boot()

    def _center(self):
        self.update_idletasks()
        self.geometry("")          # let tkinter size to content
        self.update_idletasks()
        w = max(440, self.winfo_reqwidth())
        h = max(290, self.winfo_reqheight())
        sw, sh = self.winfo_screenwidth(), self.winfo_screenheight()
        self.geometry(f"{w}x{h}+{(sw-w)//2}+{(sh-h)//2}")

    def _build(self):
        # Header
        tk.Label(self, text="📋  Work Log Journal",
                 font=("Arial", 14, "bold"),
                 bg=DARK, fg=WHITE).pack(pady=(20, 4))
        tk.Label(self, text="Server Control Panel",
                 font=("Arial", 9), bg=DARK, fg="#BAD4F5").pack()

        # Status indicator
        status_frame = tk.Frame(self, bg=DARK)
        status_frame.pack(pady=16)
        self._dot = tk.Label(status_frame, text="●", font=("Arial", 14),
                             bg=DARK, fg="#F59E0B")
        self._dot.pack(side="left", padx=(0, 6))
        self._status_lbl = tk.Label(status_frame, text="Starting…",
                                     font=("Arial", 11, "bold"), bg=DARK, fg=WHITE)
        self._status_lbl.pack(side="left")

        # URL labels (local + LAN) — both clickable
        url_frame = tk.Frame(self, bg=DARK)
        url_frame.pack(pady=(4, 0))

        self._url_local_lbl = tk.Label(url_frame, text="",
                                        font=("Arial", 10, "underline"), bg=DARK, fg="#60A5FA",
                                        cursor="hand2", anchor="center")
        self._url_local_lbl.pack()
        self._url_local_lbl.bind("<Button-1>", lambda _: self._open_browser())

        self._url_lan_lbl = tk.Label(url_frame, text="",
                                      font=("Arial", 10, "underline"), bg=DARK, fg="#60A5FA",
                                      cursor="hand2", anchor="center")
        self._url_lan_lbl.pack()
        self._url_lan_lbl.bind("<Button-1>", lambda _: self._open_browser_lan())

        # DB label
        self._db_lbl = tk.Label(self, text="",
                                 font=("Arial", 9), bg=DARK, fg=DIM_DARK)
        self._db_lbl.pack(pady=(6, 0))

        # Buttons — ttk for native macOS rendering
        btn_frame = tk.Frame(self, bg=DARK)
        btn_frame.pack(pady=20)

        ttk.Button(btn_frame, text="🌐  Open Browser",
                   command=self._open_browser,
                   ).pack(side="left", padx=5)

        ttk.Button(btn_frame, text="⚙  Settings",
                   command=self._open_settings,
                   ).pack(side="left", padx=5)

        ttk.Button(btn_frame, text="✕  Stop",
                   command=self._on_close,
                   ).pack(side="left", padx=5)

        tk.Label(self, text=f"v{APP_VERSION}  |  port {PORT}",
                 font=("Arial", 8), bg=DARK, fg=DIM_DARK).pack(side="bottom", pady=8)

    # ── Boot sequence ─────────────────────────────────────────────────────────
    def _boot(self):
        # Check version and create backup if needed
        _check_and_backup()

        env = _load_env()
        if _needs_setup(env):
            self.after(100, self._run_setup)
        else:
            self.after(100, self._start_server)

    def _run_setup(self, reconfigure=False):
        env = _load_env()   # always pre-fill wizard with existing .env values
        dlg = SetupWizard(self, env)
        self.wait_window(dlg)
        if dlg.result is None:
            # User closed the dialog without choosing — exit
            self.destroy(); return
        _save_env(dlg.result)
        self._start_server()

    def _start_server(self):
        global PORT
        PORT = _find_free_port()
        self._set_status(f"Starting on port {PORT}…", "#F59E0B")
        self._server_thread = threading.Thread(
            target=_run_flask, args=(BASE_DIR, PORT), daemon=True)
        self._server_thread.start()
        self.after(300, self._wait_for_server)

    def _wait_for_server(self, attempts=0):
        if _flask_ready(PORT):
            env = _load_env()
            # Determine database type based on configured environment
            if env.get("POSTGRES_URL"):
                db_type = "PostgreSQL ☁"
            elif env.get("POCKETBASE_URL"):
                db_type = "PocketBase ☁"
            else:
                db_type = "SQLite (local)"
            self._set_status("Running", GREEN)
            lan_ip = _get_lan_ip()
            self._url_local_lbl.config(text=f"本機: http://localhost:{PORT}  ← click")
            if lan_ip:
                self._url_lan_lbl.config(text=f"區網: http://{lan_ip}:{PORT}  ← click")
            else:
                self._url_lan_lbl.config(text="")
            env = _load_env()
            if env.get("POSTGRES_URL"):
                db_text = f"資料庫: PostgreSQL ☁"
            elif env.get("POCKETBASE_URL"):
                db_text = f"資料庫: PocketBase ☁ → {env['POCKETBASE_URL']}"
            else:
                db_text = "資料庫: SQLite (本機)"
            self._db_lbl.config(text=db_text)
            if not self._server_started:
                self._server_started = True
                webbrowser.open(f"http://localhost:{PORT}")
        elif attempts < 40:
            self.after(500, self._wait_for_server, attempts + 1)
        else:
            self._set_status("Failed to start", RED)
            messagebox.showerror(
                "Start Failed",
                f"The server failed to start on port {PORT}.\n"
                "Please restart the application.")

    def _set_status(self, text, colour):
        self._status_lbl.config(text=text)
        self._dot.config(fg=colour)

    def _open_browser(self):
        webbrowser.open(f"http://localhost:{PORT}")

    def _open_browser_lan(self):
        lan_ip = _get_lan_ip()
        if lan_ip:
            webbrowser.open(f"http://{lan_ip}:{PORT}")

    def _open_settings(self):
        if messagebox.askyesno(
                "Reconfigure",
                "Re-enter your database credentials?\n"
                "(The server will restart after saving.)"):
            self._run_setup(reconfigure=True)

    def _on_close(self):
        if messagebox.askyesno("Stop Server",
                                "Stop the Work Log server?\n"
                                "(The browser app will no longer be accessible.)"):
            self.destroy()


# ─────────────────────────────────────────────────────────────────────────────
# HELPERS
# ─────────────────────────────────────────────────────────────────────────────
def _check_and_backup():
    """
    Check if the version has changed since last run.
    If yes, create a backup of the previous version's files.
    """
    try:
        last_version = None
        if VERSION_FILE.exists():
            last_version = VERSION_FILE.read_text(encoding="utf-8").strip()

        # If version has changed and this is not the first run
        if last_version and last_version != APP_VERSION:
            # Create backups directory if it doesn't exist
            BACKUP_DIR.mkdir(exist_ok=True)

            # Create backup filename with version number
            backup_name = f"WorkLog_v{last_version}_backup.zip"
            backup_path = BACKUP_DIR / backup_name

            # Skip if backup already exists
            if not backup_path.exists():
                # Files to backup
                files_to_backup = [
                    "app.py",
                    "launcher.py",
                    "VERSION",
                    "requirements.txt",
                    "worklog.spec",
                    "schema.sql",
                    ".env.example"
                ]

                # Create zip backup
                with zipfile.ZipFile(backup_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
                    for filename in files_to_backup:
                        file_path = APP_DIR / filename
                        if file_path.exists():
                            zipf.write(file_path, filename)

                    # Also backup WorkLog.db if it exists
                    db_path = APP_DIR / "WorkLog.db"
                    if db_path.exists():
                        zipf.write(db_path, "WorkLog.db")

                print(f"✓ Backup created: {backup_name}")

        # Update version file
        VERSION_FILE.write_text(APP_VERSION, encoding="utf-8")

    except Exception as e:
        print(f"Warning: Backup failed: {e}", file=sys.stderr)
        # Don't fail startup if backup fails


def _load_env() -> dict:
    """Read .env file into a dict."""
    env = {}
    if ENV_FILE.exists():
        for line in ENV_FILE.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                k, _, v = line.partition("=")
                env[k.strip()] = v.strip()
    return env


def _save_env(values: dict):
    """Write / update .env file."""
    existing = _load_env()
    existing.update({k: v for k, v in values.items()})
    lines = [
        "# Work Log Journal — Environment Variables",
        "# Auto-generated by the setup wizard.",
        "",
    ]
    for k, v in existing.items():
        lines.append(f"{k}={v}")
    ENV_FILE.write_text("\n".join(lines) + "\n", encoding="utf-8")


def _needs_setup(env: dict) -> bool:
    """True if this is the first run (no .env) — always show setup."""
    return not ENV_FILE.exists()


def _find_free_port(start: int = 5000, end: int = 5020) -> int:
    """Return the first TCP port in [start, end] not currently in use."""
    for p in range(start, end + 1):
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            try:
                s.bind(("0.0.0.0", p))
                return p          # bind succeeded → port is free
            except OSError:
                continue
    return start                  # fallback (will likely fail gracefully)


def _port_open(port: int) -> bool:
    """True when something is listening on the port (i.e. Flask is up)."""
    try:
        with socket.create_connection(("127.0.0.1", port), timeout=0.5):
            return True
    except OSError:
        return False


def _flask_ready(port: int) -> bool:
    """True when Flask is actually responding to HTTP requests (not just TCP open)."""
    try:
        import urllib.request
        with urllib.request.urlopen(
            f"http://127.0.0.1:{port}/api/config", timeout=1
        ) as resp:
            return resp.status == 200
    except Exception:
        return False


def _get_lan_ip() -> str:
    """Return the machine's LAN IP, or empty string if unavailable."""
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
            s.connect(("8.8.8.8", 80))
            return s.getsockname()[0]
    except OSError:
        return ""


def _run_flask(base_dir: Path, port: int):
    """Launch the Flask app in-process."""
    env = _load_env()
    for k, v in env.items():
        os.environ.setdefault(k, v)

    sys.path.insert(0, str(base_dir))
    os.chdir(str(APP_DIR))

    try:
        import app as flask_app
        flask_app.app.run(host="0.0.0.0", port=port, debug=False, use_reloader=False)
    except Exception as e:
        print(f"Flask error: {e}", file=sys.stderr)


# ─────────────────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    win = ControlWindow()
    win.mainloop()
