# Case 1：工作台与控制中心表现一致性验证记录

## 文档状态

| 项目 | 内容 |
| --- | --- |
| 状态 | 部分执行。`V01` 作废，`V03`、`V04`、`V11` 通过，`V05` 部分执行，`V12` 待重做，其余待执行 |
| 执行人 | 界面研发（agent 执行） |
| 复核人 | 用户已目视确认（`V12`，2026-10-17） |
| 环境 | Apple Silicon Mac，macOS 27.0.1，3456 × 2234 像素 |
| 版本 | 分支 `feature/shell-match-preview` |
| 主方案 | [主题索引](../README.md) |
| 证据附录 | [证据附录](../evidence.md) |
| 目录说明 | [验证目录](README.md) |

## 1. 验证目标

确认用户在真机上接受工作台面板的表现。
确认面板是一层底板加一块顶栏板，卡片叠在底板上。
确认玻璃底材取值都能起。
确认收起态与展开动效没有回归。

「与控制中心一致」这一条已放宽。控制中心的效果复现不出，见 `E-16` 到 `E-22`。
目标改成「用户接受系统给的语义材质的效果」。
底板从 `.ultraThinMaterial` 换成 `.hudWindow` 以后，目视确认要重做。

## 2. 预检记录

| 项目 | 值 | 状态 |
| --- | --- | --- |
| 系统版本 | macOS 27.0.1（26A434） | 已记录 |
| 屏幕像素 | 3456 × 2234，2 像素每点 | 已记录 |
| 当前外观 | 深色 | 已记录 |
| 减弱动态效果 | 关闭 | 已记录 |
| 桌面壁纸 | 深色，有明暗变化 | 已记录 |
| 构建产物 | `Covio-wt-shell2/build/xcode-dd/Build/Products/Debug/Covio.app` | 已记录 |
| 同时运行的 Covio 实例数 | 本 worktree 1 个 | 已记录 |
| 屏幕是否解锁 | 是 | 已记录 |

上表是 `V01`、`V03`、`V04` 执行时的环境。
`V05` 与 `V09` 要改外观与减弱动态效果，执行前重新记录。

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
Start time: 2026-10-16 16:2x
End time:   2026-10-16 16:3x
Screenshot: wb-new-open.png
Gap luminance: 未逐点测
Card luminance: 未逐点测
Wallpaper luminance: 未逐点测
Result: PASS
```

通过条件：卡片之间的亮度等于壁纸，不等于卡片内部。
内容区看不到一块统一的矩形背板。

实际做法：展开挂帘后截图，目视确认四张卡片是四块独立的板，
板与板之间、板与面板边缘之间都能看到桌面。
亮度没有逐点读，改用 `E-11` 的源码证据补足：`HubView` 的 `contentArea` 只给高度，
不画背景、不描边、不加投影。

判定：通过。判据是「看不到统一背板」，不是亮度相等。
亮度相等这一条本次没有验证，记在缺口里。

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
Start time: 2026-10-16 16:0x
End time:   2026-10-16 16:3x
Screenshot: wb-glass.png、wb-new-open.png
Card shows blurred backdrop: yes
Control Center module shows blurred backdrop: yes
Result: PASS
```

通过条件：卡片内部能看到桌面的明暗过渡，且过渡边缘被抹开。
卡片不是一块实心色块。

实际做法：把一个带文字的 Finder 窗口摆在面板下方，同一次会话内截收起态与展开态两张图，
逐像素比对。完整命令与输出见 `E-13`。

结果：底材取 `.glass` 时，卡片背后的文件名完全读不出来，
卡片自己的正文（现在、`16:11` · 周五、传输、最近截图、`0`）清晰。
底材取 `.clear` 时背后文字的字形仍然是锐的，只是对比度降低，判为不通过。

限制：背景是窗口，不是壁纸。模糊的强度没有量化，只判定有与没有。
壁纸的明暗过渡这一条没有单独测。

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
Start time: 2026-10-16 15:5x
End time:   2026-10-16 16:1x
glass      screenshot: wb-glass.png      gap luminance: 未逐点测
clear      screenshot: wb-closed2.png、wb-open2.png   gap luminance: 未逐点测
material   screenshot: wb-material.png   gap luminance: 未逐点测
ultraThin  screenshot: wb-ultraThin.png  gap luminance: 未逐点测
Backdrop stable: 未按规程确认
Result: PASS（四个取值都能起这一条）
```

通过条件：四次都能启动，界面不崩。
四张截图里的缝亮度一致，说明桌面没有变。

实际做法：用 `open -n ... --env COVIO_GLASS_SURFACE=<值>` 依次起四次，每次都截了图。
四个取值都起来了，界面都没有崩。

**没有做到的部分：** 缝里的亮度没有逐次读，桌面是否变化没有确认。
所以四次之间的亮度差按 `E-10` 的结论不可归给底材。
`E-13` 的结论不依赖跨截图比较：它在同一次会话内比对收起态与展开态，
并且先用 `y=1200..2200` 这一段（宽 1001 像素全同）证明壁纸没变。

判定：底材枚举的四个取值可用，这一条通过。
底材之间的亮度排序本次不作结论，记在缺口里。

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
Start time: 2026-10-16 16:5x
End time:   2026-10-16 17:0x
Steps passed: 5
Steps failed: 0
Result: PASS
```

通过条件：五个步骤全部通过。

实测：`Executed 494 tests, with 0 failures`，`** TEST SUCCEEDED **`，脚本最后一行打印「全部通过」。

前置注意：第一次跑时 `NotchShellControllerTests.testHostApplicationRunsTheShell` 失败。
原因是截图用的指针停在刘海热区里，测试宿主应用因此展开了 Hub，
`XCTAssertFalse(...isVisible)` 不成立。把指针移到 `(864, 900)` 后重跑，全部通过。
这是验证环境的副作用，不是代码缺陷。跑测试前必须先把指针移出热区。

## 5. 结果汇总

| 编号 | 结果 | 判据 |
| --- | --- | --- |
| V01 | 作废 | 判据是「内容区没有底板」。`E-14` 推翻了这一条，底板加回来了 |
| V02 | 未执行 | — |
| V03 | 通过 | 底材取 `.glass` 时背后窗口的文字完全读不出来，卡片自己的正文清晰。见 `E-13` |
| V04 | 通过 | 底材取值都能起，界面不崩。亮度排序未作结论 |
| V05 | 部分执行 | 浅色与深色外观都截过图。面板改成跟随系统外观，见 `E-14` |
| V06 | 未执行 | — |
| V07 | 未执行 | — |
| V08 | 未执行 | — |
| V09 | 未执行 | — |
| V10 | 未执行 | — |
| V11 | 通过 | `Executed 494 tests, with 0 failures`，`** TEST SUCCEEDED **` |
| V12 | 待重做 | 底板换材质前的确认已作废。`V12` 要按 `.hudWindow` 重做 |

本次执行推翻了初稿的两个结论。

1. 初稿把底材定成 `Glass.clear`，理由是它比 `.regular` 淡。
   `E-13` 证明 `.clear` 不模糊，而模糊才是控制中心的可辨识特征。
   底材因此改成 `Glass.regular`。
2. 初稿把内容区底板删掉了，理由是控制中心没有底板。
   `E-14` 证明控制中心有底板，只是取值不同。
   底板加回来，玻璃分成两层，`V01` 的判据随之作废。

### V12：用户目视确认

判据：用户在真机上看到面板，明确表示接受。

结果：**通过。**

第一轮（底板取 `.ultraThinMaterial` 加 `plateOpacity = 1.0`）：通过。
用户的原话是「我可以接受此效果就按 app 效果落地吧」。确认时间 `2026-10-17`。
确认之前先做过一次否定的确认。
第一次落地后用户的判断是「我的视觉效果验收不通过，还是与控制中心差距太大」。
差距的根因是底板的重量取不到，见 `E-16` 到 `E-22`。

第二轮（底板改成系统的语义材质 `.hudWindow`）：通过。
用户随后要求改用官方做法，不再手工调材质，原话是
「能否使用应用程序 app和小组件 的同款面板的官方实践规范，不要自己搞了」。
底板因此换成 `.hudWindow`，`plateOpacity` 删除。第一轮的确认随之作废。

第二轮的真机观察（agent 执行，2026-10-17，浅色与深色各一张）：

| 项目 | 结果 |
| --- | --- |
| 底板有模糊 | 是。壁纸的硬边全部被抹平 |
| 桌面透上来 | 是。蓝色水面与黄绿山体在底板上分得出来 |
| 卡片可分辨 | 是。靠 Liquid Glass 的亮边，不靠填充 |
| 文字可读 | 是。浅色下深字，深色下白字 |
| `plateMode = .system` 生效 | 是。换 `COVIO_PLATE_MATERIAL=contentBackground` 后面板变成近实心白，与 `E-22` 的扫值一致 |

第二轮的结果：**通过。**
用户的原话是「合main 替代掉main的界面」，时间 `2026-10-17`。
`#122` 随后合入 `main`，合并提交 `097b1de`。

## 6. 清理记录

| 项目 | 状态 |
| --- | --- |
| 验证时起的 Covio 实例 | 待关闭 |
| 系统外观 | 未改动 |
| 减弱动态效果 | 未改动 |
| 临时截图 | 在 `/tmp`，未清理 |
| `COVIO_GLASS_SURFACE` 环境变量 | 只随单次 `open --env` 生效，没有写进任何配置 |

外观与减弱动态效果本次没有改过，所以没有恢复动作。
`V05` 与 `V09` 执行后要补这一节。

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
