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
