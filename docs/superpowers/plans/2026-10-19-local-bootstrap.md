# 前后端 Git 基线与本地环境启动计划

> 执行方式：在当前会话按顺序完成并逐项验证。当前目录尚无 Git 仓库，本次是在用户指定目录恢复上游历史和建立本地环境，不额外创建工作树或开展业务功能开发。

**目标：** 使用用户的前后端 Fork，后端保持 master-jdk17，前端对齐官方 master，初始化 Docker MySQL、配置 Redis，验证前后端登录与基础接口。

**架构：** 后端与嵌套前端保持两个独立 Git 仓库，origin 指向 CCass 的 Fork，upstream 指向官方仓库。连接密码保存在 Git 忽略的本地配置，运行日志与进程记录保存在 `.local/`。

**技术栈：** Java 17、Maven、Spring Boot 3.5、Vue 3、Vite、pnpm、Docker Desktop、MySQL 8、Redis。

## 文件与目录职责

- 后端 `.git/`：恢复 Fork 的 master-jdk17 历史，设置两个远程。
- 前端 `yudao-ui/yudao-ui-admin-vue3-master/.git/`：恢复 Fork 历史并快进到官方 master。
- 后端 `.gitignore`：忽略独立前端目录和 `.local/`，防止嵌套仓库及本机数据被提交。
- `.local/application-my.yaml`：本机专用数据库、Redis 配置，由 Git 忽略并从外部加载，避免连接密码进入 JAR。
- `script/local/`：保存可重复使用的本地启动和停止脚本；脚本不包含密码。
- `docs/kb/decisions/`：记录已确定的 Git 基线与环境组织方式。
- `docs/kb/features/`：记录启动方法、验证结果和维护说明。

## 任务 1：对齐与固定 Git 基线

- [x] 检查本地源码是否仍与上次检查的原始快照一致，保留已有 docs。
- [x] 后端初始化 Git，添加 origin=CCass/ruoyi-vue-pro、upstream=YunaiV/ruoyi-vue-pro，获取并设置 master-jdk17 基线。
- [x] 恢复上游原本跟踪的前端说明与示例文件；独立前端保留原路径。
- [x] 前端初始化 Git，添加 origin=CCass/yudao-ui-admin-vue3、upstream=yudaocode/yudao-ui-admin-vue3，获取 master 并对齐官方最新提交。
- [x] 为本地配置工作建立分支，分别记录源码起点提交；检查 `git status` 和远程地址。

验证：`git log -1`、`git remote -v`、`git status --short --branch`；前端源码与官方 master 一致，后端业务源码无额外变化。

## 任务 2：检查 Docker 并初始化专用开发数据

- [x] 读取容器版本、端口和认证状态，避免在输出中显示密码。
- [x] 检查 `ruoyi-vue-pro` 是否存在及其表数量；仅对空库导入主初始化 SQL。
- [x] 使用 `sql/mysql/ruoyi-vue-pro.sql` 初始化专用开发库，核对系统用户、菜单和租户表。
- [x] 为应用配置可用的数据库账号，检查 Redis 逻辑库使用情况，选择专用逻辑库，不清空现有 Redis 数据。
- [x] 写入被忽略的 `.local/application-my.yaml`，启动使用 `local,my` 两个 profile，并通过 `spring.config.additional-location` 加载外置配置。

验证：MySQL 查询库表和基础种子数据；Redis PING；确认私有配置由 Git 忽略。

## 任务 3：依赖与构建

- [x] 使用当前 Java 17 和 Maven 构建默认启用模块：`mvn -pl yudao-server -am package -DskipTests`。
- [x] 在前端目录执行 `pnpm install --frozen-lockfile`，保持锁文件不变。
- [x] 执行前端构建与适用的类型检查；若上游基线存在问题，先定位原因，再决定最小修复并记录。

验证：后端可运行 JAR 生成，前端生产构建完成；记录所有检查的实际结果。

## 任务 4：启动和功能联调

- [x] 创建本地启动、停止脚本，保存日志与 PID，不把密码写入命令行或提交内容。
- [x] 启动后端 JAR：`java -jar yudao-server/target/yudao-server.jar --spring.profiles.active=local,my --spring.config.additional-location=optional:file:./.local/`。
- [x] 启动前端：`pnpm dev`，确认本机页面和 API 地址。
- [x] 验证后端就绪、租户查询、账号登录、权限菜单、用户分页、字典等代表性接口。
- [x] 在浏览器打开前端，检查登录与首页，检查关键接口及控制台错误。

验证：页面能够登录并显示菜单，代表性接口返回成功，端口与进程对应本项目。

## 任务 5：提交与交付

- [x] 更新知识库索引和当前基线、环境说明，区分历史检查与本次实际结果。
- [x] 检查提交范围，确认连接密码、日志、依赖目录、运行产物未被跟踪。
- [x] 创建本地基线提交，保留 origin/upstream 和源码起点；报告是否已推送。
- [x] 交付前端地址、接口文档地址、启动停止命令及已验证事项。

本计划不包含新业务功能，也不修改已有其它数据库或清空 Redis 数据。
