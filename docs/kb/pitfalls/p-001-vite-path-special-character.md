# Vite 在含井号的 Windows 路径中构建失败

- **类型：** Pitfall
- **日期：** 2026-10-19
- **状态：** Confirmed

## 背景

本项目最初位于 `E:/z. WorkSpace/#Develop/` 下。锁定依赖安装成功后，Vite 8.1.4 首次构建报告项目根目录含 `#`，随后出现 HTML proxy 和 Sass 导入错误。

## 原因与验证

`#` 被部分路径处理当作片段标识，错误中的 Sass 根路径被截断成 `E:/z. WorkSpace`。单独把前端映射为盘符根目录虽然减少了错误，但旧 pnpm 依赖 junction 仍指向原始的含 `#` 路径，BPMN 字体资源因此继续发生读取目录错误；UnoCSS 在盘符根目录发现配置也出现问题。

## 临时处理（历史记录）

1. 将后端项目根目录映射为专用盘符，保持前端位于该盘符下的子目录。
2. 从映射后的前端目录重建 pnpm 依赖链接，确认依赖实际解析路径也不再包含 `#`。
3. 同样通过映射目录构建和启动前端。

当时由 `script/local/Common-Local.ps1` 管理映射，`Build-Local.ps1`、`Start-Local.ps1` 统一使用该路径。源码没有移动，框架 Vite 配置与依赖版本未因此修改。修复后生产构建通过。

## 后续影响

不要在原始含 `#` 路径中重新安装 pnpm 依赖后直接构建。若映射盘符改变，需重新建立依赖链接。未来新建项目时可直接选择不含 `#`、`?` 的路径，减少此类工具兼容问题。

## 最终处理：改名为 1Develop

用户授权将上层目录 `#Develop` 改为 `1Develop`。Windows 最初因当前 Codex/ChatGPT 会话持有目录句柄而拒绝改名；退出应用释放句柄后，目录改名成功。

改名后 `pnpm install --force` 仅刷新了部分链接，`.pnpm/node_modules/@vue/shared` 仍指向旧 `#Develop`，生产构建因此报告无法解析 `@vue/shared`。将整个旧 `node_modules` 移至本项目 `.local/frontend-node_modules-before-path-rebuild`，再在新路径执行 `pnpm install --frozen-lockfile --store-dir <项目根目录>/.pnpm-store` 后解决；锁文件和依赖版本均未变更。已检查 2,819 个依赖链接，均未再指向旧目录或 `Y:`。

现在前端直接从 `E:/z. WorkSpace/1Develop/NccBaseProject/ruoyi-vue-pro-master-jdk17/yudao-ui/yudao-ui-admin-vue3-master` 构建和运行，已移除临时盘符映射及旧记录。后端 Maven 打包、前端生产构建、全量类型检查、前后端启动、账号登录和代表性 API 均重新验证通过。后端打包使用 `-DskipTests`，未运行全部后端单元测试。

本机验证摘要见 `.local/native-path-api-smoke-result.json`；迁移及推送结果见 `.local/path-migration-result.json`。这些文件只保存在本机，不含访问令牌。
