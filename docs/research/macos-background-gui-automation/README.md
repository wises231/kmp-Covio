# macOS 后台 GUI 自动化与虚拟化控制研究

## 文档状态

| 项目 | 内容 |
| --- | --- |
| 文档版本 | `3.0` |
| 状态 | 初稿，可评审 |
| 日期 | `2026-10-10` |
| 适用对象 | Covio 研发、测试、发布和运维人员 |
| 当前验证环境 | Apple Silicon Mac，macOS 27.0.1，UTM 4.7.5 |
| 当前结论 | 推荐 Aqua 桥接加无界面虚拟化后端 |
| 验证状态 | 尚未执行 |

## 前因

Covio 需要支持后台创建虚拟机。
Covio 需要支持后台控制虚拟机。
Covio 需要支持锁屏、盒盖、SSH、`launchd`、注销和快速切换用户。
`Case 1` 使用 UTM 和 Archboot 验证这一类问题。
前因、问题类别、适用边界、场景和成功标准见 [context.md](context.md)。
证据链见 [evidence.md](evidence.md)。

## 背景

macOS 存在 `system`、`user`、`gui` 和 `session` 会话域。
后台进程可能位于 `Background` 会话。
GUI 应用和 WindowServer 位于 Aqua 会话。
TCC、WindowServer 和电源策略限制后台自动化。
专业说明、来源等级和证据字段见 [investigation.md](investigation.md)。
当前环境和原始观测见 [evidence.md](evidence.md)。

## 过程

调研使用 Apple 官方文档、本机 `man`、UTM 源码、上游 issue、市场文档和本机实验。
调研覆盖会话模型、原生工具、TCC、UTM、QEMU、QMP、VNC、Tart、Lima、vfkit 和商业虚拟化产品。
调研方法和工具矩阵见 [investigation.md](investigation.md)。
复现命令、来源、观察和推论见 [evidence.md](evidence.md)。
`Case 1` 验证过程见 [validation/case-utm-archboot.md](validation/case-utm-archboot.md)。

## 结果

锁屏不是唯一根因。
会话隔离是主要根因。
TCC 不能由后台进程绕过。
锁屏状态下宿主 GUI 合成输入不可靠。
注销后 Aqua 上下文不可恢复。
已有 VM 通常可以继续运行。
新建 VM、首次 AppleEvent 和宿主 GUI 输入需要 Aqua 桥接或人工路径。
根因、决策表和限制见 [conclusion.md](conclusion.md)。
证据索引和逻辑链见 [evidence.md](evidence.md)。

## 预期

目标能力是后台查询系统状态。
目标能力是后台创建和启动虚拟机。
目标能力是后台截图、发送按键和发送点击。
目标能力是锁屏和盒盖状态下保持任务运行。
目标能力是权限缺失、注销和电源策略不满足时返回明确错误。
验收标准见 [solution.md](solution.md)。
验证目标、范围、矩阵和风险见 [validation/README.md](validation/README.md)。
证据链见 [evidence.md](evidence.md)。

## 实现预期的手段

`VMBridge` 使用 Unix socket。
Socket 路径为 `~/Library/Application Support/VMBridge/control.sock`。
Socket 权限为 `0600`。
协议为换行分隔 JSON。
虚拟化操作使用 `vm.*`。
兼容操作保留 `qemu.*`、`utm.*` 和 `host.appleevent`。
无界面任务使用 QEMU、QMP、VNC 和串口。
需要 GUI 的任务使用 Aqua 桥接。
推荐架构、接口契约、流程、电源、安全、失败模式和实施计划见 [solution.md](solution.md)。
实际验证记录见 [validation/case-utm-archboot.md](validation/case-utm-archboot.md)。
证据链见 [evidence.md](evidence.md)。

## 子文档

| 文件 | 内容 |
| --- | --- |
| [context.md](context.md) | 前因、问题类别、适用边界、场景和成功标准 |
| [investigation.md](investigation.md) | 调研方法、会话模型、原生工具、TCC、UTM、无界面后端和市场对比 |
| [conclusion.md](conclusion.md) | 结论摘要、根因、决策表、限制和不采用方案 |
| [solution.md](solution.md) | 推荐架构、接口契约、流程、电源、安全、失败模式、验收和实施计划 |
| [evidence.md](evidence.md) | 命令、来源、观察、推论、置信度和已知缺口 |
| [validation/README.md](validation/README.md) | 验证目标、范围、测试矩阵、风险和清理要求 |
| [validation/case-utm-archboot.md](validation/case-utm-archboot.md) | `Case 1`：UTM 与 Archboot 验证记录 |

## 证据链

1. 从 [context.md](context.md) 阅读问题边界。
2. 从 [investigation.md](investigation.md) 阅读技术分析。
3. 从 [evidence.md](evidence.md) 阅读来源、命令和推论。
4. 从 [conclusion.md](conclusion.md) 阅读根因和限制。
5. 从 [solution.md](solution.md) 阅读推荐实现。
6. 从 [validation/README.md](validation/README.md) 阅读验证矩阵。
7. 从 [validation/case-utm-archboot.md](validation/case-utm-archboot.md) 阅读 `Case 1` 结果。

## 更新规则

执行验证后更新案例状态。
执行验证后更新验证矩阵。
执行验证后更新结论和限制。
执行验证后更新证据缺口。
执行验证后更新本索引。
