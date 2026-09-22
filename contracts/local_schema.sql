-- Specification for Drift tables, not a file to execute in parallel with Drift migrations.
PRAGMA foreign_keys = ON;
CREATE TABLE app_meta (
 id INTEGER PRIMARY KEY CHECK(id=1),
 installation_id TEXT NOT NULL,
 last_enqueued_seq INTEGER NOT NULL DEFAULT 0,
 last_acked_seq INTEGER NOT NULL DEFAULT 0,
 sync_enabled INTEGER NOT NULL DEFAULT 0 CHECK(sync_enabled IN(0,1)),
 registration_attempted INTEGER NOT NULL DEFAULT 0 CHECK(registration_attempted IN(0,1)),
 deletion_pending INTEGER NOT NULL DEFAULT 0 CHECK(deletion_pending IN(0,1)),
 last_sync_error_status INTEGER,
 CHECK(last_acked_seq >= 0 AND last_enqueued_seq >= last_acked_seq)
);
CREATE TABLE projects (
 id TEXT PRIMARY KEY, name TEXT NOT NULL CHECK(length(name) BETWEEN 1 AND 40),
 unit TEXT NOT NULL CHECK(length(unit) BETWEEN 1 AND 8), icon_key TEXT NOT NULL,
 quick_amount INTEGER NOT NULL CHECK(typeof(quick_amount)='integer' AND quick_amount BETWEEN 1 AND 9999),
 archived INTEGER NOT NULL DEFAULT 0 CHECK(archived IN(0,1)),
 created_at_utc_ms INTEGER NOT NULL, updated_at_utc_ms INTEGER NOT NULL
);
CREATE TABLE entries (
 id TEXT PRIMARY KEY, project_id TEXT NOT NULL REFERENCES projects(id),
 amount INTEGER NOT NULL CHECK(typeof(amount)='integer' AND amount BETWEEN 1 AND 999999),
 occurred_at_utc_ms INTEGER NOT NULL, utc_offset_minutes INTEGER NOT NULL,
 local_date TEXT NOT NULL, voided_at_utc_ms INTEGER
);
CREATE INDEX entries_project_date ON entries(project_id,local_date,occurred_at_utc_ms DESC,id DESC);
CREATE INDEX entries_date ON entries(local_date) WHERE voided_at_utc_ms IS NULL;
CREATE TABLE outbox (
 seq INTEGER PRIMARY KEY CHECK(seq >= 1),
 op_id TEXT NOT NULL UNIQUE,
 body_json TEXT NOT NULL,
 attempts INTEGER NOT NULL DEFAULT 0,
 next_attempt_at_utc_ms INTEGER,
 last_error_code TEXT
);
-- No bearer secret in this database. Store credentials as one secure-storage JSON value.
-- Queue order is seq ASC. Do not implement per-entity in-flight flags or reorder jobs.
