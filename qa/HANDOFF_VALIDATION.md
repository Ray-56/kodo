# 本次交接包校验记录

日期：2026-09-11。范围：本次生成的文档、接口契约、SQL 蓝本、样例和 UI 源素材。**不代表尚未实现的 Flutter/Rust 产品通过验收。**

## 实际执行

```text
python3 scripts/validate_handoff.py
PASS: 155 handoff checks. No Flutter/Rust runtime claim.
```

机器结果见 validation_results.json。155 是脚本检查断言数量，包含逐文件 SVG 与资源哈希检查；不是 155 个手机功能测试。

| 检查 | 实际结果 |
| --- | --- |
| OpenAPI JSON 本地引用 | 全部解析；6 个路径 |
| OpenAPI YAML / JSON 等价性 | 已比对，内容一致 |
| JSON Schema 与固定样例 | 两份 schema 可解析，所有操作及导出 fixture 匹配 |
| 非法数量与额外字段 | 指定边界/浮点/字符串/布尔与额外字段被拒绝 |
| 日期 / UTC / 捕获偏移 | 所有 fixture 日期匹配 |
| 统计 | 俯卧撑今日 42、累计 143；今日 6 次有效记录；7 日 13 次；缺失日补零 |
| 本地 SQL 事务 | 注入异常后 Entry、outbox、序号均回滚；这是 Python SQLite 检查，不是 Drift 集成测试 |
| 服务 SQL 防线 | 复合外键隔离、单位锁定、记录不可改、删除不可逆、seq/op_id 唯一约束通过 |
| SVG | 22 个独立线性图标及 5 个品牌 SVG 均可解析，无外链图片/脚本/字体 |
| 资源清单 | 50 个设计文件 SHA-256 与内容一致 |
| 应用图标 | 1024/512/192/180 四尺寸均为不透明 RGB；Android 前景 RGBA |
| UI 静态布局 | HTML 已渲染六屏 PNG（各 780×1690，含边框），逐屏查看；非 Flutter 截图 |
| 正文色值对比度 | 四组实际 token 配色通过 4.5:1 基线；不代表完整无障碍认证 |
| 实现手册 | DOCX 转 PDF 为 20 页；逐页查看排版，最后一次修正仅改变第 4 页并复核 |
| 脚本 | 两份 Python 源码可解析；真实 API 脚本未执行网络验收 |
| 随包字体 | 无 .ttf/.otf/.ttc/.woff/.woff2；DOCX 未附带嵌入字体文件 |
| 包内入口链接 | 已检查 README 等 Markdown 相对链接所指文件存在 |

检查环境：Python 3.13.5，SQLite 3.46.1；jsonschema 版本记录在 scripts/requirements-validation.txt。SQLite 内存库用于蓝本校验，不代表已验证服务端 WAL、进程重启、SQLx 迁移或持久卷。

未另行安装完整 OpenAPI 元规范校验器；已执行的是结构路径/引用检查、YAML/JSON 比对和所附 JSON Schema 校验，不能把这一结果当作所有客户端生成器均已兼容。

## 尚未执行，必须由后续实现补齐

Flutter / Dart / Rust SDK 不在本次文档生成环境中。未编译 App 或 Rust 服务，未启动真实 API，未执行 iOS/Android 模拟器、真机、性能、HTTPS 发布构建和服务端备份恢复验收。scripts/smoke_api.py 是实现后对真实服务运行的工具，当前没有通过的实际 API 测试报告。

产品 P01–P25 与协议 S01–S25 合计 50 项仍全部属于**待实施、待测试**。复制 IMPLEMENTATION_REPORT.template.md 后填写真实证据；不能用本文件的 155 项文档/素材校验替代它们。

源素材和 HTML 可以立即使用；scaffolding 只提供接入范式，没有 Cargo.toml、pubspec.yaml 或已完成业务代码。名称/商标、正式上架、安全审计和法律许可也不属于本次校验结果。
