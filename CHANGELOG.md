# Work Log Journal — Changelog

All notable changes to this project are documented here.  
Format: [Semantic Versioning](https://semver.org)

---

## [v0.9.8] — 2026-03-30

- 將v0.9.6程式碼從Supabase完整遷移至PocketBase
- 修改Worklogs的欄位寬度與Task Summary相同寬度
- 縮減MCHP Device欄位寬度並允許自動換行
- 程式右上角顯示版本訊息 by Keynes Hsu
- 抓取PocketBase中Database 的Size，並於版面右上方顯示
- 顯示即時資料庫Egress的流量。
- 增加PDF輸出資料項選擇
- 資料庫sync頻率設定為每3分鐘或是當有資料變更改為推送(push)至雲端資料庫進行更新

## [v0.9.7] — 2026-03-29

- Full iOS/Android native app via Capacitor or React Native
- Multi-user authentication (Supabase Row Level Security per user)
- Attachment support (non-image files)
- Rich-text editor (WYSIWYG instead of Markdown)
- 程式修改進行程式檢查及測試，然後執行Clean build。

## [v0.9.6] — 2026-03-29

- 程式碼修改前對前一個版本程式碼先進行完整備份壓縮成.zip，壓縮檔名加註程式版本編號。
- 若程式無法進行判斷資料衝突情況，則出現提示方塊，並顯示比對差異，讓使用者決定是否保留為副本。
- 完整移除Worklogs編輯時進行英文單字及文法檢查建議功能。
- PDF輸出版面以A4橫式為主，自動調整版面格式，盡量將所有資料縮放以符合頁寬。允許Task Summary, Worklogs內容自動換行
- 確保MacOS, iOS程式一併完整修正。
- 程式修改進行程式檢查及測試，然後執行Clean build。

## [v0.9.5] — 2026-03-27

- 增加"Project Schedule"，欄位具有如Worklogs的Markdown功能，但不需要預覽功能
- 增加Excel及PDF輸出功能
- 資料表與Excel欄位顯示對應，僅顯示下列欄位於Excel中
- Customer -> OEM/ODM/OBM/Disti
- SSO/ModelN -> SSO#
- Project Name -> Project Name
- Application -> Application
- BU -> BU
- MCHP Device -> Microchip Devices
- Task Summary -> Status/Update
- Project Schedule -> Timeline
- EAR(K$) -> EAR(K$)
- 抓取SUPABASE中Database Tables的Size (Estimated)，並於版面右上方顯示
- 修正資料表未能顯示Project Schedule欄位
- 欄位名稱修正 Project -> Project Name
- 欄位名稱修正 Project Schedule -> Milestone
- Excel輸出欄位對應, Milestone -> Timeline
- 修正"MCHP Device"欄位不限字元長度
- Worklogs資料表顯示寬度增加
- 調整資料庫欄位及網頁顯示順序為: Week, Category, Customer, Project Name, Status, Task Summary, Worklogs, Schedule, Application, SSO/ModelN#, MCHP Device, EAR(K$), BU, Last Update, Create Date, Due Date, Archieve
- 程式修改後執行Clean build，並將程式完整包裝為Windows執行檔

## [v0.9.4] — 2026-03-26

- 當程式連上網路，優先複製Supabase資料庫為副本到本機端Worklog目錄下
- 新增的每筆資料會帶有日期及時間戳記，資料有任何更改時，時間戳記會自動記錄資料關閉的日期及時間，當網路恢復連線時本機端的資料庫會與Supabase上的資料庫時間戳記進行比對，若有時間戳記衝突時，則保留最後的時間戳記資料。
- 若程式無法進行判斷資料衝突情況，則出現提示方塊，讓使用者決定是否保留為副本。

## [v0.9.3] — 2026-03-26

- 資料庫欄位排列順序為Week, Create Date, Due Date, BU, SSO/ModelN#, Customer, Project Name, EAR(K$), Application, MCHP Device, Category, Status, Task Summary, Worklogs, Last Update, Archieve
- 當程式連上網路，優先複製Supabase資料庫為副本到本機端Worklog目錄下
- 新增的每筆資料會帶有日期及時間戳記，資料有任何更改時，時間戳記會自動記錄資料關閉的日期及時間，當網路恢復連線時本機端的資料庫會與Supabase上的資料庫時間戳記進行比對，若有時間戳記衝突時，則保留最後的時間戳記資料。

## [v0.9.2] — 2026-03-26

- 維持目前版面配置，在"SSO/ModelN#"欄位下方增加"EAR(K$)"，長度為20字元
- 修改"SSO/ModelN#"欄位，長度為10字元
- 增加下拉式選單"BU"，選項有"DCS", "NCS"
- 修改"Inquiries"為"MCHP Device"
- 程式右上角顯示版本訊息 by Keynes Hsu

## [v0.9.1] — 2026-03-26

- Worklogs內允許多行粗體、斜體、文字加底線、文字刪除線
- 程式右上角顯示版本訊息
- 增加"SSO/ModelN#"欄位，長度為20字元
- 增加"Application"欄位，長度為50字元

## [v0.9.0] — 2026-03-25

### 🆕 New Features

- **Offline-first architecture** — all reads/writes go to local SQLite; works without internet
- **Auto cloud sync** — background thread pushes/pulls to Supabase every 30 s when online
- **Conflict resolution UI** — side-by-side diff when the same record is edited offline on two devices; user chooses which version to keep
- **Sync status bar** — shows Online/Offline state, pending upload count, and conflict badge
- **Initial pull on first launch** — automatically loads all cloud records into local cache on first run
- **Setup wizard** — GUI dialog asks for Supabase URL + Key on first launch; "Use Local Storage Only" option
- **Server control window** — shows server status, DB type, port; one-click Open Browser / Settings / Stop
- **Auto port selection** — scans ports 5000–5020 to find a free one; no more "Port in use" errors
- **PWA support** — installable on iOS / Android via Safari → Add to Home Screen
- **Nested Markdown lists** — 2-space / tab indent → next level; `•` → `◦` → `▪` hierarchy

### 🐛 Bug Fixes

- Fixed `sys` not imported — caused `Flask error: name 'sys' is not defined`
- Fixed `console: none` invalid in VSCode `launch.json`
- Fixed hardcoded `.venv` interpreter path in VSCode `settings.json`
- Fixed `SQLITE_PATH` now resolves relative to executable (not CWD), so DB persists correctly
- Fixed `_is_online()` was hitting wrong Supabase endpoint — now checks `/rest/v1/{table}`
- Fixed Supabase credentials read at call time (not cached at import) so launcher env vars take effect
- Fixed `SyncEngine` always starts regardless of whether credentials exist at module load
- Fixed Word export builder functions missing after Confluence removal
- Fixed `_build_word_doc` — `import sys` was missing
- Fixed image `[📷 uid]` placeholder now inserts at cursor position, not end of textarea
- Fixed date stamp also inserts at cursor position

### ✨ Improvements

- Word export: Task Summary added as dedicated section; week range shows Mon–Fri dates
- Word export: Markdown bold/italic/code/headings/bullets/indent rendered in .docx
- Word export: images embedded at correct indent level matching Worklogs preview
- Word export: outputs **previous week's** entries (latest week − 1)
- Word export: records selectable via checkboxes; exports only checked rows
- Word export: no Protected View (core properties + documentProtection removed)
- Worklogs: image thumbnails show ✕ delete button; deletion removes placeholder from textarea
- Worklogs: images stored as stable `[📷 img_uid]` placeholders (not sequential numbers)
- Worklogs: date-only timestamps `── YYYY-MM-DD ──` (no time component)
- Worklogs: entries auto-sorted by date after inserting a new stamp
- Worklogs: image indent aligns with surrounding text in Preview
- Worklogs: Lightbox on image click; drag-to-resize; Esc to close
- SQLite: explicit `commit()` on all writes; WAL journal mode; proper connection cleanup
- Startup diagnostics: prints `.env` path, Supabase config status, DB type on launch
- `.env` loaded by `python-dotenv` at top of `app.py` before all `os.environ.get()` calls

### 🏗 Architecture

- **DB layer**: `LocalDB` (SQLite, always primary) + `SyncEngine` (background Supabase sync)
- **Sync columns**: `cloud_id`, `sync_status` (`pending` / `synced` / `conflict` / `deleted`), `local_updated_at`
- **Conflict detection**: `last_update` timestamp comparison; cloud newer → conflict stored in `sync_conflicts` table
- **Soft delete**: records marked `deleted` in local DB; propagated to cloud on next sync
- **Version**: `APP_VERSION = "0.9.0"` exposed via `/api/config`

### 📦 Packaging

- `launcher.py` — PyInstaller entry point with SetupWizard + ControlWindow (tkinter)
- `WorkLog.spec` — PyInstaller spec (single-file executable, no console window)
- `build.bat` / `build.sh` / `build_run.py` — one-command build scripts
- VSCode project (`WorkLog_VSCode.zip`) with correct `launch.json` and `settings.json`

---

## [Future / Planned]

- [ ] v1.0 — Full iOS/Android native app via Capacitor or React Native
- [ ] v1.0 — Multi-user authentication (Supabase Row Level Security per user)
- [ ] v1.0 — Attachment support (non-image files)
- [ ] v1.0 — Rich-text editor (WYSIWYG instead of Markdown)
- [ ] v1.1 — Export to PDF
- [ ] v1.1 — Email / calendar integration
