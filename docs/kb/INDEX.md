# 项目知识库

本目录保存已经核实的项目背景、架构、技术决策和开发记录。后续开发先核对相关记录与当前代码是否仍然一致。

## Architecture（架构快照）

| 日期 | 记录 | 说明 |
| --- | --- | --- |
| 2026-10-19 | [框架版本检查与开发导航](architecture/a-001-framework-baseline.md) | 核实前后端源码来源、模块能力、扩展位置和当前环境准备状态 |

## Decisions（技术决策）

| 日期 | 记录 | 说明 |
| --- | --- | --- |
| 2026-10-19 | [Git 与本地环境组织](decisions/d-001-git-and-local-environment.md) | Fork 远程、上游标签、工作分支及本地配置边界 |

## Features（特性记录）

| 日期 | 记录 | 说明 |
| --- | --- | --- |
| 2026-10-19 | [本地开发启动与验证](features/f-001-local-bootstrap.md) | Docker 数据环境、启动构建脚本、登录和接口验证 |

## Pitfalls（踩坑记录）

| 日期 | 记录 | 说明 |
| --- | --- | --- |
| 2026-10-19 | [PowerShell 进程时间记录](pitfalls/p-003-powershell-json-process-time.md) | 避免 JSON 自动日期转换影响重复启动和停止 |
| 2026-10-19 | [Vite 路径问题](pitfalls/p-001-vite-path-special-character.md) | 已改名为 1Develop，完整重建 pnpm 旧绝对链接 |
| 2026-10-19 | [Redis 空密码问题](pitfalls/p-002-redisson-empty-password.md) | 无密码实例应省略 password 字段 |
