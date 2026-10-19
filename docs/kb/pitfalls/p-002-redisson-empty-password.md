# 无密码 Redis 不应配置空字符串密码

- **类型：** Pitfall
- **日期：** 2026-10-19
- **状态：** Confirmed

## 背景与原因

本机 Redis 容器未启用密码，直接 PING 成功。初次本机配置写入 `password: ''` 后，Redisson 4.7.0 尝试发送 AUTH，Redis 返回“AUTH called without any password configured”，导致后端启动失败。

## 处理与影响

在无密码 Redis 配置中省略 password 字段。移除空字符串配置后，后端成功启动，登录与基础 API 验证通过。未来若为 Redis 设置密码，应再添加实际密码，不应将“空字符串”和“未设置”视为相同状态。
