# Git 基线与本地环境组织方式

- **类型：** Decision
- **日期：** 2026-10-19
- **状态：** Confirmed

## 背景

用户已将前后端 Fork 到 CCass 账号，授权先对齐上游并建立 Git 基线，再初始化 Docker MySQL、配置 Redis、启动联调。

## 内容

前后端保持两个独立仓库：

| 仓库 | 位置 | origin | upstream | 上游基线 |
| --- | --- | --- | --- | --- |
| 后端 | 项目根目录 | `https://github.com/CCass/ruoyi-vue-pro.git` | `https://github.com/YunaiV/ruoyi-vue-pro.git` | `master-jdk17`，`7c397bbfae3e768b26e3ee962c5aa7064e8d7c96` |
| 前端 | `yudao-ui/yudao-ui-admin-vue3-master` | `https://github.com/CCass/yudao-ui-admin-vue3.git` | `https://github.com/yudaocode/yudao-ui-admin-vue3.git` | `master`，`050bac1eccfbe7393a1568d614151cc99501b949` |

两个仓库均以 `baseline/2026-10-19-upstream` 标签保留原始上游起点。本地环境脚本、说明及必要的前端导入修复在各自的 `chore/local-bootstrap` 分支中维护，验证后的本地起点以 `baseline/2026-10-19-local` 标签保留。

前端原 Fork 的 master 为 `0af03a93`，本地 master 已向官方 master 快进 74 个可达提交。两个 Fork 均已推送 `chore/local-bootstrap` 分支、`baseline/2026-10-19-upstream` 和 `baseline/2026-10-19-local` 标签，并逐项核对远程 SHA。后端本地基线为 `2abd9df11f8c046346762d3040f09d381a5bfc88`，前端为 `eb5f71a6db64e3dc6902a9503849b2025938eb99`。原标签保持不变，目录迁移说明作为后端后续文档提交维护。Fork 默认分支继续独立管理。

为避免首次全量历史传输长时间无数据，初始获取使用 `--depth=100` 的有限历史。这保留了本次对齐所需的提交，但不是完整历史；需要追溯更早版本时可按需 `git fetch --deepen=100 upstream <对应分支>` 或补全历史。

本机环境遵循：

- 后端忽略整个独立前端目录，防止嵌套仓库被当成后端文件或意外 gitlink 提交。
- 密码放在 `.local/application-my.yaml`，通过 `local,my` profile 和外置配置目录加载，既不提交 Git，也不打入 JAR。
- `.local/` 保存运行日志、PID、截图及迁移结果，全部由 Git 忽略。
- MySQL 使用专用开发库 `ruoyi-vue-pro`，应用账号仅授权该数据库；没有修改其它数据库。
- Redis 使用 8 号逻辑库，没有执行清空操作；当前容器无密码，连接配置中省略 password。
- 上层目录已由 `#Develop` 改为 `1Develop`，前端依赖已从新真实路径完整重建，临时盘符映射已移除；迁移后构建和联调通过，具体原因见路径问题记录。

## 依据

已核对 Fork 和官方远程提交，完成前端 fast-forward，保留检查阶段文档。后端 48 张基础表初始化完成，Redis PING、应用登录和代表性 API 已验证。

## 后续影响

后续业务开发基于已推送的 `chore/local-bootstrap` 分支或其后继分支开展。默认分支合并及 PR 按后续交付安排执行。升级依赖和上游业务代码时需要重新验证，不应仅因版本标签相同而认定兼容。

## 相关记录

- [历史源码检查](../architecture/a-001-framework-baseline.md)
- [本地开发启动与验证](../features/f-001-local-bootstrap.md)
- [Vite 路径问题](../pitfalls/p-001-vite-path-special-character.md)
