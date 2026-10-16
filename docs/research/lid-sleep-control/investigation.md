# 调研方法与技术分析

> 本文件承载调研方法、系统模型、现有能力矩阵、权限模型、产品分析和方案对比。

## 1. 调研方法

调研分四步。

1. 读 Xcode 27 SDK 头文件，列出全部电源断言类型。
2. 读 `man caffeinate` 和 `man pmset`，核对每个机制的官方说明。
3. 在本机做对照实验，验证断言的实效。
4. 读 `SMAppService.h`，再在本机跑注册探针，验证换形式的可行性。

第 3 步用对照法：同一台机器，同一段脚本，只改断言这一个变量。
测量手段是心跳文件和 `pmset -g log`。心跳文件记录用户态进程是否连续运行。电源日志记录系统状态迁移。

第 4 步用一个最小的探针应用包。包里有 `Contents/Library/LaunchDaemons` 下的 plist。
探针用两种签名配置各跑一次：`Covio Dev` 自签名证书，以及 ad-hoc。ad-hoc 与 CI 一致。
探针不修改系统设置，只调用 `register()` 和 `unregister()`，并读回 `status`。

## 2. 来源范围

| 等级 | 来源 | 用途 |
| --- | --- | --- |
| A | `IOPMLib.h`（Xcode 27 SDK） | 断言类型的权威定义和废弃状态 |
| A | `man caffeinate` | `-s` 参数的官方说明 |
| A | `man pmset` | `pmset` 参数的官方说明 |
| A | `SMAppService.h`（Xcode 27 SDK） | 注册接口的签名、公证和批准要求 |
| B | `macosApp/src/Platform/MacSleepController.swift` | 现有实现边界 |
| B | `kmpDomain/src/com/wyz/covio/core/HelperContract.kt` | helper 命令白名单 |
| B | `kmpDomain/src/com/wyz/covio/core/HelperInstallScript.kt` | 安装与卸载脚本 |
| B | `kmpDomain/src/com/wyz/covio/core/Engine.kt` | 合盖策略的判定逻辑 |
| B | `docs/adr/adr-0005-local-code-signing.md` | 现有签名配置 |
| D | 本机对照实验 | 当前环境的实际行为 |
| D | 本机注册探针 | 当前环境的注册结果 |

## 3. 系统模型

参与者有三个：用户、Covio 应用进程、`powerd`。

`powerd` 是系统电源管理器。它决定何时睡眠。它读两类输入：进程持有的断言，以及全局电源设置。

断言是进程级的。进程创建断言，`powerd` 记在列表里。进程退出或者释放断言，记录消失。断言不需要 root。

全局设置存在系统电源配置里。改设置需要 root。设置持久，不随进程消失。

合盖事件由硬件上报。`powerd` 收到后决定动作。这个决定读全局设置，不读进程断言。

## 4. 现有能力矩阵

`IOPMLib.h` 定义了全部断言类型。清单如下。

| 断言类型 | 常量值 | 状态 | 能否阻止合盖睡眠 |
| --- | --- | --- | --- |
| `kIOPMAssertPreventUserIdleSystemSleep` | `PreventUserIdleSystemSleep` | 现行 | 否 |
| `kIOPMAssertPreventUserIdleDisplaySleep` | `PreventUserIdleDisplaySleep` | 现行 | 否 |
| `kIOPMAssertNetworkClientActive` | `NetworkClientActive` | 现行 | 否 |
| `kIOPMAssertionTypePreventSystemSleep` | `PreventSystemSleep` | 废弃，任何版本都不支持 | 否 |
| `kIOPMAssertionTypeNoIdleSleep` | `NoIdleSleepAssertion` | 废弃于 10.7 | 否 |
| `kIOPMAssertionTypeNoDisplaySleep` | `NoDisplaySleepAssertion` | 废弃于 10.7 | 否 |

清单里没有合盖专用断言。

`pmset` 侧的能力如下。

| 键 | 作用域 | 需要 root | 效果 |
| --- | --- | --- | --- |
| `disablesleep` | 系统级，一份 | 是 | 合盖不睡 |
| `hibernatemode` | 每电源一份 | 是 | 控制睡眠时是否写盘 |
| `sleep` | 每电源一份 | 是 | 空闲睡眠计时器 |

## 5. 权限模型

断言和全局设置是两条独立的信任边界。

| 机制 | 权限 | 生效范围 | 生命周期 |
| --- | --- | --- | --- |
| IOKit 断言 | 无 | 当前进程持有期间 | 随进程结束 |
| `pmset` 全局设置 | root | 整机 | 持久，需要显式清除 |

## 6. 目标产品分析

Covio 的合盖功能走特权 helper。分析基于 commit `9d47e12`。

helper 是 root LaunchDaemon。协议是 Unix 域套接字。命令白名单只有三个：`version`、`setDisableSleep`、`setHibernateMode`。

鉴权用 `getpeereid` 取对端 uid，与安装时写入的 `allowed_uid` 比对。

安装和卸载都通过 `osascript` 请求管理员权限。

合盖策略的判定在 `Engine.kt` 的 `desiredLidHold()` 里。这个函数读电池状态，再选配置字段。

| 电池状态 | 使用的字段 |
| --- | --- |
| 充电中 | `disableLidSleepInCharging` |
| 放电中 | `disableLidSleepOnBattery` |
| 其他 | 不阻止 |

所以「插电合盖」和「电池合盖」在合同里已经是两个独立开关。
`Engine.kt` 的 `onPowerChanged()` 在电源变化时重新判定策略。

`MacSleepController.swift` 的注释已经记录过这个边界：「阻止空闲睡眠用 `NoIdleSleepAssertion`，这是唯一不需要 root 的机制。阻止合盖睡眠必须用 `pmset disablesleep`，那条路径由 helper 走。」

卸载脚本先执行 `pmset -a disablesleep 0`，再删 helper。顺序不能反：helper 删掉之后，这个标志没有任何进程能清。

## 7. 候选方案分析

| 方案 | 需要 root | 成本 | 风险 | 成熟度 | 可维护性 |
| --- | --- | --- | --- | --- | --- |
| `PreventSystemSleep` 断言 | 否 | 低 | 无效，断言不受支持 | 已废弃 | 不适用 |
| 保留手写 LaunchDaemon | 是 | 中 | plist 手写，卸载靠脚本 | 现行可用 | 中 |
| 改用 `SMAppService.daemon` | 是 | 中 | 被阻断，要求公证 | macOS 13 起 | 不适用 |
| 删掉合盖功能 | 否 | 低 | 功能消失 | 不适用 | 高 |

### 7.1 两种 helper 形式的对比

两个方案都要求特权组件。差别只在形式。

| 维度 | 保留现状：手写 plist | 换 `SMAppService.daemon` |
| --- | --- | --- |
| 能否落地 | 能。Apple 明确保留这条路径（`E-17`） | 不能。要求公证，本机没有 Developer ID（`E-16`、`E-20`） |
| 安装动作 | `osascript` 弹窗，一次性 | 先注册，再到 System Settings 批准（`E-18`） |
| 卸载动作 | `osascript` 弹窗，脚本以 root 运行 | `unregister()` 一步，不需要弹窗 |
| 清 `disablesleep` | 卸载脚本第一步做，有 root 权限 | `unregister()` 不做。仍然需要 root（`E-21`） |
| 应用更新 | 没有额外动作 | 每次更新要重新注册，否则可能不启动（`E-19`） |
| plist 位置 | `/Library/LaunchDaemons`，手写 | 应用包内 `Contents/Library/LaunchDaemons` |
| 组件路径 | plist 里写绝对路径 | `BundleProgram` 写包内相对路径 |

管理员动作在两个方案里都存在。现状是安装时的弹窗，`SMAppService` 是 System Settings 里的开关。
换形式不消除提权，只改变提权发生的位置和次数。

## 8. 市场对比

本主题没有收集市场数据。`WebSearch` 在本机返回 403，无法取得 C 级来源。
本节留空，缺口记在第 10 节。

## 9. 反证和限制

**反证 1：断言确实出现在系统列表里。**
`pmset -g assertions` 显示 `PreventSystemSleep 1`，并且标出持有进程的 pid。
这个观察支持「断言生效」的假设。
反驳：列表只说明 `powerd` 登记了这个断言，不说明它参与睡眠判定。实验 1 和实验 2 的结果相同，说明这个登记没有作用。

**反证 2：第一次实验里系统在 DarkWake 停留了 4 分 20 秒。**
这个延迟看起来像断言在起作用。
反驳：当时另有一个 `com.apple.powermanagement.lidopen` 断言。它在 10:09:09 超时。睡眠发生在 10:09:02。这个延迟的归属未确认，所以不采纳为证据。

**限制 1：本机实验只代表当前环境。**
D 级证据只说明这一台机器、这一个系统版本的行为。

**限制 2：合盖实验依赖人工操作。**
合盖和开盖由用户手动完成，时间点不精确。

## 10. 已知缺口

1. `man pmset` 没有 `disablesleep` 条目。这个键只有行为证据，没有文档证据。
2. 电池供电下的合盖行为没有单独测。断言路径已判定无效，所以这个测试没有意义。
3. 市场对比缺失。原因见第 8 节。
4. 探针从 `/tmp` 运行，没有单独隔离 `/Applications` 路径的影响。见 `E-20`。
5. 有 Developer ID 的机器上注册是否成功未验证。本机没有 Developer ID。
