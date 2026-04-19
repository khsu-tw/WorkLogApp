"""
Work Log Journal — Headless Server Entry Point
===============================================
Runs the Flask server directly without any GUI (no Tkinter).
Suitable for running as a background service (e.g. systemd) or on
headless servers / Raspberry Pi without a display.

Usage:
    ./WorkLogServer              # uses port 5000 by default
    PORT=8080 ./WorkLogServer    # override port via environment variable
"""

import os
import sys
import socket
from pathlib import Path

# ── Determine directories ─────────────────────────────────────────────────────
if getattr(sys, 'frozen', False):
    BASE_DIR = Path(sys._MEIPASS)
    APP_DIR  = Path(sys.executable).resolve().parent
else:
    BASE_DIR = Path(__file__).parent
    APP_DIR  = Path(__file__).parent

ENV_FILE = APP_DIR / ".env"
PORT = int(os.environ.get("PORT", 5000))


def _load_env() -> dict:
    env = {}
    if ENV_FILE.exists():
        for line in ENV_FILE.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                k, _, v = line.partition("=")
                env[k.strip()] = v.strip()
    return env


def _get_lan_ip() -> str:
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
            s.connect(("8.8.8.8", 80))
            return s.getsockname()[0]
    except OSError:
        return ""


def main():
    # Load .env into environment
    env = _load_env()
    for k, v in env.items():
        os.environ.setdefault(k, v)

    sys.path.insert(0, str(BASE_DIR))
    os.chdir(str(APP_DIR))

    lan_ip = _get_lan_ip()

    print("=" * 50)
    print(" Work Log Journal — Server")
    print("=" * 50)
    print(f"  Local:  http://localhost:{PORT}")
    if lan_ip:
        print(f"  LAN:    http://{lan_ip}:{PORT}")
    if env.get("POCKETBASE_URL"):
        print(f"  Sync:   PocketBase → {env['POCKETBASE_URL']}")
    elif env.get("POSTGRES_URL"):
        print(f"  Sync:   PostgreSQL")
    else:
        print(f"  Sync:   SQLite (local only)")
    print("=" * 50)
    print("  Press Ctrl+C to stop")
    print()

    import app as flask_app
    flask_app.app.run(host="0.0.0.0", port=PORT, debug=False, use_reloader=False)


if __name__ == "__main__":
    main()
