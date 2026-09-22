# 实施决定与边界

- 保持交接 OpenAPI 和产品统计口径不变。没有新增产品功能。
- Flutter 使用 Riverpod + Drift/SQLite；页面用原生 Navigator 管理少量 push/pop，未引入额外路由框架。Drift NativeDatabase.createInBackground 提供后台 isolate，无需再叠加 drift_flutter。时间、ID、安全存储和网络均可替换供测试。
- schema dump 命令暴露 drift 2.34.4 / drift_dev 2.34.0 的上游预览 API 不匹配。将两个包固定为实际解析通过的 2.34.0，重新生成并导出 v1 schema；没有改动包缓存或屏蔽编译错误。
- Rust serde 的整数解码拒绝浮点/科学计数/字符串；serde_json 默认有序对象递归产生规范化哈希。单 SQLx 连接把鉴权、实体写、receipt、seq、删除及快照事务串行化。
- snapshot 在同一事务中检查实体数量并读取，超过 100,000 条返回503。它只是诊断接口，不作为手机自动恢复入口。
- iOS Debug 专用 Info-Debug.plist 才包含 ATS 开发例外。Android 主 manifest 禁止 HTTP，Debug manifest 显式覆盖；Release 客户端也校验 HTTPS。Android 禁止自动备份，避免数据库/安全凭据脱配后静默上传。
- 图片只用于独立 SVG 图标和平台应用图标。无整页 PNG 背景；所有输入、计数、图表、提示和列表均为 Flutter 控件。
- 残留 Keychain 或身份不匹配会阻断上传，保留本地资料。若已尝试注册的数据库与现有凭据不匹配，不能声称已删除无法认证的旧 namespace，删除保留为待处理。
- Docker 基础镜像固定版本；当前机器到 Docker Hub 的网络超时使容器验证阻塞。本机 Rust、移动端联调和独立备份恢复不依赖 Docker。

- 提交前审查新增本地SQLite v2迁移：app_meta.last_sync_error_status用于跨重启保留401/410/409/422等永久错误阻塞。与outbox失败信息在同一事务保存，人工重试或成功ACK才清除。v1快照保留，v2只增加可空列；项目、Entry、身份、seq和原始outbox正文均不重写。contracts/local_schema.sql与Drift声明同步更新，服务端/OpenAPI/导出格式不变。
- HTTP总期限使用Dio CancelToken取消传输，禁止用只结束等待而不取消请求的Future.timeout释放发送锁。统计筛选在原项目不存在时回到总体，并重建对应FormField状态，覆盖删除全部数据后的隐藏统计页。
