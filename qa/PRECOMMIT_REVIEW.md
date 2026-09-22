# 提交前审查 · 2026-09-21

结论：**可以提交当前 MVP 开发版本**。本次发现的3项代码阻塞已修复并通过回归与复审；不等于公开发布或M5/M6全部验收完成。没有执行git add、commit或push。

基线为HEAD `8e6e4d5`（Initial commit），审查包括工作树修改和全部未跟踪文件；不能仅看`git diff`，后者最初只显示.gitignore。初始候选约396文件/28MB，最大文件为12MB运行录屏。构建目录、真实配置、SQLite文件和平台密钥均不在候选提交中。

## Standards

审查源：AGENTS.md、同步协议、实施决定，辅以代码结构审查。

- **已修复：总超时未取消HTTP传输。** 原来的Future.timeout仅停止等待；现在总期限通过Dio CancelToken取消锁定版本IO adapter的底层请求，结束前不开放下一轮。新增超时→重试→删除回归，断言maxActive=1、取消次数及完成请求不被残余计时器取消。
- **已修复：永久错误阻塞仅在内存。** app_meta新增last_sync_error_status，并与队首失败信息同事务持久化；重启恢复阻塞，人工重试或成功ACK后清除。401/410/409/422分别通过真实SQLite文件关闭/重开验证，原始op正文保留，未人工重试前没有网络调用。

本地schema升级2，保留v1快照与冻结的v1 SQL测试夹具；只增加可空列，升级测试验证项目、Entry、身份、许可、序号与outbox原文不变。contracts/local_schema.sql、Drift声明、生成代码和v2快照已同步；服务端与OpenAPI格式不变。复审未发现新的实质问题，也没有仅为代码风格而增加抽象。

Standards：原2项实质发现，均关闭；未解决阻塞0。

## Spec

审查源：HANDOFF、契约、设计说明和P/S验收要求。

- **已修复：统计选择单项目后删除全部数据会触发下拉框断言。** 根页保留统计状态，旧项目ID在空选项集无对应项。现统一按仍存在的项目解析筛选与查询，失效时回到总体，并以key重置FormField。新增回归使用真实设置页的两次删除确认，再创建另一项目，验证总体正确计为1次事件。
- 总超时取消与永久阻塞持久化两项同上，属于可靠同步要求，均修复。
- 未发现产品范围扩张。

Spec：原3项实质发现（含与Standards重叠的2项），均关闭；未解决阻塞0。

## 本次实际验证

原始输出在`qa/evidence/precommit-2026-09-21/`。

| 命令/检查 | 结果 | 日志 |
| --- | --- | --- |
| KODO_TEST_API_URL=... flutter test | 44 passed，含真实Rust | flutter-tests.log |
| flutter analyze | No issues found | analyze-final.log |
| dart format --output=none --set-exit-if-changed | 23 files / 0 changed（干净目录） | clean-format.log |
| cargo fmt --check | exit0 | cargo-fmt.log |
| cargo clippy --locked --all-targets -- -D warnings | exit0 | cargo-clippy.log |
| cargo test --locked | 7 integration groups passed | cargo-tests.log |
| validate_handoff.py | PASS 155 checks | contracts-final.log |
| smoke_api.py → 真实Rust8083 | 28 checks passed，测试namespace清理确认 | smoke.log / smoke.json |
| v1→v2 schema dump和迁移 | v2导出、数据/队列保留测试通过 | schema-v2.log / flutter-tests.log |
| 独立复审的timeout/migration/sync子集 | 21 tests passed | 审查任务执行输出；完整集见上 |
| 原统计代码的负向对照 | 新回归明确触发原Dropdown断言；临时修改随后还原 | stats-regression-before-fix.log |
| 常见凭据特征扫描 | private key、GitHub/AWS/OpenAI token、实际Bearer模式未命中；不代替全面安全审计 | 提交审查执行输出 |
| 候选源码/文档空白检查 | 无发现 | source-whitespace.log |

验证器原先会把本机build/Pods中的依赖字体当作交接源字体，已限定排除生成目录；源码区域仍检查ttf/otf/ttc/woff/woff2。初次新增统计测试的断言曾误匹配两个同文案Text，已修正为验证筛选行为；保留失败日志并另有针对真实原故障的负向对照。

## 干净候选文件验证

通过`git ls-files --cached --others --exclude-standard`复制到新的临时目录，未复制原工作区build、.dart_tool、Pods、数据库或本地配置，未改变Git索引。记录见clean-source.json。

1. `flutter pub get --offline --enforce-lockfile`通过，使用本机已缓存的精确依赖；不声称是无网络缓存的全新机器。
2. 完整44项Flutter测试在临时源目录再次通过：clean-flutter-tests.log。
3. Android调试APK从该目录构建成功：clean-android-build.log。缺省Gradle wrapper等可再生文件由固定Flutter工具链生成，没有依赖被遗漏的源文件。
4. 此Mac仍需scripts/flutter_cli.dart绕过旧Intel Android Studio枚举故障，沿用固定SDK/JDK；未修改IDE或Flutter源码。

## 提交与发布边界

- 可提交：Flutter/Rust源码、契约、迁移及两个schema快照、锁文件、测试、资源、CI、文档和验收证据。本次未创建Git提交或推送。
- 尚未远端执行GitHub CI；本机已验证它的现有format/analyze/unit/Rust/smoke检查。真实HTTPFlutter场景在本机额外启用，当前CI的Flutter任务仍默认跳过该需服务的测试。
- 本次修复后未重新跑真机录屏/profile或iOS构建；已有真机数据仍准确标记为此前补验版本。新修改由迁移/协议/原生widget回归与干净Android构建验证。
- TalkBack/VoiceOver、分享最终保存、120Hz滚动完整验收、iOS真机、Release真实HTTPS、容器持久卷和公开发布条件仍未关闭，详见IMPLEMENTATION_REPORT.md。
