# Case 1：工作台与控制中心表现一致性验证记录

## 文档状态

| 项目 | 内容 |
| --- | --- |
| 状态 | 尚未执行 |
| 执行人 | 待填写 |
| 复核人 | 待填写 |
| 环境 | Apple Silicon Mac，macOS 27.0.1，3456 × 2234 像素 |
| 版本 | 分支 `feature/shell-match-preview`，commit 待填写 |
| 主方案 | [主题索引](../README.md) |
| 证据附录 | [证据附录](../evidence.md) |
| 目录说明 | [验证目录](README.md) |

## 1. 验证目标

确认工作台的每个卡片与控制中心的内容按钮表现一致。
确认内容区没有统一底板。
确认四个玻璃底材取值都能起。
确认收起态与展开动效没有回归。

## 2. 预检记录

| 项目 | 值 | 状态 |
| --- | --- | --- |
| 系统版本 | 待填写 | 待填写 |
| 屏幕像素 | 待填写 | 待填写 |
| 当前外观 | 待填写 | 待填写 |
| 减弱动态效果 | 待填写 | 待填写 |
| 桌面壁纸 | 待填写 | 待填写 |
| 构建产物 | 待填写 | 待填写 |
| 同时运行的 Covio 实例数 | 待填写 | 待填写 |
| 屏幕是否解锁 | 待填写 | 待填写 |

## 3. 测试前采集

```sh
sw_vers
system_profiler SPDisplaysDataType | grep -i resolution
pgrep -lf "Covio"
defaults read -g AppleInterfaceStyle 2>/dev/null || echo light
defaults read com.apple.universalaccess reduceMotion 2>/dev/null || echo 0
screencapture -x before.png
```

记录字段：

```text
Start time:
System version:
Screen pixels:
Appearance:
Reduce motion:
Wallpaper:
Build path:
Running instances:
```

## 4. 验证步骤

### V01：内容区没有底板，卡片之间露出桌面

前置：应用已启动，挂帘已展开，停在首页。

操作：

1. 展开挂帘。
2. 截图。
3. 在两张卡片之间取一条直线，读亮度。
4. 在卡片内部同一高度取一点，读亮度。
5. 与桌面壁纸在同位置的亮度对照。

记录：

```text
Start time:
End time:
Screenshot:
Gap luminance:
Card luminance:
Wallpaper luminance:
Result: PENDING
```

通过条件：卡片之间的亮度等于壁纸，不等于卡片内部。
内容区看不到一块统一的矩形背板。

### V02：卡片与顶栏板的几何与控制中心对照

前置：控制中心可用。

操作：

1. 打开控制中心，截图。
2. 展开挂帘，截图。
3. 在两张截图里各测一次顶栏板或卡片的高度与圆角。
4. 把实测值与 [证据附录](../evidence.md) 的 `E-01` 到 `E-03` 对照。

记录：

```text
Start time:
End time:
Control Center screenshot:
Workbench screenshot:
Module height:
Module radius:
Horizontal gap:
Vertical gap:
Result: PENDING
```

通过条件：工作台的水平缝在 11 到 13 点之间。
卡片圆角与卡片高度的比值落在 0.35 到 0.45 之间，或者记录下偏差并说明原因。

### V03：卡片内部能看到桌面的模糊

前置：桌面壁纸有明暗变化。

操作：

1. 展开挂帘，停在设置页。
2. 把窗口移到壁纸有明显明暗过渡的位置。
3. 截图。
4. 观察卡片内部是否有被抹开的明暗过渡。
5. 与控制中心的模块内部对照。

记录：

```text
Start time:
End time:
Screenshot:
Card shows blurred backdrop: yes / no
Control Center module shows blurred backdrop: yes / no
Result: PENDING
```

通过条件：卡片内部能看到桌面的明暗过渡，且过渡边缘被抹开。
卡片不是一块实心色块。

### V04：四个底材取值都能起

前置：构建是 DEBUG。

操作：

1. 依次用 `COVIO_GLASS_SURFACE` 取 `glass`、`clear`、`material`、`ultraThin` 启动应用。
2. 每次启动后截图。
3. 每次截图后立刻读一次缝里的亮度。
4. 确认缝里的亮度在四次之间没有变化。有变化就作废，重来。

命令模板：

```sh
COVIO_GLASS_SURFACE=clear open -n build/xcode-dd/Build/Products/Debug/Covio.app
```

记录：

```text
Start time:
End time:
glass      screenshot:      gap luminance:
clear      screenshot:      gap luminance:
material   screenshot:      gap luminance:
ultraThin  screenshot:      gap luminance:
Backdrop stable: yes / no
Result: PENDING
```

通过条件：四次都能启动，界面不崩。
四张截图里的缝亮度一致，说明桌面没有变。

### V05：深色与浅色外观

前置：能在系统设置里切换外观。

操作：

1. 切到深色外观，展开挂帘，截图。
2. 切到浅色外观，展开挂帘，截图。
3. 两次都观察卡片的模糊与文字对比度。

记录：

```text
Start time:
End time:
Dark screenshot:
Light screenshot:
Dark: blur visible: yes / no   text readable: yes / no
Light: blur visible: yes / no  text readable: yes / no
Result: PENDING
```

通过条件：两种外观下都能看到模糊，文字都能读清。

### V06：卡片边缘由系统绘制，没有自绘投影

前置：无。

操作：

1. 展开挂帘。
2. 放大卡片边缘。
3. 观察边缘是不是一条细亮线。
4. 观察卡片下方有没有投影。

记录：

```text
Start time:
End time:
Screenshot:
Edge is a thin bright line: yes / no
Drop shadow present: yes / no
Result: PENDING
```

通过条件：边缘是一条细亮线。
卡片下方没有投影。

### V07：顶栏板是胶囊，与菜单栏胶囊一致

前置：菜单栏胶囊可见。

操作：

1. 截图。
2. 对照顶栏板与菜单栏胶囊的底材、圆角与亮边。

记录：

```text
Start time:
End time:
Screenshot:
Tab bar corner radius:
Menu bar capsule corner radius:
Same material: yes / no
Result: PENDING
```

通过条件：两块板的底材相同，顶栏板是胶囊形。

### V08：编辑模式下的表现

前置：首页至少有一个组件。

操作：

1. 进入编辑模式。
2. 截图。
3. 观察提示条、卡片与删除钮的表现。

记录：

```text
Start time:
End time:
Screenshot:
Banner uses the same glass: yes / no
Cards still show blur: yes / no
Result: PENDING
```

通过条件：提示条与卡片用同一种玻璃。
卡片仍然能看到模糊。

### V09：减弱动态效果下的表现

前置：能在系统设置里切换减弱动态效果。

操作：

1. 打开减弱动态效果。
2. 展开与收起挂帘，截图。
3. 观察玻璃与文字是否仍然可用。

记录：

```text
Start time:
End time:
Screenshot:
Glass still visible: yes / no
Text readable: yes / no
Result: PENDING
```

通过条件：玻璃仍然可见，文字可读，动效只改透明度。

### V10：收起态与展开动效的回归

前置：无。

操作：

1. 确认挂帘收起时没有残留的玻璃。
2. 展开挂帘，观察动效。
3. 收起挂帘，观察动效。

记录：

```text
Start time:
End time:
Collapsed state clean: yes / no
Expand animation smooth: yes / no
Collapse animation smooth: yes / no
Result: PENDING
```

通过条件：收起态没有残留。
展开与收起的动效没有可见异常。

### V11：`bash scripts/test-all.sh` 通过

前置：无。

操作：

```sh
bash scripts/test-all.sh
```

记录：

```text
Start time:
End time:
Steps passed:
Steps failed:
Result: PENDING
```

通过条件：五个步骤全部通过。

## 5. 结果汇总

待填写。

## 6. 清理记录

待填写。

## 7. 更新规则

执行后回填时间、截图文件名与实际结果。
执行后更新 [验证目录](README.md) 的测试矩阵。
执行后更新 [主题索引](../README.md) 的验证状态。
结论变化时更新 [conclusion.md](../conclusion.md)。
证据变化时更新 [evidence.md](../evidence.md)。
实施条件变化时更新 [solution.md](../solution.md)。

## 8. 关联文档

- [主题索引](../README.md)
- [证据附录](../evidence.md)
- [验证目录](README.md)
