# -*- mode: python ; coding: utf-8 -*-
"""
Work Log Journal - PyInstaller Spec File (macOS)
=================================================
Produces a .app bundle for macOS distribution.

Usage:
    pyinstaller --clean worklog_mac.spec

Or simply run:
    ./build_mac.sh
"""

import sys
from pathlib import Path

block_cipher = None

SPEC_DIR = Path(SPECPATH)

a = Analysis(
    ['../../launcher.py'],
    pathex=[str(SPEC_DIR / '../..')],
    binaries=[],
    datas=[
        ('../../app.py', '.'),
        ('schema.sql', '.'),
        ('../../VERSION', '.'),
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
    console=False,
    disable_windowed_traceback=False,
    argv_emulation=True,    # macOS: 讓 .app 能接收 Finder 傳來的檔案參數
    target_arch=None,       # None = 自動偵測目前架構 (arm64/x86_64)
    codesign_identity=None,
    entitlements_file=None,
    icon=None,              # 若有 .icns 圖示，填入路徑：icon='icon.icns'
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

# macOS .app bundle
app = BUNDLE(
    coll,
    name='WorkLog.app',
    icon=None,              # 若有 .icns 圖示，填入路徑：icon='icon.icns'
    bundle_identifier='com.worklog.journal',
    info_plist={
        'CFBundleName': 'WorkLog',
        'CFBundleDisplayName': 'Work Log Journal',
        'CFBundleVersion': (SPEC_DIR / '../../VERSION').read_text().strip(),
        'CFBundleShortVersionString': (SPEC_DIR / '../../VERSION').read_text().strip(),
        'NSHighResolutionCapable': True,
        'LSMinimumSystemVersion': '11.0',
        'NSRequiresAquaSystemAppearance': False,  # 支援 Dark Mode
    },
)
