# WorkLogServer — Raspberry Pi 5 部署指南

## 前置需求

| 項目 | 說明 |
|------|------|
| 開發機 | 已安裝 Python 3、可執行 `build_server_linux.sh` |
| Pi5 | 已開機、可透過 SSH 連線 |
| 網路 | 開發機與 Pi5 在同一區域網路 |

---

## 步驟一：Build WorkLogServer

在**開發機**上執行：

```bash
./build_server_linux.sh
```

完成後會產生壓縮包，例如：

```
WorkLogServer_v1.0.1_Linux.tar.gz
```

---

## 步驟二：傳送檔案到 Pi5

```bash
scp WorkLogServer_v*_Linux.tar.gz setup_worklog_autostart.sh khsu@<pi5-ip>:~/
```

> 將 `<pi5-ip>` 替換為 Pi5 的實際 IP，例如 `192.168.0.105`

---

## 步驟三：在 Pi5 解壓縮

透過 SSH 登入 Pi5：

```bash
ssh khsu@<pi5-ip>
```

建立目錄並解壓：

```bash
mkdir -p ~/worklog-server
tar -xzf WorkLogServer_v*_Linux.tar.gz -C ~/worklog-server --strip-components=1
```

---

## 步驟四：執行自動啟動設定腳本

```bash
sudo ./setup_worklog_autostart.sh
```

腳本會自動完成以下工作：
- 確認 binary 存在
- 建立 `/etc/systemd/system/worklog.service`
- 設定開機自動啟動
- 立即啟動服務
- 顯示服務狀態

### 自訂 Port（選用）

預設使用 port `5000`，可透過環境變數覆蓋：

```bash
PORT=8080 sudo ./setup_worklog_autostart.sh
```

---

## 驗證服務

```bash
# 確認服務狀態
sudo systemctl status worklog

# 確認服務可正常回應
curl http://localhost:5000
```

---

## 常用管理指令

```bash
# 查看狀態
sudo systemctl status worklog

# 停止服務
sudo systemctl stop worklog

# 重新啟動服務
sudo systemctl restart worklog

# 即時查看 journald logs
sudo journalctl -u worklog -f

# 查看輸出 log 檔
tail -f ~/worklog-server/worklog.log

# 查看錯誤 log 檔
tail -f ~/worklog-server/worklog_error.log

# 取消開機自動啟動
sudo systemctl disable worklog
```

---

## 存取 WorkLogServer

| 位置 | URL |
|------|-----|
| Pi5 本機 | `http://localhost:5000` |
| 區域網路 | `http://<pi5-ip>:5000` |

---

## 更新版本

重新部署新版本時，重複步驟一至三，然後執行：

```bash
sudo systemctl restart worklog
```

---

## 疑難排解

**服務無法啟動**

```bash
sudo journalctl -u worklog -n 50 --no-pager
```

**Binary 沒有執行權限**

```bash
chmod +x ~/worklog-server/WorkLogServer
sudo systemctl restart worklog
```

**Port 已被佔用**

```bash
sudo ss -tlnp | grep 5000
```

確認後更改 port，修改 `/etc/systemd/system/worklog.service` 中的 `Environment=PORT=<新port>`，再執行：

```bash
sudo systemctl daemon-reload
sudo systemctl restart worklog
```
