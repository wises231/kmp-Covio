# 控制中心视觉语言证据附录

## 文档状态

| 项目 | 内容 |
| --- | --- |
| 文档版本 | `1.0` |
| 状态 | 审计记录，可复核 |
| 日期 | `2026-10-16` |
| 主文 | [主题索引](README.md) |
| 验证目录 | [验证目录](validation/README.md) |
| 案例 | [Case 1](validation/case-control-center-parity.md) |

## 0. 问题类别与案例映射

问题类别是平台视觉语言的复现。

| 案例 | 覆盖的问题类别 | 证据 |
| --- | --- | --- |
| `Case 1` | 几何、材质、边、层级 | `E-01` 到 `E-05`、`E-11` |

## 1. 来源等级

| 等级 | 来源 | 用途 | 置信度 |
| --- | --- | --- | --- |
| A | macOS 27.0 SDK 的 `SwiftUICore.swiftinterface` 与 `SwiftUI.swiftinterface` | 玻璃 API 的签名与可用版本 | 高 |
| B | Covio 仓库分支 `feature/shell-match-preview`，commit `44b5207` | 工作台视图与几何常量的现状 | 高 |
| B | Covio 设计合同 `docs/covio-design-contract.json` | 材质与圆角令牌的定义 | 高 |
| C | Apple 的 Liquid Glass 设计说明 | 玻璃的设计意图 | 中 |
| D | 本机截图采样 | 控制中心的几何与材质实测值 | 高，但范围小 |
| E | 无 | 本主题不使用第三方来源 | — |

控制中心是系统进程，没有 B 级来源。
它的取值全部是 D 级，只代表本机环境。

## 2. 环境事实

| 项目 | 值 | 命令 | 置信度 |
| --- | --- | --- | --- |
| 系统版本 | macOS 27.0.1 | `sw_vers` | 高 |
| 系统构建号 | 26A434 | `sw_vers` | 高 |
| 屏幕像素 | 3456 × 2234 | 截图文件头 | 高 |
| 缩放比例 | 2 像素每点 | 屏幕点尺寸 1728 × 1117 | 高 |
| Xcode SDK | MacOSX27.0.sdk | `xcrun --show-sdk-path --sdk macosx` | 高 |
| 部署目标 | `MACOSX_DEPLOYMENT_TARGET = 26.0` | 工程文件 | 高 |
| 控制中心进程 | 运行中 | `pgrep -lf ControlCenter` | 高 |
| 采样截图 | 控制中心打开时的全屏截图 | `screencapture -x` | 高 |
| 采样时间 | `2026-10-15 21:34` | 截图内的菜单栏时钟 | 高 |

## 3. 证据索引

| 编号 | 主题 | 来源 | 结论 | 置信度 |
| --- | --- | --- | --- | --- |
| E-01 | 控制中心面板与模块的尺寸 | D | 面板宽 292 点，模块 140 × 49 点 | 高 |
| E-02 | 模块的边与圆角 | D | 亮边 1 到 2 像素，圆角约 19 点 | 中高 |
| E-03 | 模块之间的缝 | D | 水平 12 点，垂直 27 点 | 高 |
| E-04 | 面板的层级 | D | 模块之间没有容器底板 | 高 |
| E-05 | 模块的填充 | D | 半透明，亮度接近桌面，内部有模糊 | 中高 |
| E-06 | 玻璃 API 的可用性 | A | `glassEffect` 与 `Glass.clear` 自 macOS 26 起可用 | 高 |
| E-07 | `glassSurface` 的调用点 | B | 改动前全仓库零调用 | 高 |
| E-08 | 设计合同的材质令牌 | B | 定义了半透明材质与 60 点模糊，没有组件使用 | 高 |
| E-09 | 卡片的填充 | B | 改动前用不透明的 `token/color/surface` | 高 |
| E-10 | 玻璃底材的对照实验 | D | 不成立。跨截图的桌面内容有变化 | 高 |
| E-11 | 工作台改后的结构 | B | 四张卡片各自一块玻璃，内容区无底板 | 高 |
| E-12 | 部署目标 | B | `26.0`，满足玻璃 API 的最低版本 | 高 |

## 4. 证据详情

### E-01：控制中心面板与模块的尺寸

来源等级：D
环境：macOS 27.0.1（26A434），3456 × 2234 像素，2 像素每点。截图 `cc.png`，控制中心打开状态。
命令或来源：

```sh
swift sample.swift cc.png                       # 打印图像尺寸
swift edges.swift cc.png 2835,154,2900,154 5    # 左边缘
swift edges.swift cc.png 3100,80,3100,240 6     # 上下边缘
swift edges.swift cc.png 3380,460,3456,460 6    # 右边缘
```

关键输出：

```text
image 3456x2234
H y=154: x=2843 60 -> 15 (-45)   x=2844 15 -> 87 (+72)
H y=460: x=3428 76 -> 10 (-66)   x=3429 10 -> 36 (+26)
V x=3100: y=103 94 -> 78 (-16)   y=104 78 -> 105 (+27)
V x=3100: y=202 132 -> 147 (+15) y=204 98 -> 37 (-61)
```

观察：面板左边缘在 x = 2844 像素，右边缘在 x = 3428 像素。
左列模块的右边缘在 x = 3124 像素。
模块上边缘在 y = 104 像素，下边缘在 y = 203 像素。

推论：面板宽 584 像素，即 292 点。
左列模块宽 281 像素，即 140 点。
模块高 99 像素，即 49 点。

反证：无。

限制：只测了本机这一块屏幕与这一版系统。
控制中心的面板宽度可能随屏幕宽度变化。

置信度：高

关联：`Case 1` 的 `V01`、`V02`

### E-02：模块的边与圆角

来源等级：D
环境：同 `E-01`。
命令或来源：

```sh
swift edges.swift cc.png 3100,80,3100,240 6      # 上边缘与下边缘
swift edges.swift cc.png 2835,112,3210,112 6     # 顶部横带
swift edges.swift cc.png 2830,196,3200,196 6     # 底部横带
swift edges.swift cc.png 2835,154,2900,154 5     # 中腰
```

关键输出：

```text
V x=3100: 上边缘 y=104，亮度 78 -> 105 -> 118，之后回落到 72
V x=3100: 下边缘 y=201 到 203，亮度 88 -> 132 -> 147，之后跌到 37
H y=154: 左边缘 x=2844，亮度 15 -> 87 -> 99 -> 108，之后回落到 75
H y=112: 左边缘 x=2859，亮度 65 -> 95 -> 104
H y=196: 左边缘 x=2860，亮度 98 -> 130
H y=160: 右边缘 x=3124，亮度 65 -> 32
H y=112: 右边缘 x=3107，亮度 86 -> 106，之后跌到 66
```

观察：模块边缘有一条 1 到 2 像素的亮线。亮线外侧有一条更暗的线。
亮线的亮度随位置变化：中腰 108，下边缘 147。
中腰的左边缘在 x = 2844。距上边缘 8 像素处的左边缘在 x = 2859。距下边缘 7 像素处在 x = 2860。

推论：模块是圆角矩形，不是胶囊。
用圆角矩形的水平内缩公式反算，半径约 38.5 像素，即 19 点。
19 除以模块高 49 点，比值是 0.39。
亮线是镜面反射效果，由系统绘制。

反证：反算用二次方程，有两个根。小根是 7.5 像素，与观察到的内缩不符，舍去。

限制：反算假设边是标准圆角矩形。控制中心可能用了连续曲率圆角，半径会有偏差。

置信度：中高

关联：`Case 1` 的 `V02`

### E-03：模块之间的缝

来源等级：D
环境：同 `E-01`。
命令或来源：

```sh
swift edges.swift cc.png 2860,160,3456,160 9     # 水平缝
swift edges.swift cc.png 3100,200,3100,720 8     # 垂直缝
```

关键输出：

```text
H y=160: 左列模块右边缘 x=3124。右列模块左边缘 x=3148
V x=3100: 模块下边缘 y=203。下一个模块上边缘 y=257
V x=3100: 第二个缝 y=355 到 y=409，第三个缝 y=507 到 y=561
```

观察：三个垂直缝分别是 54、54、54 像素。
水平缝是 24 像素。

推论：水平缝 12 点。垂直缝 27 点。
控制中心的水平缝与垂直缝不同。

反证：无。

限制：只测了左列与右列之间的缝。面板内其他位置的缝未测。

置信度：高

关联：`Case 1` 的 `V02`

### E-04：面板的层级

来源等级：D
环境：同 `E-01`。
命令或来源：

```sh
swift edges.swift cc.png 3100,200,3100,720 8
```

关键输出：

```text
V x=3100: y=204 98 -> 37 (-61)。y=205 到 y=255 的亮度在 37 到 49 之间
V x=3100: y=508 116 -> 66 (-50)。y=509 到 y=559 的亮度在 60 到 77 之间
```

观察：模块之间的亮度是 37 到 77。
模块内部的亮度是 66 到 94。
两者量级相同。

推论：模块之间没有半透明填充。
面板不画统一背板，模块之间直接露出桌面。

反证：无。

限制：模块之间的亮度等于桌面，这一点由 `E-05` 的对照支持。
单独看 `E-04` 只能说明「没有比桌面更亮的一层」。

置信度：高

关联：`Case 1` 的 `V01`

### E-05：模块的填充

来源等级：D
环境：同 `E-01`。截图为 6 倍放大图，取模块左上区域。
命令或来源：

```sh
swift edges.swift cc.png 3100,80,3100,240 6
swift edges.swift cc.png 2835,154,2900,154 5
swift stack.swift z1.png 2850 100 340 130 2040 cc.png
```

关键输出：

```text
V x=3100: 模块外 y=100 到 103 的亮度 94 到 105
V x=3100: 模块内 y=107 到 115 的亮度 72 到 80
H y=154: 模块外 x=2835 到 2842 的亮度 60 到 86
H y=154: 模块内 x=2850 到 2870 的亮度 75 到 88
```

观察：模块填充的亮度比紧邻桌面低 5 到 25 级。
放大图里，壁纸的亮条穿过模块内部，边缘被抹开。

推论：填充是半透明的，下面有模糊。
模块不靠抬高亮度与桌面区分。区分靠边。

反证：亮度差随桌面内容变化，不是定值。
在桌面较亮的区域，模块看起来更暗；在桌面较暗的区域，差异变小。

限制：只在本机这一张壁纸上取样。
浅色外观下的表现未测。

置信度：中高

关联：`Case 1` 的 `V03`

### E-06：玻璃 API 的可用性

来源等级：A
环境：MacOSX27.0.sdk。
命令或来源：

```sh
SDK=$(xcrun --show-sdk-path --sdk macosx)
grep -n "glassEffect\|struct Glass\|GlassEffectContainer" \
  "$SDK/System/Library/Frameworks/SwiftUICore.framework/Modules/SwiftUICore.swiftmodule/arm64e-apple-ios-macabi.swiftinterface"
```

关键输出：

```text
@available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, *)
@available(visionOS, unavailable)
nonisolated public func glassEffect(_ glass: Glass = .regular, in shape: some Shape = DefaultGlassEffectShape()) -> some View

@available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, *)
@available(visionOS, unavailable)
public struct Glass : Equatable, Sendable {
  public static var regular: Glass
  public static var clear: Glass
  public func tint(_ color: Color?) -> Glass
  public func interactive(_ isEnabled: Bool = true) -> Glass
}

@available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, *)
@available(visionOS, unavailable)
public struct GlassEffectContainer<Content> : View where Content : View
```

观察：`glassEffect` 的默认底材是 `.regular`。
`Glass` 有两个内置变体：`.regular` 与 `.clear`。
`GlassEffectContainer` 存在，可让相邻玻璃合并。
三者的最低系统版本都是 macOS 26.0。

推论：`.clear` 是公开 API 里比 `.regular` 更淡的一档。
本机 macOS 27.0.1 满足要求。

反证：无。

限制：接口文件只给出签名，不给出观感。
`.clear` 与控制中心的接近程度要靠目视确认。

置信度：高

关联：`Case 1` 的 `V04`、`V05`

### E-07：`glassSurface` 的调用点

来源等级：B
环境：Covio 仓库。改动前是 `main` 上的 `GlassSurface.swift`。
命令或来源：

```sh
git show main:macosApp/src/Design/GlassSurface.swift
grep -rn "glassSurface(" macosApp/src
```

关键输出：

```text
改动前：macosApp/src/Design/GlassSurface.swift 定义了 glassSurface 修饰器。
改动前：全仓库没有调用点。
改动后：4 个调用点。
  macosApp/src/Hub/HubView.swift:118       顶栏板
  macosApp/src/Hub/HubView.swift:230       首页为空时的提示块
  macosApp/src/Hub/HubComponents.swift:37  MacCard
  macosApp/src/Hub/Workbench/BentoWidgetCard.swift:93  首页网格卡片
```

观察：修饰器早就存在，但改动前没有任何视图用它。
改动后四张卡片都接上了。

推论：玻璃的代码路径已经写好，缺的是接线。
问题不在 API，在用法。

反证：无。

限制：无。

置信度：高

关联：`Case 1` 的 `V06`

### E-08：设计合同的材质令牌

来源等级：B
环境：Covio 设计合同 `docs/covio-design-contract.json`。
命令或来源：

```sh
python3 -c "import json; ..."   # 遍历合同，打印 radius 与 material 相关项
```

关键输出：

```text
token/color/material-ultra-thick  深色 #1C1C1EC7
token/color/material-thick        深色 #1C1C1EAD
token/color/material-medium       深色 #1C1C1E94
token/color/surface               深色 #2C2C2E
token/radius/large                16
token/radius/medium               12
token/radius/small                8
token/radius/pill                 999
```

观察：合同定义了五档半透明材质填充，透明度从 0.62 到 0.94。
合同定义了 60 点的模糊半径。
改动前没有任何组件使用材质填充。
改动前卡片用的是不透明的 `token/color/surface`。

推论：合同的材质一栏此前是死值。
控制中心的表现与合同的设计意图一致，但实现没有跟上。

反证：无。

限制：合同里还有 `component/material` 的 10 个变体。
本次改动没有动它们。合同的文本与实现仍有不一致，见第 7 节。

置信度：高

关联：`Case 1` 的 `V06`

### E-09：卡片的填充

来源等级：B
环境：Covio 仓库分支 `feature/shell-match-preview`，commit `44b5207`。
命令或来源：

```sh
git show 7597b62 -- macosApp/src/Hub/HubComponents.swift
git show 44b5207 -- macosApp/src/Design/MacTheme.swift
```

关键输出：

```text
改动前 MacCard：.background(MacTheme.surface, in: shape)
改动前 BentoWidgetCard：.background(MacTheme.color(tint), in: shape)
改动后 MacCard：.background(MacTheme.material, in: shape).glassSurface(...)
改动后 BentoWidgetCard：.background(MacTheme.color(tint).opacity(MacTheme.tintedCardOpacity), in: shape)
```

观察：改动前两处填充都不透明。
改动后 `MacCard` 用 `token/color/material-thin`。
改动后首页卡片把色值乘上 `token/material/opacity/ultra-thin`。

推论：不透明填充是「看不到模糊」的直接原因。
玻璃画在填充下面，填充不透明时模糊被盖住。

反证：无。

限制：无。

置信度：高

关联：`Case 1` 的 `V03`、`V06`

### E-10：玻璃底材的对照实验

来源等级：D
环境：macOS 27.0.1。四张全屏截图，拍摄时间相隔约 4 分钟。
命令或来源：

```sh
swift cmp.swift glass-glass.png glass-material.png 1000,60,1000,420 8
swift cmp.swift glass-glass.png glass-ultraThin.png 1000,60,1000,420 8
```

关键输出：

```text
顶栏板区域 y=88 到 175：glass 亮度 124 到 133，material 亮度 94
顶栏板下方那条缝 y=178 到 199：glass 亮度 142 到 148，material 亮度 165
同一条缝在 ultraThin 截图里也是 165
```

观察：那条缝在两个底材下都没有玻璃，亮度应该相同。
实测 glass 截图是 142 到 148，material 截图是 165。差 17 到 23。

推论：两次截图之间桌面内容变了。
跨截图的亮度差不能归给底材。
本次对照实验不成立。

反证：这一条本身就是反证。它否定了「用跨截图亮度差比较底材」这个方法。

限制：要比较底材，必须在同一次会话里用 `COVIO_GLASS_SURFACE` 环境变量切换，
并且每切换一次都要重新截一次，同时确认桌面内容没有变化。

置信度：高

关联：`Case 1` 的 `V04`

### E-11：工作台改后的结构

来源等级：B
环境：Covio 仓库分支 `feature/shell-match-preview`，commit `44b5207`。
命令或来源：

```sh
grep -n "plateGap\|plateTopInset\|tabBarPlateRadius\|tabBarHeight\|bentoCardRadius\|panelWidth\|panelPadding" \
  macosApp/src/Design/HubMetrics.swift
git show 44b5207 -- macosApp/src/Hub/HubView.swift
```

关键输出：

```text
HubMetrics.tabBarHeight = 46
HubMetrics.plateGap = 11
HubMetrics.plateTopInset = 11
HubMetrics.tabBarPlateRadius = tabBarHeight / 2
HubMetrics.bentoCardRadius = 16
HubMetrics.panelPadding = 24
HubView：topBarPlate 套 glassSurface(23)
HubView：contentArea 只给高度，不画背景、不描边、不加投影
HubView：plates 外面套 GlassEffectContainer(spacing: 0)
```

观察：顶栏板是胶囊，圆角 23 点。
内容区没有底板。
板与板之间的缝是 11 点，与菜单栏之间的缝也是 11 点。
`GlassEffectContainer` 的 spacing 是 0。

推论：工作台的水平缝 11 点与控制中心的实测 12 点接近。
`bentoCardRadius` 16 点与卡片高 96 点的比值是 0.17，与控制中心的 0.39 不同。

反证：无。

限制：卡片圆角是否要改成 0.39 比例未定。见 [conclusion.md](conclusion.md) 第 8 节。

置信度：高

关联：`Case 1` 的 `V01`、`V02`、`V06`

### E-12：部署目标

来源等级：B
环境：Covio 仓库。
命令或来源：

```sh
grep -rn "MACOSX_DEPLOYMENT_TARGET" macosApp/Covio.xcodeproj/project.pbxproj
```

关键输出：

```text
macosApp/Covio.xcodeproj/project.pbxproj:277  MACOSX_DEPLOYMENT_TARGET = 26.0;
macosApp/Covio.xcodeproj/project.pbxproj:300  MACOSX_DEPLOYMENT_TARGET = 26.0;
```

观察：Debug 与 Release 两处都是 26.0。

推论：玻璃 API 的最低版本要求已满足，不需要条件编译。

反证：无。

限制：部署目标 26.0 意味着应用不能在 macOS 25 及更低版本运行。
这是已有决定，不是本次改动引入的。

置信度：高

关联：`Case 1` 的 `V04`

## 5. 逻辑证据链

```text
研究问题：控制中心的内容按钮由哪些可复现的取值构成？
  -> 来源 D：控制中心打开时的全屏截图
  -> 观察 E-01 到 E-05：几何、边、缝、层级、填充
  -> 推论：模块由细亮边、接近桌面亮度的半透明填充、无底板、0.39 的圆角比例定义
  -> 决策：玻璃下放到每张卡片，底材取 .clear，填充取半透明材质
  -> 验证条件：用户在真机上目视确认表现一致
  -> 回填位置：validation/case-control-center-parity.md

研究问题：工作台用哪些公开 API 能复现同一套表现？
  -> 来源 A：macOS 27.0 SDK 的 Swift 接口文件
  -> 观察 E-06：glassEffect、Glass.clear、GlassEffectContainer 自 macOS 26 起可用
  -> 推论：.clear 是公开 API 里最淡的一档
  -> 决策：底材取 .clear，保留材质降级路径
  -> 验证条件：四个底材取值都能起，界面不崩
  -> 回填位置：validation/case-control-center-parity.md

研究问题：工作台此前为什么看不到模糊？
  -> 来源 B：Covio 仓库分支 feature/shell-match-preview
  -> 观察 E-07、E-08、E-09：玻璃零调用、材质令牌没组件用、填充不透明
  -> 推论：不透明填充盖住了玻璃的模糊
  -> 决策：填充换半透明材质，玻璃接到每张卡片
  -> 验证条件：卡片之间露出桌面，卡片内部有模糊
  -> 回填位置：validation/case-control-center-parity.md
```

## 6. 反证和限制

### 6.1 跨截图的亮度比较不成立

`E-10` 证明：不同时间拍的两张截图，桌面内容会变。
缝里的亮度差 17 到 23 级，与底材无关。
所有涉及底材的比较必须在同一次会话里完成。

### 6.2 亮度差不是定值

`E-05` 的 −5 到 −25 是区间。
它随桌面内容变化，不能当成常量写进代码。

### 6.3 圆角是反算的

`E-02` 的 19 点来自二次方程的大根。
如果控制中心用的是连续曲率圆角，真实半径会更小。

### 6.4 控制中心是 D 级来源

上表全部取值只代表本机这一版系统与这一张壁纸。
不能写成平台规范。

### 6.5 没有 `.clear` 的真机对照

`.clear` 的选择依据是 `.regular` 偏重加上用户的目视确认。
没有像素级的对照数据。

## 7. 已知缺口

1. 没有 `.clear` 变体在真机上的对照截图。
2. 没有浅色外观下的控制中心截图。
3. 没有减弱动态效果下的控制中心截图。
4. 没有「玻璃在无边框透明面板里画不出来」的失败样本。
5. 采样脚本没有随仓库分发。
6. 控制中心的取值没有跨系统版本的对比。macOS 26 与 macOS 27 的差异未测。
7. 设计合同 `component/material` 的文本与实现不一致。本次改动没有回填合同。

## 8. 复核方法

1. 打开控制中心，用 `screencapture -x` 截全屏，存成 PNG。
2. 确认截图里的菜单栏时钟，记下采样时间。
3. 用任意能读 PNG 像素的工具，沿下面几条直线打印亮度：
   - 水平 `(2835,154)` 到 `(2900,154)`：左边缘与圆角。
   - 垂直 `(3100,80)` 到 `(3100,240)`：上边缘与下边缘。
   - 垂直 `(3100,200)` 到 `(3100,720)`：垂直缝。
   - 水平 `(2860,160)` 到 `(3456,160)`：水平缝与右列。
4. 找相邻两点亮度差超过 6 的位置。这些位置是边缘。
5. 按 `E-01` 到 `E-05` 的算法复算尺寸、圆角、缝宽与亮度差。
6. 复核底材时，在同一次会话里用 `COVIO_GLASS_SURFACE` 切换，每次切换后立刻截图，
   并确认缝里的亮度没有变化。变了就作废，重来。

## 参考来源

- [SwiftUI `glassEffect`](https://developer.apple.com/documentation/swiftui/view/glasseffect(_:in:))
- [SwiftUI `Glass`](https://developer.apple.com/documentation/swiftui/glass)
- [SwiftUI `GlassEffectContainer`](https://developer.apple.com/documentation/swiftui/glasseffectcontainer)
- [Apple Human Interface Guidelines：Materials](https://developer.apple.com/design/human-interface-guidelines/materials)

## 9. 关联文档

- [主题索引](README.md)
- [验证目录](validation/README.md)
- [Case 1](validation/case-control-center-parity.md)
- [前因与问题边界](context.md)
- [调研方法与技术分析](investigation.md)
- [根因、结论与限制](conclusion.md)
- [推荐架构、接口与实施计划](solution.md)
