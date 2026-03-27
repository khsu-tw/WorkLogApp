# 📱 iOS Build Instructions

## iOS 打包方案比較

### ✅ 方案 1: Capacitor (推薦)
將 Flask 應用包裝成原生 iOS 應用,可上架 App Store

**優點:**
- 真正的原生 iOS 應用
- 可訪問原生功能(相機、通知等)
- 可上架 App Store
- 保留現有 Flask 後端

**缺點:**
- 需要 macOS + Xcode
- 需要 Apple Developer Account($99/年)

### ✅ 方案 2: PWA (Progressive Web App)
將網頁加入 iOS 主畫面(程式中已支援)

**優點:**
- 無需打包,直接使用
- 免費,無需開發者帳號
- 支援離線功能

**缺點:**
- 不是真正的 App Store 應用
- 功能受限(無法訪問某些原生功能)

---

## 🔧 方案 1: 使用 Capacitor 打包 iOS 應用

### Prerequisites

1. **macOS** with **Xcode 14+**
2. **Node.js 16+** and npm
3. **CocoaPods**: `sudo gem install cocoapods`
4. **Apple Developer Account** (for App Store distribution)

### Step 1: 安裝 Capacitor

```bash
# Install Capacitor CLI
npm install -g @capacitor/cli @capacitor/core

# Initialize Capacitor project
cd WorkLogApp
npm init -y  # Create package.json if not exists
npm install @capacitor/core @capacitor/cli
npm install @capacitor/ios

# Initialize Capacitor
npx cap init "Work Log" "com.worklog.app"
```

### Step 2: 創建 Web 構建

由於 Flask 應用需要本地服務器,我們有兩個選擇:

#### 選項 A: 連接到雲端服務器 (推薦)
將 Flask 部署到雲端,iOS 應用連接雲端 API

#### 選項 B: 在應用內運行 Flask (進階)
使用 Python for iOS 在應用內嵌入 Python

### Step 3: 配置 Capacitor

創建 `capacitor.config.json`:
```json
{
  "appId": "com.worklog.app",
  "appName": "Work Log",
  "webDir": "www",
  "bundledWebRuntime": false,
  "server": {
    "url": "https://your-flask-server.com",
    "cleartext": true
  },
  "ios": {
    "contentInset": "always"
  }
}
```

### Step 4: 創建 iOS 項目

```bash
# Add iOS platform
npx cap add ios

# Open in Xcode
npx cap open ios
```

### Step 5: 在 Xcode 中構建

1. 打開 Xcode 項目
2. 選擇開發團隊 (Team)
3. 配置 Bundle Identifier: `com.worklog.app`
4. 選擇目標設備或模擬器
5. 點擊 Run (▶️) 構建並運行

### Step 6: 發布到 App Store

1. 在 Xcode 中: Product → Archive
2. 上傳到 App Store Connect
3. 在 App Store Connect 填寫應用資訊
4. 提交審核

---

## 🌐 方案 2: PWA (Progressive Web App)

### 您的應用已經支援 PWA!

用戶可以直接將應用加入主畫面:

**在 iPhone/iPad 上:**
1. 用 Safari 打開應用網址 (http://localhost:5000 或您的服務器)
2. 點擊「分享」按鈕 (↑)
3. 選擇「加入主畫面」
4. 輸入名稱,點擊「加入」

### 增強 PWA 功能

要讓 PWA 更像原生應用,可以添加這些文件:

#### 1. Service Worker (離線支援)
創建 `static/sw.js`:
```javascript
const CACHE_NAME = 'worklog-v1';
const urlsToCache = [
  '/',
  '/static/css/main.css',
  '/static/js/main.js'
];

self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => cache.addAll(urlsToCache))
  );
});
```

#### 2. Web App Manifest
創建 `static/manifest.json`:
```json
{
  "name": "Work Log Journal",
  "short_name": "WorkLog",
  "description": "Daily work logging application",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#ffffff",
  "theme_color": "#007bff",
  "icons": [
    {
      "src": "/static/icon-192.png",
      "sizes": "192x192",
      "type": "image/png"
    },
    {
      "src": "/static/icon-512.png",
      "sizes": "512x512",
      "type": "image/png"
    }
  ]
}
```

#### 3. 在 HTML 中引用
在 `app.py` 的 HTML template 中添加:
```html
<link rel="manifest" href="/static/manifest.json">
<meta name="apple-mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-status-bar-style" content="default">
<meta name="apple-mobile-web-app-title" content="WorkLog">
<link rel="apple-touch-icon" href="/static/icon-192.png">
```

---

## 🔄 混合方案: 雲端 Flask + Capacitor iOS

這是最推薦的生產環境方案:

1. **後端**: 將 Flask 部署到雲端服務器
   - Heroku, Railway, Render, DigitalOcean 等
   - 使用 Supabase 作為資料庫(已配置)

2. **iOS 應用**: 使用 Capacitor 打包
   - 連接到雲端 Flask API
   - 可以離線緩存數據
   - 上架 App Store

### 部署 Flask 到雲端

**使用 Railway (推薦,免費額度):**

1. 創建 `railway.json`:
```json
{
  "$schema": "https://railway.app/railway.schema.json",
  "build": {
    "builder": "NIXPACKS"
  },
  "deploy": {
    "startCommand": "python app.py",
    "restartPolicyType": "ON_FAILURE",
    "restartPolicyMaxRetries": 10
  }
}
```

2. 創建 `Procfile`:
```
web: python app.py
```

3. 確保 `app.py` 使用環境變量:
```python
if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    app.run(host="0.0.0.0", port=port)
```

4. 部署:
   - 訪問 railway.app
   - 連接 GitHub 倉庫
   - 自動部署

---

## 📊 方案選擇建議

| 需求 | 推薦方案 |
|------|---------|
| 快速測試 | PWA |
| 個人使用 | PWA 或 macOS 應用 |
| 團隊內部使用 | 雲端 Flask + PWA |
| 商業產品/App Store | 雲端 Flask + Capacitor iOS |
| 完全離線使用 | Python for iOS (複雜,需重構) |

## 需要幫助?

如果您選擇某個方案,我可以幫您:
1. 創建詳細的配置文件
2. 修改現有程式碼以適配該方案
3. 創建部署腳本
