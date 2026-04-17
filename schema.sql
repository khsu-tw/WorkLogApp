-- Work Log Journal — PostgreSQL Schema
-- For: PostgreSQL 12+ or PocketBase SQL Editor
-- Version: v1.0.1

-- ============================================================================
-- FOR NEW INSTALLATIONS: Run the CREATE TABLE below
-- ============================================================================

CREATE TABLE IF NOT EXISTS worklog (
    id           BIGSERIAL PRIMARY KEY,
    week         TEXT,
    due_date     TEXT,
    customer     TEXT,
    project_name TEXT,
    sso_modeln   TEXT,
    ear          TEXT,
    application  TEXT,
    bu           TEXT,
    task_summary TEXT,
    mchp_device  TEXT,
    project_schedule TEXT,
    todo_content TEXT,
    todo_due_date TEXT,
    status       TEXT DEFAULT 'Not Started',
    category     TEXT DEFAULT 'General',
    worklogs     TEXT,
    create_date  TEXT,
    last_update  TEXT,
    archived     TEXT DEFAULT 'No',
    record_hash  TEXT,
    created_at   TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for common queries
CREATE INDEX IF NOT EXISTS idx_worklog_hash ON worklog(record_hash);
CREATE INDEX IF NOT EXISTS idx_worklog_last_update ON worklog(last_update);
CREATE INDEX IF NOT EXISTS idx_worklog_customer ON worklog(customer);
CREATE INDEX IF NOT EXISTS idx_worklog_archived ON worklog(archived);

-- ============================================================================
-- FOR EXISTING INSTALLATIONS: Run these migrations to update your database
-- ============================================================================

-- Step 1: Add new columns (v0.9.2 - v0.9.5)
ALTER TABLE worklog ADD COLUMN IF NOT EXISTS sso_modeln TEXT;
ALTER TABLE worklog ADD COLUMN IF NOT EXISTS ear TEXT;
ALTER TABLE worklog ADD COLUMN IF NOT EXISTS bu TEXT;
ALTER TABLE worklog ADD COLUMN IF NOT EXISTS application TEXT;
ALTER TABLE worklog ADD COLUMN IF NOT EXISTS mchp_device TEXT;
ALTER TABLE worklog ADD COLUMN IF NOT EXISTS project_schedule TEXT;

-- Step 2: Migrate data from old 'inquiries' to new 'mchp_device' column
UPDATE worklog SET mchp_device = inquiries WHERE mchp_device IS NULL AND inquiries IS NOT NULL;

-- Step 3 (Optional): Drop old column after confirming data migration
-- ALTER TABLE worklog DROP COLUMN IF EXISTS inquiries;

-- Step 4: Add To-Do fields (v0.9.9)
ALTER TABLE worklog ADD COLUMN IF NOT EXISTS todo_content TEXT;
ALTER TABLE worklog ADD COLUMN IF NOT EXISTS todo_due_date TEXT;

-- Step 5: Rename archive column (v1.0.0 → v1.0.1)
-- Note: PocketBase uses 'archieved' (typo), PostgreSQL uses 'archived'
-- If migrating from PocketBase, you may need to rename:
-- ALTER TABLE worklog RENAME COLUMN archieved TO archived;

-- ============================================================================
-- POCKETBASE SPECIFIC (if using PocketBase)
-- ============================================================================

-- Enable Row Level Security (PocketBase-specific)
-- ALTER TABLE worklog ENABLE ROW LEVEL SECURITY;
-- DROP POLICY IF EXISTS "Allow all" ON worklog;
-- CREATE POLICY "Allow all" ON worklog FOR ALL USING (true) WITH CHECK (true);

-- ============================================================================
-- NOTES
-- ============================================================================
--
-- v1.0.1 Changes:
-- - PostgreSQL-first schema design
-- - Column 'archived' uses correct spelling (was 'archieved' in PocketBase)
-- - Added additional indexes for performance
-- - Optimized for PostgreSQL 12+ compatibility
--
-- Supported Databases:
-- - PostgreSQL 12+
-- - PocketBase (via SQL Editor)
-- - SQLite (local, uses separate schema in app.py)
