# 本地开发启动与验证

- **类型：** Feature
- **日期：** 2026-10-19
- **状态：** Confirmed

## 背景

项目已从压缩包源码恢复为前后端两个 Git 仓库，完成基础开发环境初始化。当前仅启用后端默认的 system、infra 模块。

## 使用入口

| 项目 | 地址或信息 |
| --- | --- |
| 前端 | `http://127.0.0.1/`，端口 80 |
| 后端 | `http://127.0.0.1:48080` |
| 管理接口前缀 | `/admin-api` |
| 接口文档 | `http://127.0.0.1:48080/doc.html` |
| 登录租户 | 芋道源码 |
| 初始管理员 | `admin` / `admin123`（框架种子账号） |
| MySQL | Docker 容器 `mysql`，MySQL 8.0.45，本机端口 3306，库 `ruoyi-vue-pro` |
| 应用数据库账号 | `yudao_local_20261019`，密码在本机私有配置中 |
| Redis | Docker 容器 `redis`，本机端口 6379，逻辑库 8，当前无密码 |

## 构建、启动、停止

以下命令在后端根目录的 PowerShell 中执行。先启动 Docker Desktop，并确保 `mysql`、`redis` 容器正在运行；必要时执行 `docker start mysql redis`。

```powershell
# 构建前后端；后端打包跳过单元测试
.\script\local\Build-Local.ps1

# 启动前后端，后台隐藏窗口运行
.\script\local\Start-Local.ps1

# 停止本项目记录的前后端进程
.\script\local\Stop-Local.ps1
```

可单独指定服务：

```powershell
.\script\local\Start-Local.ps1 -Service Backend
.\script\local\Start-Local.ps1 -Service Frontend
.\script\local\Stop-Local.ps1 -Service Frontend
.\script\local\Build-Local.ps1 -Service Backend
.\script\local\Build-Local.ps1 -Service Frontend -CheckTypes
```

当前工作目录为 `E:\z. WorkSpace\1Develop\NccBaseProject\ruoyi-vue-pro-master-jdk17`。上层目录已由 `#Develop` 改为 `1Develop`，前端从新真实路径构建和运行。本项目的临时盘符和旧映射记录已移除。迁移时发现 pnpm 内部仍残留旧路径链接，因此已将旧 `node_modules` 移至 `.local/frontend-node_modules-before-path-rebuild`，按现有锁文件完整重建；检查 2,819 个依赖链接，均没有指向旧 `#Develop` 或 `Y:`。

首次安装或刷新依赖时（迁移已有项目应先按上段说明移走旧 `node_modules`）：

```powershell
.\script\local\Build-Local.ps1 -Service Frontend -Install
```

这会在当前项目路径执行 `pnpm install --force --frozen-lockfile` 并构建，保持锁文件不变。Vite 开发服务会生成被忽略的全局类型声明，因此全新安装后应先启动一次前端，再执行 `-CheckTypes`。

启动脚本固定后端端口 48080，前端默认 80；前端可以通过 `-FrontendPort 3000` 指定空闲端口。若需要同时改变后端端口，应同时调整后端私有配置、启动脚本的就绪检查及前端 API 地址。

## 本机配置与日志

- `.local/application-my.yaml`：实际 MySQL、Redis 和日志配置；禁止提交。
- `script/local/application-my.example.yaml`：无密码模板；使用新机器时复制到上述本机路径，并填写账号密码或设置模板所需环境变量。
- 后端加载 `local,my`，启动参数包括 `--spring.config.additional-location=optional:file:./.local/`。
- `.local/logs/backend.stdout.log`、`backend.stderr.log`：最近一次后端启动输出。
- `.local/logs/yudao-server.log`：后端应用日志。
- `.local/logs/frontend.stdout.log`、`frontend.stderr.log`：最近一次前端启动输出。
- `.local/*-process.json`：PID、启动时间及项目路径；停止脚本只处理匹配的进程，避免误停其它应用。
- `.local/api-smoke-result.json`：接口验证摘要，不含访问令牌。

## 已验证内容

- 后端默认模块 Maven 打包成功，使用 Java 17.0.2；本次打包使用 `-DskipTests`，未声称运行全部单元测试。
- 本机连接配置不在最终 JAR 中。
- 前端锁定依赖安装、生产构建、全量 `pnpm ts:check` 通过。
- MySQL 初始化 48 张表，管理员与默认租户数据可查询，应用专用账号仅获得项目数据库权限。
- 实际账号登录、租户查询、权限菜单、用户分页和字典接口返回业务成功码 0。
- 管理员接口返回 24 个一级菜单、15 个用户及 1,725 条字典数据（初始化快照，后续数据变化时数量可不同）。
- 浏览器登录成功，首页显示当前账号；用户管理页面载入，搜索 `admin` 后从 15 条缩小到 3 条。
- 启动、停止脚本已实际执行，最终保留前后端运行。迁移到 `1Develop` 后重新完成后端打包、前端生产构建、完整类型检查、启动、登录与代表性 API 验证；前端 HTML 和入口模块均返回 HTTP 200。

本机默认配置未提供 `/actuator/health`，该地址会被统一错误处理返回业务码 404；启动脚本使用实际租户查询接口并检查业务成功码判断后端就绪，避免将单纯 HTTP 200 误判为成功。

前端保留上游的 Vue Router、Element Plus 等弃用提示；这些提示没有阻止本次验证的登录、查询和构建。未启用业务模块的完整功能未在本次逐一测试。

## 本次最小前端修复

上游基线的全量类型检查依赖按需生成的自动导入声明，首次检查存在 `ElMessage`、`ElMessageBox` 和 `ElTree` 未声明问题。8 个 Vue 文件补齐显式导入，目录树引用改用 `TreeInstance` 类型；改动为 9 行新增、1 行删除，没有调整业务流程或接口。

## 相关记录

- [Git 与本地环境组织](../decisions/d-001-git-and-local-environment.md)
- [Vite 路径问题](../pitfalls/p-001-vite-path-special-character.md)
- [Redis 空密码问题](../pitfalls/p-002-redisson-empty-password.md)
