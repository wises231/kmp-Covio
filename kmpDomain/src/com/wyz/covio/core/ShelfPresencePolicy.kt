package com.wyz.covio.core

/**
 * 晾衣线工具栏的显示与收起规则。
 *
 * 规则来自 README 第 76 到 81 行与 §4.4：
 * 指针进菜单栏停留 250 毫秒才展开，离开 500 毫秒后收起，拖拽期间不收起。
 *
 * OS 调用留在各宿主：指针位置、屏幕查找、菜单栏高度、计时器、面板呈现与鼠标穿透。
 * 这个文件只回答一个问题：给定这些信号，现在该显示还是该收起。
 */
object ShelfPresencePolicy {
    /** 指针在菜单栏停留多久才展开工具栏。 */
    const val MENU_BAR_DWELL_SECONDS = 0.250
    /** 指针离开后多久收起工具栏。 */
    const val EXIT_DELAY_SECONDS = 0.500
    /** 新截图到达后自动收起的时间。 */
    const val AUTO_HIDE_SECONDS = 2.500
    /** 指针巡检间隔。与 Compose 版一致。 */
    const val POLL_INTERVAL_SECONDS = 0.100

    /**
     * 判断这一步要显示、要收起，还是什么都不做。
     *
     * 时间戳只在这里更新，宿主负责把结果存回去。
     * 门槛用「已过去的时间 >= 阈值」，正好等于阈值就算到点。
     */
    fun decide(input: ShelfPresenceInput): ShelfPresenceDecision {
        if (input.isPointerInMenuBar || input.isPointerOnShelf) {
            // 指针回到菜单栏或卡片上，离开计时作废。
            val since = input.menuBarCandidateAt ?: input.now
            return ShelfPresenceDecision(
                shouldShow = !input.isVisible && input.now - since >= MENU_BAR_DWELL_SECONDS,
                shouldHide = false,
                menuBarCandidateAt = since,
                exitCandidateAt = null,
            )
        }

        if (!input.isVisible) {
            // 指针既不在菜单栏也不在卡片上，停留计时作废。
            return ShelfPresenceDecision(
                shouldShow = false,
                shouldHide = false,
                menuBarCandidateAt = null,
                exitCandidateAt = input.exitCandidateAt,
            )
        }

        val since = input.exitCandidateAt ?: input.now
        return ShelfPresenceDecision(
            shouldShow = false,
            shouldHide = input.now - since >= EXIT_DELAY_SECONDS,
            menuBarCandidateAt = null,
            exitCandidateAt = since,
        )
    }
}

/**
 * 一次指针巡检的输入。
 *
 * [isPointerOnShelf] 已经把「指针在卡片上」「指针在面板内容上」「正在拖拽」
 * 三件事并起来了。所以拖拽期间一定落进菜单栏分支，不会走到收起分支。
 */
data class ShelfPresenceInput(
    /** 当前时间，秒。单调时钟。 */
    val now: Double,
    /** 工具栏当前是否显示。 */
    val isVisible: Boolean,
    /** 指针是否在菜单栏那一条里。 */
    val isPointerInMenuBar: Boolean,
    /** 指针是否在工具栏的交互区里。 */
    val isPointerOnShelf: Boolean,
    /** 指针开始停在菜单栏的时刻。还没停过就是 null。 */
    val menuBarCandidateAt: Double?,
    /** 指针离开工具栏的时刻。还没离开过就是 null。 */
    val exitCandidateAt: Double?,
)

/**
 * 一次指针巡检的结论。
 *
 * [shouldShow] 与 [shouldHide] 不会同时为真。
 * 两个时间戳都要原样存回运行时，下一步的判断依赖它们。
 */
data class ShelfPresenceDecision(
    val shouldShow: Boolean,
    val shouldHide: Boolean,
    val menuBarCandidateAt: Double?,
    val exitCandidateAt: Double?,
)
