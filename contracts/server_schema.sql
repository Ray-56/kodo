-- Normative SQLite schema draft for the Rust service; SQLx migration must keep these invariants.
-- Runtime: WAL, foreign_keys=ON, synchronous=FULL, busy_timeout=5000, one pool connection.
PRAGMA foreign_keys = ON;
CREATE TABLE installations (
  id TEXT PRIMARY KEY,
  secret_hash BLOB NOT NULL CHECK(length(secret_hash)=32),
  last_seq INTEGER NOT NULL DEFAULT 0 CHECK(last_seq >= 0),
  created_at_utc_ms INTEGER NOT NULL,
  revoked_at_utc_ms INTEGER
);
CREATE TABLE projects (
  installation_id TEXT NOT NULL,
  id TEXT NOT NULL,
  name TEXT NOT NULL CHECK(length(name) BETWEEN 1 AND 40 AND name=trim(name)),
  unit TEXT NOT NULL CHECK(length(unit) BETWEEN 1 AND 8 AND unit=trim(unit)),
  icon_key TEXT NOT NULL CHECK(icon_key IN ('dumbbell','book','leaf','code','droplet','check')),
  quick_amount INTEGER NOT NULL CHECK(typeof(quick_amount)='integer' AND quick_amount BETWEEN 1 AND 9999),
  archived INTEGER NOT NULL DEFAULT 0 CHECK(archived IN (0,1)),
  created_at_utc_ms INTEGER NOT NULL,
  updated_at_utc_ms INTEGER NOT NULL,
  PRIMARY KEY(installation_id,id),
  FOREIGN KEY(installation_id) REFERENCES installations(id) ON DELETE CASCADE
);
CREATE TABLE entries (
  installation_id TEXT NOT NULL,
  id TEXT NOT NULL,
  project_id TEXT NOT NULL,
  amount INTEGER NOT NULL CHECK(typeof(amount)='integer' AND amount BETWEEN 1 AND 999999),
  occurred_at_utc_ms INTEGER NOT NULL CHECK(occurred_at_utc_ms BETWEEN 0 AND 4102444799999),
  utc_offset_minutes INTEGER NOT NULL CHECK(utc_offset_minutes BETWEEN -840 AND 840),
  local_date TEXT NOT NULL CHECK(length(local_date)=10),
  voided_at_utc_ms INTEGER,
  PRIMARY KEY(installation_id,id),
  FOREIGN KEY(installation_id,project_id) REFERENCES projects(installation_id,id)
);
CREATE INDEX entries_project_date ON entries(installation_id,project_id,local_date,occurred_at_utc_ms DESC,id DESC);
CREATE INDEX entries_date ON entries(installation_id,local_date) WHERE voided_at_utc_ms IS NULL;
CREATE TABLE operation_receipts (
  installation_id TEXT NOT NULL,
  seq INTEGER NOT NULL CHECK(seq BETWEEN 1 AND 9007199254740991),
  op_id TEXT NOT NULL,
  request_hash BLOB NOT NULL CHECK(length(request_hash)=32),
  accepted_at_utc_ms INTEGER NOT NULL,
  PRIMARY KEY(installation_id,seq),
  UNIQUE(installation_id,op_id),
  FOREIGN KEY(installation_id) REFERENCES installations(id) ON DELETE CASCADE
);
-- Defense-in-depth invariants. API validation is still required (especially Unicode/date validation).
CREATE TRIGGER project_unit_immutable BEFORE UPDATE OF unit ON projects
WHEN OLD.unit <> NEW.unit AND EXISTS (
  SELECT 1 FROM entries WHERE installation_id=OLD.installation_id AND project_id=OLD.id
) BEGIN SELECT RAISE(ABORT,'unit_locked'); END;
CREATE TRIGGER entry_data_immutable BEFORE UPDATE OF amount,project_id,occurred_at_utc_ms,utc_offset_minutes,local_date ON entries
BEGIN SELECT RAISE(ABORT,'entry_immutable'); END;
CREATE TRIGGER entry_void_monotonic BEFORE UPDATE OF voided_at_utc_ms ON entries
WHEN OLD.voided_at_utc_ms IS NOT NULL AND (NEW.voided_at_utc_ms IS NULL OR NEW.voided_at_utc_ms <> OLD.voided_at_utc_ms)
BEGIN SELECT RAISE(ABORT,'void_is_irreversible'); END;
