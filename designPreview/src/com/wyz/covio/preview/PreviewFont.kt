package com.wyz.covio.preview

import androidx.compose.material3.LocalTextStyle
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.compositionLocalOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.platform.Font
import designpreview.generated.resources.Res

/** 字体在 `composeResources` 里的路径。 */
private const val fontPath = "font/NotoSansSC-Preview.otf"

/** 字体的名字。只在本进程里用，不参与匹配。 */
private const val fontIdentity = "NotoSansSC"

/**
 * 字体加载的结果。打样的操作台把它显示出来。
 *
 * 字体加载失败时中文是豆腐块，而豆腐块与「这一屏本来就没字」不好分。
 * 把结果写出来，省得猜。
 */
val LocalPreviewFontStatus = compositionLocalOf { "字体未加载" }

/**
 * 打样用的字体。没有它，中文全是豆腐块。
 *
 * Compose 的 wasm 端自带一个只有拉丁字符的字库，也读不到系统字体。
 * `skiko.wasm` 里既没有 `queryLocalFonts`，也没有 `document.fonts`。
 * 所以中文必须随模块发一份。见 `docs/design/design-preview.md` 第 6 节。
 *
 * 字体是 Noto Sans SC 的子集，按 SIL Open Font License 1.1 使用。
 * 许可证在同目录的 `OFL.txt`。裁字集的脚本是 `scripts/subset-preview-font.py`。
 *
 * 加载是异步的。加载完之前文字用回退字库画，加载完自动重画。
 */
@Composable
fun PreviewFont(content: @Composable () -> Unit) {
    var family by remember { mutableStateOf<FontFamily?>(null) }
    var status by remember { mutableStateOf("字体加载中") }

    LaunchedEffect(Unit) {
        try {
            val bytes = Res.readBytes(fontPath)
            family = FontFamily(Font(identity = fontIdentity, data = bytes))
            status = "字体已加载，${bytes.size} 字节"
        } catch (failure: Throwable) {
            status = "字体加载失败：${failure.message}"
        }
    }

    CompositionLocalProvider(
        LocalPreviewFontStatus provides status,
        LocalTextStyle provides TextStyle(fontFamily = family ?: FontFamily.Default),
        content = content,
    )
}
