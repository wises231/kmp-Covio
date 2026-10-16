# 根因、结论与限制

> 本文件承载结论摘要、根因、决策表、限制和不采用方案。

## 1. 结论摘要

合盖睡眠没有非特权机制。
`caffeinate -s` 使用的 `PreventSystemSleep` 断言在任何 macOS 版本里都不受支持。
合盖睡眠只能通过 `pmset disablesleep` 控制。这个键需要 root。
因此特权 helper 必须保留。

helper 的形式也保留。`SMAppService.daemon` 要求应用公证，本机没有 Developer ID。
换形式也不减少提权动作，只改变提权发生的位置。

## 2. 根因或决策因素

### 2.1 主要因素

**`PreventSystemSleep` 是一个不受支持的断言。**

Apple 在 `IOPMLib.h` 里把它标为废弃，并写明「not supported in any OS X releases」（`E-01`）。
`caffeinate -s` 创建的正是这个断言（`E-03`）。
本机对照实验验证了这个判定（`E-05`、`E-06`）。

### 2.2 次要因素

**合盖判定不读进程断言。**

`powerd` 的合盖判定读全局电源设置，不读进程断言列表。
断言出现在 `pmset -g assertions` 列表里，但这个登记不参与合盖判定（`E-07`）。

**`disablesleep` 是系统级键，不是每电源一份。**

`pmset -g` 把 `SleepDisabled` 放在 `System-wide power settings` 段（`E-08`）。
`pmset -g custom` 的 AC 段和电池段都没有这个键，而 `hibernatemode` 在两端各有一份（`E-09`）。
所以按电源来源分流只能由应用侧完成。Covio 的合同已经这样设计（`E-10`、`E-11`）。

### 2.3 换形式的阻断因素

**`SMAppService` 要求公证。**

Apple 写明含 LaunchDaemon 的应用必须公证（`E-16`）。
本机只有自签名证书和 ad-hoc 签名，没有 Developer ID（ADR-0005）。
探针用这两种配置各注册一次，两次都失败（`E-20`）。
系统建了 BTM 条目，但标记为 `disallowed`，拒绝引导。

**换形式不减少提权动作。**

注册成功后守护进程要等管理员在 System Settings 批准（`E-18`）。
清 `disablesleep` 仍然需要 root。`unregister()` 不做这件事（`E-21`）。
应用更新后还要重新注册，否则守护进程可能不启动（`E-19`）。
所以管理员动作从一个安装弹窗，变成一个批准开关，加一次清理提权。

**现有路径没有兼容性风险。**

Apple 写明手写 plist 的旧路径继续有效，而且不需要 System Settings 批准（`E-17`）。

## 3. 决策表

| 决策 | 选择 | 原因 | 备选路径 |
| --- | --- | --- | --- |
| 是否用断言替代 helper | 不用 | 断言不受支持 | 无 |
| 是否保留特权组件 | 保留 | 合盖睡眠只能由 root 控制 | 删掉合盖功能 |
| 插电与电池是否区分 | 区分 | 合同已定义两个字段，电池不睡有代价 | 合并为一个开关 |
| 区分由谁执行 | 应用侧 | `disablesleep` 没有每电源版本 | 无 |
| 特权组件的形式 | 保留手写 plist | `SMAppService` 要求公证，本机没有 Developer ID | 无 |

## 4. 逻辑证据链

### 4.1 观察一

观察：`IOPMLib.h` 把 `kIOPMAssertionTypePreventSystemSleep` 标为「not supported in any OS X releases」。
推论：这个断言不能作为功能的基础。
置信度：高
证据：`E-01`

### 4.2 观察二

观察：持有 `PreventSystemSleep` 断言时，合盖后系统仍然进入完全睡眠。
推论：断言对合盖判定没有作用。
置信度：高
证据：`E-05`、`E-06`

### 4.3 观察三

观察：`pmset -g custom` 里没有 `disablesleep`，而 `hibernatemode` 在 AC 段和电池段各有一份。
推论：按电源来源分流必须在应用侧完成。
置信度：高
证据：`E-09`

### 4.4 观察四

观察：Covio 的合同已经定义 `disableLidSleepInCharging` 和 `disableLidSleepOnBattery` 两个字段，`Engine.kt` 按电池状态二选一。
推论：插电与电池的区分不需要新设计，只需要保持。
置信度：高
证据：`E-10`、`E-11`

### 4.5 观察五

观察：`SMAppService.h` 要求含 LaunchDaemon 的应用必须公证。探针用两种签名配置各注册一次，两次都失败。
推论：换 `SMAppService.daemon` 这条路走不通。
置信度：高
证据：`E-16`、`E-20`

### 4.6 观察六

观察：手写 plist 的路径被 Apple 明确保留，而且不需要 System Settings 批准。
推论：保留现状不承担兼容性风险。这条路径不是过渡方案。
置信度：高
证据：`E-17`

## 5. 限制和未决项

### 5.1 系统限制

1. 合盖睡眠只能由 root 控制。这是系统设计，不是实现缺陷。
2. `man pmset` 没有 `disablesleep` 条目。这个键没有官方文档（`E-04`）。
3. 应用不运行时，`disablesleep` 保持上次写入值。持久性是全局设置的固有属性。

### 5.2 产品限制

1. 合盖功能必须依赖一个特权组件。
2. 组件卸载时必须先清 `disablesleep`，否则机器会一直不睡。

### 5.3 未决项

1. 电池合盖不睡的电量代价没有量化。
2. 市场对比缺失。`WebSearch` 在本机返回 403。
3. 有 Developer ID 的机器上注册是否成功没有验证。本机没有 Developer ID。
4. 探针从 `/tmp` 运行，`/Applications` 路径的影响没有单独隔离。见 `E-20`。
