# 控制中心视觉语言证据附录

## 文档状态

| 项目 | 内容 |
| --- | --- |
| 文档版本 | `1.2` |
| 状态 | 审计记录，可复核 |
| 日期 | `2026-10-17` |
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
| A | macOS 27.0 SDK 的 `SwiftUICore.swiftinterface`、`SwiftUI.swiftinterface` 与 `AppKit.framework/Headers/NSVisualEffectView.h` | 玻璃与材质的签名、可用版本和官方用法 | 高 |
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
| E-04 | 面板的层级 | D | 模块之间没有填充，只有模糊 | 高 |
| E-05 | 模块的填充 | D | 半透明，亮度接近桌面，内部有模糊 | 中高 |
| E-06 | 玻璃 API 的可用性 | A | `glassEffect` 与 `Glass.clear` 自 macOS 26 起可用 | 高 |
| E-07 | `glassSurface` 的调用点 | B | 改动前全仓库零调用 | 高 |
| E-08 | 设计合同的材质令牌 | B | 定义了半透明材质与 60 点模糊，没有组件使用 | 高 |
| E-09 | 卡片的填充 | B | 改动前用不透明的 `token/color/surface` | 高 |
| E-10 | 玻璃底材的对照实验 | D | 不成立。跨截图的桌面内容有变化 | 高 |
| E-11 | 工作台改后的结构 | B | 四张卡片各自一块玻璃，内容区无底板 | 高 |
| E-12 | 部署目标 | B | `26.0`，满足玻璃 API 的最低版本 | 高 |
| E-13 | 底材的模糊对照 | D | 控制中心模糊，`.clear` 不模糊 | 高 |
| E-14 | 底板与模块各加了多少亮度 | D | 模块缝比桌面暗 8 级，工作台的卡片叠 73 到 102 级 | 高 |
| E-15 | 模糊本身在起作用 | D | 相邻亮度差降到 17% | 高 |
| E-16 | 底板的传递曲线 | D | 控制中心底板 0.95·桌面 + 0.4，公开材质透光最高 0.59 | 高 |
| E-17 | 模糊与填充由同一个旋钮定 | A + D | `p` 同时控制模糊与填充，不可分开 | 高 |
| E-18 | `NSGlassEffectView` 的私有 `variant` | B + D | 没有一档给出满量程模糊加近零填充 | 高 |
| E-19 | 非 Key 面板的镜面亮边 | B + D | 覆盖 `_hasActiveAppearance` 抬亮上边缘 25.8 级。只测到一次 | 中 |
| E-20 | AppKit 底衬层的配方 | B | `CABackdropLayer` 加三个滤镜，其中没有着色滤镜 | 高 |
| E-21 | 手搭 `CABackdropLayer` 的实测 | D | 透光 0.61、填充 140。私有接口也到不了 | 高 |
| E-22 | `NSVisualEffectView` 材质全扫 | D | 会模糊的材质透光都不超过 0.29 | 高 |

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
面板不画统一背板，模块之间没有填充。

反证：`E-13`。模块之间虽然没有填充，但有模糊。
底下的内容是窗口时，缝里的文字被抹平。
`E-04` 的截图里底下是壁纸，壁纸本身平滑，模糊看不出来，所以当时判成了「直接露出桌面」。

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

反证：`E-13`。更淡不等于更接近控制中心。
`.clear` 几乎不模糊，这一条接口文件里看不出来。

限制：接口文件只给出签名，不给出观感。
`.clear` 与控制中心的接近程度只能靠真机对照，见 `E-13`。

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

### E-13：底材的模糊对照

来源等级：D
环境：macOS 27.0.1（26A434），3456 × 2234 像素，2 像素每点。
把一个带文字的 Finder 窗口摆在面板下方。
同一台机器、同一张壁纸、同一次会话内截两张图：一张面板收起，一张面板展开。
逐像素比对这两张图。

命令或来源：

```sh
# 面板收起
swift press.swift move 864 900 && screencapture -x closed.png
# 面板展开。指针进入刘海热区
swift press.swift move 864 8 && screencapture -x open.png
# 沿竖线打印「相同」与「改动」的连续区间
swift ranges.swift closed.png open.png 3000,50,3000,1150 3
# 放大 6 倍对照缝里的内容
swift stack.swift gap.png 2900 180 220 100 1320 closed.png open.png
```

关键输出：

```text
对照组：面板下方
  相同 y=1200..2200  宽 1001

面板内 x=3000
  改动 y=50..105   宽 56   平均差 22
  改动 y=225..234  宽 10   平均差 29
  改动 y=237..247  宽 11   平均差 30
```

对照组全段逐像素相同，说明壁纸与桌面图标没有变化。
面板内的改动全部来自面板。

观察一：控制中心。缝里（`y=225..247`）的亮度改动 29 到 30 级。
放大 6 倍看，缝里的地形细节消失，只剩平滑色块。
模块内部同样被抹平。桌面文件图标的图标与文件名被抹成横条。

观察二：Covio 用 `Glass.clear` 作底材。
卡片背后的 Finder 文件名（公共、图片、音乐、影片、桌面、资源库）字形仍然是锐的，只是对比度降低。
顶栏胶囊更明显：菜单栏的 `26%`、`44%`、`13 KB/s` 透过板子，与标签压在一起。

观察三：同一份代码把底材换成 `Glass.regular`，其余不动。
卡片背后的文字完全读不出来。
卡片自己的正文（现在、`16:11` · 周五、传输、最近截图、`0`）清晰。
顶栏胶囊背后的菜单栏数字消失。

推论：控制中心的模块带模糊，`.clear` 不带。
决定能不能看清的是模糊，不是填充重量。

反证：无。三次观察在同一次会话内完成，对照组证明壁纸未变。

限制：模糊的强度没有量化，只判定「有」与「没有」。
缝里的模糊来自模块本身还是面板背板，本次没有区分。

置信度：高

关联：`Case 1` 的 `V01`、`V03`、`V04`

### E-14：底板与模块各加了多少亮度

来源等级：D
环境：macOS 27.0.1（26A434），3456 × 2234 像素，2 像素每点，浅色外观。
把控制中心与工作台面板放在同一张壁纸上，同一次会话内比收起态与展开态。
取整块矩形求平均，不是取单点。

命令或来源：

```sh
swift delta.swift closed.png open.png 2825 200 3400 700
```

关键输出：

控制中心，面板矩形取 `x=2825..3400, y=200..700`：

| 矩形 | 桌面均亮 | 面板均亮 | 带符号差 |
| --- | --- | --- | --- |
| 模块竖缝 `x=3125..3145, y=200..700` | 79 | 70 | −8.2 |
| 蓝牙模块内 | 78 | 85 | +8.0 |
| 隔空投送模块内 | 72 | 98 | +25.6 |
| 面板整片 | 75 | 89 | +13.3 |

工作台，底板着色 0.5：

| 矩形 | 桌面均亮 | 面板均亮 | 带符号差 |
| --- | --- | --- | --- |
| 卡片横缝 `x=820..2640, y=445..462` | 88 | 114 | +26.0 |
| 现在卡内 | 97 | 169 | +72.6 |
| 传输卡内 | 57 | 159 | +102.0 |
| 内容板首行区 | 94 | 156 | +62.3 |

观察：控制中心的模块缝比桌面**暗** 8 级，模块内只比桌面亮 8 到 26 级。
工作台的底板抬 26 级，卡片在底板上再叠 73 到 102 级。面板内部自己就有一倍的反差。

反证：0.5 那次校准的三个测点都在 `x=800`。
面板左边缘在 `x=768`，那是玻璃的亮边，不是板身。
板身要从 `x=1000` 往后取。0.5 的依据不成立。

推论：**观察一（E-04「没有容器底板」）不成立。**
控制中心有一层铺满面板的模糊底板，模块叠在上面。
模块缝比桌面暗，说明缝里不是桌面，是底板。

置信度：高

关联：`#124` 证据 7，`E-16`

### E-15：模糊本身在起作用

来源等级：D
环境：同 `E-14`。

命令或来源：

```sh
swift scan.swift closed.png open.png 3000 200 700
```

关键输出：

```text
桌面   相邻亮度差合计 5848
面板   相邻亮度差合计 1009
```

观察：同一条横扫线，展开后相邻亮度差降到 17%。

推论：模糊到位。工作台此前的问题不在模糊，在亮度。

置信度：高

关联：`#124` 证据 7

### E-16：底板的传递曲线

来源等级：D
环境：macOS 27.0.1（26A434），浅色外观，满量程黑白渐变垫在面板背后。

方法：桌面亮度分箱，量每个箱里面板的平均亮度，做最小二乘。
模型的斜率就是底材的有效透光比例，与桌面内容无关。
条纹残留另测：把一块高频条纹垫在板背后，量相邻行的平均亮度差。
残留 0% 表示板把条纹全糊平，91% 表示条纹原样透上来。

命令或来源：

```sh
swift plates4.swift 20 120 1200 900
swift cells.swift p4.png 300 1950 40 242 442,832 844,1234 ...
```

关键输出：

| 底材 | 传递曲线 | 条纹残留 |
| --- | --- | --- |
| 控制中心底板 | 0.95·桌面 + 0.4 | 2% |
| `Glass.clear` | 0.59·桌面 + 89 | 0% |
| `.ultraThinMaterial` | 0.53·桌面 + 98 | 0% |
| `.thinMaterial` | 0.39·桌面 + 133 | 0% |
| `.regularMaterial` | 0.34·桌面 + 150 | 0% |

观察：控制中心底板的透光比例是 0.95，几乎是一层纯模糊。
公开材质会模糊，但透光最高只有 0.59，而且都带填充。

推论：控制中心的底板与公开材质不是同一类东西。这条差距见 `E-22`。

反证：无。斜率与桌面内容无关，换壁纸不影响比较。

置信度：高

关联：`#124` 证据 8，`E-22`

### E-17：模糊与填充由同一个旋钮定

来源等级：A（推导）加 D（实测）
环境：同 `E-16`。

推导：对材质层乘一个不透明度 `p` 以后，斜率 = `1 − p(1−α)`，
截距 = `p(1−α)F`，模糊比例 = `p`。
三式消掉 `p` 得 `c = F·(1 − s)`，所以填充只由斜率定。

关键输出，`.ultraThinMaterial` 的 `p` 扫描：

| p | 传递曲线 | 条纹残留 |
| --- | --- | --- |
| 1.0 | 0.53·桌面 + 98 | 0% |
| 0.5 | 0.77·桌面 + 49 | 50% |
| 0.2 | 0.89·桌面 + 23 | 80% |
| 0.1 | 0.94·桌面 + 12 | 90% |

在真实应用上复测（面板左边距像素 776..812，面板外桌面恒为 165.2 作对照）：

| p | 板左边距亮度 |
| --- | --- |
| 1.0 | 230.8 |
| 0.5 | 236.3 |
| 0.2 | 239.8 |
| 0.1 | 241.1 |
| 0.0 | 242.5 |

观察：`p` 越小，板越接近桌面，**同时**糊得越轻。
要拿到控制中心的斜率 0.95，`p` 只能取 0.106，模糊也就只剩 10.6%。
在用户桌面上，`p = 1.0` 给出的 230.8 与控制中心的 `0.95 × 242.5 + 0.4 = 230.8` 数值相同 —— 差的是斜率，不是亮度。

推论：**模糊与可见度不可分开设。** 这是公开接口上真正的墙。

置信度：高

关联：`#124` 证据 9

### E-18：`NSGlassEffectView` 的私有 `variant` 复现不出控制中心

来源等级：B（运行时反射）加 D（实测）

一份外部技术文档主张 `NSGlassEffectView.Style` 有一个私有的 `ControlCenter = 8`，
能拿到控制中心的材质。本机验证不成立。

命令或来源：

```sh
swift glassapi.swift
swift glassvar2.swift 20 120 1200 900
```

关键输出：

- 公开 setter：`Style(rawValue:)` 对 0 到 20 都能构造，但赋给 `style` 以后 rawValue 2 到 9 全部按 `.regular` 渲染，传递曲线逐字节相同。公开 setter 忽略未公开取值。
- 私有 `_variant`：属性存在（`_variant` 与 `set_variant:`，类型 `Tq`），赋值也确实改变渲染。v8 的结果与 `.clear` 完全一致；v0 与 v1 等于 regular；v2 到 v5、v7 到 v9 等于 clear；v11、v13、v14 什么都不画（相邻像素差 63.28，裸条纹 63.36）；v6 是 0.93·桌面 − 29；v16 到 v18 是 0.41·桌面 + 138。

推论：**没有一档给出「满量程模糊加近零填充」。** 私有取值也到不了控制中心。

置信度：高

关联：`#124` 证据 10

### E-19：非 Key 面板的镜面亮边可以补（待复测）

来源等级：B（反射）加 D（实测，只测到一次）

同一份外部文档主张：镜面亮边只给活跃应用的 Key 窗口，非 Key 面板拿不到；
覆盖 `NSWindow` 的私有 `_hasActiveAppearance()` 返回 `true` 可以拿到。

命令或来源：

```sh
swift keyapi.swift
swift rimtest.swift
```

关键输出：并排放两个 `.nonactivatingPanel`，内容都是 `NSGlassEffectView(.regular)`，
压在同一张渐变上，只有一个差别是覆盖钩子：

| 位置 | 普通 NSPanel | 覆盖 `_hasActiveAppearance` |
| --- | --- | --- |
| 上边缘 | 227.9 | 253.7 |
| 内部 | 191.7 | 209.6 |

两块板都全糊（相邻像素差 0.00）。覆盖钩子把上边缘抬 25.8 级、内部抬 17.9 级。

限制：**只测到一次，屏幕随后锁定，没有复测传递曲线。**
工作台的面板是 `.nonactivatingPanel`，这条如果成立就能补上亮边。

置信度：中

关联：`#124` 证据 11

### E-20：AppKit 底衬层的配方

来源等级：B（运行时反射）

从 `NSVisualEffectView` 的图层树里读出 AppKit 自己那套底衬层。

命令或来源：

```sh
swift layerdump.swift    # 写 /tmp/layerdump.txt
swift filterdump.swift   # 写 /tmp/filterdump.txt
```

关键输出：

```text
CABackdropLayer
  windowServerAware = 1
  groupName = NSCGSWindowBehindWindowCaptureBackdropGroup
  scale = 0.125
  filters = sdrNormalize
            gaussianBlur(inputRadius=30, inputNormalizeEdges=1, inputQuality=default)
            colorSaturate(inputAmount=1.9)
```

观察：这一套滤镜里**没有着色滤镜**。
AppKit 的白色填充来自底衬层上面那几个 `CALayer` 与 `CAChameleonLayer`。

推论：照抄底衬层、去掉上面那几层，理论上应该得到纯模糊。实测见 `E-21`。

置信度：高

关联：`#124` 证据 12，`E-21`

### E-21：手搭 `CABackdropLayer` 的实测

来源等级：D
环境：macOS 27.0.1（26A434），浅色外观。
按 `E-20` 的配方手搭一个 `CABackdropLayer`，去掉上面的着色层。
仪器同 `E-16`：一张图同时给出传递曲线与条纹残留。

命令或来源：

```sh
swift plates7.swift 20 120 1200 900 "null,raw,bd0,bd20,bd80"
swift cells.swift p7.png 300 1950 40 430 442,832 844,1234 1246,1636 1648,2038
```

关键输出：

| 层 | 传递曲线 | 透光 α | 填充色 F | 条纹残留 |
| --- | --- | --- | --- | --- |
| 裸 `CABackdropLayer`，不带滤镜 | 0.61·桌面 + 55 | 0.61 | 140 | 44% |
| 同上，`gaussianBlur` 半径 0 / 20 / 80 | 0.61·桌面 + 55 | 0.61 | 140 | 44% |
| 同图里的 `NSVisualEffectView(.hudWindow)` 作对照 | — | — | — | 0% |

观察一：底衬层自己就带填充（`F = 140`）。
观察二：半径取 0、20、80，三格与不带滤镜那一格逐字节相同 ——
这个层一旦加入窗口服务器的底衬组，模糊由窗口服务器做，层上的 `filters` 不再影响结果。
观察三：同图里的系统材质把条纹全糊平（残留 0%），这个层还剩 44%。

推论：**换私有接口买不到控制中心的效果。**
透光 0.61 到不了 0.95，填充 140 也压不到 8。

反证：第一次测量把半径 0、20、80 量成了三组不同的值（0.42 / 0.43 / 0.43）。
那一次的前一轮探针没有被杀掉，两个探针窗口叠在同一位置。
清掉残留进程以后重跑两次，结果逐字节一致。

置信度：高

关联：`#124` 证据 12，`E-20`

### E-22：`NSVisualEffectView` 材质全扫

来源等级：D
环境：macOS 27.0.1（26A434），浅色与深色外观各一遍。
仪器同 `E-16`。第一格是裸条纹，当背景真值。

命令或来源：

```sh
M="null,hudWindow,selection,popover,sidebar,headerView,sheet,toolTip,titlebar,menu,fullScreenUI,contentBackground,underWindowBackground"
swift plates6.swift 20 120 1200 900 mat     "$M"
swift plates6.swift 20 120 1200 900 matdark "$M"
```

关键输出：

| 材质 | 浅色传递曲线 | α | F | 深色传递曲线 | α | F |
| --- | --- | --- | --- | --- | --- | --- |
| `.selection` | 0.93·桌面 − 6 | 0.93 | −93 | 0.90·桌面 + 33 | 0.90 | 337 |
| `.hudWindow` | 0.25·桌面 + 149 | 0.25 | 200 | 0.29·桌面 + 57 | 0.29 | 81 |
| `.fullScreenUI` | 0.25·桌面 + 149 | 0.25 | 200 | 0.24·桌面 + 55 | 0.24 | 72 |
| `.popover` | 0.20·桌面 + 169 | 0.20 | 210 | 0.20·桌面 + 52 | 0.20 | 65 |
| `.menu` | 0.14·桌面 + 189 | 0.14 | 220 | 0.15·桌面 + 49 | 0.15 | 58 |
| `.titlebar` | 0.10·桌面 + 208 | 0.10 | 231 | 0.10·桌面 + 62 | 0.10 | 68 |
| `.headerView` | 0.10·桌面 + 218 | 0.10 | 243 | 0.10·桌面 + 40 | 0.10 | 44 |
| `.sidebar` | 0.06·桌面 + 211 | 0.06 | 225 | 0.10·桌面 + 47 | 0.10 | 52 |
| `.toolTip` | 0.06·桌面 + 211 | 0.06 | 225 | 0.10·桌面 + 47 | 0.10 | 52 |
| `.underWindowBackground` | 0.06·桌面 + 211 | 0.06 | 225 | 0.10·桌面 + 47 | 0.10 | 52 |
| `.sheet` | 0.00·桌面 + 255 | 0.00 | 255 | 0.00·桌面 + 33 | 0.00 | 33 |
| `.contentBackground` | 0.00·桌面 + 255 | 0.00 | 255 | 0.00·桌面 + 33 | 0.00 | 33 |

条纹残留：只有 `.selection` 不糊（浅色 93%、深色 90%），其余全部 0% 到 1%。

观察：**会模糊的材质，透光都不超过 0.29；
唯一透光到 0.90 以上的 `.selection`，根本不模糊。**
深色外观的填充色低得多（33 到 81），但透光同样低。

推论：公开材质里不存在「高透光加满量程模糊」。
两条路都到不了控制中心的底板。

反证：无。浅色与深色两轮各跑一次，`E-16` 里的 `.ultraThinMaterial` 与 `.clear` 由另一套探针独立得出，量级一致。

限制：`F` 是 `截距 ÷ (1 − α)` 外推出来的，`α` 接近 1 时误差放大。
`.selection` 的 `F` 是负数，说明它的模型不是「模糊加填充」，只是一层透明着色。

置信度：高

关联：`#124` 证据 13，`E-16`，`E-21`

### E-23：AppKit 要求用语义材质，不用固定外观的材质

来源等级：A
环境：macOS 27.0 SDK，`AppKit.framework/Headers/NSVisualEffectView.h`。

命令或来源：

```sh
H=$(xcrun --show-sdk-path)/System/Library/Frameworks/AppKit.framework/Headers/NSVisualEffectView.h
grep -n "API_DEPRECATED\|instead choose\|semantic material\|hudWindow" "$H"
```

关键输出：

```objc
/// A default material appropriate for the view's effectiveAppearance.  You should instead choose an appropriate semantic material.
NSVisualEffectMaterialAppearanceBased API_DEPRECATED("Use a specific semantic material instead.", macos(10.10, 10.14)) = 0,

// Materials with specific looks.  You should instead choose an appropriate semantic material.
NSVisualEffectMaterialLight API_DEPRECATED(...) = 1,
NSVisualEffectMaterialDark API_DEPRECATED(...) = 2,
NSVisualEffectMaterialMediumLight API_DEPRECATED(...) = 8,
NSVisualEffectMaterialUltraDark API_DEPRECATED(...) = 9,
```

未废弃的材质按所属界面元素命名并说明：

| 材质 | 头文件说明 |
| --- | --- |
| `.popover` | The material used in the background of popovers. |
| `.sidebar` | The material used in the background of window sidebars. |
| `.sheet` | The material used as the background of sheet windows. |
| `.hudWindow` | The material used as the background of heads-up display (HUD) windows. |
| `.fullScreenUI` | The material used as the background of full-screen modal UI. |

观察：**固定外观的那一组（`AppearanceBased`、`Light`、`Dark`、`MediumLight`、`UltraDark`）在 macOS 10.14 就被废弃。**
头文件要求改用语义材质。
剩下的材质全部按所属界面元素命名。

推论：工作台面板浮在桌面上，对应 `.hudWindow`。
底材走 `NSVisualEffectView` 加 `.hudWindow`，材质原样使用。
SwiftUI 的 `Material` 只有 `ultraThin` 到 `ultraThick` 和 `bar`，没有面板这一档。

反证：无。这是 SDK 头文件的原文。

限制：头文件只给用法，不给取值。
`.hudWindow` 的透光 0.25 来自 `E-22` 的实测。

置信度：高

关联：`E-22`，`E-17`

## 5. 逻辑证据链

```text
研究问题：控制中心的内容按钮由哪些可复现的取值构成？
  -> 来源 D：控制中心打开时的全屏截图
  -> 观察 E-01 到 E-05：几何、边、缝、层级、填充
  -> 推论：模块由细亮边、接近桌面亮度的半透明填充、无底板、0.39 的圆角比例定义
  -> 决策：玻璃下放到每张卡片，填充取半透明材质
  -> 验证条件：用户在真机上目视确认表现一致
  -> 回填位置：validation/case-control-center-parity.md

研究问题：工作台用哪些公开 API 能复现同一套表现？
  -> 来源 A：macOS 27.0 SDK 的 Swift 接口文件
  -> 观察 E-06：glassEffect、Glass.clear、GlassEffectContainer 自 macOS 26 起可用
  -> 推论：.clear 是公开 API 里最淡的一档
  -> 决策：底材取 .clear，保留材质降级路径
  -> 来源 D：E-13 的真机对照
  -> 观察 E-13：控制中心模糊，.clear 不模糊
  -> 推论：决定能不能看清的是模糊，不是填充重量
  -> 决策：底材改成 .regular
  -> 验证条件：四个底材取值都能起，界面不崩
  -> 回填位置：validation/case-control-center-parity.md

研究问题：工作台此前为什么看不到模糊？
  -> 来源 B：Covio 仓库分支 feature/shell-match-preview
  -> 观察 E-07、E-08、E-09：玻璃零调用、材质令牌没组件用、填充不透明
  -> 推论：不透明填充盖住了玻璃的模糊
  -> 决策：填充换半透明材质，玻璃接到每张卡片
  -> 验证条件：卡片之间没有填充，卡片内部有模糊
  -> 回填位置：validation/case-control-center-parity.md

研究问题：控制中心的层级到底是什么？
  -> 来源 D：E-14 的矩形均亮对照
  -> 观察 E-14：模块缝比桌面暗 8 级，模块内只亮 8 到 26 级，面板整片亮 13 级
  -> 观察 E-15：面板内的相邻亮度差降到 17%，模糊到位
  -> 推论：观察一（E-04「没有容器底板」）不成立。模糊来自一层铺满面板的底板
  -> 决策：底板加回来，卡片叠在底板上

研究问题：底板取哪个底材？
  -> 来源 D：E-16 的传递曲线
  -> 观察 E-16：控制中心底板 0.95·桌面 + 0.4，公开材质透光最高 0.59 且都带填充
  -> 来源 A + D：E-17 的推导与 p 扫描
  -> 观察 E-17：模糊与填充由同一个旋钮定，不能分开设
  -> 推论：控制中心的「满量程模糊加近零填充」在公开材质上取不到
  -> 来源 B + D：E-18 的私有 variant，E-20 与 E-21 的私有底衬层
  -> 观察 E-18、E-21、E-22：私有取值、私有底衬层、全部公开材质都到不了
  -> 推论：这条差距关不掉，只能在这条线上选一点
  -> 决策：取 `.ultraThinMaterial` 加 `plateOpacity = 1.0`，选模糊不选齐平
  -> 验证条件：用户在真机上目视确认接受
  -> 回填位置：validation/case-control-center-parity.md

研究问题：底材用哪个公开接口？
  -> 来源 A：E-23 的 AppKit 头文件
  -> 观察 E-23：固定外观的材质组在 macOS 10.14 废弃，头文件要求改用语义材质
  -> 推论：面板底材应当走 `NSVisualEffectView` 加语义材质
  -> 来源 D：E-22 的材质全扫
  -> 观察 E-22：会模糊的材质透光都不超过 0.29，其中 `.hudWindow` 最高
  -> 决策：底材取 `.hudWindow`，材质原样使用，删掉 `plateOpacity`
  -> 验证条件：真机上底板有模糊，桌面颜色透上来，文字可读
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

### 6.5 底材的对照已补齐

`.clear` 最初的选择依据是 `.regular` 偏重，没有像素级的对照数据。
`E-13` 补齐了对照，结论反过来：`.clear` 不模糊，不能用。

### 6.6 观察一被推翻

`E-04` 由官方宣传图的像素扫描得出，结论是「模块之间没有填充，只有模糊」。
`E-14` 用同一次会话内的矩形均亮对照推翻了这一条：
模块缝比桌面**暗** 8 级，缝里不是桌面，是一层底板。
宣传图是压缩过的，且没有展开态与收起态的对照，不适合用来判定层级。
`E-04` 的几何结论（缝宽）仍然成立，层级结论作废。

### 6.7 残留进程会污染探针

`E-21` 的第一次测量出现三组不同的值，原因是前一轮探针没有被杀掉，
两个探针窗口叠在同一位置。
探针脚本必须先 `pkill`，再确认新进程活着，然后才截图。
两次重跑结果逐字节一致才算数。

## 7. 已知缺口

1. 模糊的强度在 `E-13` 里只判定有与没有。`E-16` 起改用传递曲线与条纹残留量化，已补齐。
2. 浅色外观下的控制中心截图已补（2026-10-17）：浅底板加深色文字，见 `conclusion.md` 第 6 节。
3. 没有减弱动态效果下的控制中心截图。
4. 没有「玻璃在无边框透明面板里画不出来」的失败样本。
5. 采样脚本没有随仓库分发。
6. 控制中心的取值没有跨系统版本的对比。macOS 26 与 macOS 27 的差异未测。
7. 设计合同 `component/material` 的文本与实现不一致。本次改动没有回填合同。
8. 缝里的模糊来自模块本身还是面板背板，已区分：来自面板背板，见 `E-14`。
9. `E-19` 只测到一次，没有复测传递曲线。
10. `E-22` 的 `F` 是外推值，`α` 接近 1 时误差放大。`.selection` 的 `F` 为负，说明它不属于这个模型。

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
