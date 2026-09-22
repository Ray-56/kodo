# 给 Codex 的开工指令

将本文件以下内容连同整个交接包放进代码仓库上下文。不要只传 PDF，contracts、design/assets 与 examples 是实施所需的机器文件。

---

你需要根据本交接包实现 Kodo（行一）0.1.0：Flutter 手机端 + Rust 服务端。

首先读取 AGENTS.md、HANDOFF.md、design/README.md、contracts/openapi.yaml，以及 examples 中的黄金数据与期望结果。旧 PNG 中有超出 MVP 的功能，以书面冻结范围为准。不要再写一遍泛泛的产品方案，请完成工程实现。

先检查当前仓库和本机工具链，记录真实版本及缺失环境。没有现成工程就建立 apps/mobile 和 services/api。按 docs/04_delivery.md 的 M0 到 M6 分阶段实现，不在 M0 为未来功能搭建多余框架。

第一条纵向闭环是：创建「俯卧撑」（单位个、快捷量10）→首页记录10→本地持久化→重启仍保留。接着做历史撤销、统计、Rust API和离线队列。最终必须在真实 Rust 服务上执行 scripts/smoke_api.py，不能用一个 MockRepository 代替完成后端联调。

必须实现本地事务内 Entry+Outbox 原子写入、单发送者 FIFO、严格 seq、op_id 幂等、防重复计数、单安装身份隔离、上传许可、JSON 导出、删除恢复阶段与错误状态。正文中定义的日期与统计口径不可更改。服务端是单设备镜像，不得宣称本期支持换机恢复。

页面按 design/implementation 的 MVP 布局和 design/tokens.json 实施，使用独立 SVG 素材，所有按钮、输入和图表是 Flutter 原生控件；不能使用整页图片铺底。简体中文，浅色，两个主入口，无分类、目标、Notes和账号页。

每个里程碑完成后提供：已完成项、修改文件、实际执行命令和结果、截图、未完成/阻塞项。无法执行某项测试时明说原因，不能写“全部通过”。交付时生成 qa/IMPLEMENTATION_REPORT.md，逐项填写 P01–P25、S01–S25 与设备验收；同时提交锁文件、迁移、README、Dockerfile、compose 和可复现命令。

现在从 M0 开始检查环境与仓库，然后实现。

---

本包当前交付的是设计/契约/资源/验收计划，不包含已经完成的 Flutter 或 Rust 产品代码。scaffolding 是接入样例，不能用它的存在代替功能验收。
