# Codex 实施 Dockerfile 的要求

先选定并记录 Rust stable 版本，再使用固定的多阶段构建镜像。编译与运行的 libc/链接方式须匹配，避免把 glibc 二进制放进无法运行的极简镜像。最终以非 root 用户运行，显式处理 /data 可写权限，工作目录固定。

不要在交接阶段伪造一个已验证的版本号；必须在 M0/M3 实际构建与启动。COPY Cargo.lock，依赖构建和 release 构建使用 --locked。数据库迁移随二进制打包或完整 COPY；外部配置从环境读取。容器停止优雅处理 SIGTERM。健康检查不要依赖一个最终镜像里不存在的 curl/wget。

不能把 server_schema.sql 简单当成每次启动重建数据库的脚本。必须转换成 SQLx v1 migration 并在启动时执行；就绪检查等迁移成功。健康检查命令、非 root 写权限及持久化重启都需要测试。
