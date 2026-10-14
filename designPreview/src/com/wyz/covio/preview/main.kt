package com.wyz.covio.preview

import androidx.compose.material3.MaterialTheme
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
        // 外壳自己定色，不靠主题。套一层是为了让 Material3 的默认值有出处。
        MaterialTheme {
            // 中文字体要自己带。见 PreviewFont.kt。
            PreviewFont {
                PreviewApp()
            }
        }
    }
}
