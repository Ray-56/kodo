# 技术来源与查阅范围

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
