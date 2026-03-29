"""
Work Log Journal — Launcher
===========================
Entry point for the packaged application.
• On first run: shows a setup wizard asking for Supabase credentials
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
    # Running as PyInstaller bundle
    APP_DIR  = Path(sys.executable).parent
    BASE_DIR = Path(sys._MEIPASS)          # bundled files
else:
    APP_DIR  = Path(__file__).parent
    BASE_DIR = Path(__file__).parent

APP_VERSION = "0.9.6"
ENV_FILE = APP_DIR / ".env"
VERSION_FILE = APP_DIR / ".last_version"
BACKUP_DIR = APP_DIR / "backups"
PORT     = 5000   # default; _find_free_port() may change this at runtime

# ── Colours ──────────────────────────────────────────────────────────────────
DARK     = "#1E3A5F"
ACCENT   = "#2E75B6"
LIGHT    = "#F0F4FB"
WHITE    = "#FFFFFF"
GREEN    = "#16A34A"
RED      = "#DC2626"


# ─────────────────────────────────────────────────────────────────────────────
# SETUP WIZARD
# ─────────────────────────────────────────────────────────────────────────────
class SetupWizard(tk.Toplevel):
    """
    Modal dialog that asks the user for Supabase credentials.
    Shown on first launch or when .env is missing / invalid.
    """
    def __init__(self, parent, existing: dict):
        super().__init__(parent)
        self.title("Work Log — Initial Setup")
        self.resizable(False, False)
        self.configure(bg=LIGHT)
        self.grab_set()
        self.result = None
        self._build(existing)
        self._center()

    def _center(self):
        self.update_idletasks()
        w, h = self.winfo_width(), self.winfo_height()
        sw, sh = self.winfo_screenwidth(), self.winfo_screenheight()
        self.geometry(f"{w}x{h}+{(sw-w)//2}+{(sh-h)//2}")

    def _build(self, existing):
        # Header
        hdr = tk.Frame(self, bg=DARK, height=56)
        hdr.pack(fill="x"); hdr.pack_propagate(False)
        tk.Label(hdr, text="  📋  Work Log Journal", font=("Arial", 14, "bold"),
                 bg=DARK, fg=WHITE).pack(side="left", padx=14, pady=10)

        body = tk.Frame(self, bg=LIGHT, padx=24, pady=18)
        body.pack(fill="both", expand=True)

        # Intro
        intro = ("Welcome!  Work Log can store data in the cloud using Supabase,\n"
                 "or locally on this computer.\n\n"
                 "Leave both fields blank to use local storage only.")
        tk.Label(body, text=intro, font=("Arial", 9), bg=LIGHT, fg="#374151",
                 justify="left", anchor="w").pack(fill="x", pady=(0, 16))

        # Supabase URL
        tk.Label(body, text="Supabase URL", font=("Arial", 9, "bold"),
                 bg=LIGHT, fg=DARK, anchor="w").pack(fill="x")
        self._url = ttk.Entry(body, font=("Arial", 10), width=52)
        self._url.insert(0, existing.get("SUPABASE_URL", ""))
        self._url.pack(fill="x", pady=(2, 10))
        tk.Label(body, text="e.g. https://xxxx.supabase.co",
                 font=("Arial", 8), bg=LIGHT, fg="#6B7280", anchor="w").pack(fill="x")

        # Supabase Key
        tk.Label(body, text="Supabase Anon Key", font=("Arial", 9, "bold"),
                 bg=LIGHT, fg=DARK, anchor="w").pack(fill="x", pady=(12, 0))
        self._key = ttk.Entry(body, font=("Arial", 10), width=52, show="•")
        self._key.insert(0, existing.get("SUPABASE_KEY", ""))
        self._key.pack(fill="x", pady=(2, 4))
        tk.Label(body,
                 text="Generate at: id.atlassian.com/manage-profile/security/api-tokens  "
                      "(Project Settings → API → anon public)",
                 font=("Arial", 8), bg=LIGHT, fg="#6B7280",
                 anchor="w", wraplength=460, justify="left").pack(fill="x")

        # Show / hide key
        self._show_key = tk.BooleanVar(value=False)
        ttk.Checkbutton(body, text="Show key", variable=self._show_key,
                        command=self._toggle_key).pack(anchor="w", pady=(2, 0))

        # Separator
        tk.Frame(body, bg="#E5E7EB", height=1).pack(fill="x", pady=14)

        # Buttons
        btn_row = tk.Frame(body, bg=LIGHT)
        btn_row.pack(fill="x")
        tk.Button(btn_row, text="Use Local Storage Only",
                  command=self._use_local,
                  bg="#E5E7EB", fg="#374151", font=("Arial", 9),
                  padx=12, pady=6, relief="flat", cursor="hand2"
                  ).pack(side="left")
        tk.Button(btn_row, text="▶  Start App",
                  command=self._save,
                  bg=ACCENT, fg=WHITE, font=("Arial", 10, "bold"),
                  padx=18, pady=6, relief="flat", cursor="hand2",
                  activebackground=DARK, activeforeground=WHITE
                  ).pack(side="right")

    def _toggle_key(self):
        self._key.config(show="" if self._show_key.get() else "•")

    def _use_local(self):
        self.result = {"SUPABASE_URL": "", "SUPABASE_KEY": ""}
        self.destroy()

    def _save(self):
        self.result = {
            "SUPABASE_URL": self._url.get().strip(),
            "SUPABASE_KEY": self._key.get().strip(),
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
        w, h = 360, 260
        sw, sh = self.winfo_screenwidth(), self.winfo_screenheight()
        self.geometry(f"{w}x{h}+{(sw-w)//2}+{(sh-h)//2}")

    def _build(self):
        # Header
        tk.Label(self, text="📋  Work Log Journal",
                 font=("Arial", 14, "bold"),
                 bg=DARK, fg=WHITE).pack(pady=(20, 4))
        tk.Label(self, text="Server Control Panel",
                 font=("Arial", 9), bg=DARK, fg="#93C5FD").pack()

        # Status indicator
        status_frame = tk.Frame(self, bg=DARK)
        status_frame.pack(pady=16)
        self._dot = tk.Label(status_frame, text="●", font=("Arial", 14),
                             bg=DARK, fg="#F59E0B")
        self._dot.pack(side="left", padx=(0, 6))
        self._status_lbl = tk.Label(status_frame, text="Starting…",
                                     font=("Arial", 10), bg=DARK, fg=WHITE)
        self._status_lbl.pack(side="left")

        # URL label
        self._url_lbl = tk.Label(self, text="",
                                  font=("Arial", 9), bg=DARK, fg="#93C5FD",
                                  cursor="hand2")
        self._url_lbl.pack()
        self._url_lbl.bind("<Button-1>", lambda _: self._open_browser())

        # DB label
        self._db_lbl = tk.Label(self, text="",
                                 font=("Arial", 8), bg=DARK, fg="#64748B")
        self._db_lbl.pack(pady=(4, 0))

        # Buttons
        btn_frame = tk.Frame(self, bg=DARK)
        btn_frame.pack(pady=20)

        tk.Button(btn_frame, text="🌐  Open Browser",
                  command=self._open_browser,
                  bg=ACCENT, fg=WHITE, font=("Arial", 10, "bold"),
                  padx=14, pady=6, relief="flat", cursor="hand2",
                  activebackground="#1E60A0"
                  ).pack(side="left", padx=5)

        tk.Button(btn_frame, text="⚙  Settings",
                  command=self._open_settings,
                  bg="#334155", fg=WHITE, font=("Arial", 10),
                  padx=10, pady=6, relief="flat", cursor="hand2"
                  ).pack(side="left", padx=5)

        tk.Button(btn_frame, text="✕  Stop",
                  command=self._on_close,
                  bg=RED, fg=WHITE, font=("Arial", 10),
                  padx=10, pady=6, relief="flat", cursor="hand2"
                  ).pack(side="left", padx=5)

        tk.Label(self, text=f"v{APP_VERSION}  |  port {PORT}",
                 font=("Arial", 7), bg=DARK, fg="#475569").pack(side="bottom", pady=8)

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
        env = _load_env() if not reconfigure else {}
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
        if _port_open(PORT):
            env = _load_env()
            db_type = "Supabase ☁" if env.get("SUPABASE_URL") else "SQLite (local)"
            self._set_status("Running", GREEN)
            self._url_lbl.config(text=f"http://localhost:{PORT}  ← click to open")
            self._db_lbl.config(text=f"Database: {db_type}")
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

    def _open_settings(self):
        if messagebox.askyesno(
                "Reconfigure",
                "Re-enter your Supabase credentials?\n"
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
                s.bind(("127.0.0.1", p))
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


def _run_flask(base_dir: Path, port: int):
    """Launch the Flask app in-process."""
    env = _load_env()
    for k, v in env.items():
        os.environ.setdefault(k, v)

    sys.path.insert(0, str(base_dir))
    os.chdir(str(APP_DIR))

    try:
        import app as flask_app
        flask_app.app.run(host="127.0.0.1", port=port, debug=False, use_reloader=False)
    except Exception as e:
        print(f"Flask error: {e}", file=sys.stderr)


# ─────────────────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    win = ControlWindow()
    win.mainloop()
