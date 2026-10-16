# 合盖睡眠控制与权限边界

## 文档状态

| 项目 | 内容 |
| --- | --- |
| 文档版本 | `1.0` |
| 状态 | 初稿，可评审 |
| 日期 | `2026-10-16` |
| 适用对象 | 产品、研发、测试和安全评审人员 |
| 当前验证环境 | MacBook Pro 18,2，Apple M1 Max，macOS 27.0.1（26A434），Xcode 27 SDK |
| 当前结论 | 合盖睡眠没有非特权机制。特权组件必须保留，形式也不换。 |
| 验证状态 | 部分执行。`V04` 由注册探针回答，其余待执行。 |

## 前因

Covio 需要「合盖不睡」功能。这个功能现在由一个特权 helper 实现。
helper 是 root LaunchDaemon，安装时请求管理员权限。
用户认为这个形式太重，要求找一个不提权的替代方案。
本主题判定替代方案是否存在，并给出取舍。
前因、研究问题、问题类别、适用边界、场景和成功标准见 [context.md](context.md)。
证据链见 [evidence.md](evidence.md)。

## 背景

macOS 的睡眠控制分两条路径。
一条是进程级断言，不需要 root，随进程结束失效。
另一条是全局电源设置，需要 root，持久。
空闲睡眠走第一条。合盖睡眠走第二条。
断言清单里唯一与「系统睡眠」同名的类型是 `PreventSystemSleep`。
Apple 在头文件里把它标为「not supported in any OS X releases」。
技术说明、来源等级和证据字段见 [investigation.md](investigation.md)。
当前环境和原始观测见 [evidence.md](evidence.md)。

## 过程

本主题先读 Xcode 27 SDK 头文件，列出全部断言类型。
再读 `man caffeinate` 和 `man pmset`，核对官方说明。
最后在本机做对照实验：同一台机器，同一段脚本，只改断言这一个变量。
实验用心跳文件测用户态进程是否连续运行，用 `pmset -g log` 测系统状态迁移。
第二步读 `SMAppService.h`，再在本机跑注册探针，验证换形式的可行性。
探针用两种签名配置各注册一次，并读回 `status`。
调研方法和方案矩阵见 [investigation.md](investigation.md)。
复现命令、来源、观察和推论见 [evidence.md](evidence.md)。
案例验证过程见 [validation/case-macos-lid-sleep.md](validation/case-macos-lid-sleep.md)。

## 结果

断言路径无效。
持有 `PreventSystemSleep` 断言时，合盖后系统仍然进入完全睡眠。
没有断言时，合盖后 5 秒进入完全睡眠。两个实验的终点相同。
Apple 的头文件写明这个断言在任何版本都不受支持。
因此合盖睡眠只能由 root 控制，特权 helper 必须保留。

helper 的形式也不换。
`SMAppService.daemon` 要求应用公证，本机没有 Developer ID。注册探针用两种签名配置各试一次，两次都失败。
换形式也不减少提权动作，只改变提权发生的位置。
Apple 明确保留手写 plist 这条路径，而且不需要 System Settings 批准。

决策记录见 [ADR-0006](../adr/adr-0006-lid-sleep-privileged-helper.md)。

插电与电池的区分不需要新设计。合同里已经是两个独立字段，`Engine.kt` 按电池状态二选一。
根因、决策表和限制见 [conclusion.md](conclusion.md)。
证据索引和逻辑链见 [evidence.md](evidence.md)。

## 预期

目标是让用户在不安装特权组件的前提下控制合盖睡眠。
本主题判定这个目标不能达成。
调整后的目标是：保留特权组件，但降低它的安装和卸载成本。
验收标准见 [solution.md](solution.md)。
验证目标、范围、矩阵和风险见 [validation/README.md](validation/README.md)。
证据链见 [evidence.md](evidence.md)。

## 实现预期的手段

保留现有 helper。它已经可用，协议和鉴权都已经实现。
候选的形式改进是 `SMAppService.daemon`：plist 放在应用包内，注册和注销由系统托管。
本主题验证了这个候选。注册探针用两种签名配置各试一次，两次都失败。
原因在 Apple 的接口要求：含 LaunchDaemon 的应用必须公证。
因此本主题不改代码。
将来取得 Developer ID 时，重跑注册探针，再评估换形式。
推荐方案、接口契约、流程、安全、失败模式和实施计划见 [solution.md](solution.md)。
实际验证记录见 [validation/case-macos-lid-sleep.md](validation/case-macos-lid-sleep.md)。
证据链见 [evidence.md](evidence.md)。

## 子文档

| 文件 | 内容 |
| --- | --- |
| [context.md](context.md) | 研究问题、问题类别、状态矩阵、场景和成功标准 |
| [investigation.md](investigation.md) | 调研方法、来源等级、断言清单、候选方案和反证 |
| [conclusion.md](conclusion.md) | 结论、决策因素、决策表、限制和未决项 |
| [solution.md](solution.md) | 推荐架构、接口契约、电源策略、失败模式和实施计划 |
| [evidence.md](evidence.md) | 环境事实、复现命令、21 条证据、逻辑链和已知缺口 |
| [validation/README.md](validation/README.md) | 验证目标、范围、测试矩阵、风险和清理步骤 |
| [validation/case-macos-lid-sleep.md](validation/case-macos-lid-sleep.md) | 合盖睡眠与特权组件验证记录，尚未执行 |

## 证据链

1. 从 [context.md](context.md) 阅读问题边界。
2. 从 [investigation.md](investigation.md) 阅读技术分析。
3. 从 [evidence.md](evidence.md) 阅读来源、命令和推论。
4. 从 [conclusion.md](conclusion.md) 阅读决策因素和限制。
5. 从 [solution.md](solution.md) 阅读推荐实现。
6. 从 [validation/README.md](validation/README.md) 阅读验证矩阵。
7. 从 [validation/case-macos-lid-sleep.md](validation/case-macos-lid-sleep.md) 阅读案例结果。

## 更新规则

执行验证后更新案例状态。
执行验证后更新验证矩阵。
执行验证后更新结论和限制。
执行验证后更新证据缺口。
执行验证后更新本索引。
系统大版本升级后重跑全部本机实验。
