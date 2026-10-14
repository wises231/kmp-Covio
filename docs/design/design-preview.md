# Compose Web 打样模块

## 文档状态

| 项目 | 内容 |
| --- | --- |
| 文档版本 | `1.0` |
| 状态 | 待评审 |
| 日期 | `2026-10-13` |
| 适用范围 | `designPreview` 模块。只在开发机上跑。 |
| 上游文档 | [研发工作流](../../doc/process/workflow.md) 的设计闸门、[设计合同](../covio-design-contract.json) |
| 下游文档 | 每一份打样对应的 issue |

本文写清三件事：模块是什么、怎么起、怎么加一份打样。

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
  - org.jetbrains.compose.runtime:runtime:1.12.1
  - org.jetbrains.compose.foundation:foundation:1.12.1
  - org.jetbrains.compose.ui:ui:1.12.1

settings:
  compose:
    enabled: true
```

产品类型是 `wasm-js/app`。`kmp/app` 不是合法值。
Amper 自动装 pnpm 与 Node，自动生成 `index.html`。不用手写 HTML。

**注意：** 入口是 `androidx.compose.ui.window.ComposeViewport`。
`CanvasBasedWindow` 在 1.11.1 里不存在，用它编译不过。

### 2.1 为什么不写 `$compose.*`

Amper 0.12.1 的内置 catalog 把 Compose 钉在 `1.11.1`。
`1.11.1` 在 web 目标下渲染不了中文：字形全部是方框。

原因是 Compose for Web 用 Skia 画字，wasm 沙箱读不到系统字体。
`1.12.0` 起才有按需下载 Noto 子集的字体回退。所以这里写显式坐标。

`1.12.1` 没有 `material3` 的稳定版本，只有 `1.12.0-alpha03` 这样的预发布版。
所以本模块不引 material3，只用 foundation 画。
打样要还原的是 Covio 的设计，不是 Material 的默认样式，少这一层反而干净。

**警告：** 不要把这三行换回 `$compose.*`。换回去中文就没了。

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

## 4. 写一份打样

1. 在 `designPreview/src/com/wyz/covio/preview/previews/` 下建一个文件，写一个 `@Composable` 函数。
2. 在 `PreviewRegistry.kt` 的 `previews` 里加一条，填名字、覆盖范围、issue 号和这个函数。
3. 刷新浏览器。

**注意：** 只加画得完的条目。首页上点进去是空壳就是死路，违反设计闸门的 R7。

色值从设计合同取。合同的取值进 Kotlin 侧的通道还没建，先手抄，
并在注释里写清抄的是哪一枚令牌。见第 6 节。

宿主的颜色写在 `PreviewApp.kt` 的 `Harness` 里。宿主是工具，不是 Covio 的界面，
所以宿主用中性灰，不读合同。

## 5. 截图

1. 打样画完后截图。
2. 图存进 `docs/design/previews/`。命名见该目录的 `README.md`。
3. 图路径写进提出这份打样的 issue 正文。设计闸门的 R8 要求这一条。

**注意：** 不要只看浏览器有没有报错。页面能打开不等于画对了。
1.11.1 那次就是页面正常打开，字全是方框。
截图之后要看一眼图，或者用第 3 节的命令跑起来自己看。

截图可以走命令行。脚本用系统的 WKWebView 渲染，不用装浏览器。

```bash
swiftc -O scripts/preview-shot.swift -o build/preview-shot
build/preview-shot http://127.0.0.1:8080 docs/design/previews/106-device-pane-1.png 1440 900 16
```

第 4、5 个参数是宽高，第 6 个是等页面画完的秒数。
脚本同时打印页面里的 JS 错误。`PROBE` 行的 `errors` 是空数组才算干净。

## 6. 边界

1. 模块不进发布物。`macosApp` 不依赖它，打包脚本也不含它。
2. 模块不依赖 `kmpDomain`。`kmpDomain` 现在只有 `jvm` 与 `macosArm64` 两个平台，接不上 wasmJs。
3. 打样不是权威。权威是设计合同。打样与合同不一致时，改打样。

## 7. 未决项

| 编号 | 未决项 | 影响 |
| --- | --- | --- |
| `Q-E` | 打样与合同漂移时谁来拦 | 校验脚本要不要读打样 |
| `Q-F` | `platformMapping` 的 `status` 三值是否还要 | 去掉 Figma 后只剩 Swift 一个平台 |
| `Q-H` | 合同令牌怎么进 Kotlin 侧 | 打样现在手抄色值 |

`Q-E` 与 `Q-F` 记在 #98。`Q-H` 记在 #103 的后续动作第 3 条。
