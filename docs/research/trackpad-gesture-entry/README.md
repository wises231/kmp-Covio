# 触控板多指手势入口

## 文档状态

| 项目 | 内容 |
| --- | --- |
| 文档版本 | `1.0` |
| 状态 | 初稿，可评审 |
| 日期 | `2026-10-13` |
| 适用对象 | 产品、研发、测试和无障碍评审人员 |
| 当前验证环境 | MacBook Pro 18,2，Apple M1 Max，macOS 27.0.1（26A434），Xcode 27 SDK |
| 当前结论 | 可交付。路径是私有 `MultitouchSupport.framework`。 |
| 验证状态 | 尚未执行 |

## 前因

产品需求要求用户四指下滑打开挂帘。
macOS 把四指垂直轻扫绑给调度中心。前台应用和后台应用都收不到这个手势。
本主题判定这个需求能否交付，并给出降级方案。
前因、研究问题、问题类别、适用边界、场景和成功标准见 [context.md](context.md)。
证据链见 [evidence.md](evidence.md)。

## 背景

系统输入事件分三层：公开 AppKit 事件、公开 CoreGraphics 事件流、私有 IOKit 多触点设备。
公开层没有全局多指手势入口。私有层直接给出每帧的手指数量和位置。
本仓库已经在 `PointerTrackingHost.swift:6` 记录过全局监听器的教训。
技术说明、来源等级和证据字段见 [investigation.md](investigation.md)。
当前环境和原始观测见 [evidence.md](evidence.md)。

## 过程

本主题先查公开 API 的边界，再验证私有 API 的可用性。
公开 API 的边界用 Xcode 27 SDK 头文件判定。私有 API 的可用性用本机实验判定。
本主题同时扫描了 macOS 26 与 27 新增的手势相关 API，没有找到全局多指手势入口。
调研方法和方案矩阵见 [investigation.md](investigation.md)。
复现命令、来源、观察和推论见 [evidence.md](evidence.md)。
案例验证过程见 [validation/case-macos-trackpad-gesture.md](validation/case-macos-trackpad-gesture.md)。

## 结果

四指下滑可以交付。交付路径是私有 `MultitouchSupport.framework`。
私有框架在本机可加载。`MTDeviceCreateList` 返回内建触控板。
`MTRegisterContactFrameCallback` 加 `MTDeviceStart` 成功，设备状态从 0 变为 1。
公开 API 没有替代路径。macOS 26 与 27 没有新增全局多指手势接口。
私有框架的表面不稳定。四个 `MTDeviceGet*` 访问器在本机直接崩溃。
根因、决策表和限制见 [conclusion.md](conclusion.md)。
证据索引和逻辑链见 [evidence.md](evidence.md)。

## 预期

目标是让触发层拿到“四指下滑”这一个事件。
触发层不关心手指的精确轨迹。触发层只关心手指数、方向和位移。
验收标准见 [solution.md](solution.md)。
验证目标、范围、矩阵和风险见 [validation/README.md](validation/README.md)。
证据链见 [evidence.md](evidence.md)。

## 实现预期的手段

推荐做法是新增一个 `MultitouchContactSource`，把私有框架包在一层薄封装里。
封装只调用 `MTDeviceCreateList`、`MTRegisterContactFrameCallback`、`MTDeviceStart` 和 `MTDeviceStop`。
封装禁止调用 `MTDeviceGet*` 访问器，因为本机实测这些函数崩溃。
封装把接触帧归一成 `TouchFrame`，再交给手势识别器。
识别器判定四指下滑，并发出一个触发事件。
私有路径不可用时，触发层降级到刘海悬停、全局快捷键和菜单栏图标。
推荐方案、接口契约、流程、安全、失败模式和实施计划见 [solution.md](solution.md)。
实际验证记录见 [validation/case-macos-trackpad-gesture.md](validation/case-macos-trackpad-gesture.md)。
证据链见 [evidence.md](evidence.md)。

## 子文档

| 文件 | 内容 |
| --- | --- |
| [context.md](context.md) | 研究问题、问题类别、系统模型、状态矩阵、场景和成功标准 |
| [investigation.md](investigation.md) | 调研方法、来源等级、能力矩阵、候选方案和反证 |
| [conclusion.md](conclusion.md) | 结论、决策因素、决策表、不采用方案和未决项 |
| [solution.md](solution.md) | 推荐架构、接口契约、失败模式、验收标准和实施计划 |
| [evidence.md](evidence.md) | 环境事实、复现命令、16 条证据、逻辑链和已知缺口 |
| [validation/README.md](validation/README.md) | 验证目标、范围、测试矩阵、风险和清理步骤 |
| [validation/case-macos-trackpad-gesture.md](validation/case-macos-trackpad-gesture.md) | 真机手势采集记录，尚未执行 |

## 证据链

1. 从 [context.md](context.md) 阅读问题边界。
2. 从 [investigation.md](investigation.md) 阅读技术分析。
3. 从 [evidence.md](evidence.md) 阅读来源、命令和推论。
4. 从 [conclusion.md](conclusion.md) 阅读决策因素和限制。
5. 从 [solution.md](solution.md) 阅读推荐实现。
6. 从 [validation/README.md](validation/README.md) 阅读验证矩阵。
7. 从 [validation/case-macos-trackpad-gesture.md](validation/case-macos-trackpad-gesture.md) 阅读案例结果。

## 更新规则

执行验证后更新案例状态。
执行验证后更新验证矩阵。
执行验证后更新结论和限制。
执行验证后更新证据缺口。
执行验证后更新本索引。
系统大版本升级后重跑全部本机实验。
