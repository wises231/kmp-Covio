# 推荐架构、接口与实施计划

> 本文件承载推荐架构、接口契约、流程、资源策略、安全、失败模式、验收和实施计划。

主题索引见 [README.md](README.md)。结论与决策表见 [conclusion.md](conclusion.md)。

## 1. 推荐架构

### 1.1 路径选择

每张卡片自己一块玻璃。
底材取 `Glass.clear`。
卡片填充取半透明的 `token/color/material-thin`。
内容区不放底板。
顶栏板用同一个底材。

不用接口。
本方案没有跨进程通信，没有网络，没有持久化格式。
接口契约、请求字段、响应字段、操作列表和错误码五节因此省略。
省略的理由：本方案是纯绘制改动，没有对外契约。

### 1.2 组件

| 组件 | 职责 | 环境 | 启动方式 |
| --- | --- | --- | --- |
| `GlassSurfaceMode` | 保存当前底材，读环境变量 | 应用进程 | 应用启动时调用 |
| `glassSurface(cornerRadius:tint:interactive:mode:)` | 给视图套一块玻璃 | 应用进程 | 视图构建时调用 |
| `MacCard` | 设置页的分组卡片 | 应用进程 | 视图构建时调用 |
| `BentoWidgetCard` | 首页网格卡片 | 应用进程 | 视图构建时调用 |
| `EmptyHomeView` | 首页为空时的提示块 | 应用进程 | 视图构建时调用 |
| `HubView` | 面板根视图。顶栏板与内容区 | 应用进程 | 视图构建时调用 |
| `WorkbenchTabBar` | 顶栏板的内容 | 应用进程 | 视图构建时调用 |

### 1.3 调用路径

```text
AppDelegate.applicationDidFinishLaunching
  -> GlassSurfaceMode.applyEnvironmentOverride()
     -> 读 COVIO_GLASS_SURFACE，覆盖 GlassSurfaceMode.current

HubView.body
  -> plates
     -> GlassEffectContainer(spacing: 0)
        -> topBarPlate.glassSurface(23)       顶栏板
        -> contentArea                         内容区，无底板
           -> MacCard.glassSurface(cardRadius)
           -> BentoWidgetCard.glassSurface(bentoCardRadius)
           -> EmptyHomeView.glassSurface(bentoCardRadius)
```

## 2. 关键流程

### 2.1 卡片绘制

1. 视图先铺一层半透明填充。
2. 再叠一层 1 点 `divider` 描边。
3. 最后套 `glassSurface`。玻璃的模糊压在填充与描边下面。
4. WindowServer 取桌面内容做模糊，与填充合成。

顺序不能反。
玻璃写在填充之前时，填充会盖住模糊。

### 2.2 底材切换

1. 应用启动时读 `COVIO_GLASS_SURFACE`。
2. 取值是 `glass`、`clear`、`material` 或 `ultraThin`。
3. 取值无效时保持默认 `.clear`。
4. 只在 DEBUG 构建生效。

### 2.3 降级

`.glassEffect` 在无边框透明面板里画不出来时，改 `GlassSurfaceMode.current` 的默认值。
`.material` 与 `.ultraThin` 两条路不依赖 Liquid Glass。

## 3. 文件位置

| 文件 | 内容 |
| --- | --- |
| `macosApp/src/Design/GlassSurface.swift` | 底材枚举与 `glassSurface` 修饰器 |
| `macosApp/src/Design/MacTheme.swift` | 令牌到 SwiftUI 的映射。材质填充与着色透明度 |
| `macosApp/src/Design/HubMetrics.swift` | 板间距、顶栏高、圆角 |
| `macosApp/src/Hub/HubView.swift` | 面板根视图。顶栏板与内容区 |
| `macosApp/src/Hub/HubComponents.swift` | `MacCard` |
| `macosApp/src/Hub/Workbench/BentoWidgetCard.swift` | 首页网格卡片 |
| `macosApp/src/App/AppDelegate.swift` | 启动时读环境变量 |
| `docs/design/workbench-architecture.md` | 第 6 节版式表 |

## 4. 安全设计

本方案不引入新的安全边界。

1. 不做网络请求。
2. 不读写用户文件。
3. 不申请新权限。
4. 环境变量只在 DEBUG 构建读取。
5. 玻璃要读桌面内容，这一步由 WindowServer 完成。应用拿不到原始像素。

## 5. 合规设计

1. 只用公开 API。`glassEffect` 是 macOS 26 起的公开接口。
2. 不调用私有接口。
3. 不修改系统设置。
4. 玻璃不可用时退回公开的 `Material`。

## 6. 可靠性设计

1. 底材枚举有四个取值，任一取值都能起。
2. 环境变量无效时不改默认值。
3. 玻璃不可用时改一处默认值即可降级。
4. 令牌取不到时 `MacTheme.nsColor` 返回洋红色，错误一眼可见。

## 7. 失败模式

| 失败 | 表现 | 处理 |
| --- | --- | --- |
| 玻璃画不出来 | 卡片没有模糊，也没有亮边 | 把默认底材改成 `.material` |
| 玻璃把两块板合成一块 | 顶栏板与内容区糊在一起 | 把 `GlassEffectContainer` 的 spacing 设成 0 |
| 填充盖住模糊 | 卡片是实心色块 | 检查填充是不是不透明 |
| 卡片边缘发闷 | 没有亮边 | 检查有没有自绘描边压在上面 |
| 环境变量拼错 | 底材不切换 | 日志里有一条「玻璃底材被环境变量改成 …」。没有这条就是没生效 |
| 深色下对比度不足 | 文字看不清 | 提高填充透明度，或改用更厚的材质令牌 |

## 8. 验收标准

1. 用户在真机上目视确认卡片与控制中心的内容按钮表现一致。
2. 卡片之间露出桌面，内容区没有统一背板。
3. 深色与浅色外观下都能看到模糊。
4. 四个底材取值都能起，界面不崩。
5. `bash scripts/test-all.sh` 全部通过。
6. `docs/design/workbench-architecture.md` 第 6 节的版式表与实现一致。

## 9. 实施计划

| 阶段 | 内容 | 状态 |
| --- | --- | --- |
| 阶段 0 | 取样与实测控制中心 | 已完成 |
| 阶段 1 | 底材枚举加默认值与环境变量开关 | 已完成 |
| 阶段 2 | 删掉内容区底板 | 已完成 |
| 阶段 3 | 玻璃下放到每张卡片，填充换半透明 | 已完成 |
| 阶段 4 | 真机验收 | 尚未执行。见 [validation/README.md](validation/README.md) |
| 阶段 5 | 按验收结果定取值，更新 ADR | 尚未执行 |
| 阶段 6 | 按 `#115` 处理设计合同 | 尚未执行 |

阶段 1 到 3 的代码在分支 `feature/shell-match-preview`。
阶段 4 之前不合入主干。

## 10. 回滚条件

1. 玻璃在无边框透明面板里画不出来，且材质降级也不可用。
2. 用户目视确认表现不如改动前。
3. `bash scripts/test-all.sh` 出现与本次改动相关的失败。
4. 面板展开或收起的动效出现可见异常。

回滚方式：把分支 `feature/shell-match-preview` 上的两次提交反向应用。
两次提交是 `Match the plate material to Control Center` 与 `Move the glass from the content plate onto the cards`。

## 11. 产品化条件

1. 真机验收通过，用户签字确认。
2. 深色与浅色外观都验证过。
3. 减弱动态效果下验证过。
4. 至少两台不同屏幕尺寸的机器上验证过。
5. `docs/design/workbench-architecture.md` 与实现一致。
6. 设计合同的去留已按 `#115` 定案。
