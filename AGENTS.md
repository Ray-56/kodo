# Kodo / Codex implementation rules

1. Read CODEX_START_HERE.md, HANDOFF.md, contracts/openapi.yaml and design/README.md before changing code. This package is a handoff, not a working app.
2. Build Flutter mobile + standalone Rust HTTP service. No Rust FFI, Firebase replacement, WebView-based UI or additional product scope without an explicit decision record.
3. Scope: two root tabs, project counters, immutable positive logging entries, soft-void undo, archive, local-first persistence, single-installation authorized cloud mirror, JSON export. NO accounts, goals, categories, reminders, Notes or five-tab navigation.
4. Commit the local domain change, seq allocation and immutable outbox body in ONE SQLite transaction. Display success only after commit. Never wait for network to permit a local record.
5. Only one FIFO SyncWorker, one in-flight operation. Retry using the original op_id and seq. Never skip or silently drop a failed operation.
6. Server duplicate check must happen BEFORE current domain-state validation. Domain change + receipt + last_seq is one transaction. Replay cannot increase totals.
7. Derive every server namespace from verified credentials. Never trust an installation_id supplied inside a domain payload; reject unknown fields. Never log or commit credentials.
8. Numeric amount is a strict positive JSON integer. Unit locks after ANY entry, including voided ones. Overall stats count events, not sum heterogeneous units.
9. Preserve original local_date + offset; do not move history between dates after timezone change. Inject Clock and ID generation for tests.
10. Use supplied independent SVG assets and tokens. Rebuild native widgets. Old AI concept PNGs are reference only, not pixel-golden tests or full-screen backgrounds.
11. Pin real, compatible toolchains and lock files after actual resolution. Do not invent successful builds, device tests or benchmark results. No demo seed data on normal first launch.
12. Work M0 -> M6. Each stage must include executed commands, test output, changed files, limitations and relevant screenshots. All P/S test cases are implementation requirements, not pre-passed tests.
13. Preserve local data on security-store, database or server errors. Handle consent, deletion phases and reinstall identity mismatch explicitly. No automatic multi-device restore.
14. Build contracts first. When schemas or product rules conflict, document and reconcile the minimal change before continuing; update fixtures and tests together.
15. App names / package IDs are provisional. Do not claim trademark, store review, signing or public-launch readiness merely because debug builds work.
