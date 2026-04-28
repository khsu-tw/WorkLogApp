# Work Log Journal - Installation Guide

## 📦 Package Contents

This package contains:
- `WorkLog.exe` / `WorkLog` / `WorkLog.app` - Main application
- `_internal/` - Required dependencies and data files
- `launch_debug.bat` / `launch_debug.sh` - Debug launcher (shows errors)
- `.env.example` - Configuration template

**⚠️ IMPORTANT**: Do NOT move or run the executable alone. The entire folder structure must stay together!

## 🚀 Quick Start

### Windows
1. **Extract the entire ZIP file** to a folder (e.g., `C:\WorkLog\`)
2. Double-click `WorkLog.exe` to launch

**If nothing happens:**
- Right-click `launch_debug.bat` → **Run as Administrator**
- This will show any error messages
- Take a screenshot and report at: https://github.com/khsu-tw/WorkLogApp/issues

### macOS
1. **Extract the entire archive** to a folder (e.g., `~/Applications/`)
2. Open Terminal and run:
   ```bash
   chmod +x launch_debug.sh
   ./launch_debug.sh
   ```
3. If blocked by Gatekeeper:
   - Right-click `WorkLog.app` → Open → Click "Open"
   - Or run: `xattr -cr WorkLog.app`

### Linux
1. **Extract the entire archive** to a folder
2. Make the launcher executable:
   ```bash
   chmod +x launch_debug.sh WorkLog
   ./launch_debug.sh
   ```

## 🔧 Troubleshooting

### Windows: "Missing VCRUNTIME140.dll"
Install Visual C++ Redistributable:
https://aka.ms/vs/17/release/vc_redist.x64.exe

### macOS: "Cannot be opened because the developer cannot be verified"
Run in Terminal:
```bash
xattr -cr WorkLog.app
```

### Linux: "Permission denied"
```bash
chmod +x WorkLog launch_debug.sh
```

### Application starts but shows errors
1. Run the debug launcher (`launch_debug.bat` or `launch_debug.sh`)
2. Screenshot any error messages
3. Report at: https://github.com/khsu-tw/WorkLogApp/issues

## 📁 File Structure

```
WorkLog/
├── WorkLog.exe (or WorkLog, WorkLog.app)
├── _internal/          ← DO NOT DELETE
│   ├── app.py          ← Core application
│   ├── VERSION         ← Version info
│   ├── .env.example    ← Config template
│   ├── schema.sql      ← Database schema
│   └── [many .pyd/.so/.dylib files]
├── launch_debug.bat    ← Debug launcher (Windows)
└── launch_debug.sh     ← Debug launcher (Linux/Mac)
```

## 🗄️ Data Files

Your data is stored in the same folder:
- `WorkLog.db` - Your work logs database
- `.env` - Configuration (created on first run)
- `backups/` - Automatic backups (created on version updates)

## 🆘 Still Having Issues?

1. Run the debug launcher to see error messages
2. Check that all files are extracted (not just the .exe)
3. Try running as Administrator (Windows) or with `sudo` (Linux)
4. Report issues with full error messages at:
   https://github.com/khsu-tw/WorkLogApp/issues

## 📝 Notes

- **First run**: A setup wizard will appear to configure your database
- **Port 5000**: The app uses port 5000 by default (auto-adjusts if busy)
- **Browser**: Opens automatically at http://localhost:5000
- **Updates**: Check GitHub releases for new versions
