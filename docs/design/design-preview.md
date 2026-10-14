# Compose Web 打样模块

## 文档状态

| 项目 | 内容 |
| --- | --- |
| 文档版本 | `1.2` |
| 状态 | 待评审 |
| 日期 | `2026-10-14` |
| 适用范围 | `designPreview` 模块。只在开发机上跑。 |
| 上游文档 | [研发工作流](../../doc/process/workflow.md) 的设计闸门、[设计合同](../covio-design-contract.json) |
| 下游文档 | 每一份打样对应的 issue |

本文写清四件事：模块是什么、怎么起、预览怎么累积、怎么加一份打样。

## 1. 目标与非目标

目标是让改界面的 issue 在动工前有一份可点的预览。评审人打开页面就能判断设计对不对。

非目标：

1. 不做交付物。发布物里没有这个模块。
2. 不接 `kmpDomain`。打样用假数据。
3. 不做像素级还原。打样回答「这样排对不对」，不回答「这一像素差多少」。
4. 不做组件库。每个打样各画各的，重复的件等第三次出现再抽。

## 2. 模块

模块名是 `designPreview`，在 `project.yaml` 的 `modules` 里。

```yaml
product:
  type: wasm-js/app

dependencies:
  - $compose.runtime
  - $compose.foundation
  - $compose.material3
  - $compose.ui

settings:
  compose:
    enabled: true
```

产品类型是 `wasm-js/app`。`kmp/app` 不是合法值。
Amper 自动装 pnpm 与 Node，自动生成 `index.html`。不用手写 HTML。

**注意：** 入口是 `androidx.compose.ui.window.ComposeViewport`。
`CanvasBasedWindow` 在 Compose Multiplatform 1.11.1 里不存在，用它编译不过。

## 3. 起服务

1. 起服务。

   ```bash
   ./kotlin run -m designPreview
   ```

2. 打开 `http://127.0.0.1:8080`。

3. 停止服务按 `Ctrl+C`。

编译不通过时先单独跑构建，报错更清楚。

```bash
./kotlin build -m designPreview
```

## 4. 预览怎么累积

`designPreview` 模块由多份打样组成。一份打样对应一个 issue。

| 位置 | 内容 |
| --- | --- |
| `main` 上的预览 | 稳定版。含全部已合并的打样。 |
| issue 分支上的预览 | 从 `main` 取的一份快照，加本条 issue 的新界面。 |

评审人打开 `main` 上的预览，看到的就是稳定版。

新 issue 的分支先取 `main` 的快照。分支只加自己的一条打样。
合并回 `main` 后，这一条进入稳定版。下一个 issue 取到的快照就含这一条。

模型图见 [预览由 issue 组合而成](preview-composition.html)。此文件是 HTML，用浏览器打开。

**注意：** `previews` 是共用的入口列表。在分支上只追加自己的条目。
改动已合并的条目会让两条分支冲突。两条分支都在末尾追加时，后合并的一条要解冲突。

锚点前缀是 issue 号。多份打样因此能在同一页上共存，各用各的锚点。见第 6 节。

## 5. 写一份打样

1. 在 `designPreview/src/com/wyz/covio/preview/previews/` 下建一个文件，写一个 `@Composable` 函数。
2. 在 `PreviewRegistry.kt` 的 `previews` 里加一条，填名字、覆盖范围、issue 号和这个函数。
3. 刷新浏览器。

**注意：** 只加画得完的条目。首页上点进去是空壳就是死路，违反设计闸门的 R7。

色值从设计合同取。合同的取值进 Kotlin 侧的通道还没建，先手抄，
并在注释里写清抄的是哪一枚令牌。见第 8 节。

宿主的颜色写在 `PreviewApp.kt` 的 `Harness` 里。宿主是工具，不是 Covio 的界面，
所以宿主用中性灰，不读合同。

## 6. 截图

1. 打样画完后截图。
2. 图存进 `docs/design/previews/`。命名见该目录的 `README.md`。
3. 图路径写进提出这份打样的 issue 正文。设计闸门的 R8 要求这一条。

地址栏可以带锚点，直接落到某一屏，不用手点。格式是 `#<issue 号>-<锚点>`。
锚点名由每一份打样自己定，写在它的 `StartScreen` 里。例如 `#107-home` 直接进
第 107 号打样的首页。锚点名不认识时，打样抛错，不静默落回首页。

**注意：** 字体是异步加载的。截图工具要在字体就绪后再拍，否则拍到豆腐块。
判断方法是看操作台那一行。写「字体已加载」才对。写「字体加载中」要重拍。

无头浏览器用 `--virtual-time-budget` 时，这个预算同时管虚拟时间与真实等待。
预算给小了会在字体到位前拍。这个值按机器调，一次拍不对就加大重拍。

## 7. 中文字体

打样自带一份中文字体。没有它，中文全是豆腐块。

Compose 的 wasm 端只带一份拉丁字库，也读不到系统字体。`skiko.wasm` 里既没有
`queryLocalFonts`，也没有 `document.fonts`。所以中文必须随模块发一份。

| 项目 | 内容 |
| --- | --- |
| 文件 | `designPreview/composeResources/font/NotoSansSC-Preview.otf` |
| 大小 | 2,054,972 字节 |
| 来源 | Noto Sans SC Regular 的子集 |
| 许可证 | SIL Open Font License 1.1，全文在同目录的 `OFL.txt` |
| 生成脚本 | `scripts/subset-preview-font.py` |

加载在 `PreviewFont.kt` 里。字体没加载完时，文字用回退字库画，加载完自动重画。

**注意：** 资源目录是 `designPreview/composeResources/`，不是 `designPreview/src/composeResources/`。
放在 `src` 下面，Amper 不生成 `Res`，也不把文件复制进构建输出。

字集不够用时重新生成。脚本收全部 GB2312 字符，加上 ASCII、常用标点、箭头、
数学符号和制表符。

```bash
python3 -I scripts/subset-preview-font.py <完整的 NotoSansSC-Regular.otf> designPreview/composeResources/font/NotoSansSC-Preview.otf
```

遇到新的豆腐块时，先看操作台那一行写的字。写「字体已加载」是字集缺字，扩脚本里的字集。
写「字体加载中」是截图太早，见第 6 节。

## 8. 边界

1. 模块不进发布物。`macosApp` 不依赖它，打包脚本也不含它。
2. 模块不依赖 `kmpDomain`。`kmpDomain` 现在只有 `jvm` 与 `macosArm64` 两个平台，接不上 wasmJs。
3. 打样不是权威。权威是设计合同。打样与合同不一致时，改打样。

## 9. 未决项

| 编号 | 未决项 | 影响 |
| --- | --- | --- |
| `Q-E` | 打样与合同漂移时谁来拦 | 校验脚本要不要读打样 |
| `Q-F` | `platformMapping` 的 `status` 三值是否还要 | 去掉 Figma 后只剩 Swift 一个平台 |
| `Q-H` | 合同令牌怎么进 Kotlin 侧 | 打样现在手抄色值 |

`Q-E` 与 `Q-F` 记在 #98。`Q-H` 记在 #103 的后续动作第 3 条。
