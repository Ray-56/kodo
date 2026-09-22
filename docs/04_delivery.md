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
