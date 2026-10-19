# 项目协作说明

- 默认使用中文沟通、编写项目文档和新增注释。
- 开始工作先读 `docs/kb/INDEX.md`，按需求查阅对应记录；当前环境用法见 `docs/kb/features/f-001-local-bootstrap.md`。
- 当前目录是后端独立仓库，基于官方 `master-jdk17`；前端独立仓库在 `yudao-ui/yudao-ui-admin-vue3-master`，基于官方 `master`。两个仓库各有 origin（CCass Fork）和 upstream（官方）。
- 独立前端目录由后端 Git 忽略；分别检查、提交两个仓库，避免把嵌套仓库加入后端提交。
- `.local/` 保存实际连接密码、日志、运行状态和截图，禁止加入 Git；连接配置从外部加载，不应打入 JAR。
- 当前目录含 `#`，前端构建和启动使用 `script/local/` 脚本提供的映射路径；不要在原始路径重建依赖链接。
- 新业务按需求放入对应的 `yudao-module-*`；复用权限、租户、数据权限、日志、统一返回与前端请求封装，具体导航见架构记录。
