# M0—M6 execution ledger

## M0 — foundation

- Imported the full machine contracts, fixtures, design sources, instructions and QA matrix into this previously empty repository.
- Flutter 3.41.4 / Dart 3.11.1; Rust 1.96.0; Xcode 26.6; Android SDK 36.1.0; CocoaPods 1.16.2. `flutter doctor -v`: no issues. Exact outputs in `evidence/m0-*` and `flutter-version.json`.
- `cargo check --manifest-path services/api/Cargo.toml`: exit 0. Minimal Rust process ran and `/health/live` returned `{"status":"ok"}` (m0-live.json).
- `flutter create`, `flutter pub get`, Drift code generation executed, lock files resolved. `scripts/validate_handoff.py`: 155 checks passed.
- Runtime Flutter empty-state screenshot: `evidence/m1-empty.png` (captured by the subsequent M1 integration test, not a design image).
- Foundation-only limitations: API persistence arrived at M3; physical device unavailable in initial device inventory.
- Changed: project scaffolds, pinned toolchains, imported specifications, assets, migrations and theme.

## M1 — local vertical slice

- Real background-isolate Drift/SQLite storage; project/entry/outbox/seq changes are one transaction. No production seed data.
- `flutter test test/repository_test.dart --reporter expanded`: 14 tests passed, including file database close/reopen, rollback injection and 100 accepted independent commands (m1-m2-repository-tests.log).
- `flutter drive --driver=test_driver/integration_test.dart --target=integration_test/local_flow_test.dart -d EF4253D9-9968-4AE6-9FEA-C3221A8F364F`: passed on iPhone 17 Pro / iOS 26.5 simulator, debug. Create 俯卧撑 / 个 / 10, tap +10, remain on home with 10.
- Initial reinstall from integration target to normal application produced an empty sandbox. `m1-restarted.png` is a failed/invalid restart attempt, not persistence evidence. A same-installation force-stop/relaunch must be completed; file-database close/reopen independently passed.
- Corrected same-installation test: host driver force-stopped and relaunched the test binary before Flutter uninstalled it. Both restarted UI assertion and SQLite inspection passed: one valid Entry, total 10, two queued operations. Evidence: m1-ios-same-install.log, m1-same-install-database.json, m1-same-install-restart.png.
- Screenshots: m1-empty.png, m1-create.png, m1-home-ten.png, m1-same-install-restart.png.
- Changed: `lib/core/storage`, `lib/core/theme`, `lib/app.dart`, `lib/main.dart`, native Flutter pages, repository and device tests.
- At this checkpoint: no cloud upload; M3/M4 implement it next. No physical-device claim.

## M2 — full local data behavior

- History with (timestamp,id) cursor; exact-ID soft void; archive/restore; immutable units after any history; 7/30 calendar-day statistics; JSON snapshot/share.
- Repository test evidence above covers Unicode bounds, numerical types, duplicate names, 20+10+12−10=32, repeated void, archived history, midnight/travel/DST, 50+5 pagination, export contents.
- Imported fixtures in test only. Assertions match `demo_expected.json`: pushups 42 today / 143 total, six events today, thirteen over seven days. Zero fill and heterogeneous units verified.
- `flutter analyze`: no issues (m2-analyze.log). Further native screens and accessibility captured in M5.
- Pending at checkpoint: system share-sheet manual interaction and hardware accessibility/performance remain device acceptance items.

## M3 — Rust mirror service

- Implemented all six endpoints, SHA-256 secret hashes and constant-time comparison, strict typed bodies, 16 KiB limit, per-IP/per-installation quotas and safe logging.
- Domain mutation + receipt + last_seq in one transaction; duplicate lookup precedes archive/unit/domain-state validation. Namespace comes exclusively from Bearer credentials.
- `python3 scripts/smoke_api.py --report qa/evidence/m3-smoke.json`: 28 real HTTP checks passed; cleanup confirmed.
- Final `cargo test`: 7 integration groups passed on temporary SQLite files, including external write lock, trigger-induced commit failure, concurrent snapshot/delete/write and durable reopen. `cargo fmt --check` / `cargo clippy --all-targets -- -D warnings`: passed.
- Changed: services/api sources, migration, protocol tests, Cargo.lock.
- This API-only stage has no screen; mobile integration screenshots in M4 are the runtime view of its result. No design screenshots used as proof.

## M4 — reliable synchronization

- Single sender/in-flight FIFO, immutable body retry, consent gate, captured error codes, persisted attempt/backoff state, Retry-After and foreground pause. ACK atomically removes only the matching head.
- Security store pairing, missing keys, orphaned installation, deletion wait/sending/remote_deleted and restart cleanup implemented. Local recording remains independent of network.
- `KODO_TEST_API_URL=http://127.0.0.1:8080 flutter test`: final 36 tests passed, including real Rust roundtrip; logs in final-flutter-tests.log. Fault tests discard actual HTTP responses after server commit, inject local ACK failure, then reopen file DB and retry exact operation.
- Screenshots: m4-ios-consent/synced/deleted.png and Android equivalents. Native integration on both simulators confirms total30 and duplicate replay safety.
- Changed: worker.dart, identity.dart, bootstrap/providers/settings, sync and real_sync tests.
- Hardware process interruption during a deletion still requires a physical-device drill; boundary fault-injection tests passed.

## M5 — UI and devices

- Native project/form/detail/history/stats/settings, SVG assets, min48 controls, draft-only presets, readonly archive state, confirmations, failure states and text alternatives for the chart.
- iPhone 17 Pro / iOS26.5 simulator: full_flow_test passed. Android SDK built for arm64 / API36 emulator: full_flow_test passed. Both debug builds reached the real Rust server through platform network stacks.
- 390×844 / 360×800 × 100% / 200% text: layout tests passed. Fixed 2.5px date-label overflow by wrapping labels; native/widget snapshots captured. Midnight visible-today refresh tested.
- Screens: m2-*-home-30/detail-30/stats.png; m5-layout-*.png; video m5-ios-flow-short.mp4 (trimmed from actual simulator recording).
- Original fixture screenshots are runtime evidence and candidate visual baselines, not human-approved pixel golden baselines.
- Remaining: physical handset, profile-mode latency/cold-start/scrolling, real VoiceOver/TalkBack reading, manual share-to-Files and final mask inspection. Debug emulator jank logs are not physical performance results.

## M6 — packaging and evidence

- README, pinned SDK/locks, v1 Drift schema snapshot, SQLx migration, CI definition, environment example, nonroot Dockerfile, loopback compose, online backup/audit scripts and acceptance matrix provided.
- Android debug APK and iOS unsigned Release app built. Final check logs explicitly record outputs.
- Online backup during WAL activity -> separate restored Rust process -> identical authenticated projects/entries/last_seq snapshot: passed; integrity_check=ok.
- Docker build attempted twice after validating image tags; registry-1.docker.io connection timed out. Compose validation can run locally, but container startup/persistent-volume test is not claimed.
- CI workflow authored, not remotely executed. Physical-device gates remain open; M6 is not a declaration of all-platform acceptance or store readiness.

## 2026-09-21 — Android physical-device addendum

- M1/M4: same QA APK force-stop/relaunch passed on Xiaomi 23127PN0CC, Android 16; 1 Entry / total10 preserved, outbox2→0 after consent and real Rust synchronization. Exact original op duplicate did not add another Entry.
- M4: actual remote DELETE committed, test adapter held its response before local checkpoint; physical process killed and restarted. Production bootstrap completed cleanup, preserved sequencing of deletion phases, old registration returned410.
- M5: full native flow passed in26s with7 screenshots. Profile100 accepted taps p95=35.075ms;100 projects/10,000 entries process-cold startup1.260–1.421s (3 runs).1402 scroll frames measured;120Hz smoothness remains qualified, not a zero-jank claim.
- Changed: explicit Android secure-store resetOnError=false; optional QA package suffix; platform-channel regression; local/deletion/performance integration targets; restart probe/metrics driver and CLI discovery workaround. No new product features.
- Validation:37 Flutter tests passed including real HTTP; analyzer no issues; physical build/drive logs and screenshots under evidence/physical-2026-09-21. See PHYSICAL_DEVICE_REPORT.md for exact commands, raw metrics and retained failed attempts.
- M5/M6 remain partial: manual screen-reader/share/icon checks, iOS hardware, Release HTTPS and container/remote CI gates remain.

## 2026-09-21 — pre-commit review fixes

- Reviewed all candidate files against HEAD8e6e4d5, including untracked implementation. Fixed selected statistics after delete-all, actual HTTP cancellation at total deadline, and durable permanent-error blocking across restart.
- Local schema2 adds one nullable app_meta status; contracts, generatedDrift andsnapshot aligned, v1 fixture/snapshot retained. Upgrade preserves business rows, identity, seq and immutable queue.
- Executed:44 Flutter tests (including realRust), analyzer clean, formatter clean,7 Rust integration groups/fmt/clippy,28 realAPI checks,155 contract checks. Candidate-only temporary copy independently passed44 tests and Android APK build. Details and outstanding release gates:PRECOMMIT_REVIEW.md.
- No new device-performance claim, Git commit or push.
