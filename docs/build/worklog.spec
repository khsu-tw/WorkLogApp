# -*- mode: python ; coding: utf-8 -*-
"""
Work Log Journal - PyInstaller Spec File
=========================================
This file configures how PyInstaller packages the application.

Usage:
    pyinstaller --clean worklog.spec

Or simply run:
    build.bat
"""

import sys
from pathlib import Path

block_cipher = None

# Get the directory containing this spec file
SPEC_DIR = Path(SPECPATH)

a = Analysis(
    ['../../launcher.py'],
    pathex=[str(SPEC_DIR / '../..')],
    binaries=[],
    datas=[
        # Include app.py as data (imported at runtime)
        ('../../app.py', '.'),
        # Include schema for database initialization
        ('schema.sql', '.'),
        # Include version file
        ('../../VERSION', '.'),
        # Include .env.example as template
        ('../../.env.example', '.'),
    ],
    hiddenimports=[
        # Flask and dependencies
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
        # PocketBase (cloud sync)
        'pocketbase',
        'httpx',
        'httpcore',
        'anyio',
        'sniffio',
        'h11',
        'certifi',
        'idna',
        # PostgreSQL (alternative cloud sync)
        'psycopg2',
        'psycopg2.extras',
        'psycopg2.extensions',
        # python-docx
        'docx',
        'docx.shared',
        'docx.enum.text',
        'docx.oxml',
        'docx.oxml.ns',
        'lxml',
        'lxml.etree',
        'lxml._elementpath',
        # Pillow
        'PIL',
        'PIL.Image',
        # openpyxl (Excel)
        'openpyxl',
        'openpyxl.styles',
        'openpyxl.workbook',
        'openpyxl.worksheet',
        # fpdf2 (PDF)
        'fpdf',
        # Other
        'dotenv',
        'sqlite3',
        'email.mime.text',
    ],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[
        'matplotlib',
        'numpy',
        'pandas',
        'scipy',
        'pytest',
        'IPython',
        'notebook',
        'tkinter.test',
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
    name='WorkLog',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    console=False,  # No console window (GUI app)
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
    icon=None,  # Add icon path here if you have one: icon='icon.ico'
    version='version_info.txt' if Path('version_info.txt').exists() else None,
)

coll = COLLECT(
    exe,
    a.binaries,
    a.zipfiles,
    a.datas,
    strip=False,
    upx=True,
    upx_exclude=[],
    name='WorkLog',
)
