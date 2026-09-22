# 运行证据

原始命令、结果和未完成项见 [验收报告](IMPLEMENTATION_REPORT.md) 与 [阶段记录](MILESTONES.md)。这些图片来自运行中的 Flutter，没有使用设计PNG替代运行证据。

## M0：原生空态

基础界面截图在M1测试时采集；后端基础阶段无GUI，见 [health返回](evidence/m0-live.json)。

![真实iOS空态](evidence/m1-empty.png)

## M1：同一安装强制终止，再启动仍为10

[重启命令与断言](evidence/m1-ios-same-install.log) · [数据库结果](evidence/m1-same-install-database.json)

![同安装重启后10个](evidence/m1-same-install-restart.png)

## M2：详情与统计

![iOS详情](evidence/m2-ios-detail-30.png)

![Android统计](evidence/m2-android-stats.png)

## M3：真实Rust API

这是无GUI服务阶段，不制造界面截图。实际HTTP结果：[28项smoke报告](evidence/m3-smoke.json)；数据库/协议：[7组Rust集成测试](evidence/final-cargo-test.log)。下一个阶段截图对应手机与此服务联调后的状态。

## M4：许可、同步与删除

![上传许可](evidence/m4-ios-consent.png)

![真实服务已更新](evidence/m4-ios-synced.png)

![删除完成](evidence/m4-android-deleted.png)

## M5：尺寸与字号

这些是实际Flutter Widget渲染，测试时读取本机系统字体；字体没有打包或分发。截图为候选基线，未宣称已经人工批准为像素golden。

![390宽100%字号](evidence/m5-layout-home-390-100.png)

![360宽200%字号](evidence/m5-layout-stats-360-200.png)

[真实iOS完整流程短录屏](evidence/m5-ios-flow-short.mp4)

## M6：构建与恢复

该阶段以构建日志和机器结果验收，无独立产品页面。

[Android APK构建](evidence/m6-android-build.log) · [iOS未签名构建](evidence/m6-ios-build.log) · [备份恢复结果](evidence/m6-backup-report.json) · [Docker网络阻塞](evidence/m6-docker-build.log)

真机、人工读屏、profile性能、系统分享最终落盘和图标蒙版仍未验收，详见报告。

## Android 真机 · 2026-09-21

详见 [真机补验与性能方法](PHYSICAL_DEVICE_REPORT.md)。下列均为小米Android16运行画面。

![真机累计30](evidence/physical-2026-09-21/m2-android-home-30.png)

![真机授权与同步](evidence/physical-2026-09-21/m4-android-synced.png)

![同安装强停后仍为10](evidence/physical-2026-09-21/local-sync/local-sync-same-install-restart.png)

![服务端删除后强停再启动已清空](evidence/physical-2026-09-21/deletion/deletion-same-install-restart.png)

![Profile100项目/1万记录同安装重启](evidence/physical-2026-09-21/profile/performance-same-install-restart.png)
