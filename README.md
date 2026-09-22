# Kodo · 行一 0.1.0

Flutter 手机计数器与独立 Rust 单安装副本服务。简体中文、浅色、项目 / 统计两个入口。本机 SQLite 是读取来源；默认不上传。没有账号、换机恢复、多设备合并、目标或分类。

## 环境

实际验证：Flutter **3.41.4** / Dart **3.11.1**，Rust **1.96.0**，Xcode **26.6**，CocoaPods **1.16.2**，Android SDK **36.1.0**。Flutter 固定在 `mise.toml`，Rust 在 `rust-toolchain.toml`；提交了 `pubspec.lock`、`Cargo.lock`、`Podfile.lock`。应用组织标识暂用 `dev.example`。

```sh
mise install
rustup show
flutter doctor -v
```

## 本地运行

在仓库根目录启动服务（SQLite 父目录必须存在；cargo 不自动加载 .env）：

```sh
mkdir -p var/kodo
export KODO_BIND=127.0.0.1:8080
export KODO_DATABASE_URL=sqlite://var/kodo/kodo.sqlite
cargo run --locked --manifest-path services/api/Cargo.toml
```

新终端：

```sh
python3 scripts/smoke_api.py --report qa/evidence/manual-smoke.json
cd apps/mobile
flutter pub get --enforce-lockfile
dart run build_runner build
flutter devices
flutter run -d <iOS-simulator-id> --dart-define=API_BASE_URL=http://127.0.0.1:8080
# Android 模拟器用 --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

应用首次为空。从「+」创建俯卧撑，单位个、快捷10；首页按「+10」即先在本机落盘。设置中明确同意才会注册、上传所有积压操作。默认地址 `https://localhost:8080` 只是无密钥占位地址，运行本机服务时必须传上述开发地址。Release 构建拒绝 HTTP。真机联调使用同一受控局域网内 Mac 的地址，并显式把服务监听改为 `0.0.0.0`。

## 测试与构建

```sh
cargo fmt --manifest-path services/api/Cargo.toml --check
cargo clippy --manifest-path services/api/Cargo.toml --locked --all-targets -- -D warnings
cargo test --manifest-path services/api/Cargo.toml --locked
cd apps/mobile
dart format --output=none --set-exit-if-changed lib test integration_test test_driver
flutter analyze
flutter test
# 真实 Rust 服务运行时，启用故障联调测试：
KODO_TEST_API_URL=http://127.0.0.1:8080 flutter test test/real_sync_test.dart --reporter expanded
# 测试目标只用于可丢弃的模拟器安装，会清理测试身份及数据：
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/full_flow_test.dart -d <device-id> --dart-define=API_BASE_URL=http://127.0.0.1:8080
flutter build apk --debug --dart-define=API_BASE_URL=http://10.0.2.2:8080
flutter build ios --no-codesign
```

`flutter drive` 完成后会卸载测试应用。iOS Keychain可能保留测试安装凭据；随后普通安装若提示身份不匹配，这是已实施的保护路径。可在设置中明确执行清理旧副本/删除全部数据后开始，不能自动复用旧序号。真正的同一安装重启验收使用：

```sh
KODO_RESTART_IOS=<iOS-simulator-id> flutter drive --driver=test_driver/integration_test.dart --target=integration_test/local_flow_test.dart -d <iOS-simulator-id> --dart-define=API_BASE_URL=http://127.0.0.1:8080
```

主机驱动在卸载前 force-stop/relaunch，检查恢复页面与真实 SQLite：一条有效 Entry、总量10、两条待同步操作。测试不会把“重新安装”当作“重启”。

## 数据与可靠性

- Flutter Drift 版本2（保留v1快照与无损升级测试）：`apps/mobile/lib/core/storage/schema.drift`；后台 isolate、WAL/FULL、事务内实体 + seq + 不可变 outbox。
- Rust SQLx 迁移：`services/api/migrations/0001_initial.sql`；一个池连接串行事务，凭据隔离命名空间。先检查 receipt，再校验当前项目状态。
- 只有一个 FIFO worker。ACK 只确认队首，不覆盖本地实体；丢失响应和确认前崩溃使用原 op_id/seq 重试。永久错误保留队首。
- 时间使用每条记录保存的 UTC 毫秒、偏移和 local_date；总体统计只计有效记录次数。
- 密钥仅在平台安全存储。数据库与凭据不匹配时停同步、保留本地记录和导出；残余 Keychain 凭据只供旧副本清理，不作恢复或复用。
- 删除先记录意图，等待在途任务，再删服务端；`sending` / `remote_deleted` 阶段保存在安全存储。204 后才清本机和旧凭据。
- 导出是本地事务快照，包含 void 标记，排除身份、密钥、outbox。本期不支持导入。

## 部署与备份

```sh
docker compose config
docker compose up --build -d
curl -f http://127.0.0.1:8080/health/ready
```

单实例、单本地持久卷，宿主机默认仅绑定 loopback。公网必须使用 HTTPS 反向代理；不信任任意转发 IP。注册10/IP/小时，操作120/身份/分钟、突发60，快照6/身份/分钟，均可通过 `.env.example` 中的环境变量调整。请求最多16 KiB。诊断快照超过10万实体返回503，避免无界内存；不作为手机自动拉取接口。

本次 Docker Hub 网络超时，容器构建与持久卷运行尚未验收，详见报告。Dockerfile 固定 Rust 1.96.0 与 Debian bookworm-20260824-slim（[官方镜像清单](https://github.com/docker-library/official-images/blob/master/library/debian)）；不能把本机 cargo 成功当作容器验证。

对直接运行的服务，可以在线生成一致备份：

```sh
python3 scripts/backup_sqlite.py var/kodo/kodo.sqlite /安全目录/kodo-backup.sqlite
# 在隔离目录恢复并启动；不得覆盖运行中的原数据库
KODO_BIND=127.0.0.1:8081 KODO_DATABASE_URL=sqlite:///安全目录/kodo-backup.sqlite cargo run --manifest-path services/api/Cargo.toml
```

脚本使用 SQLite Online Backup API，并检查 integrity_check。不要只复制活跃 WAL 数据库的主文件。若使用目录复制法，先停止服务，再复制整个数据目录。备份包含活动数据与凭据哈希，应加密并限制访问；旧备份不会因在线删除而自动物理擦除。

## 验收与限制

逐项结果见 [qa/IMPLEMENTATION_REPORT.md](qa/IMPLEMENTATION_REPORT.md)，阶段证据见 [qa/MILESTONES.md](qa/MILESTONES.md)。所有截图来自 Flutter 运行页面。未执行项目明确标记，不以静态设计图代替验收。

真机 profile 性能、VoiceOver/TalkBack 人工朗读、平台最终图标蒙版与系统分享落盘，依验收报告状态为准。未签名 iOS 构建不代表可分发。此交付不包含商标、商店审核、公开匿名注册安全评估或多设备恢复能力。

### Android 真机验收（2026-09-21）

真机结果、可复现命令和未完成门槛见 [qa/PHYSICAL_DEVICE_REPORT.md](qa/PHYSICAL_DEVICE_REPORT.md)。使用 `ORG_GRADLE_PROJECT_kodoQa=true` 构建独立 `dev.example.kodo_app.qa` / Kodo QA；默认构建仍为Kodo原包名。设备测试包含删除和性能夹具，只能在新建的可丢弃QA安装运行；full_flow初始检查非空即失败，不再自动擦除已有数据。

本机旧Intel Android Studio导致Flutter3.41.4的IDE自动探测崩溃时，可以使用 `scripts/flutter_cli.dart` 包装入口，沿用显式固定的JDK/SDK，并绕过IDE发现；它不修改Flutter或IDE。具体命令在真机报告中。QA包应先构建，再以 `flutter drive --use-application-binary=...` 运行，避免工具从Gradle源码错误推断包名。性能采集使用profile和 `--no-dds`。
