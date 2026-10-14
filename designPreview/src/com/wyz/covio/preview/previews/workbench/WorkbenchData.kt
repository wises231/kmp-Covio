package com.wyz.covio.preview.previews.workbench

import androidx.compose.ui.graphics.Color

/**
 * 打样自带的假数据。
 *
 * 打样不接 `kmpDomain`。`kmpDomain` 只有 `jvm` 与 `macosArm64` 两个平台，接不上 wasmJs。
 * 见 #103 的后续动作第 2 条。所以模型在这里重写一份，字段按 #78 的形状取。
 */

/** 工作区的种类。内置六个，加一个用户自建的。 */
internal enum class PaneKind {
    NOW,
    CLIPBOARD,
    FILES,
    SCREENSHOTS,
    DEVICES,
    SETTINGS,
    BOARD,
    ;

    /** 内置工作区不能删除，只能隐藏。见 ADR-0002 决策 6。 */
    val isBuiltin: Boolean get() = this != BOARD

    /** 显示名的文案键。内置的取自设计合同 `copy/hub/tab/<键>`。 */
    val titleCopyKey: String? get() = if (isBuiltin) "copy/hub/tab/${name.lowercase()}" else null
}

/** 一个工作区。 */
internal data class Pane(
    val id: String,
    val kind: PaneKind,
    /** 用户改过的名字。空串表示用内置名字。 */
    val title: String = "",
    /** 用户换过的图标。空串表示用内置图标。 */
    val icon: String = "",
    val hidden: Boolean = false,
) {
    /** tab bar 上显示的名字。用户改过就用改过的。 */
    val displayTitle: String get() = title.ifEmpty { kind.defaultTitle }

    val displayIcon: String get() = icon.ifEmpty { kind.defaultIcon }

    /** 内置与否由种类推导，不单独存字段。 */
    val isBuiltin: Boolean get() = kind.isBuiltin
}

/** 内置工作区的名字。取自合同 `copy/hub/tab/<键>`。 */
internal val PaneKind.defaultTitle: String
    get() = when (this) {
        PaneKind.NOW -> "现在"
        PaneKind.CLIPBOARD -> "剪贴板"
        PaneKind.FILES -> "文件"
        PaneKind.SCREENSHOTS -> "截图"
        PaneKind.DEVICES -> "设备"
        PaneKind.SETTINGS -> "设置"
        PaneKind.BOARD -> "自建"
    }

/**
 * 内置工作区的图标。
 *
 * 合同用 SF Symbol 名。浏览器里没有 SF Symbol，所以这里存一个近似字符。
 * 打样只判断「图标换没换」，不判断字形对不对。
 */
internal val PaneKind.defaultIcon: String
    get() = when (this) {
        PaneKind.NOW -> "◉"
        PaneKind.CLIPBOARD -> "▤"
        PaneKind.FILES -> "▢"
        PaneKind.SCREENSHOTS -> "▣"
        PaneKind.DEVICES -> "▭"
        PaneKind.SETTINGS -> "⚙"
        PaneKind.BOARD -> "◇"
    }

/** 图标选择器里的候选。 */
internal val iconChoices = listOf("◉", "▤", "▢", "▣", "▭", "⚙", "◇", "★", "◆", "✦")

/** 组件卡片的尺寸档位。小 1×1，宽 2×1，高 1×2，大 2×2。 */
internal enum class WidgetSize(val columns: Int, val rows: Int) {
    SMALL(1, 1),
    WIDE(2, 1),
    TALL(1, 2),
    LARGE(2, 2),
    ;

    val label: String
        get() = when (this) {
            SMALL -> "小"
            WIDE -> "宽"
            TALL -> "高"
            LARGE -> "大"
        }
}

/** 首页网格上的一块组件。 */
internal data class Widget(
    val id: String,
    val title: String,
    val size: WidgetSize,
    val tint: Color,
    /** 卡片上显示的一行内容。假数据。 */
    val detail: String,
)

/** 六个内置工作区，按需求文档第 5 节的顺序。 */
internal fun defaultPanes(): List<Pane> = listOf(
    PaneKind.NOW,
    PaneKind.CLIPBOARD,
    PaneKind.FILES,
    PaneKind.SCREENSHOTS,
    PaneKind.DEVICES,
    PaneKind.SETTINGS,
).map { Pane(id = it.name.lowercase(), kind = it) }

/** 首页的组件。假数据，但尺寸档位与底色按 ADR-0002 决策 7 混着给。 */
internal fun defaultWidgets(): List<Widget> = listOf(
    Widget("w-clock", "现在", WidgetSize.WIDE, Tokens.cardTints[0], "14:32 · 周三"),
    Widget("w-battery", "电量", WidgetSize.SMALL, Tokens.cardTints[1], "82%"),
    Widget("w-transfer", "传输", WidgetSize.WIDE, Tokens.cardTints[2], "2 项进行中"),
    Widget("w-actions", "快捷操作", WidgetSize.TALL, Tokens.cardTints[4], "4 个动作"),
    Widget("w-shots", "最近截图", WidgetSize.LARGE, Tokens.cardTints[3], "6 张 · 今天"),
    Widget("w-devices", "设备", WidgetSize.SMALL, Tokens.cardTints[5], "3 台"),
)

/** 工作区数量上限。见 ADR-0002 决策 5。 */
internal const val MAX_PANES = 12

/** 十二个工作区。用来量页签的排版，与 ADR-0002 的证据表核对。 */
internal fun filledPanes(): List<Pane> =
    defaultPanes() + (7..MAX_PANES).map { Pane(id = "board$it", kind = PaneKind.BOARD, title = "工作区 $it") }

/**
 * 一个工作区自己的设置项。S7 与 F5。
 *
 * 打样只放两行，够判断「每工作区有独立设置」这一条。
 */
internal data class PaneSetting(val key: String, val label: String, val summary: String, val on: Boolean)

internal fun defaultPaneSettings(kind: PaneKind): List<PaneSetting> = when (kind) {
    PaneKind.NOW -> listOf(
        PaneSetting("live", "实时指标", "在挂帘里显示电量与电源状态。", true),
        PaneSetting("links", "设备连接", "显示已连接设备的链路。", true),
    )
    PaneKind.CLIPBOARD -> listOf(
        PaneSetting("history", "记录剪切板历史", "保留最近复制的内容。", true),
        PaneSetting("images", "记录图片", "图片占用空间较大。", false),
    )
    PaneKind.FILES -> listOf(
        PaneSetting("sweep", "自动清理过期文件", "超过 7 天的文件自动删除。", true),
        PaneSetting("space", "保留剩余空间提示", "空间不足时提醒。", true),
    )
    PaneKind.SCREENSHOTS -> listOf(
        PaneSetting("toolbar", "捕获后显示工具栏", "截完立刻显示动作。", true),
        PaneSetting("copy", "捕获后自动复制", "截图直接进剪贴板。", false),
    )
    PaneKind.DEVICES -> listOf(
        PaneSetting("discovery", "自动发现设备", "在同一个网络里查找。", true),
        PaneSetting("queue", "显示传输队列", "列出等待中的传输。", true),
    )
    PaneKind.SETTINGS -> listOf(
        PaneSetting("language", "跟随系统语言", "关闭后手动选语言。", true),
        PaneSetting("notify", "通知", "传输完成与错误时提醒。", true),
    )
    PaneKind.BOARD -> listOf(
        PaneSetting("grid", "网格对齐", "拖动后吸附到网格列。", true),
        PaneSetting("dense", "紧凑排布", "缩小卡片间距。", false),
    )
}

/** 工作区内容页上的一行。S5。 */
internal data class RowItem(val title: String, val detail: String, val trailing: String)

internal fun contentRows(kind: PaneKind): List<RowItem> = when (kind) {
    PaneKind.NOW -> listOf(
        RowItem("电源", "已连接电源适配器", "充电中"),
        RowItem("电池", "剩余 4 小时 12 分", "82%"),
        RowItem("合盖", "合盖后保持唤醒", "开启"),
        RowItem("待处理", "2 项等待确认", "查看"),
    )
    PaneKind.CLIPBOARD -> listOf(
        RowItem("会议纪要草稿", "文本 · 1.2 KB", "2 分钟前"),
        RowItem("屏幕截图 2026-10-13", "图片 · 480 KB", "18 分钟前"),
        RowItem("https://example.com/spec", "链接", "1 小时前"),
        RowItem("设计稿批注", "文本 · 640 B", "3 小时前"),
    )
    PaneKind.FILES -> listOf(
        RowItem("report-final.pdf", "2.4 MB · 3 天后过期", "打开"),
        RowItem("mockups.zip", "18 MB · 6 天后过期", "打开"),
        RowItem("notes.md", "4 KB · 今天过期", "打开"),
    )
    PaneKind.SCREENSHOTS -> listOf(
        RowItem("截图 14:02", "2560 × 1440", "复制"),
        RowItem("截图 13:47", "2560 × 1440", "复制"),
        RowItem("截图 11:20", "1440 × 900", "复制"),
    )
    PaneKind.DEVICES -> listOf(
        RowItem("MacBook Pro", "已配对 · 刚刚在线", "发送"),
        RowItem("iPad Air", "已配对 · 12 分钟前", "发送"),
        RowItem("iPhone 17", "发现中", "配对"),
    )
    PaneKind.SETTINGS -> listOf(
        RowItem("权限", "辅助功能未授权", "去授权"),
        RowItem("语言", "简体中文", "更改"),
        RowItem("通知", "已开启", "更改"),
        RowItem("隐私与保留", "历史保留 7 天", "更改"),
    )
    PaneKind.BOARD -> listOf(
        RowItem("这个工作区还是空的", "拖动组件到这里", "添加"),
    )
}
