# -*- mode: python ; coding: utf-8 -*-
"""
Work Log Journal - macOS PyInstaller Spec File
===============================================
This file configures how PyInstaller packages the application for macOS.

Usage (on macOS):
    pyinstaller --clean worklog_macos.spec

Or use the build script:
    ./build_macos.sh
"""

import sys
from pathlib import Path

block_cipher = None

# Get the directory containing this spec file
SPEC_DIR = Path(SPECPATH)

a = Analysis(
    ['launcher.py'],
    pathex=[str(SPEC_DIR)],
    binaries=[],
    datas=[
        # Include app.py as data (imported at runtime)
        ('app.py', '.'),
        # Include schema for database initialization
        ('schema.sql', '.'),
        # Include version file
        ('VERSION', '.'),
        # Include .env.example as template
        ('.env.example', '.'),
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
        # Supabase and dependencies
        'supabase',
        'postgrest',
        'gotrue',
        'realtime',
        'storage3',
        'httpx',
        'httpcore',
        'anyio',
        'sniffio',
        'h11',
        'certifi',
        'idna',
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

# Create macOS .app bundle
app = BUNDLE(
    coll,
    name='WorkLog.app',
    icon=None,  # Add icon path here if you have one: icon='icon.icns'
    bundle_identifier='com.worklog.app',
    info_plist={
        'NSPrincipalClass': 'NSApplication',
        'NSHighResolutionCapable': 'True',
        'CFBundleShortVersionString': '1.0.0',
        'CFBundleVersion': '1.0.0',
        'LSMinimumSystemVersion': '10.13.0',
        'NSHumanReadableCopyright': 'Copyright © 2024',
        'LSApplicationCategoryType': 'public.app-category.productivity',
    },
)
