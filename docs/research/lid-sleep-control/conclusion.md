# 根因、结论与限制

> 本文件承载结论摘要、根因、决策表、限制和不采用方案。

## 1. 结论摘要

合盖睡眠没有非特权机制。
`caffeinate -s` 使用的 `PreventSystemSleep` 断言在任何 macOS 版本里都不受支持。
合盖睡眠只能通过 `pmset disablesleep` 控制。这个键需要 root。
因此特权 helper 必须保留。可优化的部分是 helper 的形式，不是它的存在。

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

## 3. 决策表

| 决策 | 选择 | 原因 | 备选路径 |
| --- | --- | --- | --- |
| 是否用断言替代 helper | 不用 | 断言不受支持 | 无 |
| 是否保留特权组件 | 保留 | 合盖睡眠只能由 root 控制 | 删掉合盖功能 |
| 插电与电池是否区分 | 区分 | 合同已定义两个字段，电池不睡有代价 | 合并为一个开关 |
| 区分由谁执行 | 应用侧 | `disablesleep` 没有每电源版本 | 无 |
| 特权组件的形式 | 待定 | `SMAppService` 的签名要求未验证 | 保留手写 plist |

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

## 5. 限制和未决项

### 5.1 系统限制

1. 合盖睡眠只能由 root 控制。这是系统设计，不是实现缺陷。
2. `man pmset` 没有 `disablesleep` 条目。这个键没有官方文档（`E-04`）。
3. 应用不运行时，`disablesleep` 保持上次写入值。持久性是全局设置的固有属性。

### 5.2 产品限制

1. 合盖功能必须依赖一个特权组件。
2. 组件卸载时必须先清 `disablesleep`，否则机器会一直不睡。

### 5.3 未决项

1. `SMAppService.daemon` 在自签名证书下能否注册。本机没有 Developer ID。见验证矩阵 `V04`。
2. 电池合盖不睡的电量代价没有量化。
3. 市场对比缺失。`WebSearch` 在本机返回 403。
