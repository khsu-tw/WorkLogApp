-- Work Log Journal — Supabase Schema
-- Run in: Supabase Dashboard → SQL Editor → New Query → Run

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
    status       TEXT DEFAULT 'Not Started',
    category     TEXT DEFAULT 'General',
    worklogs     TEXT,
    create_date  TEXT,
    last_update  TEXT,
    archive      TEXT DEFAULT 'No',
    record_hash  TEXT,
    created_at   TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_worklog_hash ON worklog(record_hash);

ALTER TABLE worklog ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow all" ON worklog;
CREATE POLICY "Allow all" ON worklog FOR ALL USING (true) WITH CHECK (true);

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
