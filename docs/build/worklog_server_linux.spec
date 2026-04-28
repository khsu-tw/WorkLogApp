# -*- mode: python ; coding: utf-8 -*-
"""
Work Log Journal - PyInstaller Spec (Headless Server, Linux)
=============================================================
Produces WorkLogServer — a standalone Flask server with no GUI dependency.
Suitable for running as a systemd service or on headless Raspberry Pi.

Usage:
    pyinstaller --clean docs/build/worklog_server_linux.spec
Or:
    ./build_server_linux.sh
"""

import sys
from pathlib import Path

block_cipher = None

SPEC_DIR = Path(SPECPATH)

a = Analysis(
    ['../../server.py'],
    pathex=[str(SPEC_DIR / '../..')],
    binaries=[],
    datas=[
        ('../../app.py', '.'),
        ('schema.sql', '.'),
        ('../../VERSION', '.'),
        ('../../.env.example', '.'),
        ('launch_debug.sh', '.'),
        ('PACKAGE_README.md', 'README.txt'),
    ],
    hiddenimports=[
        'flask',
        'flask.json',
        'flask.templating',
        'jinja2',
        'werkzeug',
        'werkzeug.serving',
        'werkzeug.debug',
        'click',
        'itsdangerous',
        'markupsafe',
        'pocketbase',
        'httpx',
        'httpcore',
        'anyio',
        'sniffio',
        'h11',
        'certifi',
        'idna',
        'psycopg2',
        'psycopg2.extras',
        'psycopg2.extensions',
        'docx',
        'docx.shared',
        'docx.enum.text',
        'docx.oxml',
        'docx.oxml.ns',
        'lxml',
        'lxml.etree',
        'lxml._elementpath',
        'PIL',
        'PIL.Image',
        'openpyxl',
        'openpyxl.styles',
        'openpyxl.workbook',
        'openpyxl.worksheet',
        'fpdf',
        'dotenv',
        'sqlite3',
        'email.mime.text',
    ],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[
        'tkinter',
        'tkinter.ttk',
        'tkinter.messagebox',
        '_tkinter',
        'matplotlib',
        'numpy',
        'pandas',
        'scipy',
        'pytest',
        'IPython',
        'notebook',
    ],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
)

pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

exe = EXE(
    pyz,
    a.scripts,
    [],
    exclude_binaries=True,
    name='WorkLogServer',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    console=True,   # show terminal output (headless server)
    disable_windowed_traceback=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
)

coll = COLLECT(
    exe,
    a.binaries,
    a.zipfiles,
    a.datas,
    strip=False,
    upx=True,
    upx_exclude=[],
    name='WorkLogServer',
)
