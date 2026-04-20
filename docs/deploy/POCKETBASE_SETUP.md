# PocketBase 設定指南 - Work Log Journal v0.9.8

## 快速開始

### 1. 下載 PocketBase
```bash
# 訪問 https://pocketbase.io/docs/
# 下載 Windows 版本並解壓縮
```

### 2. 啟動 PocketBase
```bash
pocketbase serve
# 預設: http://127.0.0.1:8090
```

### 3. 創建管理員帳號
訪問 http://127.0.0.1:8090/_/ 並創建管理員帳號

### 4. 創建 worklog Collection

**Settings → Collections → New Collection**

**Collection 名稱**: `worklog`
**Type**: Base

**欄位設定:**
| 名稱 | 類型 | 必填 | 預設值 |
|------|------|------|--------|
| week | Text | No | - |
| due_date | Text | No | - |
| customer | Text | No | - |
| project_name | Text | No | - |
| sso_modeln | Text | No | - |
| ear | Text | No | - |
| application | Text | No | - |
| bu | Text | No | - |
| task_summary | Text | No | - |
| mchp_device | Text | No | - |
| project_schedule | Text | No | - |
| status | Text | No | Not Started |
| category | Text | No | General |
| worklogs | **Editor** | No | - |
| create_date | Text | No | - |
| last_update | Text | No | - |
| archive | Text | No | No |
| record_hash | Text | No | - |

**API Rules** (允許全部):
- List/Search: 留空 (允許公開訪問)
- View: 留空
- Create: 留空
- Update: 留空
- Delete: 留空

**重要**:
- `worklogs` 欄位必須設為 **Editor** 類型 (支援大型文字和圖片 base64)
- API Rules 必須留空以允許公開訪問

完成後儲存 Collection。

## 運行遷移腳本
```bash
python migrate_data.py
```
