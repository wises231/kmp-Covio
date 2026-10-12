# macOS 后台 GUI 自动化验证目录

## 文档状态

| 项目 | 内容 |
| --- | --- |
| 状态 | 尚未执行 |
| 日期 | `2026-10-10` |
| 目标主机 | Apple Silicon Mac，macOS 27.0.1 |
| 问题类别 | macOS 后台 GUI 自动化与虚拟化控制 |
| 目标 UTM | `4.7.5` |
| Case 1 | UTM 与 Archboot aarch64 ISO |
| 主方案 | [macOS 后台 GUI 自动化与虚拟化控制通用方案](../README.md) |
| 证据附录 | [macOS 后台 GUI 自动化证据附录](../evidence.md) |
| 验证记录 | [Case 1：UTM 与 Archboot](case-utm-archboot.md) |

本目录用于保存实际验证资料。
当前验证状态为“尚未执行”。
预检已完成 ISO 下载。
预检已完成 BLAKE2b 校验。
预检尚未完成数字签名验证。
预检尚未创建 UTM VM。
预检尚未安装 Archboot。
预检尚未运行锁屏自动化。

## 0. 案例索引

| 编号 | 案例 | 状态 | 记录 |
| --- | --- | --- | --- |
| Case 1 | UTM 与 Archboot | 尚未执行 | [case-utm-archboot.md](case-utm-archboot.md) |

本文验证通用问题类别。
`Case 1` 验证 UTM 和 Archboot。
后续案例使用同一状态矩阵。
后续案例使用同一接口契约。

## 1. 目标

验证锁屏后后台客户端可以查询桥接状态。
验证锁屏后后台客户端可以创建无界面 VM。
验证锁屏后后台客户端可以启动无界面 VM。
验证锁屏后后台客户端可以截图客机。
验证锁屏后后台客户端可以发送键盘输入。
验证锁屏后后台客户端可以发送鼠标点击。
验证锁屏后 Aqua 桥接可以创建 UTM VM。
验证锁屏后 Aqua 桥接可以启动已有 UTM VM。
验证盒盖状态下的电源策略。
验证注销后的错误处理。
验证清理步骤可逆。

## 2. 范围

### 2.1 范围内

- UTM 4.7.5。
- Archboot aarch64 ISO。
- Apple Silicon 主机。
- Aqua LaunchAgent。
- `VMBridge` 设计验证。
- QEMU、QMP、VNC 和串口。
- 锁屏状态。
- 盒盖状态。
- TCC 缺失状态。
- 注销状态。
- 清理和恢复。

### 2.2 范围外

- Intel Mac。
- Windows 客机。
- macOS 客机。
- 企业 MDM 环境。
- 跨用户控制。
- 公网 VNC。
- 生产发布。
- 应用 UI 改版。
- Covio Helper 协议修改。

## 3. 当前事实

本机已存在 UTM。
UTM 版本为 `4.7.5`。
本机已存在 Archboot ISO。
ISO 路径为 `/Users/wyz/Downloads/archboot-2026.10.08-02.27-7.2.9-1-aarch64-ARCH-aarch64.iso`。
ISO 大小为 469 MiB。
ISO 类型为 ISO 9660。
ISO 卷标为 `ARCHBOOT`。
ISO 标记为 bootable。
ISO 的 BLAKE2b 与清单一致。
清单文件为 `/Users/wyz/Downloads/archboot-b2sum.txt`。
签名文件为 `/Users/wyz/Downloads/archboot-2026.10.08-02.27-7.2.9-1-aarch64-ARCH-aarch64.iso.sig`。
当前环境缺少 `signify-openbsd`。
当前环境尚未验证签名。
当前 GUI 域存在。
当前控制台处于锁屏。
当前 UTM 进程存在。
当前 `utmctl list` 在 5 秒看门狗后超时。
当前 VM 枚举 AppleEvent 在 5 秒看门狗后超时。
当前简单 UTM 版本 AppleEvent 成功。

## 4. 成功标准

### 4.1 文档

所有相对链接有效。
所有命令有结果。
所有失败有错误码。
所有时间有记录。
所有 hash 有记录。
所有清理有记录。
所有结论有证据。

### 4.2 功能

锁屏后 `health` 返回成功。
锁屏后 QEMU VM 可以创建。
锁屏后 QEMU VM 可以启动。
锁屏后 QMP socket 可用。
锁屏后 VNC 可用。
锁屏后客机截图可见。
锁屏后客机按键有效。
锁屏后客机点击有效。
锁屏后 UTM VM 可以创建。
锁屏后 UTM VM 可以启动。
注销后返回 `gui_session_unavailable`。
权限缺失后返回 `tcc_missing`。
任务结束后清理完成。
任务结束后电源设置恢复。

## 5. 前置条件

1. 备份重要数据。
2. 确认有 10 GiB 以上空余磁盘。
3. 确认主机接通 AC 电源。
4. 确认 ISO 哈希正确。
5. 确认 UTM 版本。
6. 确认 UTM 路径。
7. 确认 `utmctl` 路径。
8. 解锁 macOS。
9. 登录 Aqua 会话。
10. 批准 Automation 权限。
11. 批准所需 Accessibility 权限。
12. 确认 LaunchAgent 已加载。
13. 确认 `VMBridge` 已启动。
14. 记录 `SleepDisabled` 原值。
15. 记录当前电源状态。

**警告：** 测试前备份 VM 和安装介质。错误删除会丢失数据。

## 6. 风险

VNC 若绑定公网会暴露客机画面。
VNC 必须绑定 `127.0.0.1`。
QMP 若暴露会控制客机。
QMP 必须使用 Unix socket。
`pmset -a disablesleep 1` 会全局禁止睡眠。
此命令必须恢复原值。
盒盖测试会消耗电池。
注销会结束 Aqua 桥接。
TCC 授权会留下系统记录。
测试 VM 会占用磁盘。

## 7. 测试矩阵

| 编号 | 场景 | 当前状态 | 结果文件 |
| --- | --- | --- | --- |
| V01 | 解锁状态健康检查 | 待执行 | `case-utm-archboot.md` |
| V02 | 锁屏状态健康检查 | 待执行 | `case-utm-archboot.md` |
| V03 | 锁屏状态创建 UTM VM | 待执行 | `case-utm-archboot.md` |
| V04 | 锁屏状态启动 UTM VM | 待执行 | `case-utm-archboot.md` |
| V05 | 锁屏状态创建 QEMU VM | 待执行 | `case-utm-archboot.md` |
| V06 | 锁屏状态启动 QEMU VM | 待执行 | `case-utm-archboot.md` |
| V07 | 锁屏状态 QMP 查询 | 待执行 | `case-utm-archboot.md` |
| V08 | 锁屏状态 VNC 截图 | 待执行 | `case-utm-archboot.md` |
| V09 | 锁屏状态 VNC 按键 | 待执行 | `case-utm-archboot.md` |
| V10 | 锁屏状态 VNC 点击 | 待执行 | `case-utm-archboot.md` |
| V11 | TCC 缺失 | 待执行 | `case-utm-archboot.md` |
| V12 | 注销状态 | 待执行 | `case-utm-archboot.md` |
| V13 | 盒盖 AC 模式 | 待执行 | `case-utm-archboot.md` |
| V14 | 盒盖电池模式 | 待执行 | `case-utm-archboot.md` |
| V15 | 清理和恢复 | 待执行 | `case-utm-archboot.md` |

## 8. 证据要求

每次测试记录开始时间。
每次测试记录结束时间。
每次测试记录当前会话。
每次测试记录锁屏状态。
每次测试记录电源状态。
每次测试记录命令。
每次测试记录退出码。
每次测试记录错误码。
每次测试记录截图路径。
每次测试记录 QMP 响应。
每次测试记录 VNC 响应。
每次测试记录清理结果。

## 9. 清理步骤

1. 停止测试 VM。
2. 删除测试 UTM VM。
3. 删除测试 QEMU VM。
4. 删除测试 VNC 端口。
5. 删除测试 QMP socket。
6. 删除桥接测试 socket。
7. 卸载测试 LaunchAgent。
8. 恢复 `SleepDisabled` 原值。
9. 卸载临时 QEMU 包。
10. 保留脱敏日志。
11. 更新验证记录。
12. 确认主文和证据附录已引用结果。

## 10. 关联文档

- [主方案](../README.md)
- [证据附录](../evidence.md)
- [Case 1：UTM 与 Archboot 验证记录](case-utm-archboot.md)
