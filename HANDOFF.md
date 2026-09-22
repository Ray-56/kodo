# Kodo · 行一｜MVP 实现交接文档

**文档版本：1.0.0 · 产品目标版本：0.1.0 · 日期：2026-09-11**

技术栈：Flutter 手机客户端 + Rust HTTP 服务。交接对象：Codex / 开发者。品牌与正式包名暂定，先交付私人试用 MVP。

> 不是再做一组效果图，而是实现一个可靠的极简计数应用：做了多少，就记多少。

## 先读这四点

本包是可执行的实施说明与资源包，不是已经完成的产品源码。机器契约、SQL、固定数据、独立 UI 素材、脚本与逐项验收条件均已附上；实际 Flutter/Rust 编译和设备验收由 Codex 接手完成。

MVP 只保留「项目 / 统计」两个主入口。之前生成图片中的分类、目标、Notes、五栏导航不进入本期；图片只作风格参考，不能直接裁成 App 页面。

采用先本机、后副本的写入方式：本地事务成功即记好；Rust 负责经授权的单安装数据镜像。第一期没有账号和换机恢复，也不允许多个手机共享一个 token 写入同一序列。

交给 Codex 时请提供整个目录，先读 CODEX_START_HERE.md 与 AGENTS.md，再实施 M0–M6。只传本 PDF 会丢失 OpenAPI、SQL 和可直接使用的源素材。

## 导航

1. 产品范围与页面交互：做什么、怎样点、数字如何计算。
2. 技术架构与数据模型：Flutter、Rust、SQLite 的责任边界。
3. API 与一致性：身份、操作、重试、删除和异常恢复。
4. 开发交付：里程碑、运行命令、运维与完成定义。
5. 测试计划：25 项产品/数据测试 + 25 项协议/故障测试。
6. 附录：设计资源、文件索引与技术来源。

# 1. 产品范围与页面交互

## 1.1 一句话定位

Kodo · 行一：创建一个项目，随时记录已经完成的数量。品牌名暂用 Kodo，尚未核验商标、域名与商店重名。标语为「让每一次行动，都算数」。它不是待办工具，不要求先定目标，也不因断签惩罚用户。

本次冻结的产品版本为 **0.1.0 私人试用 MVP**。客户端 Flutter，服务端 Rust，先验收 iOS 与 Android 手机端；macOS 是开发环境，不是本期必须交付的桌面客户端。默认简体中文、浅色主题。真正的成功标准是：做完 10 个俯卧撑，从首页点一次「+10」即可靠记录，断网与重试也不会漏记或多记。

## 1.2 必须做与不做

| 必须完成 | 本期明确不做 |
| --- | --- |
| 创建、编辑、归档、恢复项目 | 分类、标签、任务截止时间、提醒 |
| 自定义整数计数与单位、首页快捷记录 | 小数、负数记录、计时器、自动识别运动 |
| 今日数量、累计数量、逐条历史 | 目标、连续打卡、积分、排行榜 |
| 撤销最近记录、删除指定记录 | 修改旧记录数量、补记历史时间 |
| 最近 7 天 / 30 天统计 | 日/周/月/年复杂报表、同比/环比 |
| 本地持久化、断网可创建与记录 | 账号登录、跨设备同步、自动恢复 |
| 经用户开启的单设备云端副本 | 多人协作、分享社区、AI 功能 |
| JSON 导出、删除本机及服务端数据 | JSON 导入、订阅支付、公开商店上架 |

项目归档不删除历史。单个项目不提供永久删除，避免误删；需要清空所有资料时使用设置中的明确删除流程。两端服务与联调都属于最终 MVP 的交付范围，不能在本地版完成后就宣告整个项目完工。

## 1.3 核心模型与规则

**项目不是一个可任意覆盖的 total。** 项目包含名称、单位、图标、快捷数量与归档状态。每一次确认记录都创建一条独立 Entry：例如 20 个、10 个、12 个。今日数量为 42，而记录次数为 3。删除其中 10 个那一条之后，数量为 32，记录次数为 2。

名称去掉首尾空白后为 1–40 个 Unicode 标量；单位为 1–8 个，默认「次」。拒绝控制字符、换行与全空白。名称可以重复，身份只认 UUID。图标仅允许 dumbbell / book / leaf / code / droplet / check 六种。默认快捷数量为 1，可改为 1–9,999 的整数；单条数量为 1–999,999 的整数。API 不接受浮点值、科学计数形式或数字字符串；不要把 1.9 自动截成 1。

单位一旦存在任何历史记录，包括已删除的记录，就不可修改。名称、图标、快捷数量仍可改。界面提示「已有记录，单位不可更改；请新建项目」。没有历史记录时单位可编辑。记录数量永远是正数；所谓删除是在原 Entry 上写入 voided_at_utc_ms，不是另建一条负数记录。

首页不显示一个跨项目的「总数量」。20 个俯卧撑与 10 页阅读不能相加成 30。总体统计只汇总有效记录次数、参与项目数和活跃日期；单项目才汇总其自身单位的数量。

## 1.4 信息架构

根页面只有两个入口：**项目 / 统计**。首页右上角「+」创建项目，「更多」进入设置及归档项目列表。项目卡片点主体进入详情，点右侧快捷按钮直接记录；事件区域必须分开，快捷按钮不得同时触发进入详情。没有「我的」、重复的 Projects 页，也没有正中的第三个大加号。

路由建议：`/projects`、`/projects/new`、`/projects/:id`、`/projects/:id/edit`、`/projects/:id/history`、`/stats`、`/archived`、`/settings`。根页面切换保留各自滚动位置；详情与表单返回后回到原项目列表位置。

## 1.5 P01 项目首页

标题 Kodo，副标题「让每一次行动，都算数」。主内容为竖向卡片列表，卡片显示图标、名称、今日数量与单位、累计数量，以及一个 ≥48×48 逻辑像素的快捷按钮。默认新项目在上，按 created_at_utc_ms DESC、id DESC 固定排序；记录操作不自动重排卡片。

快捷按钮显示该项目的快捷量，例如「+10」。一次被接受的点击创建一条独立记录。按钮只在本地事务提交期间短暂防重入，不等待网络，也不对正常连续点击做 500 毫秒之类的吞点击防抖。提交后展示 5 秒提示：「已记录 10 个 · 撤销」。提示每次只对应最近一次 Entry 的 ID；历史页可处理更早的误记。

没有项目时，显示符号、文案「从一次行动开始」及「创建第一个项目」按钮。不自动写入演示数据。应用数据库打开期间使用轻量骨架或进度状态；若数据库损坏或磁盘写入失败，必须显示错误与保留/导出路径，不可伪装成空列表。

## 1.6 P02 创建 / 编辑项目

从上到下：页面标题与取消/保存、六个图标选项、项目名称、单位、快捷记录数量。默认选择 check 图标，单位「次」，快捷量 1。表单没有分类、目标、动机文本框。名称为空时保存禁用；非法数字展示字段错误。保存以本地事务为准，成功后返回首页并显示新项目；网络不可用不阻止保存。

编辑与新建共用表单；已有历史时锁定单位。键盘弹出时表单可滚动，保存按钮仍可到达。存在未保存变更时返回应确认「放弃修改？」；未改动不弹框。保存中的再次点击不得生成重复项目。

## 1.7 P03 项目详情 / 记录

顶栏返回与更多；项目图标、名称、单位；「今日」大数字与「累计」小数字；然后是「本次数量」输入控件。初始值为 quick_amount。减号 / 加号只调整本次草稿数量，不能减少累计数量。快捷选项显示「1 / 5 / 10 / 20」，点击只选择草稿值，不直接写记录。主按钮始终写明「记录 10 个」这样的明确动作。

主按钮提交后，保留当前草稿数量，便于做一组后继续记同样的一组；今日与累计从数据库流自动刷新。给出轻触反馈和 120–160 毫秒的数字变化，不放烟花，不显示长篇励志横幅。5 秒撤销指向准确 Entry ID。

下方「最近记录」展示最多 5 条：数量、记录时的本地日期和时间。看全部进入历史页。更多菜单提供编辑、归档。归档要确认，归档后不能新记录，详情显示只读提示及「恢复项目」动作；仍允许删除误记。

## 1.8 P04 历史、P05 统计

历史每条显示独立发生事件，不把一天所有记录合并成一行。按 occurred_at_utc_ms DESC、id DESC 排序，首屏 50 条，向下以时间戳+ID 游标分页。点行打开删除确认，或左滑露出明确删除按钮；不可仅靠难以发现的长按。删除后隐藏该条并重算所有统计；重复删除相同记录无额外效果。

统计顶部仅为「最近 7 天 / 最近 30 天」。默认总体视图显示有效记录次数与参与项目数，条形图每根柱表示该日期的记录次数。日期序列为今天及之前 6 / 29 个**日历日**，包括今天，缺失日期填 0。选择一个项目后，标题、单位和柱状图一起切换到该项目的数量。每个项目的汇总行必须带单位，不画不同单位数量之间的排名条。

全局统计包括已归档项目的有效历史。项目筛选也可选归档项目并加标记。全零数据保持坐标与空态文案，不显示 NaN、∞ 或 0/0；不要虚构百分比增长。大数使用分组格式，不用省略号截掉数值；用自适应布局或横向数值区域处理。

## 1.9 设置与必要状态

设置只保留：云端副本开关与状态、立即重试、导出数据、归档项目入口、删除全部数据、关于。初始只在本机保存，不自动上传。开启副本前告知会发送项目名称、单位、记录数量与时间，以及服务地址；本期没有账户找回和换机恢复。关闭开关只暂停上传，不删除已经发送的数据。

统一状态文案：仅本机 / 待同步 N 项操作 / 正在同步 / 云端副本已更新 / 连接失败，记录已保存在本机 / 同步需要处理。N 指 outbox 操作数，不是运动次数。只有 outbox 为空且本轮确认完成才显示已更新；网络失败不能显示「记录失败」误导用户重新点一次。

导出使用本地一致性快照，包含所有项目、所有记录及删除标记；不包含 secret、Authorization、outbox 或设备凭据。文件 schema 为 contracts/local_export.schema.json。文件名 `kodo-export-YYYYMMDD-HHmmss.json`，先写临时文件再通过系统分享/保存，明确提醒其中包含个人活动信息。本期导出不是可导入恢复的承诺。

## 1.10 日期与可用性

每条记录保存 UTC 毫秒时间戳、发生时偏移分钟数及 local_date。历史永远按记录发生时的日历日期展示；旅行改变时区不重新分组历史。今天指当前设备日历日期。应用回到前台、午夜跨日、系统时区变化时重新计算今天并刷新读取；不使用服务器的 UTC 日期覆盖设备当天。

所有操作区最小 48×48 逻辑像素。正文默认 16，辅助说明不低于 12；支持系统文字放大到 200% 时滚动、换行而不遮挡按钮。图标按钮提供语义标签；统计图提供逐日期文本等价内容。颜色不能是唯一状态提示。无障碍指标参考 [S10][S11]，最终必须以真实 Flutter 页面验收，而非仅检查效果图。


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


# 3. API、离线与一致性协议

## 3.1 安装身份与上传许可

每次全新安装生成 installation_id（UUID v4）和 secret（32 字节密码学安全随机数，base64url 无填充）。这不是账号，也不是可以公开分享的注册码。客户端先将两者作为一个 JSON 值写入安全存储，再创建匹配的本地元数据；只有两者一致才允许同步。注册与上传必须等用户开启云端副本。

首次网络请求为 `POST /v1/installations`，body 为 `{installation_id, secret}`。在发送前持久化 registration_attempted=true。新 ID 返回 201；相同 ID 与相同 secret 重试返回 200，解决服务器已创建但响应丢失的问题。相同 ID、不同 secret 返回 401；已撤销身份返回 410。服务器保存原始 32 字节 secret 的 SHA-256，不保存 secret 原文，不记录注册 body。

其他请求使用 `Authorization: Bearer <installation_id>.<secret>`。服务端从凭据推导命名空间，操作 body 不接受 installation_id。后端须验证 secret 编码规范并比较哈希。授权缺失或错误为 401，不暴露其他命名空间的记录存在性。没有以「不做登录」为借口省掉鉴权的选项。

如果本地数据库存在但密钥丢失：保留数据，停同步，展示故障与导出，不自动生成新身份把同一数据库上传到别处。如果数据库不存在而安全存储残留旧凭据：将其保留为只供清理旧副本的待处理凭据，不能用 seq=1 向旧身份写入；明确提示无法自动恢复，用户确认新建后生成独立身份。不得默默复用旧身份或丢弃用于删除旧云端副本的凭据。此恢复异常路径须有测试。

## 3.2 端点

| 方法 / 路径 | 目的 |
| --- | --- |
| GET /health/live | 进程存活，无业务数据 |
| GET /health/ready | 数据库与迁移就绪；失败 503 |
| POST /v1/installations | 幂等建立安装身份 |
| POST /v1/operations | 每次提交一条不可变操作 |
| GET /v1/snapshot | 授权的、一致性服务端副本，诊断用 |
| DELETE /v1/installations/current | 删除该身份所有业务数据并撤销凭据 |

完整结构、必填字段、数值边界和响应在 contracts/openapi.yaml（同时提供 JSON）。Operation 为三选一：project.put、entry.add、entry.void。未知字段和未知操作类型必须拒绝。请求最大 16 KiB，Content-Type 为 application/json。snapshot 不受这个请求体限制；服务端在同一个读事务中输出 last_seq、projects、entries，包含归档和删除标记，不作为自动覆盖手机数据库的接口。

## 3.3 三类操作的语义

project.put：entity_id 为项目 ID，payload 为项目完整状态。首次创建时必须未归档；更新保留原 created_at，校验单位锁定规则，updated_at 不用于排序或冲突胜负，不因手机时钟回拨而覆盖顺序判断。顺序只认 seq。

entry.add：entity_id 为新记录 ID，payload 包含 project_id、amount、occurred_at_utc_ms、utc_offset_minutes、local_date。项目必须属于当前身份且在此 seq 时未归档。服务器按 timestamp + offset 验证 local_date，不能按服务器时区重写日期。客户端没有补记 UI，但服务器要允许积压的旧时间；不因「超过一天」而拒绝离线记录。设备时间与现实时间是否准确并不是本期能保证的事。

entry.void：entity_id 为记录 ID，payload 为 voided_at_utc_ms。只能删除当前身份的已存在记录；归档项目也允许删除误记。已删除记录再次 void 为无副作用操作，但这个新的有效 seq 仍要写 receipt、推进 last_seq。不可把删除变成 amount -= N。

新 op_id 企图重复创建同一个 Entry ID 返回 409 entity_exists，不复用旧结果。真正重试必须保留同一个 seq、op_id、entity_id、kind 和 payload。操作 body 入 outbox 后不可编辑、拼接、压缩合并或重新赋 ID。

## 3.4 本地写入与同步工作器

每次领域命令在一个 Drift 事务中：读取并校验项目 → 创建/变更实体 → last_enqueued_seq 加 1 → 生成 op_id → 生成并保存完整 body_json → 提交。异常则全部回滚，包含 seq，不留空洞。即使副本开关关闭也保留 outbox，之后开启时可完整上传所有历史操作。每个被接受的用户记录动作对应一条 Entry；业务没有写入成功就不能吐司成功。

SyncWorker 是唯一发送者，在前台、启动、用户手动重试、事务提交时被唤醒；一次只发送最小 seq 的操作。多次唤醒要合并，不能跑两个 worker。不要求 iOS/Android 进程被杀后继续同步。请求在前台进行，网络可用性提示不是成功判据，以真实 HTTP 结果为准。

收到 ACK 后，在本地事务中验证 op_id 与 seq，删除**该条** outbox 并推进 last_acked_seq。不能删除「所有 seq≤服务器值」来掩盖本地缺项。若刚收到 ACK 就崩溃但还未落盘，下次重发同操作，服务端返回 duplicate，依旧安全。ACK 不修改 Entry、项目、总数或今天。

## 3.5 服务端严格处理次序

一个操作在单个数据库事务中完成以下顺序，不能把第 3 步移到第 5 步后面：

1. 解析 JSON、类型与 envelope，认证身份；被撤销身份拒绝操作。
2. 计算规范化请求哈希。定义为解析合法 JSON 对象后递归按键排序、保留整数类型、UTF-8 紧凑序列化，再 SHA-256；数组不重排。哈希仅在服务器内部比较，不要求 Dart 产生相同哈希。
3. 先检查已有 seq 和 op_id。若 seq / op_id / 请求哈希完全一致，返回原 accepted_at 和 status=duplicate，不再次执行业务校验或写入。这能处理项目后来归档、Entry 后来删除后的旧请求重放。
4. 若相同 seq 或 op_id 对应不同内容，409 operation_mismatch；否则只有 seq=last_seq+1 可以继续。过大为 409 sequence_gap，附 expected_seq。较小但无 receipt 也是一致性故障，禁止当新操作执行。
5. 校验项目/记录存在性、归档、单位锁定、值域及日期，执行业务变更；写 receipt 与新 last_seq；提交成功后才 200 applied。

不是「exactly-once 网络投递」。本方案是客户端至少一次重试，在永久保留 receipt 的单安装命名空间内，实现相同操作的至多一次业务效果。不能清理仍可能被重放的 receipt，不能用一个短期内存缓存代替数据库去重。

## 3.6 失败处理

| 故障 | 客户端规定 |
| --- | --- |
| 超时、断网、503、其他 5xx | 保留同一 outbox；本地数字不回滚；前台退避重试 |
| 429 | 遵守 Retry-After；无值时使用退避 |
| 401 / 410 | 停止自动上传，提示凭据或副本失效；允许继续本地记录及导出 |
| 409 / 422 | 阻塞队首，显示需要处理与错误码；不能跳过 seq 或偷偷丢队列 |
| SQLite 写入失败 | 不显示已记录、不增加数字；错误可重试 |
| ACK 格式或 ID 不匹配 | 当协议错误，不删除 outbox |

退避基线为 1、2、4、8、16、32、60 秒，叠加 0–20% 随机抖动，之后最多每 60 秒重试。只在应用前台运行；请求总超时 15 秒。达到永久错误时由开发者修复校验/协议并重新验收；本期不做任意编辑失败 outbox 的 UI。诊断导出只含 seq、op_id、错误码、版本与时间，不包含凭据及活动 payload。

## 3.7 删除、禁用与边界

关闭副本只暂停上传。删除所有数据是另一个操作，二次确认。如果从未尝试注册，可仅清理本地。若尝试过注册，先持久化 deletion_pending、停止并等待当前同步任务结束，暂时禁止新增写入，再发送 DELETE。断网时显示「待联网完成删除」，保留密钥和删除意图；不能先抹掉 token 导致远端无法删除。

DELETE 与 operations 串行：要么旧操作先提交再被删除，要么身份先撤销而后续操作被拒绝。删除移除 projects、entries、receipts，只留下最小匿名撤销记录（ID、secret_hash、revoked_at；清空其他不必要元数据），防迟到请求复活。重复相同有效凭据返回 204；从未存在的 ID 返回 204 且不修改任何数据；存在但密钥不对返回 401。

收到 204 后，客户端先把「远端已删，待本地清理」阶段写入独立安全存储状态，再清理本地数据与旧密钥，最后移除删除状态。重启根据阶段继续清理，避免清到一半丢失意图。删除进入发送阶段后不可取消；尚未发送时可撤销等待操作。旧服务器备份不保证立即物理擦除，私人试用必须明示；公开发布前另行制定备份保留与清理策略。

## 3.8 最小安全与运行约束

对外只开放 HTTPS；明文 HTTP 仅用于受控本机开发。body、secret、Authorization 均不写日志，错误响应不泄露 SQL 或堆栈。日志记录 request_id、匿名身份截断/哈希标识、op_id、seq、状态码、耗时。不能信任任意 X-Forwarded-For，仅接受明确配置的反向代理。

私人服务也要限制注册与操作滥用：基线为注册每 IP 每小时 10 次、操作每身份每分钟 120 次并允许 60 次突发；snapshot 每身份每分钟 6 次。限流为部署可调参数，集成测试可以提高配额，不能跳过认证。匿名注册的公共滥用风险尚未等同于完整账号体系解决方案，公网上架不在本期验收内。


# 4. 开发步骤、启动方式与交付标准

## 4.1 Codex 的工作方式

先读根目录 AGENTS.md 与 CODEX_START_HERE.md，再读本手册、contracts 与 design/README.md。遵守范围冻结：先做可用的计数器，再接可靠副本，不要自行添加账号、分类、目标或复杂首页。文本规则优先于旧概念图；操作结构以 OpenAPI 为准；发现文字与机器契约冲突时先记录差异、修正最小范围，不凭感觉选一个掩盖问题。

每个里程碑结束要提交：变更摘要、运行命令、真实测试输出、截图/录屏（适用时）、遗留问题。下一阶段不能绕过上一阶段的数据可靠性缺陷。不允许只交一组截图或使用假数据证明后端联调成功。

## 4.2 里程碑与验收门槛

| 阶段 | 具体工作 | 完成门槛 |
| --- | --- | --- |
| M0 工程基础 | 建立 Flutter 与 Rust 项目、固定工具链、接入资源与 tokens、健康检查、CI 基础 | 两端最小项目能启动；版本与命令有记录；测试与分析命令真实执行 |
| M1 本地纵向闭环 | Drift 表与事务、创建项目、首页、详情、快捷记录 | 新建俯卧撑→记录 10→退出重开仍为 10；全程可离线 |
| M2 完整本地 MVP | 历史/撤销、归档/恢复、7/30 天统计、JSON 导出 | 统计口径与 demo_expected.json 一致；跨日、单位锁定、空态测试通过 |
| M3 Rust 副本服务 | 注册、鉴权、三种操作、receipt、snapshot、删除与数据库持久化 | scripts/smoke_api.py 对真实 Rust 服务通过；跨身份访问不泄露数据 |
| M4 可靠同步 | Outbox worker、前台唤醒、ACK、退避、上传许可、删除恢复状态 | 离线积压→恢复网络；响应丢失→重放；进程崩溃→恢复；计数不重不漏 |
| M5 UI 与设备质量 | 原生重建页面、无障碍、异常状态、性能、平台网络配置 | iOS/Android 模拟器必测；至少一台真机完整流程；无溢出/截图背景拼界面 |
| M6 打包与交付 | 清空演示种子、更新 README/锁文件、部署与备份演练、证据归档 | 完整 MVP 勾选通过；两端构建记录与已知限制齐全；没有未声明的阻塞错误 |

M1 和 M2 是开发中的中间验收点，不代表 Rust 服务可以被删掉。若某平台环境暂缺，必须明确列为未验收，并给出可复現步骤，不能写成双端已完成。

## 4.3 本地开发环境

开发机器为 macOS；先运行 `flutter doctor -v`，安装和确认可用的 iOS/Android 开发工具。Rust 使用 rustup 管理的固定 stable toolchain。Docker Desktop 可作为后端部署/联调方式，但普通 `cargo run` 也必须能运行。这里不预填未经编译验证的 Flutter、Rust 或插件版本；由 M0 固化组合。

建议在新的代码仓库创建目录，而不是覆盖本交接包：

```bash
mkdir -p kodo/apps kodo/services
cd kodo
flutter create --platforms=ios,android --org dev.example \
  --project-name kodo_app apps/mobile
cargo new --bin --name kodo-api services/api
```

dev.example 是临时组织标识，不代表可用于正式上架的包名。将本包的 contracts、design、docs、scripts 与 AGENTS.md 放入新仓库；按照 scaffold 示例建立环境文件与 compose。上述命令只创建空工程，不能视为功能已实现。

## 4.4 实现后必须支持的命令

后端应从环境变量读取配置，不把密钥放进源码。用 cargo run 本地启动时需加载 .env，或者显式导出变量；不能假设 Rust 会自动读取文件。

```bash
# 仓库根目录，代码与依赖实现完毕后
mkdir -p var/kodo
export KODO_BIND=127.0.0.1:8080
export KODO_DATABASE_URL=sqlite://$(pwd)/var/kodo/kodo.sqlite
cargo run --manifest-path services/api/Cargo.toml

# 另一终端
python3 scripts/smoke_api.py --base-url http://127.0.0.1:8080

# 手机端目录；替换成 flutter devices 列出的设备 ID
cd apps/mobile
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d <device-id> \
  --dart-define=API_BASE_URL=http://127.0.0.1:8080
```

API_BASE_URL 只放公开服务地址，不能放 token。iOS 模拟器使用 Mac 上已发布的本地端口；Android 标准模拟器访问宿主机使用 10.0.2.2，而不是模拟器自己的 127.0.0.1。[S12] 真机使用同一受控局域网内 Mac 的地址，且后端监听 0.0.0.0；保持防火墙权限最小化。不要把 0.0.0.0 当客户端请求地址。

开发 HTTP 例外只放 Debug 配置；Release 强制 HTTPS。Android 权限与网络安全配置、iOS 本地网络说明/ATS 调试例外都要在 M5 逐项实测。开发用 compose 默认只绑定宿主机 127.0.0.1；真机联调时需要显式调整端口绑定，不能仅改服务容器内部监听。

## 4.5 测试和构建入口

```bash
cargo fmt --manifest-path services/api/Cargo.toml --check
cargo clippy --manifest-path services/api/Cargo.toml --all-targets -- -D warnings
cargo test --manifest-path services/api/Cargo.toml

cd apps/mobile
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze
flutter test
flutter test integration_test -d <device-id>
flutter build apk --debug
flutter build ios --no-codesign
```

这些是 Codex 完成实现后应执行并记录的目标命令，不是本交接包已经运行成功的声明。iOS 构建在 macOS/Xcode 环境执行；未签名构建不等同于可分发给任意真机的安装包。CI 可以将 Rust 和 Flutter 逻辑测试放在 Linux，iOS 构建/设备测试单独放 macOS。

## 4.6 备份、迁移与运维

数据库迁移纳入 SQLx 与 Drift 的版本管理；不要每次启动清表。首次启动自动建立 v1 schema，再次启动保持数据。为未来版本保存 schema v1 测试快照。服务端启动先完成迁移，再让 ready 返回 200。日志中不含 Authorization、secret 或用户活动 body。

服务端为单实例、本地持久卷。备份选择 SQLite Online Backup API，或停服务后复制整个数据目录；不要在 WAL 活跃时只复制主 .sqlite 文件而漏掉 WAL。[S8][S9] 私人试用推荐先用明确停机步骤：停止 API→复制整个 var/kodo→恢复 API→在独立临时目录恢复备份并验证 snapshot 数据。保留加密/访问控制的备份位置，不把备份提交 Git。

上传副本只是数据冗余，不等于本期已经具备用户自助恢复。账号恢复、换机导入和跨设备同步应在下一期一起设计，不能提前共享同一 token 让两个客户端同时写 seq。

## 4.7 最终 Definition of Done

最终代码必须能从清洁环境按 README 启动；iOS 与 Android 核心路径、Rust API 持久化、跨设备身份隔离和异常同步均有真实证据。必须交付截图、短录屏、测试报告、锁文件、数据库迁移、.env.example、Dockerfile、compose.yaml、无密钥的演示配置和已知限制。

必测流程：创建俯卧撑（个，快捷 10）→首页记 10→详情记 12→撤销 12→断网记 20→重启仍为 30→联网后服务端也为 30→重发同一请求仍为 30→归档→恢复→导出→删除全部数据。过程中没有注册登录阻塞，也没有记录被网络失败回滚。

私人 MVP 验收通过不等于已经完成商店隐私声明、商标核验、安全评估、公开注册防滥用或所有平台的发布签名。未完成项必须写清楚，不得用占位 TODO 隐藏为已完成。


# 5. 测试计划与验收证据

## 5.1 测试层级

Flutter 领域/仓储单元测试验证输入、事务、日期和查询；Widget 测试验证文案、操作与无障碍；Integration 测试覆盖真实数据库、应用重启及网络切换。Rust 以临时 SQLite 文件做 API 集成测试，不仅用内存结构代替存储。官方 Flutter 测试概览对单元、Widget 与集成层级有说明。[S13]

统一使用可注入 FakeClock 与 UUID 工厂。视觉演示时钟固定在 2026-09-11 18:00 UTC+08:00。examples/demo_export.json 是纯测试数据，生产首次启动不得自动导入。expected 文件给出确切结果：俯卧撑今日 42 个、累计 143 个；全项目今日 6 次有效记录；最近七天 13 次有效记录。被删除的 +10 个不进入任何有效数量或有效记录次数。

## 5.2 功能与数据测试矩阵

| ID | 场景 | 必须观察到的结果 |
| --- | --- | --- |
| P01 | 首次打开，无网络 | 空态可创建；无登录阻塞、无自动种子 |
| P02 | 保存合法中文项目 | 正确持久化；重启后还在 |
| P03 | 全空白/超长名称 | 保存禁用或字段错误，无脏数据 |
| P04 | 单位 1/8/9 个字符 | 前两种合法，9 个拒绝 |
| P05 | 重名项目 | ID 不同，相互记录不干扰 |
| P06 | 首页快捷 +10 | 一条 Entry，数量 +10，不进入详情 |
| P07 | 详情草稿 1→5→20 | 未点主按钮前数量不变 |
| P08 | 单条 0/-1/1.5/999999/1000000 | 只有 999999 合法；0 不代表删除 |
| P09 | 100 次被接受的 +10 命令 | 100 条不同 Entry，共 1000，无合并/吞掉 |
| P10 | 本地事务故意失败 | Entry、outbox、seq 同时回滚 |
| P11 | 成功落盘后立即杀进程 | 重启仍有记录与待上传操作 |
| P12 | 20+10+12，再撤销 10 | 32 个、2 次有效记录 |
| P13 | 最后一条之外的历史删除 | 只删除选中 ID，不误减最近一条 |
| P14 | 同一 Entry 删除两次 | 第二次不改变统计 |
| P15 | 有记录/全被删后改单位 | 两种均禁止改单位 |
| P16 | 无记录项目改单位 | 允许，不改变其他项目 |
| P17 | 归档→试图记录→恢复 | 归档不允许新记录；历史保留；恢复后可记 |
| P18 | 归档项目删除误记 | 允许；总体统计更新 |
| P19 | 混合个/页/分钟/题 | 总体只报记录次数，不相加数量 |
| P20 | 7/30 日全零与稀疏数据 | 补齐日期，无 NaN / 除零 |
| P21 | 午夜 23:59→00:01 | 今日刷新，前一日记录不挪动 |
| P22 | UTC+8→UTC-7 旅行 | 历史按保存日期；今天按当前设备日期 |
| P23 | 夏令时切换前后偏移 | local_date 与各条 captured offset 一致 |
| P24 | 同毫秒 55 条历史，分页 50 | 第二页 5 条，排序稳定且无重复/遗漏 |
| P25 | JSON 导出 | 通过 schema，含删除标记，无凭据/outbox |

## 5.3 协议与故障测试矩阵

| ID | 场景 | 必须观察到的结果 |
| --- | --- | --- |
| S01 | 注册成功但丢失响应后重试 | 同一身份 200 existing，不生成新身份 |
| S02 | 同一身份不同 secret | 401，不改变原数据 |
| S03 | 未授权访问 snapshot/operations | 401，没有业务数据泄露 |
| S04 | B 身份引用 A 的 project_id | 拒绝；两套 namespace 无越权 |
| S05 | 相同 op 重放 10 次 | 一次业务效果，后续 duplicate |
| S06 | 相同 seq 或 op_id 改 payload | 409 operation_mismatch，无写入 |
| S07 | seq=1 后直接发 seq=3 | 409 sequence_gap，expected_seq=2 |
| S08 | 入库成功，响应被代理丢弃 | 客户端保留队列；重放不重复记 |
| S09 | ACK 收到后、本地确认前崩溃 | 重启重发，同一效果，队列最终清空 |
| S10 | 新建→记录→归档均离线 | FIFO 顺序完整应用，记录被接受 |
| S11 | 加记录→立刻撤销，均未同步 | 最终服务端该 Entry 已删除，有两份 receipt |
| S12 | 项目归档后重放旧 add | duplicate；不能被归档校验误拒绝 |
| S13 | 队首永久 422 | 停队列且显示错误，不跳过 seq |
| S14 | 多次前台/保存同时唤醒 | 只有一个 worker、一个在途操作 |
| S15 | 关闭开关→产生新记录→开启 | 本地可用；重新开启后补齐所有操作 |
| S16 | DELETE 与在途操作竞争 | 删除后无复活，迟到写入被拒绝 |
| S17 | 删除请求/回应丢失与进程重启 | 继续删除阶段，不丢密钥，最终本地与云端清空 |
| S18 | 删除后同 secret 注册/写入 | 410；重复 DELETE 为 204 |
| S19 | 429 / 503 / 超时 | 等待或退避；本地记录不回滚 |
| S20 | 日期与 timestamp+offset 不符 | 422，seq 不前进、无实体/receipt |
| S21 | SQLite 写锁或提交失败 | 非 200；业务、receipt、last_seq 一起回滚 |
| S22 | token 丢失或 DB/凭据不配对 | 同步停用，保留数据，不能默默新建并上传 |
| S23 | 查询与删除、快照并发 | snapshot 为一个一致版本，不出现混合半旧半新 |
| S24 | 日志与诊断检查 | 不含 secret、Authorization、活动请求体 |
| S25 | 超长 body / 未知字段 / 数字字符串 | 明确 413/422，不宽松强制转换 |

## 5.4 视觉与性能检查

至少覆盖 390×844 与 360×800 的逻辑尺寸，以及 100% / 200% 字体缩放；所有内容可滚动到达，主按钮没有被键盘挡住。TalkBack/VoiceOver 能读出项目、数量、按钮动作与同步状态，图表有文字等价内容。点击目标 ≥48×48。正常文本颜色组合按 tokens 对比度检查，但这不是完整无障碍合规证明。

Golden 截图必须来自真正 Flutter 页面。使用固定平台/字体/时钟/fixture 建立各平台独立基线；不得把 AI 效果图当像素级 golden。首次基线需人工核对后再提交，不能遇到回归就全量更新基线。设计 PNG 与 HTML 只是视觉/布局参考。

性能为待测目标：在记录明确型号和系统版本的真机 profile 模式，100 次本地提交到可见反馈 p95 ≤150ms；1 万条记录、100 个项目时冷启动到可交互目标 ≤2s，页面滚动没有持续掉帧。超标需记录环境、耗时与定位，不可将模拟器 debug 模式结果包装成真机性能结论。

## 5.5 本交接包已经验证 / 尚未验证

本包附带机器契约、SQL、样例、UI 源素材和校验脚本。qa/HANDOFF_VALIDATION.md 记录本次在文档生成环境中实际完成的检查，例如 JSON Schema/样例一致性、SQL 约束、统计期望、资产哈希与文档渲染。

**当前环境没有 Flutter / Dart / Rust SDK，因此没有编译手机应用、启动真实 Rust API 或执行真机联调。** scripts/smoke_api.py 是供实现后对真实服务运行的验收入口，不是测试已经通过的声明。所有上述 P/S 编号均属于 Codex 后续必须实现的验收用例。


# 附录 A. 设计资源与文件索引

## 资源实施原则

完整设计说明见 design/README.md。最终布局看 design/implementation/index.html 与六张对应屏幕 PNG；它们是静态 HTML 的实际渲染，不是 Flutter 运行证明。字体使用平台系统字体，不分发或下载字体文件。主色 #416954、背景 #FAFAF8、正文 #1F2937，tokens.json 定义完整参数。

原始 AI 视觉稿完整保存在 design/references。另提供 22 个独立 SVG 线性图标、矢量品牌符号、1024/512/192/180 PNG 应用图标源，以及 Android 透明前景。Flutter 只打包 design/assets 中的所需资产；文字、输入框、按钮、卡片与图表必须用真实控件重建。

原图的浅绿文字按钮对比度不作为实施标准；白字主按钮改用更深的 #416954。几组正文对比度已按实际色值计算，结果见 contrast_checks.json。最终仍须检查动态字号、触控与读屏。

## 关键文件

| 文件 | 用途 |
| --- | --- |
| CODEX_START_HERE.md / AGENTS.md | 直接开工指令与工程约束 |
| HANDOFF.md / Kodo_MVP_Handoff.docx / PDF | 同一实施文档的可读版本 |
| contracts/openapi.yaml + openapi.json | 六个 API 路径与完整对象结构 |
| contracts/operation.schema.json | 三种操作联合结构 |
| contracts/server_schema.sql + local_schema.sql | 服务器/客户端表与核心约束 |
| contracts/queries.sql | 总量、今日、统计和历史查询样例 |
| examples/demo_export.json + demo_expected.json | 固定时钟的演示数据与准确结果 |
| examples/operations_sequence.json | 新建→两次记录→删除的协议样例 |
| design/assets + tokens.json | 原始矢量、图标源与设计参数 |
| design/implementation/index.html | 两主入口的最终静态布局基线 |
| scripts/validate_handoff.py | 契约、样例、SQL 与资源校验 |
| scripts/smoke_api.py | 后续对真实 Rust 服务运行的验收脚本 |
| scaffolding/ | 环境、compose、pubspec 资源、主题接入示例 |
| qa/ | 本包校验结果与待实施测试报告模板 |


# 附录 B. 技术来源与查阅范围

查阅日期：2026-09-11。仅采用官方文档或项目维护者文档。页面可能继续更新；实施时以固定的工具链和依赖锁文件为准。这些来源用于支持技术机制，产品功能与同步契约是本项目的设计选择，不是来源对本方案作出的保证。

| 编号 | 来源 | 本方案使用范围 |
| --- | --- | --- |
| S1 | Flutter Offline-first support — https://docs.flutter.dev/app-architecture/design-patterns/offline-first | 本地优先写入、Repository、同步的取舍 |
| S2 | Flutter Architecture recommendations — https://docs.flutter.dev/app-architecture/recommendations | UI/数据分层、Repository、可测试性 |
| S3 | Drift Transactions — https://drift.simonbinder.eu/dart_api/transactions/ | 本地事务原子性与流更新 |
| S4 | Drift package — https://pub.dev/packages/drift | SQLite、响应式查询、迁移 |
| S5 | Axum crate documentation — https://docs.rs/axum/latest/axum/ | Rust HTTP 服务选型 |
| S6 | SQLx crate documentation — https://docs.rs/sqlx/latest/sqlx/ | Rust 异步数据库访问 |
| S7 | flutter_secure_storage — https://pub.dev/packages/flutter_secure_storage | 平台安全存储与配置注意事项 |
| S8 | SQLite Write-Ahead Logging — https://www.sqlite.org/wal.html | WAL 与本地数据库运行边界 |
| S9 | SQLite Backup API — https://www.sqlite.org/backup.html | 一致性备份，不仅复制活跃主文件 |
| S10 | W3C Understanding SC 1.4.3 — https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html | 正文 4.5:1 对比度检查依据 |
| S11 | Flutter Accessibility — https://docs.flutter.dev/ui/accessibility | 手机界面可访问性验收 |
| S12 | Android Emulator networking — https://developer.android.com/studio/run/emulator-networking | 模拟器连接宿主机的地址 |
| S13 | Flutter Testing overview — https://docs.flutter.dev/testing/overview | 单元、Widget、集成测试划分 |
| S14 | flutter_riverpod — https://pub.dev/packages/flutter_riverpod | 状态管理依赖资料 |
| S15 | flutter_svg — https://pub.dev/packages/flutter_svg | SVG 资源加载资料 |

没有在本轮核验正式上架政策、开发者账户费用、商标可用性或域名所有权；这些不是私人 MVP 的完成条件，也不应从本文推断已获许可。
