# 推荐架构、接口与实施计划

> 本文件承载推荐架构、接口契约、流程、资源策略、安全、失败模式、验收和实施计划。

## 1. 推荐架构

### 1.1 路径选择

保留特权组件，形式也不换。两个候选路径都被排除。

断言路径已判定无效，所以没有非特权替代品。
`SMAppService.daemon` 要求应用公证，本机没有 Developer ID（`E-16`、`E-20`）。
换形式也不减少提权动作，只改变提权发生的位置（`E-18`、`E-21`）。

推荐保留现有 helper。它已经可用，协议和鉴权都已经实现。
Apple 明确保留手写 plist 这条路径，而且不需要 System Settings 批准（`E-17`）。

本节不改代码。

### 1.2 组件

| 组件 | 职责 | 环境 | 启动方式 |
| --- | --- | --- | --- |
| `Covio` 应用 | 读电池状态，判定策略，调用 helper | 用户态 | 用户启动 |
| `HelperClient` | 连接套接字，发命令，读回复 | 用户态 | 应用内 |
| helper 服务端 | 校验 uid，执行白名单命令 | root | LaunchDaemon |
| `powerd` | 读全局设置，决定睡眠 | 系统 | 系统 |

### 1.3 调用路径

```text
用户合盖
  -> 硬件上报合盖事件
  -> powerd 读 SleepDisabled
  -> SleepDisabled 为 1 时不睡

应用侧（提前发生）
  -> 读电池状态
  -> desiredLidHold() 选配置字段
  -> HelperClient 发 setDisableSleep
  -> helper 执行 pmset -a disablesleep 1
```

## 2. 接口契约

契约已经实现，本节记录现状，不改动。

### 2.1 传输

Unix 域套接字。路径 `/Library/Application Support/Covio/helper.sock`。
单条请求和回复各限 64 KiB。
socket 文件权限位 `0666`。任意用户可连，uid 校验在连接后做。

### 2.2 请求

```json
{"version":"1","requestId":"req-0001","command":"setDisableSleep","payload":{"disabled":"true"}}
```

### 2.3 响应

```json
{"version":"1","requestId":"req-0001","ok":true}
```

### 2.4 操作

| 操作 | 参数 | 映射的 pmset 命令 |
| --- | --- | --- |
| `version` | 无 | 无 |
| `setDisableSleep` | `disabled` 取 `"true"` 或 `"false"` | `pmset -a disablesleep 1` 或 `0` |
| `setHibernateMode` | `mode` 取整数字符串 | `pmset -a hibernatemode <mode>` |

命令是白名单。新命令必须显式加入 `HELPER_ALLOWED_COMMANDS`。

### 2.5 鉴权

服务端用 `getpeereid` 取对端 uid。
对端 uid 与 `/Library/Application Support/Covio/allowed_uid` 比对。
不匹配就拒绝。

## 3. 流程

### 3.1 电源变化

```text
powerd 上报电源变化
  -> Engine.onPowerChanged()
  -> 读电池状态
  -> desiredLidHold() 重新判定
  -> 需要时调用 helper
```

这个流程是插电与电池区分的执行点。

### 3.2 卸载

```text
pmset -a disablesleep 0
  -> launchctl bootout
  -> rm -f plist
  -> rm -rf 安装目录
```

顺序不能改。先清标志：helper 删掉之后，没有任何进程能清这个标志。

## 4. 电源或资源策略

| 电池状态 | 使用的字段 | 默认值 |
| --- | --- | --- |
| 充电中 | `disableLidSleepInCharging` | `false` |
| 放电中 | `disableLidSleepOnBattery` | `false` |
| 其他 | 不阻止 | 不适用 |

两个字段的默认值都是 `false`。所以默认行为与系统默认一致。

低电量时强制睡眠。判定在 `lowBatterySleepRequired()` 里，优先于上面的两个字段。

## 5. 安全设计

| 项 | 措施 |
| --- | --- |
| 命令注入 | 白名单，不是黑名单。未列出的命令被拒绝。 |
| 越权调用 | `getpeereid` 校验 uid。 |
| 参数注入 | `pmset` 参数由服务端构造，客户端只传值。 |
| 请求撑爆内存 | 单条请求限 64 KiB。 |
| 残留状态 | 卸载脚本先清 `disablesleep`。 |

## 6. 失败模式

| 失败 | 表现 | 处理 |
| --- | --- | --- |
| helper 未安装 | 合盖开关不可用 | 界面禁用并提示 |
| helper 未运行 | 连接失败 | 状态如实反映，不假装成功 |
| 应用崩溃 | 断言释放，`disablesleep` 保持 | 下次启动重新判定 |
| 卸载中断 | `disablesleep` 可能为 1 | 重跑卸载脚本 |
| 应用未运行 | 标志保持上次值 | 已知限制，见 `conclusion.md` 5.1 |

## 7. 验收标准

1. helper 未安装时，合盖相关的开关不可用。
2. 插电合盖时，`pmset -g` 显示 `SleepDisabled 1`。
3. 拔掉电源后，电池字段为 `false` 时 `SleepDisabled` 回到 `0`。
4. 卸载 helper 后，`SleepDisabled` 为 `0`，plist 和安装目录都不存在。
5. 应用退出后，`disablesleep` 的状态符合 `Engine.kt:97` 的收尾逻辑。

## 8. 实施计划

1. 本主题不改代码。结论是保留现有实现。
2. 不换 helper 形式。注册探针已判定 `SMAppService` 路径不可用，见 `E-20`。
3. 验证矩阵保留 `V01` 到 `V03`、`V05`。`V04` 由注册探针回答。
4. 将来取得 Developer ID 时，重跑注册探针，再评估换形式。

## 9. 回滚条件

本节只在将来换形式时生效。当前不换形式。

换 `SMAppService` 之后出现下列情况时，回滚到现有 helper。

1. 签名或公证失效导致无法注册。
2. 注册后 helper 无法启动。
3. 卸载后 `disablesleep` 残留。

回滚路径：恢复手写 plist 的安装脚本。安装脚本在 `HelperInstallScript.kt` 里，两端共用。
