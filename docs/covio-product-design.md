# Covio — Product Design

## 状态

- 本文档记录 Figma 侧的视觉基准与设计原则。
- 界面取值的权威是 `macosApp/src/Design/` 下的 Swift 代码。
- `docs/covio-product-master.md` 管产品行为。
- `Covio — Product Design · macOS 27` 是视觉基准。
- Figma 文件 key 是 `Bktv2SGgjcHuUZ7KJXEkPx`。
- 源库是 `macOS 27 (Community)`。源库 key 是 `Sh6AKZJPJXTf3GxM0mvBjj`。
- 源库 URL 是 https://www.figma.com/design/Sh6AKZJPJXTf3GxM0mvBjj/macOS-27--Community- 。
- 源库的 42 个页面全部保留。源页面内容不修改。
- 交付页面有 8 个。交付画板有 35 个。
- 交付页面只使用浅色模式。源页面中的深色变体保留。
- 交付页面使用来源组件。来源组件缺失时，允许自绘缺失控件。
- 本次不修改 Kotlin UI。公共 API、配置模型和运行时行为保持不变。

| 项目 | 数量 |
| --- | --- |
| 页面总数 | 50 |
| 源页面 | 42 |
| 交付页面 | 8 |
| 交付 Section | 8 |
| 顶层画板 | 35 |
| 组件角色 | 22 |
| 源组件集 | 130 |
| 组件节点 | 186 |
| 变量 | 147 |
| 文字样式 | 22 |
| 交付文字节点 | 1259 |
| 自绘系统控件 | 0 |

### 文档链

| 层级 | 文件 | 职责 |
| --- | --- | --- |
| 产品行为 | `docs/covio-product-master.md` | 产品行为、范围和优先级 |
| 界面取值与文案 | `macosApp/src/Design/` | 颜色、间距、取值与全部文案 |
| 界面打样 | `designPreview/` | 目标画面，评审用 |
| 视觉基准 | `Covio — Product Design · macOS 27` | Figma 侧的画面与组件 |
| 迁移记录 | `docs/covio-macos-swiftui-migration-plan.md` | macOS 界面层换用 SwiftUI 的历史记录 |

- 冲突顺序是安全与无障碍、产品行为、界面打样、Swift 实现、Figma 视觉基准。

## 设计原则

- 产品先显示状态，再显示操作。
- 交互控件优先使用 `macOS 27 (Community)` 来源组件。
- 来源组件存在时，禁止自绘替代品。
- 禁止分离来源组件实例。分离实例数量是 `0`。
- 禁止直接修改实例内部文字。实例文字通过组件属性设置。
- 窗口内容放入 `Windows - Composed` 的 `Content Area` Slot。
- 品牌图形只用于品牌识别。Covio 数据只用于产品内容。
- 菜单、弹窗、Popover、Alert 和 Sheet 使用原生来源组件。
- 风险动作使用警告色和清晰后果。
- 颜色不单独表达状态。文字或图标同时表达状态。
- Figma UI 文案只使用英文。Markdown 文档使用中文。
- Figma 文字使用 `SF Pro`。交付页面不使用 `Inter`。
- Figma 画布不限制节点扩展。Section 右侧和底部保留 `120` 扩展区。
- 组件和画板读取来源变量。

## 来源优先边界

组件复用顺序如下：

1. 实例化完全匹配的来源变体。
2. 使用同一来源组件集的最接近变体。
3. 组合多个来源组件。
4. 自绘来源库缺失的控件。
5. 自绘控件绑定来源变量。
6. 自绘文字使用 `SF Pro`。
7. 记录自绘原因。
8. 重复出现的自绘控件建立本地组件。
9. 单次出现的自绘控件使用组合框。

| 合同角色 | 原生来源 | 复用模式 | 品牌自定义 |
| --- | --- | --- | --- |
| `component/window-bar` | Windows - Composed、Window BG、Window Titles/Window、Window Controls/Standard | 来源组合 | 否 |
| `component/page-title` | Auto Layout、SF Pro、原生控件 | 来源缺口 | 否 |
| `component/tab-bar` | Segmented Control | 完全匹配来源 | 否 |
| `component/card` | Materials | 完全匹配来源 | 否 |
| `component/setting-row` | Auto Layout、SF Pro、原生控件 | 来源缺口 | 否 |
| `component/switch` | Toggles - Switches | 完全匹配来源 | 否 |
| `component/number-field` | Text Field、Stepper/Inside Field | 来源组合 | 否 |
| `component/segmented` | Segmented Control | 完全匹配来源 | 否 |
| `component/button` | Buttons | 完全匹配来源 | 否 |
| `component/badge` | SF Pro、源状态色 | 来源缺口 | 否 |
| `component/alert` | Alert | 完全匹配来源 | 否 |
| `component/dialog` | Sheet、Alert、Windows - Composed | 来源组合 | 否 |
| `component/toast` | Notification | 完全匹配来源 | 否 |
| `component/screenshot-card` | Materials、Covio/Content/Screenshot Card | 来源与品牌混合 | 是 |
| `component/tray-menu-item` | Menu Items | 完全匹配来源 | 否 |
| `component/clothespin` | Covio/Brand/Clothespin | 来源缺口 | 是 |
| `component/tray-icon` | Covio/Brand/Tray Icon | 来源缺口 | 是 |
| `component/tray-menu` | Menu Background、Menu Items、Headers、Separators | 来源组合 | 否 |
| `component/material` | Materials、Liquid Glass - Large/Medium/Small | 来源组合 | 否 |
| `component/window-shell` | Windows - Composed、Sidebars - Composed、Toolbars/Button | 来源组合 | 否 |
| `component/toolbar` | Toolbars/Button、Button Group、Pull Down Button、Pop-Up Button、Search | 来源组合 | 否 |
| `component/popover` | Popover | 完全匹配来源 | 否 |

### 复用模式

- `exact-source` 表示使用完全匹配的来源组件。
- `source-variant` 表示使用同一来源组件集的适配变体。
- `source-composition` 表示组合多个来源组件。
- `custom-gap` 表示来源组件集缺失。组合布局可以补齐缺口。
- `mixed` 表示来源材质和 Covio 品牌内容组合。

### 自定义边界

- 品牌自定义组件是 `Covio/Brand/Tray Icon`、`Covio/Brand/Clothespin` 和 `Covio/Content/Screenshot Card`。
- `trayIconVariants` 只引用 `Covio/Brand/Tray Icon`。
- 自绘系统控件总数是 `0`。
- `component/page-title`、`component/setting-row` 和 `component/badge` 是 `custom-gap` 组合角色。
- 组合角色使用 Auto Layout、`SF Pro` 和来源控件。组合角色不复制系统控件外观。
- 源组件名称保持不变。Covio 不把来源组件重命名为 `Covio/...`。
- 禁止复制旧文件中的 `Covio/...` 系统控件组件集。

## Figma 文件结构

### 交付页面

| 交付页面 | 页面 ID | Section ID | 画板数量 |
| --- | --- | --- | --- |
| `Covio 01 · Product Overview` | `8303:68461` | `8303:68469` | 3 |
| `Covio 02 · First Run & Pairing` | `8303:68462` | `8303:68470` | 5 |
| `Covio 03 · Transfer` | `8303:68463` | `8303:68471` | 5 |
| `Covio 04 · Clipboard & Files` | `8303:68464` | `8303:68472` | 4 |
| `Covio 05 · Screenshots & Top Shelf` | `8303:68465` | `8303:68473` | 6 |
| `Covio 06 · Menu Bar & Notch Hub` | `8303:68466` | `8303:68474` | 6 |
| `Covio 07 · Power & Settings` | `8303:68467` | `8303:68475` | 5 |
| `Covio 08 · Prototype Map` | `8303:68468` | `8303:68476` | 1 |

### Section 实际尺寸

| 页面与 Section | Section ID | 尺寸 |
| --- | --- | --- |
| Covio 01 · Product Overview | `8303:68469` | `5280×1140` |
| Covio 02 · First Run & Pairing | `8303:68470` | `3560×2940` |
| Covio 03 · Transfer | `8303:68471` | `3560×2920` |
| Covio 04 · Clipboard & Files | `8303:68472` | `3560×1880` |
| Covio 05 · Screenshots & Top Shelf | `8303:68473` | `3560×3180` |
| Covio 06 · Menu Bar & Notch Hub | `8303:68474` | `3560×3180` |
| Covio 07 · Power & Settings | `8303:68475` | `3560×2980` |
| Covio 08 · Prototype Map | `8303:68476` | `1840×1140` |

### 画板清单

| 画板 | 页面 | 本地位置 | 尺寸 | 主题 |
| --- | --- | --- | --- | --- |
| `00 · Brand Cover` | Covio 01 · Product Overview | `[120,120]` | `1600×900` | Light |
| `01 · Product Promise` | Covio 01 · Product Overview | `[1840,120]` | `1600×700` | Light |
| `02 · Core Loop Map` | Covio 01 · Product Overview | `[3560,120]` | `1600×900` | Light |
| `03 · Welcome & Mode Choice` | Covio 02 · First Run & Pairing | `[120,120]` | `1600×520` | Light |
| `04 · Permissions & Discovery` | Covio 02 · First Run & Pairing | `[1840,120]` | `1600×520` | Light |
| `05 · Pairing Code` | Covio 02 · First Run & Pairing | `[120,1140]` | `1600×535` | Light |
| `06 · Pairing Confirmation & Success` | Covio 02 · First Run & Pairing | `[1840,1140]` | `1600×635` | Light |
| `07 · Pairing Error & Recovery` | Covio 02 · First Run & Pairing | `[120,2160]` | `1600×675` | Light |
| `08 · File Selection` | Covio 03 · Transfer | `[120,120]` | `1600×435` | Light |
| `09 · Transfer Setup & Readiness` | Covio 03 · Transfer | `[1840,120]` | `1600×575` | Light |
| `10 · Transfer Progress & Pause` | Covio 03 · Transfer | `[120,1140]` | `1600×455` | Light |
| `11 · Transfer Complete` | Covio 03 · Transfer | `[1840,1140]` | `1600×605` | Light |
| `12 · Transfer Error & Recovery` | Covio 03 · Transfer | `[120,2160]` | `1600×655` | Light |
| `13 · Clipboard History` | Covio 04 · Clipboard & Files | `[120,120]` | `1600×485` | Light |
| `14 · Clipboard Detail & Send` | Covio 04 · Clipboard & Files | `[1840,120]` | `1600×595` | Light |
| `15 · Temporary Files & Cleanup` | Covio 04 · Clipboard & Files | `[120,1140]` | `1600×475` | Light |
| `16 · Clipboard & Files Errors` | Covio 04 · Clipboard & Files | `[1840,1140]` | `1600×635` | Light |
| `17 · Screenshot Received` | Covio 05 · Screenshots & Top Shelf | `[120,120]` | `1600×900` | Light |
| `18 · Screenshot Preview & Actions` | Covio 05 · Screenshots & Top Shelf | `[1840,120]` | `1600×835` | Light |
| `19 · Screenshot Drag Destinations` | Covio 05 · Screenshots & Top Shelf | `[120,1140]` | `1600×900` | Light |
| `20 · Top Shelf Empty` | Covio 05 · Screenshots & Top Shelf | `[1840,1140]` | `1600×900` | Light |
| `21 · Top Shelf Populated` | Covio 05 · Screenshots & Top Shelf | `[120,2160]` | `1600×900` | Light |
| `22 · Top Shelf Context & Drop` | Covio 05 · Screenshots & Top Shelf | `[1840,2160]` | `1600×900` | Light |
| `23 · Menu Bar & Tray` | Covio 06 · Menu Bar & Notch Hub | `[120,120]` | `1600×900` | Light |
| `24 · Tray Menu` | Covio 06 · Menu Bar & Notch Hub | `[1840,120]` | `1600×900` | Light |
| `25 · Hub Collapsed & Ready` | Covio 06 · Menu Bar & Notch Hub | `[120,1140]` | `1600×900` | Light |
| `26 · Hub Expanded Output` | Covio 06 · Menu Bar & Notch Hub | `[1840,1140]` | `1600×900` | Light |
| `27 · Hub Tabs` | Covio 06 · Menu Bar & Notch Hub | `[120,2160]` | `1600×900` | Light |
| `28 · Hub Error & Recovery` | Covio 06 · Menu Bar & Notch Hub | `[1840,2160]` | `1600×900` | Light |
| `29 · Settings Overview & General` | Covio 07 · Power & Settings | `[120,120]` | `1600×575` | Light |
| `30 · Settings Battery` | Covio 07 · Power & Settings | `[1840,120]` | `1600×605` | Light |
| `31 · Settings Lid` | Covio 07 · Power & Settings | `[120,1140]` | `1600×655` | Light |
| `32 · Settings Idle` | Covio 07 · Power & Settings | `[1840,1140]` | `1600×575` | Light |
| `33 · Settings Top Shelf & About` | Covio 07 · Power & Settings | `[120,2160]` | `1600×715` | Light |
| `34 · End-to-End Prototype Map` | Covio 08 · Prototype Map | `[120,120]` | `1600×900` | Light |

- 每个画板展示一个真实产品场景。
- 每个画板使用 Auto Layout。画板高度由内容决定。
- 画板起点是 `[120,120]`。画板间距是 `120`。
- 画板宽度是 `1600`。只有 `08 · File Selection` 高度是 `435`。
- 画板名称和合同 `figmaNodeMap.boards` 一致。

## 变量与字体

| 变量集合 | 数量 | 模式 | 权威来源 |
| --- | --- | --- | --- |
| Colors | 63 | Light、Dark | macOS 27 (Community) |
| Sizes | 65 | Default | macOS 27 (Community) |
| Kit | 18 | Light、Dark | macOS 27 (Community) |
| Context | 1 | Default | macOS 27 (Community) |

- 变量总数是 `147`。
- 颜色和尺寸优先绑定来源变量。
- 新增 Covio 品牌变量只保存来源库没有的品牌值。
- 交付页面使用 `SF Pro`。
- 文字样式总数是 `22`。
- 交付文字节点总数是 `1259`。
- 缺失字体数量是 `0`。
- 交付页面不含中文界面文案。
- 交付页面不使用 `Title 2/Emphasized`。来源样式的字体问题是已知限制。

## 产品页面规格

### `Covio 01 · Product Overview`

- `00 · Brand Cover` 展示品牌封面、产品名称和入口。
- `01 · Product Promise` 说明核心价值、目标设备和主要场景。
- `02 · Core Loop Map` 展示发现、配对、传输、截图、置物架和设置路径。

### `Covio 02 · First Run & Pairing`

- `03 · Welcome & Mode Choice` 展示首次启动和模式选择。
- `04 · Permissions & Discovery` 展示权限说明和设备发现。
- `05 · Pairing Code` 展示 6 位配对码输入。
- `06 · Pairing Confirmation & Success` 展示确认和成功结果。
- `07 · Pairing Error & Recovery` 展示配对码错误、网络错误和恢复动作。

### `Covio 03 · Transfer`

- `08 · File Selection` 展示文件选择和发送入口。
- `09 · Transfer Setup & Readiness` 展示目标设备、文件名、大小和开始动作。
- `10 · Transfer Progress & Pause` 展示进度、暂停、继续和取消。
- `11 · Transfer Complete` 展示完成结果、位置和后续动作。
- `12 · Transfer Error & Recovery` 展示网络中断、空间不足和重试动作。

### `Covio 04 · Clipboard & Files`

- `13 · Clipboard History` 展示剪切板历史、搜索和条目状态。
- `14 · Clipboard Detail & Send` 展示内容详情、预览和发送。
- `15 · Temporary Files & Cleanup` 展示保留时间、空间上限和清理。
- `16 · Clipboard & Files Errors` 展示读取失败、空间不足和恢复动作。

### `Covio 05 · Screenshots & Top Shelf`

- `17 · Screenshot Received` 展示截图到达和即时反馈。
- `18 · Screenshot Preview & Actions` 展示预览、复制、标记、拖放和删除。
- `19 · Screenshot Drag Destinations` 展示应用、文件夹和废纸篓目标。
- `20 · Top Shelf Empty` 展示空状态和捕获说明。
- `21 · Top Shelf Populated` 展示多项内容、置顶和排序。
- `22 · Top Shelf Context & Drop` 展示右键菜单、拖放和完成状态。

### `Covio 06 · Menu Bar & Notch Hub`

- `23 · Menu Bar & Tray` 展示状态项和菜单栏入口。
- `24 · Tray Menu` 展示原生菜单、Top Shelf、Settings 和 About。
- `25 · Hub Collapsed & Ready` 展示 Hub 收起和就绪状态。
- `26 · Hub Expanded Output` 展示 Hub 展开和输出状态。
- `27 · Hub Tabs` 展示 Now、Screenshots、Clipboard、Files、Devices 和 Settings。
- `28 · Hub Error & Recovery` 展示 Hub 错误、重试和菜单栏回退。

### `Covio 07 · Power & Settings`

- `29 · Settings Overview & General` 展示总开关、助手状态和常规设置。
- `30 · Settings Battery` 展示低电量阈值和剩余时间阈值。
- `31 · Settings Lid` 展示合盖行为和例外规则。
- `32 · Settings Idle` 展示空闲睡眠和保持唤醒规则。
- `33 · Settings Top Shelf & About` 展示置物架设置、版本和 About。

### `Covio 08 · Prototype Map`

- `34 · End-to-End Prototype Map` 记录主路径和异常恢复路径。
- 离屏品牌组件是 `Covio/Brand/Tray Icon`、`Covio/Brand/Clothespin` 和 `Covio/Content/Screenshot Card`。

## 原型

- 原型 edges 总数是 `42`。
- 原型 reactions 总数是 `42`。
- 必需 reactions 是 `42`。缺失 reactions 是 `0`。
- 含 reactions 的画板有 `33` 个。
- 主路径是 `00 → 01 → 02 → 03 → 04 → 05 → 06 → 08 → 09 → 10 → 11 → 13 → 17 → 18 → 20 → 25 → 29`。
- 配对错误由 `07` 返回 `05` 或 `06`。
- 传输错误由 `12` 返回 `09`。
- 剪切板错误由 `16` 返回 `13`。
- Tray Menu 连接 Top Shelf、Settings 和 About。
- Settings 页面通过 Tab 控件互联。
- Hub 按 `25 → 26 → 27` 展开。
- Hub 错误由 `28` 返回 `25` 或 `27`。
- 菜单、弹窗、Popover、Alert 和 Sheet 使用 `DISSOLVE`。
- 拖放使用 `On drag`。About 延迟使用 `After delay`。
- `14 · Clipboard Detail & Send`、`15 · Temporary Files & Cleanup` 和 `34 · End-to-End Prototype Map` 是孤立画板。
- 跨页 reactions 不在 Figma 演示模式运行。页内 reactions 可以运行。

## Compose 映射

- Compose 是打样的运行时。
- 来源组件提供 Figma 视觉基准。
- 打样保留现有公共 API、配置模型、数据类型和运行时行为。
- 状态、键盘、VoiceOver 和减弱动态效果由运行时验证。
- 设计修改先改共享取值，再改组件。

## SwiftUI 映射

macOS 0.5.0 起，macOS 界面用原生 SwiftUI 与 AppKit。
Compose 保留给打样与未来的 Windows 与 Android 宿主。

- 颜色与间距在 `macosApp/src/Design/MacTheme.swift`。
- 半径、间距与动效时长在 `macosApp/src/Design/Tokens.swift`。
- 文案在 `macosApp/src/Design/Copy.swift`，中英各一份。
- 状态机在 `macosApp/src/NotchShell/HubStateMachine.swift`。
- 动效时长取自 `docs/covio-product-master.md` 第 6.4 节。

**规则：** 改界面取值就改上面三个文件。没有上游文件需要同步。

## 修改流程

1. 改界面时先出打样，见 `docs/design/design-preview.md`。
2. 评审通过后改 `macosApp/src/Design/` 下的取值或文案。
3. 需要时同步更新 Figma 页面、画板、组件或变量。
4. 使用 Talk to Figma 插件读取实时节点。
5. 运行 `node .git/covio-figma/proto_status.mjs`。
6. 运行 `node .git/covio-figma/verify_text.mjs`。
7. 更新本文档。
8. 运行 `git diff --check`。
9. 记录来源缺口和自绘原因。

**警告：** 写入 Figma 前核对文件 key `Bktv2SGgjcHuUZ7KJXEkPx`。错误的 key 会改动错误文件。

## 验收清单

### 结构

- [x] 文件名称是 `Covio — Product Design · macOS 27`。
- [x] 文件 key 是 `Bktv2SGgjcHuUZ7KJXEkPx`。
- [x] 页面总数是 `50`。
- [x] 源页面数量是 `42`。
- [x] 交付页面数量是 `8`。
- [x] 交付 Section 数量是 `8`。
- [x] 顶层画板数量是 `35`。
- [x] 画板宽度是 `1600`。画板起点是 `[120,120]`。
- [x] 交付页面只使用浅色模式。
- [x] `figmaNodeMap.pages` 包含 50 个页面。
- [x] `figmaNodeMap.deliveryPages` 包含页面、Section 和画板。
- [x] `figmaNodeMap.sourcePages` 包含 42 个源页面。
- [x] `figmaNodeMap.boards` 包含 35 个画板。
- [x] `figmaNodeMap.componentRoleMappings` 包含 22 项。
- [x] 3 个品牌组件已迁移。

### 组件

- [x] 源组件集数量是 `130`。
- [x] 组件节点数量是 `186`。
- [x] 来源组件存在时，没有自绘替代品。
- [x] 分离实例数量是 `0`。
- [x] 自定义内容只在允许列表内。
- [x] 自绘系统控件数量是 `0`。
- [x] 自绘内容都有来源缺口记录。
- [x] `trayIconVariants` 只引用 Covio 品牌组件。

### 文字与变量

- [x] 交付文字节点数量是 `1259`。
- [x] 文字样式数量是 `22`。
- [x] 变量数量是 `147`。
- [x] 缺失字体数量是 `0`。
- [x] 交付页面不含 `Inter`。
- [x] 交付页面不含中文界面文案。
- [x] 画板没有未绑定的系统颜色。

### 原型与合同

- [x] reactions 数量是 `42`。
- [x] 缺失 reactions 数量是 `0`。
- [x] 含 reactions 的画板数量是 `33`。
- [x] 主路径可点击。
- [x] 异常分支可以返回恢复流程。
- [x] 菜单、弹窗、Popover、Alert 和 Sheet 使用 `DISSOLVE`。
- [x] 拖放状态使用 `On drag`。
- [x] JSON Schema Draft 2020-12 校验通过。
- [x] 图节点计数与合同一致。
- [x] `git diff --check` 通过。

### 历史归档

- 旧文件是 `Covio — Product Design`。旧文件 key 是 `8LZX9sDtCHLsVHAIktk2aN`。
- 旧文件禁止修改。旧文件只作历史记录。
- 旧的 macOS 15 Sequoia 版本记录只作历史。
- 旧 Lunacy 文件保持冻结。
