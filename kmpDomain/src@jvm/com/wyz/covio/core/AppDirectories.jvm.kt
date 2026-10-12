package com.wyz.covio.core

internal actual object AppDirectories {
    actual val home: String = System.getProperty("user.home")

    actual val userApplicationSupport: String = platformDataRoot()

    actual val support: String = "$userApplicationSupport/$APP_ID"
}

/**
 * 应用数据根目录。按系统选择，不用缓存目录或临时目录。
 *
 * 依据见 `docs/research/shared-transfer-workspace/evidence.md` 的 `E-04`：
 * 三个桌面系统各有自己的「每用户应用数据」目录。
 * 取值顺序与 `solution.md` 第 1.3 节一致。
 *
 * macOS 上返回 Apple 的布局，与 0.4.2 的既有路径一致。
 * 老用户在那一版存放的设置与截图不会因为这次改动挪位置。
 *
 * 参数都带默认值，方便按系统取值写单元测试。
 * 测试在 `test@jvm` 里，两个平台的目标都跑不到 Windows 分支。
 */
internal fun platformDataRoot(
    osName: String = System.getProperty("os.name"),
    home: String = System.getProperty("user.home"),
    localAppData: String? = System.getenv("LOCALAPPDATA"),
    xdgDataHome: String? = System.getenv("XDG_DATA_HOME"),
): String {
    val system = osName.trim().lowercase()
    val homeRoot = trimTrailingSeparators(home)
    return when {
        system.startsWith("mac") || system.startsWith("darwin") ->
            "$homeRoot/Library/Application Support"

        system.startsWith("win") ->
            trimTrailingSeparators(localAppData).ifEmpty { "$homeRoot/AppData/Local" }

        else ->
            trimTrailingSeparators(xdgDataHome).ifEmpty { "$homeRoot/.local/share" }
    }
}

/** 去掉首尾空白与结尾的分隔符。根目录返回空串，拼出来的路径不带两个斜杠。 */
private fun trimTrailingSeparators(value: String?): String {
    val trimmed = value?.trim().orEmpty()
    if (trimmed == "/" || trimmed == "\\") return ""
    if (trimmed.length <= 1) return trimmed
    return trimmed.trimEnd('/', '\\')
}
