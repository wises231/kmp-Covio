# Case 1：UTM 与 Archboot 验证记录

## 验证状态

| 项目 | 内容 |
| --- | --- |
| 状态 | 尚未执行 |
| 计划日期 | `2026-10-10` |
| 执行人 | 待填写 |
| 复核人 | 待填写 |
| 主机 | Apple Silicon Mac |
| macOS | `27.0.1` |
| 构建 | `26A434` |
| UTM | `4.7.5` |
| 主方案 | [macOS 后台 GUI 自动化与虚拟化控制通用方案](../README.md) |
| 证据附录 | [macOS 后台 GUI 自动化证据附录](../evidence.md) |
| 目录说明 | [后台 GUI 自动化验证目录](README.md) |

本文记录 `Case 1` 的实际执行结果。
当前结果为空。
当前没有创建 UTM VM。
当前没有安装 Archboot。
当前没有运行桥接。
当前没有执行锁屏自动化。
当前没有执行盒盖测试。

## 1. 验证目标

验证锁屏下创建 UTM VM。
验证锁屏下启动 UTM VM。
验证锁屏下创建 QEMU VM。
验证锁屏下启动 QEMU VM。
验证锁屏下使用 QMP。
验证锁屏下使用 VNC。
验证锁屏下截图客机。
验证锁屏下发送键盘输入。
验证锁屏下发送鼠标输入。
验证 TCC 缺失错误。
验证注销错误。
验证盒盖电源策略。
验证清理步骤。

## 2. 预检记录

### 2.1 主机

| 项目 | 值 | 状态 |
| --- | --- | --- |
| 架构 | `arm64` | 已记录 |
| 硬件模型 | `MacBookPro18,2` | 已记录 |
| macOS | `27.0.1` | 已记录 |
| 构建 | `26A434` | 已记录 |
| 当前用户 | `wyz` | 已记录 |
| 用户 ID | `501` | 已记录 |
| 当前控制台 | `wyz` | 已记录 |
| 当前锁屏 | `Yes` | 已记录 |
| 当前会话类型 | `Background` | 已记录 |
| 当前 GUI 域 | `gui/501`，`Aqua` | 已记录 |

### 2.2 UTM

| 项目 | 值 | 状态 |
| --- | --- | --- |
| App | `/Applications/UTM.app` | 已存在 |
| 版本 | `4.7.5` | 已记录 |
| `utmctl` | `/Applications/UTM.app/Contents/MacOS/utmctl` | 已存在 |
| 源码 commit | `7eadb056ae0f91d979059544d0ddcd2d5a40be92` | 已记录 |
| `utmctl list` | 5 秒超时 | 已记录 |
| `utmctl version` | 5 秒超时 | 已记录 |
| 简单 AppleEvent | 返回 `4.7.5` | 已记录 |
| VM 枚举 AppleEvent | 5 秒超时 | 已记录 |

### 2.3 Archboot ISO

| 项目 | 值 | 状态 |
| --- | --- | --- |
| 路径 | `/Users/wyz/Downloads/archboot-2026.10.08-02.27-7.2.9-1-aarch64-ARCH-aarch64.iso` | 已存在 |
| 大小 | `469M` | 已记录 |
| 类型 | ISO 9660 | 已记录 |
| 卷标 | `ARCHBOOT` | 已记录 |
| 启动标记 | bootable | 已记录 |
| SHA-256 | `784d5290b9f34a82f6b10a1e1f8c638b1e768bde50071bab18b4c186e8321b1c` | 已计算 |
| BLAKE2b | `64dfed8faef876d815c7b049d93663cacfc97209953aca5a3d5f5b1f8e178dce388220b193192b704e8bfdd434b36cb98702671b275b227f4f7b769667f7c1c7` | 已匹配 |
| 清单 | `/Users/wyz/Downloads/archboot-b2sum.txt` | 已存在 |
| 签名 | `/Users/wyz/Downloads/archboot-2026.10.08-02.27-7.2.9-1-aarch64-ARCH-aarch64.iso.sig` | 已存在 |
| 签名验证 | 缺少 `signify-openbsd` | 未完成 |

预检结论：ISO 可用于后续 VM 测试。
预检结论：数字签名仍待验证。
预检结论：VM 尚未创建。

## 3. 测试前采集

### 3.1 会话

```sh
launchctl print user/501
launchctl print gui/501
```

记录字段：

```text
User session:
GUI session:
Aqua domain present:
Bridge loaded:
Bridge PID:
```

### 3.2 锁屏

```sh
ioreg -n Root -d1 -r | rg 'IOConsoleLocked|CGSSessionScreenIsLocked|kCGSSessionUserIDKey'
```

记录字段：

```text
IOConsoleLocked:
CGSSessionScreenIsLocked:
Session user ID:
```

### 3.3 电源

```sh
pmset -g assertions
pmset -g batt
pmset -g | rg 'SleepDisabled|hibernatemode'
```

记录字段：

```text
AC or battery:
Battery percent:
PreventUserIdleSystemSleep:
PreventUserIdleDisplaySleep:
SleepDisabled before:
hibernatemode before:
```

### 3.4 TCC

检查 Automation。
检查 Accessibility。
检查 Screen Recording。
记录授权状态。
记录授权时间。
记录授权应用。
不要在文档中写入 TCC 数据库路径内容。

### 3.5 桥接

```sh
printf '%s\n' '{"request_id":"preflight-1","op":"health","args":{}}' | nc -U "$HOME/Library/Application Support/VMBridge/control.sock"
```

记录字段：

```text
Socket path:
Socket mode:
Health response:
Aqua status:
TCC status:
UTM status:
QEMU status:
```

## 4. UTM 验证步骤

### V03：锁屏状态创建 UTM VM

前置：Aqua 桥接已加载。
前置：Automation 已授权。
前置：UTM 已运行。
前置：屏幕已锁定。

请求：

```json
{"request_id":"utm-create-1","op":"utm.create","args":{"name":"Archboot-Validation","architecture":"aarch64","memory_mib":4096,"disk_gib":64}}
```

记录：

```text
Start time:
End time:
Response:
Error code:
UTM VM path:
Config path:
Disk path:
Result: PENDING
```

通过条件：返回 UTM VM ID。
通过条件：`.utm` 目录存在。
通过条件：`config.plist` 存在。
通过条件：`Data` 目录存在。

### V04：锁屏状态启动 UTM VM

前置：V03 通过。

请求：

```json
{"request_id":"utm-start-1","op":"utm.start","args":{"vm_id":"<utm-vm-id>","headless":true}}
```

记录：

```text
Start time:
End time:
Response:
Error code:
VM state:
Console type:
Result: PENDING
```

通过条件：VM 进入运行状态。
通过条件：后台客户端收到接受响应。
通过条件：UTM 没有阻塞。

## 5. Archboot 安装验证步骤

### 5.1 挂载 ISO

1. 确认 ISO 哈希。
2. 打开 VM 配置。
3. 添加 ISO 为只读光驱。
4. 设置启动顺序。
5. 保存配置。

记录：

```text
ISO path:
ISO hash:
Read-only:
Boot order:
Result: PENDING
```

### 5.2 启动安装

1. 启动 VM。
2. 连接 VNC。
3. 截图启动画面。
4. 确认进入 Archboot。
5. 记录架构。
6. 记录内核版本。
7. 记录启动时间。

记录：

```text
VNC address:
Screenshot path:
Architecture:
Kernel:
Boot result: PENDING
```

### 5.3 客机输入

1. 发送方向键。
2. 截图确认菜单变化。
3. 发送回车。
4. 截图确认选择变化。
5. 发送文本。
6. 截图确认文本变化。

记录：

```text
Key request:
Key response:
Click request:
Click response:
Screenshot before:
Screenshot after:
Input result: PENDING
```

### 5.4 停止安装

1. 发送关机请求。
2. 等待 QMP 状态。
3. 超时后按策略结束进程。
4. 记录退出码。
5. 保留串口日志。

记录：

```text
Stop request:
Stop mode:
QMP final state:
Exit code:
Serial log:
Stop result: PENDING
```

## 6. QEMU 无界面验证步骤

### V05：创建 QEMU VM

前置：`qemu-system-aarch64` 已安装。
前置：UEFI 固件路径已确认。
前置：屏幕已锁定。

请求：

```json
{"request_id":"vm-create-1","op":"vm.create","args":{"provider":"qemu","name":"archboot-qemu","iso":"/Users/wyz/Downloads/archboot-2026.10.08-02.27-7.2.9-1-aarch64-ARCH-aarch64.iso","disk_gib":64,"memory_mib":4096,"cpu_count":4}}
```

记录：

```text
QEMU version:
Firmware path:
VM directory:
Disk path:
Metadata path:
Response:
Result: PENDING
```

### V06：启动 QEMU VM

请求：

```json
{"request_id":"vm-start-1","op":"vm.start","args":{"provider":"qemu","vm_id":"archboot-qemu","vnc":"127.0.0.1:5900"}}
```

记录：

```text
Start time:
PID:
QMP socket:
VNC address:
Serial log:
Response:
Result: PENDING
```

通过条件：QMP socket 存在。
通过条件：VNC 端口只绑定 `127.0.0.1`。
通过条件：串口日志有新内容。

### V07：QMP 查询

```sh
printf '%s\r\n' '{"execute":"qmp_capabilities"}' '{"execute":"query-status"}' | nc -U "$HOME/VMs/archboot-qemu/qmp.sock"
```

记录：

```text
QMP response:
VM status:
Error:
Result: PENDING
```

### V08：VNC 截图

命令示例保留为待填写。
截图必须来自客机。
截图必须包含 Archboot 画面。
截图文件不进入公开仓库。

记录：

```text
VNC client:
Capture time:
Image path:
Image hash:
Visual result:
Result: PENDING
```

### V09：VNC 按键

记录：

```text
Key sequence:
Before screenshot:
After screenshot:
Response:
Result: PENDING
```

### V10：VNC 点击

记录：

```text
Click coordinates:
Button:
Before screenshot:
After screenshot:
Response:
Result: PENDING
```

## 7. 错误路径验证

### V11：TCC 缺失

1. 移除测试 Automation 授权。
2. 保持锁屏。
3. 发送 `utm.create`。
4. 记录返回。
5. 恢复授权。

预期：返回 `tcc_missing`。

记录：

```text
Authorization before:
Authorization after:
Response:
Result: PENDING
```

### V12：注销状态

1. 注销用户。
2. 从登录窗口运行后台客户端。
3. 发送 `health`。
4. 记录返回。
5. 重新登录。

预期：返回 `gui_session_unavailable`。

记录：

```text
Login window state:
Response:
Result: PENDING
```

## 8. 盒盖验证

### V13：AC 模式

1. 接通 AC 电源。
2. 启动 QEMU VM。
3. 关闭盒盖。
4. 等待 5 分钟。
5. 从远端检查 QMP。
6. 打开盒盖。
7. 记录状态。

预期：VM 保持运行。
预期：SSH 或 QMP 可访问。

记录：

```text
Power source:
SleepDisabled:
Assertions:
Lid state:
VM status:
Result: PENDING
```

### V14：电池模式

1. 断开 AC 电源。
2. 记录电池容量。
3. 启动 QEMU VM。
4. 关闭盒盖。
5. 等待 5 分钟。
6. 检查 QMP。
7. 打开盒盖。
8. 记录电池容量。

预期：行为符合选定策略。
预期：电池下降有数据。

记录：

```text
Battery before:
Battery after:
Lid state:
VM status:
Result: PENDING
```

## 9. 结果汇总

| 编号 | 结果 | 证据 | 备注 |
| --- | --- | --- | --- |
| V01 | PENDING | 待填写 | 解锁状态健康检查 |
| V02 | PENDING | 待填写 | 锁屏状态健康检查 |
| V03 | PENDING | 待填写 | 锁屏状态创建 UTM VM |
| V04 | PENDING | 待填写 | 锁屏状态启动 UTM VM |
| V05 | PENDING | 待填写 | 锁屏状态创建 QEMU VM |
| V06 | PENDING | 待填写 | 锁屏状态启动 QEMU VM |
| V07 | PENDING | 待填写 | QMP 查询 |
| V08 | PENDING | 待填写 | VNC 截图 |
| V09 | PENDING | 待填写 | VNC 按键 |
| V10 | PENDING | 待填写 | VNC 点击 |
| V11 | PENDING | 待填写 | TCC 缺失 |
| V12 | PENDING | 待填写 | 注销状态 |
| V13 | PENDING | 待填写 | 盒盖 AC |
| V14 | PENDING | 待填写 | 盒盖电池 |
| V15 | PENDING | 待填写 | 清理和恢复 |

## 10. 清理记录

| 项目 | 原值或路径 | 清理动作 | 结果 |
| --- | --- | --- | --- |
| UTM 测试 VM | 待填写 | 删除 | PENDING |
| QEMU 测试 VM | 待填写 | 删除 | PENDING |
| VNC 端口 | `127.0.0.1:5900` | 停止 | PENDING |
| QMP socket | `~/VMs/archboot-qemu/qmp.sock` | 删除 | PENDING |
| Bridge socket | `~/Library/Application Support/VMBridge/control.sock` | 删除 | PENDING |
| LaunchAgent | `待填写` | 卸载 | PENDING |
| `SleepDisabled` | 待填写 | 恢复 | PENDING |
| QEMU 包 | 待填写 | 卸载 | PENDING |
| 脱敏日志 | 待填写 | 保留 | PENDING |

## 11. 更新规则

执行后填写所有 PENDING。
执行后保存命令和退出码。
执行后保存关键输出。
执行后保存截图路径。
执行后更新主方案限制。
执行后更新证据附录缺口。
执行后更新目录说明状态。
执行后提交复核记录。

## 12. 关联文档

- [主方案](../README.md)
- [证据附录](../evidence.md)
- [后台 GUI 自动化验证目录](README.md)
