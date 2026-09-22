# Kodo 实施与验收报告

验收时间：2026-09-18；Android真机补验：2026-09-21，Asia/Shanghai。**实现和可运行环境内的自动化验收完成；M5/M6仍有明确未验收门槛，不能宣称整体DoD全部通过。**

## 1. 环境与构建版本

- 基础Git commit：`8e6e4d5b305d26a978b38d4698bce9f56b913fdc`。本次交付为该工作树中的新增实现，未创建提交或推送远端。
- macOS26.6.2 (25G83) arm64；Flutter3.41.4 / Dart3.11.1；Rust1.96.0；Xcode26.6 (17F113)；CocoaPods1.16.2；Android SDK36.1.0，Java17.0.19。详见 evidence/m0-flutter-doctor.log 与版本JSON。
- Drift/drift_dev均固定2.34.0，当前本地schema v2，保留v1/v2快照与升级测试；SQLx0.8.6，服务端v1迁移。实际解析版本以pubspec.lock/Cargo.lock/Podfile.lock为准。
- iPhone17 Pro / iOS26.5模拟器，debug；Android SDK built for arm64 / API36模拟器，debug。2026-09-21补验小米23127PN0CC / Android16真机，debug全流程与profile性能，详见[真机补验报告](PHYSICAL_DEVICE_REPORT.md)。主机当日为macOS27.0 (26A428)。
- Rust在Mac直接运行，127.0.0.1:8080，真实SQLite持久文件；测试提升限流额度，生产默认限流仍启用。Docker Desktop24.0.7引擎可用，Docker Hub网络访问超时。

## 2. 里程碑

每阶段详细修改范围、命令、截图与限制见 [MILESTONES.md](MILESTONES.md)；可直接浏览 [运行证据画廊](EVIDENCE.md)。

| 阶段 | 状态 | 提交与执行证据 | 未完成/阻塞 |
| --- | --- | --- | --- |
| M0 工程基础 | 通过 | 两端启动、doctor、cargo check、锁文件、155项交接校验 | CI已定义，未在远端运行 |
| M1 本地纵向闭环 | 通过 | m1-ios-same-install.log / database.json / restart.png；真实Entry与outbox持久化 | 最初换包空态已识别为无效重启证据，已补做同安装重启 |
| M2 完整本地 MVP | 通过 | repository_test、黄金统计、导出schema、m2-ios/Android页面 | 系统分享最终保存到Files需人工设备验收 |
| M3 Rust 副本服务 | 通过 | 28项真实API smoke；7组Rust集成测试 | 容器运行另列M6 |
| M4 可靠同步 | 通过 | 真实HTTP丢响应/ACK失败/重开文件库；双方模拟器服务端30与重放 | Android真机服务端删除提交后强杀/恢复通过；详见physical-2026-09-21/deletion |
| M5 UI 与设备质量 | 部分通过 | 双模拟器全流程；4组尺寸/字号；截图与录屏 | Android真机与profile记录/启动已通过；120Hz滚动、读屏、图标蒙版、分享保存仍未完整验收 |
| M6 打包与交付 | 部分通过 | APK、未签名iOS构建；迁移、锁、README、compose；独立备份恢复 | Docker Hub超时；人工/Release HTTPS门槛未闭合；无公开上架声明 |

## 3. 产品与协议验收

下表“通过”指对应自动化场景通过，**不代替第4节的真机验收**。本地仓储与worker测试使用真实SQLite；real_sync_test和手机integration_test连接真实Rust。故障测试明确在HTTP完成后丢弃响应、在本地ACK事务中注入失败，以及关库重开来模拟崩溃边界；未冒充物理断网、代理崩溃或所有真机杀进程场景。2026-09-21新增真实Android force-stop/relaunch，含删除提交后中断，边界与证据详见补验报告。

命令总日志：evidence/final-flutter-tests.log（36 tests）；evidence/final-cargo-test.log（7 integration tests）；evidence/m3-smoke.json（28 checks）。

| ID | 场景 | 状态 | 证据 |
| --- | --- | --- | --- |
| P01 | 首次打开，无网络 | 通过 | m1-empty.png；repository_test first launch empty；iOS/Android full_flow |
| P02 | 保存合法中文项目 | 通过 | repository_test file reopen；m1-ios-same-install.log / m1-same-install-restart.png |
| P03 | 全空白/超长名称 | 通过 | repository_test text Unicode scalar validation and controls |
| P04 | 单位 1/8/9 个字符 | 通过 | repository_test 单位1/8/9个Unicode标量边界 |
| P05 | 重名项目 | 通过 | repository_test repeated names are independent UUIDs |
| P06 | 首页快捷 +10 | 通过 | widget_test quick hit target；iOS/Android full_flow首页+10不跳详情 |
| P07 | 详情草稿 1→5→20 | 通过 | widget_test draft only；full_flow 1→5→20不改变累计 |
| P08 | 单条 0/-1/1.5/999999/1000000 | 通过 | repository_test strict integer boundaries；Rust strict_types |
| P09 | 100 次被接受的 +10 命令 | 通过 | repository_test 100 accepted commands → 100 Entry / 1000 |
| P10 | 本地事务故意失败 | 通过 | repository_test transaction-boundary failure injection → 三者回滚 |
| P11 | 成功落盘后立即杀进程 | 通过 | m1-ios-same-install.log / m1-same-install-database.json：同安装force-stop/relaunch，10与2条outbox保留 |
| P12 | 20+10+12，再撤销 10 | 通过 | repository_test void exact ID：20+10+12，撤销10得32 |
| P13 | 最后一条之外的历史删除 | 通过 | repository_test 删除中间Entry的确切ID |
| P14 | 同一 Entry 删除两次 | 通过 | repository_test repeated void，统计及seq不再变化 |
| P15 | 有记录/全被删后改单位 | 通过 | repository_test unit locks after all voided；Rust unit_locked |
| P16 | 无记录项目改单位 | 通过 | repository_test unit edits without history |
| P17 | 归档→试图记录→恢复 | 通过 | repository_test archive blocks additions；双模拟器full_flow归档/恢复 |
| P18 | 归档项目删除误记 | 通过 | repository_test archive permits void；Rust sequence_replay... |
| P19 | 混合个/页/分钟/题 | 通过 | repository_test supplied golden data：混合单位只计事件 |
| P20 | 7/30 日全零与稀疏数据 | 通过 | repository_test golden + zero fill，7/30日；m2-*-stats.png |
| P21 | 午夜 23:59→00:01 | 通过 | repository_test midnight；widget_test visible today refreshes across midnight |
| P22 | UTC+8→UTC-7 旅行 | 通过 | repository_test midnight and travel preserve captured dates |
| P23 | 夏令时切换前后偏移 | 通过 | repository_test DST captured offsets |
| P24 | 同毫秒 55 条历史，分页 50 | 通过 | repository_test same-millisecond cursor 50+5 |
| P25 | JSON 导出 | 通过 | m2-export-schema.log；local-export.json；含void标记且无凭据/outbox |
| S01 | 注册成功但丢失响应后重试 | 通过 | real_sync_test：真实注册成功后适配器丢弃响应，再注册existing |
| S02 | 同一身份不同 secret | 通过 | m3-smoke.json registration credential mismatch；Rust registration_auth... |
| S03 | 未授权访问 snapshot/operations | 通过 | m3-smoke.json unauthorized snapshot；Rust registration_auth... |
| S04 | B 身份引用 A 的 project_id | 通过 | m3-smoke.json cross namespace project reference + empty isolated namespace |
| S05 | 相同 op 重放 10 次 | 通过 | Rust sequence_replay...：同op重放10次；双模拟器重放Entry后仍30 |
| S06 | 相同 seq 或 op_id 改 payload | 通过 | Rust sequence_replay...；m3-smoke same identity changed body |
| S07 | seq=1 后直接发 seq=3 | 通过 | m3-smoke sequence gap；Rust sequence_replay... |
| S08 | 入库成功，响应被代理丢弃 | 通过 | real_sync_test：实际HTTP提交后丢弃响应，保留原body并重试 |
| S09 | ACK 收到后、本地确认前崩溃 | 通过 | real_sync_test：服务端ACK后本地DELETE触发器失败，关库重开、duplicate确认 |
| S10 | 新建→记录→归档均离线 | 通过 | sync_test consent gates registration + FIFO offline create/add/archive |
| S11 | 加记录→立刻撤销，均未同步 | 通过 | sync_test create/add/void/archive FIFO；real_sync服务端保留void标记 |
| S12 | 项目归档后重放旧 add | 通过 | m3-smoke replay before archived-state validation；Rust sequence_replay... |
| S13 | 队首永久 422 | 通过 | sync_test permanent 422 blocks head，后续seq不发送 |
| S14 | 多次前台/保存同时唤醒 | 通过 | sync_test merged wakeups：20次并发唤醒，max in-flight=1 |
| S15 | 关闭开关→产生新记录→开启 | 通过 | sync_test consent pause/resume补齐队列；关闭时零注册请求 |
| S16 | DELETE 与在途操作竞争 | 通过 | Rust concurrent_delete_snapshot_operation；sync_test waits for in-flight |
| S17 | 删除请求/回应丢失与进程重启 | 通过 | real_sync_test DELETE响应丢失+文件库重开；sync_test sending/remote_deleted/安全存储失败 |
| S18 | 删除后同 secret 注册/写入 | 通过 | m3-smoke revoked registration/late operation/repeat deletion |
| S19 | 429 / 503 / 超时 | 通过 | sync_test timeout/backoff/Retry-After120s/foreground pause；Rust rate_limits |
| S20 | 日期与 timestamp+offset 不符 | 通过 | m3-smoke date consistency；Rust strict_types...last_seq不变 |
| S21 | SQLite 写锁或提交失败 | 通过 | Rust external_sqlite_write_lock... + receipt触发器失败，业务/receipt/seq原子回滚 |
| S22 | token 丢失或 DB/凭据不配对 | 通过 | sync_test missing/mismatched key、残留keychain、secure-store failure |
| S23 | 查询与删除、快照并发 | 通过 | Rust concurrent_delete_snapshot_operation：一致版本last_seq与Entry数 |
| S24 | 日志与诊断检查 | 通过 | m6-log-audit.log：审计2份真实服务日志，无Bearer/secret/活动JSON |
| S25 | 超长 body / 未知字段 / 数字字符串 | 通过 | Rust strict_types_unknown_fields_body_size...：413/422，无宽松数值转换 |

## 4. UI 与设备

| 检查 | 状态 | 设备/环境与证据 |
| --- | --- | --- |
| iOS 完整关键流程 | 通过 | iPhone17 Pro / iOS26.5模拟器；m5-ios-full-flow.log |
| Android 完整关键流程 | 通过 | API36 arm64模拟器；m5-android-full-flow.log |
| 至少一台真机全链路 | 通过 | 小米23127PN0CC / Android16；physical-2026-09-21/full-flow-device.log、local-sync/device.log、deletion/device.log |
| 390×844 与 360×800 | 通过 | widget_test四组布局，m5-layout-home/stats-*.png |
| 200% 字体与键盘遮挡 | 通过 | 四组布局含280px键盘遮挡并断言保存按钮可滚动到键盘上方；原生双端输入测试；final-flutter-tests.log |
| VoiceOver/TalkBack 与图表等价文本 | 待测试 | 已实现语义标签/逐日期文本；真人读屏和焦点顺序未验收 |
| Debug HTTP 与 Release HTTPS | 待测试 | 双端Debug实际HTTP已通过；Release保护配置与iOS构建完成，但Release实际HTTPS服务连接尚未执行 |
| 实际应用图标与平台蒙版 | 待测试 | iOS全尺寸图标、Android legacy/adaptive资源已生成；最终蒙版人工检查未执行 |
| 离线→重启→联网，数据不重不漏 | 通过 | 禁用上传的离线积压、file reopen与真实HTTP；同安装iOS及Android force-stop/relaunch；Android重启后真实Rust补发2→0，旧操作重放不增量；无物理飞行模式声称 |
| 删除中断/重启恢复 | 通过 | 软件边界故障注入与真实DELETE响应丢失/关库重开通过；新增Android真实强杀，在sending阶段保留意图并在重启后完成清理/拒绝旧凭据 |
| 部署/持久卷/备份恢复 | 阻塞 | 直接Rust与在线备份独立恢复通过；Docker build网络超时，容器持久卷未执行 |

运行截图：m1-same-install-restart.png；m2-ios/Android-home-30、detail-30、stats.png；m4-ios/Android-consent、synced、deleted.png。字体尺寸截图由实际Flutter Widget渲染，使用本机系统字体仅供测试；未打包或分发字体。均为候选视觉基线，尚未由用户确认作像素golden。

录屏：[iOS关键流程短片](evidence/m5-ios-flow-short.mp4)，源文件m5-ios-flow.mp4。没有用静态设计图伪装运行证据。

## 5. 实际命令和输出

| 命令 | 实际结果 | 原始输出 |
| --- | --- | --- |
| flutter doctor -v | No issues found | m0-flutter-doctor.log |
| Python validate_handoff.py | PASS 155 checks（契约验证，非产品运行） | m0-handoff-validation.log |
| cargo fmt --check | exit0 | final-cargo-fmt.log |
| cargo clippy --locked --all-targets -- -D warnings | exit0 | final-cargo-clippy.log |
| cargo test --locked | 7 tests passed | final-cargo-test.log |
| flutter analyze | No issues found | final-flutter-analyze.log |
| KODO_TEST_API_URL=http://127.0.0.1:8080 flutter test | 36 tests passed，含真实服务 | final-flutter-tests.log |
| flutter drive ... local_flow_test.dart + restart probe | 同安装重启：1条Entry/10/2条待同步 | m1-ios-same-install.log |
| flutter drive ... full_flow_test.dart (iOS) | All tests passed | m5-ios-full-flow.log |
| flutter drive ... full_flow_test.dart (Android) | All tests passed | m5-android-full-flow.log |
| python3 scripts/smoke_api.py | PASSED 28 real API checks，清理确认 | m3-smoke.log / json |
| flutter build apk --debug | Built app-debug.apk | m6-android-build.log |
| flutter build ios --no-codesign | Built Runner.app，未签名 | m6-ios-build.log |
| dart run drift_dev schema dump ... | Wrote drift_schema_v1.json | m6-drift-schema.log |
| python3 scripts/verify_backup.py | PASS恢复Rust快照一致 | m6-backup-drill.log / report.json |
| python3 scripts/audit_logs.py | PASS 2份真实服务日志隐私字段检查 | m6-log-audit.log |
| docker compose config | 已解析配置 | m6-compose-config.log |
| docker build -t kodo-api:0.1.0 services/api | 失败：registry-1.docker.io:443超时 | m6-docker-build.log |

2026-09-21补验命令：独立QA APK的debug full_flow、local_flow + ADB同安装重启/补同步、deletion_restart + 实际强停恢复、profile performance + `--no-dds`，均通过。新增安全存储通道故障回归后 `flutter test` **37 tests passed**，`flutter analyze`无问题。实际命令、失败重试与原始输出见 [PHYSICAL_DEVICE_REPORT.md](PHYSICAL_DEVICE_REPORT.md)。

全部文件在 `qa/evidence/`。早期分析、布局和依赖不匹配失败也有记录；最终日志与上述通过结果对应。未把失败命令隐藏为成功。

## 6. 性能与数据规模

2026-09-21小米Android16真机profile：100次被接受的快捷记录产生100条Entry/总量1000；点击至事务提交后的数字帧p50 **33.237ms**、p95 **35.075ms**、max38.097ms（≤150ms通过）。100项目/10,000记录/10,100待同步操作下，3次同安装进程冷启动至验证列表帧为 **1.421 / 1.415 / 1.260s**（均≤2s）。主机计时包含ADB和轮询，保留OS文件缓存，不是整机重启或Release基准。

24次fling共1,402帧：build平均2.819ms/p95 10.292ms，raster平均5.561ms/p95 7.778ms；按16.67ms预算超时分别1.64%/2.21%，按8.33ms预算为8.20%/3.57%。**不宣称120Hz滚动已完全验收或零卡顿。** 原始样本、逐帧数据及3次重启报告位于physical-2026-09-21/profile；完整方法和限制见[真机补验报告](PHYSICAL_DEVICE_REPORT.md)。

## 7. 已知限制与交付物

- Android真机核心流程、profile记录延迟和冷启动已通过；仍有iOS真机、120Hz滚动、人工VoiceOver/TalkBack、系统分享落盘、平台图标蒙版、Release真实HTTPS以及Docker容器运行未完成。上述事项使M5/M6保持部分完成，整体验收不能全勾选。
- 服务是单安装云端副本；无账号、换机恢复、导入、多设备并发写入或公开注册安全承诺。备份可能包含已经在线删除的数据，需运维访问控制和保留策略。
- Debug网络例外只供受控开发网络。公开部署仍需HTTPS终止、注册防滥用评估、备份加密/清理及平台隐私声明。临时包名和品牌未作商标或商店验证。
- 源码：apps/mobile、services/api；协议：contracts；迁移：schema.drift / drift_schema_v1.json / migrations/0001_initial.sql；锁：pubspec.lock / Cargo.lock / Podfile.lock；配置：mise.toml / rust-toolchain.toml / .env.example / compose.yaml / services/api/Dockerfile；操作说明：README.md；实施决定：docs/IMPLEMENTATION_DECISIONS.md；CI：.github/workflows/ci.yml。
- 本机产物：apps/mobile/build/app/outputs/flutter-apk/app-debug.apk；apps/mobile/build/ios/iphoneos/Runner.app。构建目录不进入Git；用户可按README重建。未签名iOS不能直接分发给任意真机。

2026-09-21已在Android真机安装并打开普通Kodo调试包（独立自动化QA包已卸载），首次页面为空态；开发副本经USB连接本机Rust8083，非公网服务。详见[真机补验和体验版本说明](PHYSICAL_DEVICE_REPORT.md)。

提交前审查修复（2026-09-21）：统计筛选后清空数据、HTTP总超时取消、永久同步错误跨重启保留；本地schema升级v2，v1数据与outbox保留。最新验证与提交判断见[提交前审查报告](PRECOMMIT_REVIEW.md)，历史真机性能数据仍对应补验时版本，不冒充修复后重新测量。
