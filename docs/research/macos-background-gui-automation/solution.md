# 推荐架构、接口与实施计划

> 本文件承载推荐架构、接口契约、流程、电源、安全、失败模式、验收和实施计划。
> 原研究文档的章节编号保留，便于后续证据引用。

## 11. 推荐架构

### 11.1 路径选择

Aqua 桥接承载 GUI 和 AppleEvent 任务。
无界面后端承载新 VM 和不依赖 WindowServer 的任务。
客机内部通道承载 SSH、串口和客机代理任务。
调用方先查询 `session.status` 和 `tcc.status`。
调用方再按任务选择路径。
锁屏下的宿主 GUI 输入返回 `host_gui_locked`。
注销后的请求返回 `gui_session_unavailable`。
provider 不支持操作时返回 `provider_unsupported`。

### 11.2 组件

| 组件 | 职责 | 会话 | 启动方式 |
| --- | --- | --- | --- |
| `VMBridge.app` | 接收请求并执行操作 | Aqua | LaunchAgent |
| LaunchAgent | 启动和守护桥接 | Aqua | `~/Library/LaunchAgents` |
| 控制 socket | 接收后台请求 | 文件系统 | 按需或常驻 |
| UTM | 管理已有 VM | Aqua | AppleEvent |
| QEMU | 管理无界面 VM | Background 或 Aqua | 子进程 |
| VNC | 客机 GUI | 本机 TCP | QEMU |
| QMP | 客机控制 | Unix socket | QEMU |
| 日志 | 审计和排错 | 文件系统 | 追加写入 |

### 11.3 调用路径

```text
Background client
  -> Unix socket
  -> VMBridge.app in Aqua
  -> UTM AppleEvent
  -> existing UTM VM
```

```text
Background client
  -> Unix socket
  -> VMBridge.app in Aqua
  -> QEMU process
  -> QMP, VNC, serial
  -> headless VM
```

### 11.4 文件位置

| 项目 | 路径 |
| --- | --- |
| 桥接应用 | `~/Applications/VMBridge.app` |
| LaunchAgent | `~/Library/LaunchAgents/com.example.vmbridge.plist` |
| 控制 socket | `~/Library/Application Support/VMBridge/control.sock` |
| 日志 | `~/Library/Logs/VMBridge.log` |
| QEMU VM | `~/VMs/<name>/` |
| UTM VM | `~/Library/Containers/com.utmapp.UTM/Data/Documents/` 或用户选择的目录 |

### 11.5 启动策略

1. 用户解锁并登录 Aqua。
2. 安装 LaunchAgent。
3. 启动 `VMBridge.app`。
4. 检查 Aqua 会话。
5. 检查 TCC 状态。
6. 启动 UTM。
7. 发送 `get version` 探测请求。
8. 写入健康状态。
9. 锁屏后保留桥接进程。
10. 注销时停止服务并清理 socket。

## 12. 接口契约

### 12.1 传输

`VMBridge` 使用 Unix domain socket。
Socket 路径为 `~/Library/Application Support/VMBridge/control.sock`。
Socket 权限为 `0600`。
Socket 只允许同一用户访问。
协议为换行分隔 JSON。
每个请求只占一行。
每个响应只占一行。
服务不提供远程 TCP。
服务不提供 UDP。
服务不提供网络转发。

### 12.2 请求

```json
{"request_id":"req-0001","op":"health","args":{}}
```

字段说明：

| 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `request_id` | string | 是 | 调用方生成的唯一 ID |
| `op` | string | 是 | 操作名 |
| `args` | object | 是 | 操作参数 |

### 12.3 响应

```json
{"ok":true,"data":{"status":"ready"},"error_code":null,"error_message":null}
```

字段说明：

| 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `ok` | boolean | 是 | 操作是否成功 |
| `data` | object 或 null | 是 | 成功数据 |
| `error_code` | string 或 null | 是 | 稳定错误码 |
| `error_message` | string 或 null | 是 | 供日志使用的错误信息 |

### 12.4 操作

| 操作 | 参数 | 返回 | 说明 |
| --- | --- | --- | --- |
| `health` | 无 | 会话、TCC、UTM 和 QEMU 状态 | 健康检查 |
| `session.status` | 无 | 会话类型和 GUI 域 | 查询会话状态 |
| `tcc.status` | 能力名 | 授权状态 | 查询 TCC 状态 |
| `power.assert` | 断言类型和期限 | 断言 ID | 创建临时电源断言 |
| `vm.create` | provider、名称、ISO、磁盘大小 | VM ID 和路径 | 创建通用 VM |
| `vm.start` | provider、VM ID | 进程信息和 VNC 地址 | 启动通用 VM |
| `vm.stop` | provider、VM ID、模式 | 停止结果 | 停止通用 VM |
| `vm.status` | provider、VM ID | 状态和 PID | 查询通用 VM |
| `guest.vnc.screenshot` | VM ID、输出路径 | 图片信息 | 捕获客机画面 |
| `guest.vnc.key` | VM ID、按键列表 | 输入结果 | 发送键盘输入 |
| `guest.vnc.click` | VM ID、坐标和按钮 | 输入结果 | 发送鼠标点击 |
| `qemu.*` | provider 专属参数 | provider 专属结果 | 兼容操作；新调用方使用 `vm.*` |
| `utm.create` | 配置对象 | UTM VM ID | 通过 Aqua 桥接创建 |
| `utm.start` | UTM VM ID | 启动结果 | 启动已有 VM |
| `utm.stop` | UTM VM ID、模式 | 停止结果 | 停止已有 VM |
| `utm.input` | UTM VM ID、输入对象 | 输入结果 | QEMU 后端输入 |
| `host.appleevent` | 目标应用和脚本 ID | AppleEvent 结果 | 受控宿主调用 |

### 12.5 错误码

| 错误码 | 触发条件 | 可重试 | 人工处理 |
| --- | --- | --- | --- |
| `gui_session_unavailable` | 无 Aqua 会话 | 否 | 重新登录 |
| `tcc_missing` | 缺少 TCC 授权 | 否 | 解锁后授权 |
| `host_gui_locked` | 锁屏阻止宿主 GUI 操作 | 否 | 解锁后执行 |
| `window_server_unavailable` | WindowServer 不可用 | 是 | 恢复 GUI 会话 |
| `power_policy_unmet` | 电源或盒盖策略阻止 | 条件重试 | 接通电源或修改策略 |
| `provider_unsupported` | 后端不支持操作 | 否 | 选择其他 provider |
| `utm_not_ready` | UTM 未运行或阻塞 | 是 | 启动 UTM 或解锁后重试 |
| `vnc_unavailable` | VNC 无响应 | 是 | 检查 QEMU 和端口 |
| `lock_screen_denied` | 应用策略拒绝锁屏操作 | 否 | 解锁后执行 |

## 13. 流程设计

### 13.1 创建无界面 VM

1. 调用方连接 Unix socket。
2. 调用方发送 `vm.create`。
3. `VMBridge` 校验参数。
4. `VMBridge` 创建 VM 目录。
5. `VMBridge` 创建 `qcow2` 磁盘。
6. `VMBridge` 写入 `metadata.json`。
7. `VMBridge` 返回 VM ID。
8. 调用方发送 `vm.start`。
9. `VMBridge` 启动 QEMU。
10. `VMBridge` 等待 QMP 就绪。
11. `VMBridge` 返回 VNC 地址和 PID。

### 13.2 创建 UTM VM

1. 调用方确认处于 Aqua。
2. 调用方确认 Automation 已授权。
3. 调用方连接 Unix socket。
4. 调用方发送 `utm.create`。
5. `VMBridge` 启动 UTM。
6. `VMBridge` 等待 UTM 注册 AppleEvent。
7. `VMBridge` 发送 AppleScript。
8. UTM 创建 `.utm` 包。
9. `VMBridge` 返回 UTM VM ID。
10. 失败时返回 `utm_not_ready` 或 `tcc_missing`。

### 13.3 客机 GUI 自动化

1. 调用方发送 `guest.vnc.screenshot`。
2. `VMBridge` 通过 VNC 连接客机。
3. `VMBridge` 保存截图。
4. 调用方分析截图。
5. 调用方发送 `guest.vnc.key`。
6. `VMBridge` 将按键发送到 VNC。
7. 调用方发送 `guest.vnc.click`。
8. `VMBridge` 将点击发送到 VNC。
9. 调用方再次截图确认结果。

### 13.4 停止和清理

1. 调用方发送 `vm.stop`。
2. `VMBridge` 首选 ACPI 关机。
3. 超时后按策略关闭。
4. `VMBridge` 删除 PID 文件。
5. `VMBridge` 关闭 QMP socket。
6. `VMBridge` 关闭 VNC 监听。
7. `VMBridge` 写入审计日志。
8. 验证阶段删除测试 VM。

## 14. 电源和盒盖策略

### 14.1 `caffeinate`

`caffeinate -s` 可以创建系统睡眠断言。
`caffeinate -i` 可以创建空闲睡眠断言。
`caffeinate -d` 可以创建显示睡眠断言。
`caffeinate` 只影响当前命令运行期间。
`caffeinate` 不修改硬件策略。
首选 `caffeinate -s`。
需要验证显示状态时增加 `-d`。

### 14.2 `pmset`

`pmset -g assertions` 显示当前断言。
`pmset -g batt` 显示电源状态。
`pmset -g` 显示 `SleepDisabled`。
`sudo pmset -a disablesleep 1` 会全局禁止睡眠。
此命令需要 root。
此命令影响整机。
只在锁屏任务期间使用。
任务结束必须恢复原值。
产品不得默认永久修改此值。

### 14.3 IOKit

Covio 已有盒盖监听逻辑。
IOKit 可以监听电源和盒盖事件。
IOKit 不负责 AppleEvent。
IOKit 不负责 UTM 会话。
IOKit 可以作为电源状态输入。
桥接应读取 Covio 的电源状态。
桥接不应重复实现所有电源逻辑。

### 14.4 策略组合

| 条件 | 策略 | 结果 |
| --- | --- | --- |
| AC 电源，盒盖关闭 | `caffeinate -s` | 系统保持运行 |
| 电池电源，盒盖关闭 | 用户明确允许 | 电池会消耗 |
| 显示器关闭 | QEMU 继续运行 | 无界面 VM 不受影响 |
| 系统睡眠 | QEMU 暂停或断开 | 唤醒后检查状态 |
| 注销 | Aqua 域消失 | 返回 `gui_session_unavailable` |
| 安全输入模式 | 输入可能被拦截 | 不使用宿主输入 |

## 15. 安全设计

### 15.1 本机边界

控制 socket 只在本机。
控制 socket 只允许同一用户。
Socket 权限必须为 `0600`。
父目录权限必须限制。
服务不得监听公网地址。
VNC 只绑定 `127.0.0.1`。
QMP 只使用 Unix socket。
串口日志不得包含敏感信息。

### 15.2 授权边界

服务不执行任意 shell 字符串。
服务只执行允许的操作。
每个操作使用结构化参数。
VM 名称必须经过白名单校验。
路径必须位于允许目录。
ISO 必须校验哈希。
脚本 ID 必须映射到固定脚本。
`host.appleevent` 只允许目标应用白名单。
每次请求记录请求 ID 和用户 ID。
错误信息不返回秘密值。

### 15.3 日志

日志记录时间。
日志记录操作名。
日志记录请求 ID。
日志记录结果码。
日志记录目标 VM ID。
日志不记录密码。
日志不记录令牌。
日志不记录完整 TCC 数据库。
日志默认位于用户目录。
日志轮换由后续版本设计。

## 16. 失败模式和恢复

| 场景 | 错误码 | 检测 | 重试 | 处理 |
| --- | --- | --- | --- | --- |
| 无 GUI 登录 | `gui_session_unavailable` | `launchctl print gui/<uid>` | 否 | 用户登录 |
| 未批准 Automation | `tcc_missing` | UTM 探测失败 | 否 | 解锁后授权 |
| 未批准 Accessibility | `tcc_missing` | 宿主输入测试失败 | 否 | 解锁后授权 |
| UTM 未启动 | `utm_not_ready` | 进程或探测失败 | 是 | 启动 UTM |
| UTM 首次连接阻塞 | `utm_not_ready` | AppleEvent 超时 | 是 | 重置连接 |
| AppleEvent 阻塞 | `utm_not_ready` | 看门狗超时 | 是 | 解锁后重试 |
| QEMU 未安装 | `vnc_unavailable` | 命令不存在 | 否 | 安装 QEMU |
| QMP 未就绪 | `vnc_unavailable` | socket 不存在 | 是 | 等待启动 |
| VNC 不可达 | `vnc_unavailable` | TCP 连接失败 | 是 | 检查端口 |
| 盒盖睡眠 | `power_policy_unmet` | `pmset` 和 IOKit | 条件 | 接通电源 |
| 策略拒绝锁屏 | `lock_screen_denied` | 请求上下文 | 否 | 解锁后执行 |
| 注销 | `gui_session_unavailable` | `gui/<uid>` 不存在 | 否 | 重新登录 |

## 17. 验收标准

### 17.1 文档验收

1. 检查 Markdown 链接。
2. 检查主文和证据附录链接。
3. 检查主文和验证目录链接。
4. 检查命令路径。
5. 检查版本号。
6. 检查 ISO 哈希。
7. 检查源码 commit。

### 17.2 功能验收

| 编号 | 场景 | 预期 |
| --- | --- | --- |
| A01 | 解锁状态启动桥接 | `health` 返回 `ready` |
| A02 | 锁屏后调用 `health` | 返回 Aqua 和 TCC 状态 |
| A03 | 锁屏后启动已有 UTM VM | VM 进入运行状态 |
| A04 | 锁屏后创建 UTM VM | 返回 UTM VM ID |
| A05 | 锁屏后创建 QEMU VM | 磁盘和元数据存在 |
| A06 | 锁屏后启动 QEMU VM | QMP 和 VNC 可用 |
| A07 | 锁屏后截图客机 | 图片包含客机画面 |
| A08 | 锁屏后发送按键 | 客机收到输入 |
| A09 | 锁屏后发送点击 | 客机收到输入 |
| A10 | 关闭权限后调用 | 返回 `tcc_missing` |
| A11 | 注销后调用 | 返回 `gui_session_unavailable` |
| A12 | 系统休眠后恢复 | 状态可查询 |
| A13 | 任务结束清理 | 临时进程和 socket 已删除 |
| A14 | 恢复电源设置 | `SleepDisabled` 恢复原值 |

### 17.3 通过条件

所有高优先级测试通过。
所有错误返回稳定错误码。
所有日志包含请求 ID。
所有敏感数据不出现在日志。
所有临时设置恢复原值。
所有验证结果写入验证目录。

## 18. 实施计划

### 18.1 阶段 0：文档

1. 提交主方案。
2. 提交证据附录。
3. 提交验证目录。
4. 更新 README 链接。
5. 执行链接检查。

### 18.2 阶段 1：桥接 PoC

1. 创建 `VMBridge.app`。
2. 设置 `LSUIElement`。
3. 创建 Aqua LaunchAgent。
4. 创建 Unix socket。
5. 实现 `health`。
6. 实现 `host.appleevent` 探测。
7. 记录日志。

### 18.3 阶段 2：无界面后端

1. 安装 QEMU。
2. 验证 `qemu-system-aarch64`。
3. 验证 UEFI 固件。
4. 实现 `vm.create`。
5. 实现 `vm.start`。
6. 实现 `vm.stop`。
7. 实现 QMP 状态查询。
8. 实现 VNC 截图和输入。

### 18.4 阶段 3：UTM 桥接

1. 实现 UTM 启动。
2. 实现 UTM 首次探测。
3. 实现 `utm.create`。
4. 实现 `utm.start`。
5. 实现 `utm.stop`。
6. 实现 `utm.input`。
7. 记录 AppleEvent 超时。
8. 记录 TCC 错误。

### 18.5 阶段 4：验证和产品化

1. 运行 Archboot 验证。
2. 运行盒盖验证。
3. 运行锁屏验证。
4. 运行注销验证。
5. 运行升级验证。
6. 评估 `SMAppService`。
7. 评估签名和公证。
8. 评估安装和卸载。

### 18.6 回滚

1. 卸载 LaunchAgent。
2. 停止桥接进程。
3. 删除控制 socket。
4. 删除测试 VM。
5. 恢复 `pmset` 设置。
6. 保留审计日志。
7. 记录回滚结果。
