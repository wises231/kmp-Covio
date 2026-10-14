package com.wyz.covio.preview.previews.workbench

import androidx.compose.ui.graphics.Color

/**
 * 打样用的取值。逐条手抄自 `docs/covio-design-contract.json`。
 *
 * 合同取值进 Kotlin 侧的通道还没建。见 #103 的后续动作第 3 条，记为 `Q-H`。
 * 通道建好后本文件整体换成生成代码。在那之前，每条都写清抄的是哪一枚令牌。
 * 合同里还没有的条目（工作台新形态），注释写清抄的是需求文档第 6 节。
 */
internal object Tokens {

    // ---- 颜色 ----

    /** `token/color/text-primary`，浅色档。 */
    val textPrimary = Color(0xFF1D1D1F)

    /** `token/color/text-secondary`，浅色档。 */
    val textSecondary = Color(0xFF6E6E73)

    /** `token/color/disabled-text`。内置工作区的删除项用它。 */
    val disabledText = Color(0xFF98989D)

    /** `token/color/brand`。收起态胶囊的底色。 */
    val brand = Color(0xFF4656A4)

    /** `token/color/action-fill`。选中态胶囊滑块与主按钮用它。 */
    val actionFill = Color(0xFF0A84FF)

    /** `token/color/text-on-accent`。 */
    val textOnAccent = Color(0xFFFFFFFF)

    /** `token/color/surface`。组件卡片的中性底色。 */
    val surface = Color(0xFFFFFFFF)

    /** `token/color/divider`。细边框与分隔线。 */
    val divider = Color(0xFFD1D1D6)

    /** `token/color/shadow`。面板的轻量阴影。 */
    val shadow = Color(0x0000002E)

    /** `token/color/error-text`。 */
    val errorText = Color(0xFFD70015)

    /** `token/color/error-bg`。 */
    val errorBg = Color(0xFFFFF0F1)

    /** `token/color/info-bg`。编辑模式状态条的底色。 */
    val infoBg = Color(0xFFEEF5FF)

    /** `token/color/success-fill`。状态点。 */
    val successFill = Color(0xFF34C759)

    /** `token/color/warning-fill`。状态点。 */
    val warningFill = Color(0xFFFF9F0A)

    /** `token/color/material-thick`，浅色档。面板是玻璃，取值来自这一档。 */
    val materialThick = Color(0xDBFFFFFF)

    /** `token/color/control-fill`。tab bar 上的输入框与次要按钮。 */
    val controlFill = Color(0xFFFFFFFF)

    /**
     * 组件卡片的底色。
     *
     * 抄的是 `token/art` 那一族。合同给这一族的用途写的是「插画、品牌装饰与缩略图占位」。
     * ADR-0002 决策 2 要求卡片各自带底色，所以打样先用这一族当卡片底色。
     * 合同给工作台加卡片底色条目之后（#77），换成那一批。
     */
    val cardTints = listOf(
        Color(0xFFFFF2BD), // token/art/fff2bd
        Color(0xFFE5F8EA), // token/art/e5f8ea
        Color(0xFFDDE7F8), // token/art/d9ddf0 一族
        Color(0xFFFFE8EA), // token/art/ffe8ea
        Color(0xFFFFF1DD), // token/art/fff1dd
        Color(0xFFE9EDF5), // token/art/e9edf5
    )

    // ---- 版式 ----
    // 需求文档第 6 节。合同里还没有工作台的条目，所以这一段是字面值。

    /** 面板圆角 22 点。 */
    val panelRadius = 22

    /** 组件卡片圆角 16 点，等于 `token/radius/large`。 */
    val cardRadius = 16

    /** `token/radius/pill`。页签滑块与胶囊。 */
    val pillRadius = 999

    /** `token/radius/control`。按钮与输入框。 */
    val controlRadius = 6

    /** 面板内边距 24 点，等于 `token/space/6`。 */
    val panelPadding = 24

    /** 组件卡片间距 12 点，等于 `token/space/3`。 */
    val gridGap = 12

    /** tab bar 高 46 点。 */
    val tabBarHeight = 46

    /** 页签高 30 点。 */
    val tabHeight = 30

    /** 收起态胶囊高 20 点。 */
    val capsuleHeight = 20

    /** 面板宽 960 点。窄于此值取最小宽度 720 点。 */
    val panelWidth = 960
    val panelMinWidth = 720

    /** 组件网格四列。行高 96 点。 */
    val gridColumns = 4
    val gridRowHeight = 96

    // ---- 动效 ----
    // `token/motion/*`。durationMs 是名义值，minMs 到 maxMs 是验收区间。

    /** `token/motion/hub-expand`：250 毫秒，弹性曲线，220 至 280 之间。 */
    const val EXPAND_MS = 250

    /** `token/motion/hub-collapse`：190 毫秒，缓出曲线，160 至 220 之间。 */
    const val COLLAPSE_MS = 190

    /** `token/motion/tab-switch`：160 毫秒，横向滑动加淡入。 */
    const val TAB_SWITCH_MS = 160

    /** `token/motion/error-appear`：160 毫秒，淡入和轻微位移。 */
    const val ERROR_APPEAR_MS = 160

    /** `token/motion/reduced-motion`：120 毫秒，只改变透明度。 */
    const val REDUCED_MOTION_MS = 120

    /** `token/motion/pointer-exit-collapse`：500 毫秒。 */
    const val POINTER_EXIT_MS = 500
}
