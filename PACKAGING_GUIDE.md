# 📦 應用程式打包完整指南

Work Log Journal 跨平台打包方案總覽

---

## 🎯 快速選擇指南

| 平台 | 方案 | 難度 | 需要 | 說明 |
|------|------|------|------|------|
| **Windows** | ✅ PyInstaller | 簡單 | Windows PC | 已完成 - 使用 `build.bat` |
| **macOS** | ✅ PyInstaller | 簡單 | macOS | 查看下方說明 |
| **iOS (快速)** | ✅ PWA | 極簡單 | 任何手機 | Safari 加入主畫面 |
| **iOS (App Store)** | ✅ Capacitor | 中等 | macOS + Xcode + $99/年 | 真正的 iOS 應用 |
| **Android** | 🔄 Capacitor | 中等 | Android Studio | 類似 iOS 流程 |

---

## 🖥️ macOS 應用程式

### 📋 需求
- macOS 電腦
- Python 3.8+
- Xcode Command Line Tools

### 🚀 快速開始

```bash
# 1. 賦予執行權限
chmod +x build_macos.sh create_dmg.sh

# 2. 構建應用
./build_macos.sh

# 3. (可選) 創建 DMG 安裝檔
./create_dmg.sh
```

### 📂 輸出
- **應用程式**: `dist/WorkLog.app`
- **安裝檔**: `dist/WorkLog-macOS.dmg`

### 📖 詳細說明
查看 [BUILD_MACOS.md](BUILD_MACOS.md)

---

## 📱 iOS 應用程式

### 方案比較

#### 🌐 方案 1: PWA (Progressive Web App) - 推薦快速部署

**優點:**
- ✅ 完全免費
- ✅ 無需開發者帳號
- ✅ 支援離線功能
- ✅ 即時更新,無需重新安裝
- ✅ 您的應用已支援!

**限制:**
- ❌ 不在 App Store
- ❌ 某些原生功能受限

**如何使用:**
1. 在 iPhone/iPad 的 Safari 打開應用
2. 點擊分享按鈕 (↑)
3. 選擇「加入主畫面」
4. 完成!應用圖標會出現在主畫面

**增強 PWA:**
- 已創建 `manifest.json` - PWA 配置文件
- 可以添加 Service Worker 實現離線功能
- 圖標需放在 `static/` 目錄

---

#### 📲 方案 2: Capacitor (原生 iOS 應用)

**優點:**
- ✅ 真正的原生應用
- ✅ 可上架 App Store
- ✅ 訪問所有原生功能(相機、通知等)
- ✅ 更好的效能和使用者體驗

**需求:**
- 💻 macOS + Xcode 14+
- 💰 Apple Developer Account ($99/年)
- 🌐 Flask 後端需部署到雲端

**架構:**
```
┌─────────────┐      ┌──────────────┐
│  iOS 應用   │ ───> │ 雲端 Flask    │
│ (Capacitor) │ API  │ (Railway 等) │
└─────────────┘      └──────────────┘
```

**快速開始:**
```bash
# 1. 安裝 Capacitor
chmod +x setup_ios_capacitor.sh
./setup_ios_capacitor.sh

# 2. 部署 Flask 到雲端 (見下方)

# 3. 更新 capacitor.config.json 的服務器網址

# 4. 在 Xcode 中構建
npx cap open ios
```

### 📖 詳細說明
查看 [BUILD_IOS.md](BUILD_IOS.md)

---

## ☁️ 雲端部署 (iOS Capacitor 需要)

### 選項 1: Railway (推薦)

**優點:** 免費額度、簡單、自動部署

```bash
# 1. 訪問 https://railway.app
# 2. 連接 GitHub 倉庫
# 3. 選擇這個專案
# 4. 自動部署!
```

配置文件已創建:
- ✅ `railway.json`
- ✅ `Procfile`

### 選項 2: Render

**優點:** 免費額度、可靠

1. 訪問 https://render.com
2. New → Web Service
3. 連接 GitHub
4. 設定:
   - Build Command: `pip install -r requirements.txt`
   - Start Command: `python app.py`

### 選項 3: Heroku

**優點:** 成熟穩定

```bash
# 安裝 Heroku CLI
heroku login
heroku create your-worklog-app
git push heroku main
```

### 選項 4: DigitalOcean App Platform

**優點:** 效能好,可擴展

1. 訪問 DigitalOcean
2. App Platform → Create App
3. 連接 GitHub
4. 選擇倉庫,自動檢測 Python

---

## 🔧 環境變數設定

部署到雲端時需要設定:

```bash
SECRET_KEY=your-secret-key-here
SUPABASE_URL=your-supabase-url
SUPABASE_KEY=your-supabase-key
PORT=5000  # 某些平台會自動設定
```

---

## 📊 推薦工作流程

### 個人/測試使用
```
Windows: build.bat
macOS: ./build_macos.sh
iOS/Android: PWA (Safari 加入主畫面)
```

### 團隊/內部使用
```
後端: 部署到 Railway/Render
存取: 任何設備瀏覽器 + PWA
```

### 商業/App Store 發布
```
後端: Railway/DigitalOcean + Supabase
iOS: Capacitor → Xcode → App Store
Android: Capacitor → Android Studio → Play Store
macOS: PyInstaller → 簽名 → DMG 分發
```

---

## 🛠️ 建置檔案說明

### Windows (已完成)
- `worklog.spec` - PyInstaller 配置
- `build.bat` - Windows 建置腳本

### macOS
- `worklog_macos.spec` - PyInstaller 配置
- `build_macos.sh` - macOS 建置腳本
- `create_dmg.sh` - DMG 安裝檔生成腳本

### iOS/PWA
- `manifest.json` - PWA 配置
- `setup_ios_capacitor.sh` - Capacitor 初始化腳本
- `capacitor.config.json` - (執行腳本後生成)

### 部署
- `railway.json` - Railway 部署配置
- `Procfile` - Heroku/Railway 啟動命令
- `requirements.txt` - Python 依賴

---

## 📞 需要協助?

**選擇方案後我可以幫您:**
1. 詳細配置特定平台
2. 修改程式碼以適配方案
3. 創建自動化部署腳本
4. 解決建置問題

**常見問題:**
- macOS 建置必須在 macOS 上執行
- iOS 建置需要 Apple 開發者帳號
- PWA 適合快速測試和內部使用
- Capacitor 適合 App Store 正式發布

---

## 🎉 下一步

1. **測試 Windows 版本**: 已有 `dist/WorkLog/WorkLog.exe`
2. **macOS**: 在 Mac 上執行 `./build_macos.sh`
3. **iOS 快速測試**: 使用 PWA (無需構建)
4. **iOS App Store**: 設定 Capacitor + 部署雲端

選擇您的方案,我隨時協助您完成!
