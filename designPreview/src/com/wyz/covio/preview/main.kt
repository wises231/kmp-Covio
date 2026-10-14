package com.wyz.covio.preview

import androidx.compose.ui.ExperimentalComposeUiApi
import androidx.compose.ui.window.ComposeViewport

/**
 * 打样模块的入口。
 *
 * 起服务：
 *
 * ```bash
 * ./kotlin run -m designPreview
 * ```
 *
 * 浏览器打开 `http://127.0.0.1:8080`。
 *
 * 这个模块是设计闸门的预览产物。它不是交付物，不进发布物，也不接 `kmpDomain`。
 * 读法与写法见 `docs/design/design-preview.md`。
 */
@OptIn(ExperimentalComposeUiApi::class)
fun main() {
    ComposeViewport {
        PreviewApp()
    }
}
