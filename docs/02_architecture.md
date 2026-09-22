# 2. 技术架构与数据模型

## 2.1 选型结论

Flutter 负责手机页面、领域校验和本地存储；Rust 是独立 HTTP 服务，不是通过 FFI 嵌入 Flutter。客户端采用 Riverpod + Repository + Drift/SQLite；服务端采用 Axum + Tokio + SQLx/SQLite。架构刻意保持单体，不引入 Kubernetes、Redis、Kafka、GraphQL、WebSocket 或微服务。

Flutter 官方文档提供了 UI/数据层分离、Repository 与离线写入模式的说明；本方案在此基础上选择「先本地提交，再异步发往服务端」，而非等待请求成功才更新页面。[S1][S2] Drift 提供事务与响应式读取，适合让页面订阅落盘后的记录。[S3][S4] Axum 与 SQLx 的能力参照其项目文档。[S5][S6] 这些材料支持技术机制，本文对范围、同步协议和页面的具体规定是本项目自己的设计决策。

本地数据库是本期交互与展示的读取来源；服务端是授权设备数据的持久副本。每个安装实例只允许一个写入端。本期没有服务端编辑、自动 pull、换机恢复、账号合并或多端冲突解决。不能把这个单设备镜像协议宣传成完整的跨设备云同步。

## 2.2 一次记录的数据流

`页面点击 → Controller → Repository 本地事务 → Entry + Outbox 一起落盘 → DB Stream 更新页面 → SyncWorker 逐条发送 → Rust 校验与事务提交 → ACK → 本地删除已确认 outbox 项`

本地事务不持有网络请求。同步回包不覆盖项目或记录，只确认 outbox；这样不会让较旧的服务端结果覆盖用户刚刚离线创建的新记录。local-first 不等于只修改内存后显示成功：只有 SQLite 事务提交成功后，界面才提示「已记录」。

## 2.3 推荐代码目录

```text
kodo/
  AGENTS.md
  apps/mobile/
    lib/app/                  # 启动、路由、依赖装配
    lib/core/theme/           # tokens、字体、间距
    lib/core/storage/         # Drift、迁移、凭据
    lib/core/network/         # Dio、认证、错误映射
    lib/core/sync/            # 唯一 SyncWorker
    lib/features/projects/   # view/controller/repository
    lib/features/entries/
    lib/features/stats/
    lib/features/settings/
    assets/brand/  assets/icons/
    test/  integration_test/
  services/api/
    src/main.rs  src/config.rs  src/error.rs
    src/routes/  src/domain/  src/storage/
    migrations/  tests/
  contracts/                  # OpenAPI、JSON Schema
  docs/  design/  scripts/
  compose.yaml
```

采用 feature-first 分组，各 feature 内保持 presentation / data 的职责边界即可；不要为了计数器强制创建一百个空 UseCase。时间、UUID、网络与安全存储均通过接口注入，以便固定测试时钟、模拟失败和重放操作。

## 2.4 依赖与版本规则

手机端计划依赖 flutter_riverpod、go_router、drift、drift_flutter、dio、uuid、flutter_secure_storage、flutter_svg、intl、share_plus、path_provider；开发依赖 drift_dev、build_runner 和 Flutter 测试组件。Riverpod 先使用非代码生成写法，DTO 优先简单不可变 Dart 类，减少不必要的生成链。

服务端计划依赖 axum、tokio、serde、serde_json、sqlx（sqlite、migrate、tokio 对应 feature）、uuid、sha2、subtle、tracing、tracing-subscriber、tower-http，以及时间解析库。不要自行实现密码学；凭据比较使用常量时间实现。具体 crate feature 名称由 M0 对照选定版本校验。

依赖资料查阅于 2026-09-11，但**没有把「最新」字符串当成可复现版本**。M0 必须记录实际 `flutter --version`、`dart --version`、`rustc -Vv`、Xcode/Android 工具链输出，选择互相兼容的 stable 版本，提交 pubspec.lock、Cargo.lock、明确 Rust toolchain 和 Flutter SDK 固定方式。不要直接假定本文件代表一个已经编译验证过的版本组合。服务器基础镜像同样要固定版本，不能交付漂移的 latest 标签。

## 2.5 客户端职责

ProjectRepository 负责项目写入、归档和查询；EntryRepository 负责新增、撤销、分页历史；StatsRepository 只读查询；SyncWorker 只读取 outbox 与确认回执。页面不得直接调用 HTTP 或拼 SQL。TodayProvider 每次前台恢复和日期变化重新读取当前设备日期；Clock 抽象用于跨日测试。

Drift 数据库在后台 isolate 运行，避免大查询阻塞 UI。首页使用聚合查询，不要每张卡片执行一次 HTTP；尽量一次数据库查询得到今日与累计。统计直接读明细聚合，不为 MVP 维护容易失真的 total_count 字段。图表只有 7/30 根柱，使用原生布局或 CustomPainter，并补充 Semantics，不引入重量级图表依赖。

凭据通过 flutter_secure_storage 保存到平台安全存储，相关平台配置以包文档核对。[S7] 不把 token 放在 SharedPreferences、Dart 常量、编译参数、日志或 JSON 导出中。安全存储失败时可以继续纯本机记录，但不得把明文密钥降级存到普通文件。

## 2.6 表结构与不变量

| 表 | 核心字段与用途 |
| --- | --- |
| projects | id、name、unit、icon_key、quick_amount、archived、created/updated 时间 |
| entries | id、project_id、amount、occurred_at_utc_ms、utc_offset_minutes、local_date、voided_at_utc_ms |
| outbox（客户端） | seq、op_id、不可变 body_json、attempts、下一次重试时间、错误码 |
| app_meta（客户端） | installation_id、最后入队/确认序号、副本开关、注册尝试与删除意图 |
| installations（服务器） | id、secret_hash、last_seq、created_at、revoked_at |
| operation_receipts（服务器） | installation_id+seq、op_id、request_hash、accepted_at |

SQL 的字段、约束与索引见 contracts/server_schema.sql 和 local_schema.sql；查询样例见 queries.sql。服务端所有实体主键和外键均以 installation_id 为隔离前缀，尤其禁止用全局 project_id 查询后就把记录返回给请求者。

必须维持：有效记录为 voided_at IS NULL；累计仅为有效 amount 的求和；单位有任何历史后不可变；amount 与原发生日期不可原地改写；删除不可逆（误删只能新记一条）；归档不影响历史；seq 严格递增且无空洞；一个 op_id 只能对应一份操作内容。

服务端初期一个 SQLx 连接、一个 API 实例、一个本地持久化卷。开启 foreign_keys、WAL、synchronous=FULL、busy_timeout=5000。事务覆盖操作验证、实体修改、receipt 与 last_seq，不能先回 200 再提交。SQLite WAL 的约束和备份方式参见 [S8][S9]。一旦需要多副本服务或多机写入，先更换数据与同步设计，不把 SQLite 文件放进共享网络盘硬撑。
