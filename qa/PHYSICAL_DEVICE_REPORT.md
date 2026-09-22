# Android 真机补验 · 2026-09-21

已完成 Android 真机关键链路、同安装重启、真实 Rust 同步和删除中断恢复；记录延迟与进程冷启动达到交接指标。**整体 M5/M6 仍为部分完成**：120 Hz 下的滚动表现、人工读屏/分享保存、iOS 真机、Release HTTPS 和容器运行仍需验收。

## 环境与隔离

- 小米 23127PN0CC（houji），SM8650，Android 16 / API 36，安全补丁 2026-08-01；1200×2670，480 dpi，字号 100%，系统峰值刷新率设为 120 Hz。测试时连接 USB 并充电，系统 thermal status 为 0；没有修改手机字体、刷新率或网络开关。
- 主机此次已升级到 macOS 27.0 (26A428)。Flutter 3.41.4 / Dart 3.11.1 / Java 17.0.19；版本未升级。
- 自动化统一安装独立包 `dev.example.kodo_app.qa` / Kodo QA。首次检查没有任何 Kodo 包。`flutter drive` 结束会卸载测试包；重启探针在卸载前对同一 APK 执行 `am force-stop` / `am start`，**没有清数据或换包冒充重启**。
- Rust 实际进程监听主机 `127.0.0.1:8083`，SQLite 位于 `var/device-qa/kodo.sqlite`，ADB reverse 连接手机。仅本机模式通过上传许可关闭验证，没有声称切断整个手机移动网络。测试限流临时提高；生产默认值未改。
- 原始日志、截图及逐样本数据：`qa/evidence/physical-2026-09-21/`。

## 已执行场景

| 场景 | 结果及证据 |
| --- | --- |
| 原生完整流程 | `full-flow-device.log`：26 秒测试通过。空态→中文项目→快捷10→输入12→精确撤销→草稿20→累计30→统计→明确许可→真实Rust→旧Entry重放仍30→归档/恢复→双重确认删除。7张截图。 |
| 本地强制停止/重启 | `local-restart.log` / `local-restart.json`：停止前后均1项目、1有效Entry、累计10、outbox2。重新启动后页面断言通过。此 debug 运行不作为性能指标。 |
| 本地积压→重启→授权同步 | `local-sync/device.log` / `local-sync/local-sync-restart.json`：最终代码验证安全存储读回与身份配对；待同步2→0，项目1、Entry1、累计10不变；实际服务端snapshot为10，原op重放返回duplicate。 |
| 删除提交后中断 | `deletion/device.log` / `deletion/integration-metrics.json`：真实DELETE返回204后，测试适配器暂扣响应，安全存储仍为sending、SQLite仍有10。随后主机真正强停手机进程。重启运行生产bootstrap，恢复删除、本地清空、标记清除、新身份独立、旧身份重新注册返回410。 |
| 安全存储异常 | `platform-store.log`：真实平台通道边界注入KeyStoreUnavailable，确认请求`resetOnError=false`，没有写入/删除凭据；SQLite项目、10数量、2操作及meta均不变。 |
| 回归 | `flutter-tests.log`：37 tests passed，含实际Rust HTTP；`analyze-final.log`：No issues found。 |

## Profile 性能

`performance_test.dart` 断言 `kProfileMode=true`。使用实际生产 Repository、后台 isolate SQLite、WAL/FULL 和原生页面；性能数据仅由测试 target 创建，普通首次启动无种子数据。截图在计时结束后捕获，避免 Android screenshot surface conversion 改变性能采样。

| 指标 | 实测 |
| --- | --- |
| 100次首页快捷记录 | 100条Entry、总量1000、outbox101；未吞点击 |
| 点击→事务落盘后的数字帧 | p50 **33.237 ms** / p95 **35.075 ms** / max **38.097 ms**；p95≤150ms通过 |
| 数据规模 | 100项目 / 10,000 Entry / 10,100不可变待同步操作 |
| 3次进程冷启动→验证完成列表帧 | **1421.41 / 1415.00 / 1259.86 ms**，全部≤2s |
| Dart入口→列表帧 | 910.807 / 860.896 / 835.477 ms（不包含Android进程启动） |
| 滚动 | 24次上下fling，1,402帧；build平均2.819ms / p95 10.292ms，raster平均5.561ms / p95 7.778ms |
| 16.67ms预算（60Hz参考） | build超时23帧（1.64%），raster超时31帧（2.21%） |
| 8.33ms预算（120Hz参考） | build超时115帧（8.20%），raster超时50帧（3.57%）；不宣称120Hz零卡顿或此项完全验收 |

冷启动计时是主机monotonic钟从发出ADB启动到读取“已验证列表帧”标记，包含USB命令与轮询开销；每次停止进程，但保留OS文件缓存。它不是重启整机、清页缓存或商店Release基准。点击计时包含测试手势与帧采样开销；该手机上的单轮100样本不能代表所有机型。帧阶段耗时并不等同于Android实际呈现掉帧率；以上60/120Hz为两种固定预算比较，系统动态刷新率未逐帧采集。

原始100样本、逐帧build/raster耗时：`profile/integration-metrics.json`；三次重启：`profile/performance-restart.json`；预算重算：`profile/frame-budget-analysis.json`。Flutter内置摘要使用16ms预算，报告另按16.67/8.33ms从原始微秒值计算，因此计数稍有差别。

## 实际遇到的问题与修改

1. ADB初始unauthorized，手机授权后正常；首次USB安装被系统限制，后续安装成功。失败日志保留。
2. Flutter 3.41.4自动枚举 `/Applications/Android Studio.app` 时执行其旧Intel JRE，当前主机无可用Rosetta，连显式JDK配置也不能避免枚举崩溃。使用 `scripts/flutter_cli.dart` 仅绕过IDE枚举，仍使用固定Flutter SDK/JDK/Android SDK；没有修改SDK或已安装IDE。命令行可以构建，不声称旧IDE问题已解决。
3. Flutter源码项目启动错误推断基本包名而忽略可选QA后缀。改为先构建，再用 `--use-application-binary` 从APK读取真实包名，已验证QA和常规包分别为正确ID。
4. 性能首轮开启DDS，设备端采集器连接VM service失败；`--no-dds`复测通过，失败轮不计入基准。
5. 真机重启日志出现插件对旧EncryptedSharedPreferences格式的探测失败，随后使用其现有AES-GCM存储路径；最终测试验证凭据可重读并继续原身份同步，没有观测到凭据丢失。检查中发现插件`resetOnError`默认true与保留凭据要求不符，已在 `identity.dart` 明确设为false，并补了平台通道故障回归。

变更文件：Android Gradle/Manifest中的可选QA包标识；`identity.dart`；三个设备测试target（local/performance/deletion）与full_flow的“初始必须为空”断言；`test/platform_store_test.dart`；driver结果保存和重启探针；CLI兼容入口；本报告、里程碑、验收报告及README。没有扩大产品功能。

## 复现

在项目根目录设置 `FLUTTER_ROOT` 为固定SDK路径，并确保 `flutter config --jdk-dir` 指向17.0.19。以下包装入口只为本机旧IDE枚举故障；正常环境可用普通flutter命令。

```sh
export FLUTTER_ROOT=/Users/ray/flutter
cd apps/mobile
flutter_cli() {
  "$FLUTTER_ROOT/bin/cache/dart-sdk/bin/dart" \
    --packages="$FLUTTER_ROOT/packages/flutter_tools/.dart_tool/package_config.json" \
    ../../scripts/flutter_cli.dart "$@"
}
# 先启动Rust 8083及adb reverse tcp:8083 tcp:8083。
ORG_GRADLE_PROJECT_kodoQa=true flutter_cli build apk --debug \
  --target=integration_test/full_flow_test.dart \
  --dart-define=API_BASE_URL=http://127.0.0.1:8083
KODO_EVIDENCE=/absolute/evidence flutter_cli drive \
  --driver=test_driver/integration_test.dart \
  --use-application-binary=build/app/outputs/flutter-apk/app-debug.apk -d DEVICE
# 同安装+同步：target换为local_flow_test.dart，增加
# --dart-define=QA_SYNC_AFTER_RESTART=true；drive增加环境变量
# KODO_RESTART_ANDROID=DEVICE KODO_RESTART_MODE=local-sync。
# 删除中断：target换为deletion_restart_test.dart；mode=deletion。
ORG_GRADLE_PROJECT_kodoQa=true flutter_cli build apk --profile \
  --target-platform=android-arm64 --target=integration_test/performance_test.dart
KODO_EVIDENCE=/absolute/evidence KODO_RESTART_ANDROID=DEVICE \
KODO_RESTART_MODE=performance flutter_cli drive --profile --no-dds \
  --driver=test_driver/integration_test.dart \
  --use-application-binary=build/app/outputs/flutter-apk/app-profile.apk -d DEVICE
```

仅对新建/可丢弃QA安装执行这些target；不能把包含测试夹具或删除操作的target安装到用户已有正式数据上。

## 仍未完成

- 人工TalkBack/VoiceOver阅读与焦点顺序、系统分享最终保存、两平台所有图标蒙版。
- iOS真机验证、Release真实HTTPS联调、120Hz滚动验收及更多机型/多轮性能稳定性。
- Docker Hub网络阻塞后的容器运行/持久卷验收、远端CI；未重新声称这些历史阻塞已解决。
- 未进行生产签名、公开上架或品牌审核。

## 留在手机上的体验版本

普通 `dev.example.kodo_app` / Kodo调试包已在用户允许USB安装后安装并启动成功；QA包已移除。`interactive-first-launch.png` 确认原生空态，没有自动演示数据，云端副本默认关闭。APK校验值见 `interactive-build.json`，安装/启动原始日志为 `interactive-install-final.log` / `interactive-launch-final.log`。

本次调试包连接电脑上的Rust开发服务 `127.0.0.1:8083`，当前通过USB转发；服务保持运行便于试用。拔线或电脑服务停止后，手机仍可本地记录，云端补发需恢复此连接。这不是公网部署。
