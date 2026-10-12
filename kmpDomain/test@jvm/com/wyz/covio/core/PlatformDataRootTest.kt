package com.wyz.covio.core

import kotlin.test.Test
import kotlin.test.assertEquals

/**
 * `platformDataRoot` 的三条分支。
 *
 * 这个文件只跑在 jvm 上，因为 `AppDirectories` 的 jvm actual 才是带分支的那一份。
 * 测试按系统名取值，所以在 macOS 上也能验到 Windows 与 Linux 的分支。
 * 依据见 `docs/research/shared-transfer-workspace/evidence.md` 的 `E-04`。
 */
class PlatformDataRootTest {
    /// macOS 保持 0.4.2 的既有布局，老用户的设置与截图不挪位置。
    @Test
    fun `macos keeps the apple layout`() {
        assertEquals(
            "/Users/tester/Library/Application Support",
            platformDataRoot("Mac OS X", "/Users/tester", null, null),
        )
    }

    @Test
    fun `windows uses the local app data directory`() {
        assertEquals(
            "C:\\Users\\tester\\AppData\\Local",
            platformDataRoot("Windows 11", "C:\\Users\\tester", "C:\\Users\\tester\\AppData\\Local", null),
        )
    }

    /// 环境变量拿不到时回落到主目录下的同一位置。
    @Test
    fun `windows falls back to the home directory`() {
        assertEquals(
            "C:/Users/tester/AppData/Local",
            platformDataRoot("Windows 10", "C:/Users/tester", "   ", null),
        )
    }

    @Test
    fun `linux uses the xdg data home`() {
        assertEquals("/home/tester/.local/share", platformDataRoot("Linux", "/home/tester/", null, null))
        assertEquals("/data/tester", platformDataRoot("Linux", "/home/tester", null, "/data/tester/"))
    }

    /// 结尾的分隔符不重复，根目录不加倍。
    @Test
    fun `trailing separators are trimmed`() {
        assertEquals("/Library/Application Support", platformDataRoot("macOS", "/", null, null))
        assertEquals(
            "/Users/tester/Library/Application Support",
            platformDataRoot("macOS", "/Users/tester/", null, null),
        )
    }
}
