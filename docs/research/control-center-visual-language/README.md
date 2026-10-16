# 控制中心视觉语言的复现研究

## 文档状态

| 项目 | 内容 |
| --- | --- |
| 文档版本 | `1.0` |
| 状态 | 初稿，可评审 |
| 日期 | `2026-10-16` |
| 适用对象 | Covio 界面研发与设计评审人员 |
| 当前验证环境 | Apple Silicon Mac，macOS 27.0.1（26A434），3456 × 2234 像素，2 像素每点 |
| 当前结论 | 推荐每个卡片自己一块 `Glass.clear` 玻璃，填充取半透明材质，不加容器底板 |
| 验证状态 | 尚未执行 |

## 前因

用户要求挂帘工作台的表现与控制中心一致。
用户的原话是工作台「完全走控制中心一样的表现效果的路线」。
布局与功能可以不同。
每个卡片要与控制中心的内容按钮表现一致。
前因、研究问题、问题类别、适用边界、场景和成功标准见 [context.md](context.md)。
证据链见 [evidence.md](evidence.md)。

## 背景

控制中心是系统进程，源码不公开。
第三方只能从截图反推它的取值，再用公开 API 逼近。
macOS 26 起 SwiftUI 提供 `glassEffect` 与 `Glass.clear`，是公开 API 里最接近的一条路。
技术说明、来源等级和证据字段见 [investigation.md](investigation.md)。
当前环境和原始观测见 [evidence.md](evidence.md)。

## 过程

调研用像素采样读控制中心的几何与材质，用 SDK 接口文件核对 API 可用性，用仓库源码核对现状。
调研覆盖几何、材质、边、层级、API 能力、候选方案和降级路径。
调研方法和方案矩阵见 [investigation.md](investigation.md)。
复现命令、来源、观察和推论见 [evidence.md](evidence.md)。
案例验证过程见 [validation/case-control-center-parity.md](validation/case-control-center-parity.md)。

## 结果

控制中心的模块由四件事定义。
一是细亮边，宽 1 到 2 像素。
二是半透明填充，亮度接近紧邻的桌面。
三是模块之间没有容器底板。
四是圆角约等于模块高度的 0.39。
工作台的卡片此前用不透明填充，所以看不到模糊。
根因、决策表和限制见 [conclusion.md](conclusion.md)。
证据索引和逻辑链见 [evidence.md](evidence.md)。

## 预期

目标能力是工作台的每个卡片与控制中心的内容按钮表现一致。
目标能力是卡片之间露出桌面，没有统一背板。
目标能力是玻璃底材不可用时退回材质，界面仍然可用。
目标能力是深色与浅色外观下表现都成立。
验收标准见 [solution.md](solution.md)。
验证目标、范围、矩阵和风险见 [validation/README.md](validation/README.md)。
证据链见 [evidence.md](evidence.md)。

## 实现预期的手段

每张卡片自己一块玻璃，底材取 `Glass.clear`。
卡片填充取 `token/color/material-thin`，半透明。
顶栏板用同一个底材，圆角 23 点。
内容区不放底板。
`GlassSurfaceMode` 保留四个取值，调试构建用 `COVIO_GLASS_SURFACE` 环境变量切换。
推荐方案、流程、失败模式和实施计划见 [solution.md](solution.md)。
验证目标、范围、矩阵和风险见 [validation/README.md](validation/README.md)。
实际验证记录见 [validation/case-control-center-parity.md](validation/case-control-center-parity.md)。
证据链见 [evidence.md](evidence.md)。

## 子文档

| 文件 | 内容 |
| --- | --- |
| [context.md](context.md) | 前因、研究问题、问题分类、状态矩阵、场景和成功标准 |
| [investigation.md](investigation.md) | 调研方法、系统模型、能力矩阵、候选方案对比、反证和缺口 |
| [conclusion.md](conclusion.md) | 结论摘要、决策因素、决策表、限制和未决项 |
| [solution.md](solution.md) | 推荐架构、组件职责、调用路径、失败模式、验收和实施计划 |
| [evidence.md](evidence.md) | 命令、来源、观察、推论、置信度和已知缺口 |
| [validation/README.md](validation/README.md) | 验证目标、范围、测试矩阵、风险和清理要求 |
| [validation/case-control-center-parity.md](validation/case-control-center-parity.md) | `Case 1`：工作台与控制中心表现一致性验证记录 |

## 证据链

1. 从 [context.md](context.md) 阅读问题边界。
2. 从 [investigation.md](investigation.md) 阅读技术分析。
3. 从 [evidence.md](evidence.md) 阅读来源、命令和推论。
4. 从 [conclusion.md](conclusion.md) 阅读决策和限制。
5. 从 [solution.md](solution.md) 阅读推荐实现。
6. 从 [validation/README.md](validation/README.md) 阅读验证矩阵。
7. 从 [validation/case-control-center-parity.md](validation/case-control-center-parity.md) 阅读 `Case 1` 结果。

## 更新规则

执行验证后更新案例状态。
执行验证后更新验证矩阵。
执行验证后更新结论和限制。
执行验证后更新证据缺口。
执行验证后更新本索引。
