# Work Log Journal - Linux/Ubuntu 建置說明

## 建置環境需求

### Ubuntu/Debian 系統
```bash
# 安裝 Python 3 和 pip
sudo apt update
sudo apt install python3 python3-pip python3-venv

# 安裝系統依賴（用於 lxml、Pillow 等套件）
sudo apt install python3-dev libxml2-dev libxslt1-dev zlib1g-dev libjpeg-dev
```

### 其他 Linux 發行版
- **Fedora/RHEL/CentOS**: `sudo dnf install python3 python3-pip python3-devel libxml2-devel libxslt-devel zlib-devel libjpeg-devel`
- **Arch Linux**: `sudo pacman -S python python-pip libxml2 libxslt zlib libjpeg`

---

## 建置步驟

### 1. 克隆或下載專案
```bash
git clone <repository-url>
cd WorkLogApp
```

### 2. 給予腳本執行權限
```bash
chmod +x build_linux.sh
```

### 3. 執行建置腳本
```bash
./build_linux.sh
```

建置過程需要 3-10 分鐘，取決於您的系統效能。

### 4. 檢查建置結果
建置完成後會產生：
- `dist/WorkLog/` - 包含執行檔的目錄
- `WorkLog_v<版本>_Linux.tar.gz` - 封裝檔（可分發）

---

## 執行應用程式

### 方法 1：直接執行
```bash
cd dist/WorkLog
./WorkLog
```

### 方法 2：解壓封裝檔
```bash
tar -xzf WorkLog_v1.0.1_Linux.tar.gz
cd WorkLog
./WorkLog
```

應用程式會自動：
1. 在瀏覽器開啟 http://127.0.0.1:5000
2. 創建 `WorkLog.db` 資料庫檔案（如果不存在）
3. 生成 `.env` 配置檔（如果不存在）

---

## 疑難排解

### 問題：無法執行（Permission denied）
```bash
chmod +x WorkLog
./WorkLog
```

### 問題：缺少共享函式庫
如果出現類似 `error while loading shared libraries` 的錯誤：
```bash
# 安裝缺少的系統函式庫
sudo apt install libglib2.0-0 libsm6 libxrender1 libxext6
```

### 問題：Port 5000 被占用
編輯 `.env` 檔案，修改 `FLASK_PORT` 參數：
```
FLASK_PORT=8080
```

### 問題：建置失敗
1. 確認已安裝所有系統依賴
2. 使用虛擬環境重新建置：
```bash
python3 -m venv venv
source venv/bin/activate
./build_linux.sh
```

---

## 系統需求

- **作業系統**: Ubuntu 20.04+ / Debian 10+ / 其他 Linux 發行版
- **記憶體**: 至少 512 MB
- **磁碟空間**: 至少 200 MB（包含資料庫）
- **瀏覽器**: Chrome、Firefox、Edge 等現代瀏覽器

---

## 注意事項

1. **可攜性**: 打包後的執行檔包含所有 Python 依賴，但仍需要系統的基本共享函式庫
2. **架構相依**: 在 x86_64 系統建置的執行檔只能在 x86_64 系統執行（ARM 需在 ARM 系統建置）
3. **資料庫檔案**: `WorkLog.db` 會在執行目錄創建，請定期備份
4. **防火牆**: 如需外部連線，請開放指定的 Port（預設 5000）

---

## 更多資訊

- **主要文件**: [README.md](README.md)
- **變更日誌**: [CHANGELOG.md](CHANGELOG.md)
- **PocketBase 設定**: [POCKETBASE_SETUP.md](POCKETBASE_SETUP.md)
- **PostgreSQL 設定**: [RASPBERRY_PI_POSTGRES_SETUP.md](RASPBERRY_PI_POSTGRES_SETUP.md)
