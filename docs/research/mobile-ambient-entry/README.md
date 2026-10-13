# iOS 免打开入口研究

## 文档状态

| 项目 | 内容 |
| --- | --- |
| 文档版本 | `1.0` |
| 状态 | 初稿，可评审 |
| 日期 | `2026-10-13` |
| 适用对象 | Covio 产品、研发、测试和安全人员 |
| 当前验证环境 | Apple Silicon Mac，macOS 27.0.1；无 iOS 真机 |
| 当前结论 | 主屏上滑手势不可实现；推荐入口是主屏交互小组件、控制中心控件和 Action Button |
| 验证状态 | 尚未执行 |

## 前因

产品需求要求在 iOS 主页用上滑手势带出 bottom sheet。
iOS 不向第三方应用提供主屏手势入口。
这条需求按原样不能实现。
本调研列出替代入口，并给出优先级顺序。
结论不预设实现，实现留给后续单独评审。
问题定义、适用边界、场景和成功标准见 [context.md](context.md)。
证据链见 [evidence.md](evidence.md)。

## 背景

iOS 用系统手势、锁屏和主屏三个空间控制用户入口。
第三方应用只能使用系统开放的接入面。
接入面包括 WidgetKit 小组件、控制中心控件、Action Button 和 App Intent。
每个接入面的系统版本门槛、用户配置成本和冷启动能力不同。
系统限制、来源等级和接入面矩阵见 [investigation.md](investigation.md)。
当前环境和原始观测见 [evidence.md](evidence.md)。

## 过程

调研分两路执行。
第一路覆盖 Apple 接口参考页，读取平台可用性和接口定义。
第二路覆盖 Apple 使用手册、支持文章、Human Interface Guidelines 和 WWDC 讲稿。
两路来源都是 Apple 官方来源。
本调研没有 iOS 真机实验。
每一格结论都带证据编号。
调研方法和来源范围见 [investigation.md](investigation.md)。
复现命令、来源、观察和推论见 [evidence.md](evidence.md)。
验证计划见 [validation/README.md](validation/README.md)。

## 结果

主屏上滑手势、锁屏手势和边缘手势都不对第三方应用开放。
主屏上唯一的第三方交互面是图标长按快速操作。
控制中心控件可以一键打开应用并进入指定工作区。
控件要求 iOS 18 及以上，并要求用户手动添加。
交互小组件要求 iOS 17 及以上，只支持 `Button` 和 `Toggle`。
锁定设备上小组件的按钮和开关不生效。
结论摘要、决策表、不采用方案和限制见 [conclusion.md](conclusion.md)。
证据索引、逻辑链和已知缺口见 [evidence.md](evidence.md)。

## 预期

目标能力是用户不打开应用就能触发一次应用动作。
目标能力是每个入口标注可用性、系统版本、配置成本和冷启动能力。
目标能力是入口在应用未启动时可以工作。
目标能力是系统限制有明确说明和降级路径。
目标能力是结论不绑定具体实现。
验收标准见 [solution.md](solution.md)。
验证目标、范围、矩阵和风险见 [validation/README.md](validation/README.md)。
证据链见 [evidence.md](evidence.md)。

## 实现预期的手段

入口按优先级分为六层。
第一层是主屏交互小组件。
第二层是锁屏交互小组件。
第三层是控制中心控件，配 `OpenIntent`。
第四层是 Action Button。
第五层是轻点背面加快捷指令。
第六层是应用内 `presentationDetents` bottom sheet。
所有入口共用同一套 App Intent。
推荐路径、契约草案、流程、安全和实施条件见 [solution.md](solution.md)。
实际验证记录见 [validation/case-ios-ambient-entry.md](validation/case-ios-ambient-entry.md)。
证据链见 [evidence.md](evidence.md)。

## 子文档

| 文件 | 内容 |
| --- | --- |
| [context.md](context.md) | 前因、研究问题、问题分类、状态矩阵、场景和成功标准 |
| [investigation.md](investigation.md) | 调研方法、系统模型、接入面矩阵、约束模型和方案对比 |
| [conclusion.md](conclusion.md) | 结论摘要、决策因素、决策表、不采用方案、限制和未决项 |
| [solution.md](solution.md) | 推荐入口顺序、契约草案、流程、安全、失败模式和实施条件 |
| [evidence.md](evidence.md) | 来源、命令、观察、推论、置信度、反证和已知缺口 |
| [validation/README.md](validation/README.md) | 验证目标、范围、测试矩阵、风险和清理要求 |
| [validation/case-ios-ambient-entry.md](validation/case-ios-ambient-entry.md) | `Case 1`：iOS 免打开入口可用性 |

## 证据链

1. 从 [context.md](context.md) 阅读问题边界与状态矩阵。
2. 从 [investigation.md](investigation.md) 阅读接入面矩阵与约束模型。
3. 从 [evidence.md](evidence.md) 阅读来源、命令和推论。
4. 从 [conclusion.md](conclusion.md) 阅读决策与限制。
5. 从 [solution.md](solution.md) 阅读推荐入口顺序与契约草案。
6. 从 [validation/README.md](validation/README.md) 阅读验证矩阵。
7. 从 [validation/case-ios-ambient-entry.md](validation/case-ios-ambient-entry.md) 阅读案例结果。

## 更新规则

执行验证后更新案例状态。
执行验证后更新验证矩阵。
执行验证后更新结论和限制。
执行验证后更新证据缺口。
执行验证后更新本索引。
Apple 文档更新后复核平台版本门槛。
