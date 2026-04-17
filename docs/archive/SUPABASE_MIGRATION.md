# Supabase 資料庫遷移指南

如果您使用 Supabase 雲端資料庫，請按照以下步驟更新資料庫結構。

## 更新步驟

### 1. 登入 Supabase Dashboard
前往：https://supabase.com/dashboard

### 2. 開啟 SQL Editor
- 選擇您的專案
- 點選左側選單的「SQL Editor」
- 點選「New Query」

### 3. 執行遷移 SQL

複製並執行以下 SQL 指令：

```sql
-- 新增 v0.9.2 - v0.9.5 的新欄位
ALTER TABLE worklog ADD COLUMN IF NOT EXISTS sso_modeln TEXT;
ALTER TABLE worklog ADD COLUMN IF NOT EXISTS ear TEXT;
ALTER TABLE worklog ADD COLUMN IF NOT EXISTS bu TEXT;
ALTER TABLE worklog ADD COLUMN IF NOT EXISTS application TEXT;
ALTER TABLE worklog ADD COLUMN IF NOT EXISTS mchp_device TEXT;
ALTER TABLE worklog ADD COLUMN IF NOT EXISTS project_schedule TEXT;

-- 將舊欄位 'inquiries' 的資料遷移到新欄位 'mchp_device'
UPDATE worklog
SET mchp_device = inquiries
WHERE mchp_device IS NULL AND inquiries IS NOT NULL;
```

### 4. 驗證更新

執行以下查詢確認新欄位已建立：

```sql
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'worklog'
ORDER BY ordinal_position;
```

您應該會看到：
- sso_modeln
- ear
- bu
- application
- mchp_device
- project_schedule

### 5. （選用）移除舊欄位

確認資料遷移成功後，可以移除舊欄位：

```sql
ALTER TABLE worklog DROP COLUMN IF EXISTS inquiries;
```

## 欄位對應表

| 舊欄位 | 新欄位 | 長度 | 說明 |
|--------|--------|------|------|
| inquiries | mchp_device | 20 | Microchip Device |
| - | sso_modeln | 10 | SSO/ModelN# |
| - | ear | 20 | EAR(K$) |
| - | bu | - | BU (DCS/NCS) |
| - | application | 50 | Application |
| - | project_schedule | - | Project Schedule (Markdown) |

## 注意事項

1. **執行前請先備份資料庫**
2. `IF NOT EXISTS` 子句確保重複執行不會出錯
3. 如果不執行遷移，本地端的新欄位資料將不會同步到雲端
4. 本地端程式會自動處理新舊 schema 的相容性

## 檢查同步狀態

更新完成後，在 Work Log 程式中：
1. 點選「⟳ Sync」按鈕
2. 確認右上角顯示「Online」狀態
3. 檢查是否有衝突需要解決

## 問題排除

**Q: 執行 SQL 時出現權限錯誤**
A: 確認您是專案的 Owner 或具有修改 schema 的權限

**Q: 資料沒有同步**
A: 檢查 F12 Console 是否有錯誤訊息，確認新欄位已建立

**Q: 想要保留舊 schema**
A: 程式會自動處理相容性，新欄位只會存在本地端
