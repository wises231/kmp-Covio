package com.wyz.covio.core

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

/**
 * 指针巡检的判定。
 *
 * 门槛都写成「已过去的时间 >= 阈值」，所以正好等于阈值时必须到点。
 * 差一个 epsilon 时不能到点：差一点点就提前展开会让工具栏乱闪。
 */
class ShelfPresencePolicyTest {
    private fun input(
        now: Double,
        isVisible: Boolean = false,
        isPointerInMenuBar: Boolean = false,
        isPointerOnShelf: Boolean = false,
        menuBarCandidateAt: Double? = null,
        exitCandidateAt: Double? = null,
    ) = ShelfPresenceInput(
        now = now,
        isVisible = isVisible,
        isPointerInMenuBar = isPointerInMenuBar,
        isPointerOnShelf = isPointerOnShelf,
        menuBarCandidateAt = menuBarCandidateAt,
        exitCandidateAt = exitCandidateAt,
    )

    // MARK: 常量

    @Test
    fun `the timings keep their shipped values`() {
        assertEquals(0.250, ShelfPresencePolicy.MENU_BAR_DWELL_SECONDS)
        assertEquals(0.500, ShelfPresencePolicy.EXIT_DELAY_SECONDS)
        assertEquals(2.500, ShelfPresencePolicy.AUTO_HIDE_SECONDS)
        assertEquals(0.100, ShelfPresencePolicy.POLL_INTERVAL_SECONDS)
    }

    // MARK: 展开

    @Test
    fun `the first pass in the menu bar only starts the clock`() {
        val decision = ShelfPresencePolicy.decide(input(now = 100.0, isPointerInMenuBar = true))

        assertFalse(decision.shouldShow, "刚进菜单栏就展开，缺了停留时间")
        assertFalse(decision.shouldHide)
        assertEquals(100.0, decision.menuBarCandidateAt, "第一次经过要记下时刻")
        assertNull(decision.exitCandidateAt)
    }

    @Test
    fun `dwelling exactly the threshold expands the shelf`() {
        val decision = ShelfPresencePolicy.decide(
            input(
                now = 100.0 + ShelfPresencePolicy.MENU_BAR_DWELL_SECONDS,
                isPointerInMenuBar = true,
                menuBarCandidateAt = 100.0,
            ),
        )

        assertTrue(decision.shouldShow, "正好到阈值就该展开")
    }

    /** 差一个 epsilon 不能展开。 */
    @Test
    fun `one epsilon short of the threshold does not expand`() {
        val decision = ShelfPresencePolicy.decide(
            input(
                now = 100.0 + ShelfPresencePolicy.MENU_BAR_DWELL_SECONDS - 0.001,
                isPointerInMenuBar = true,
                menuBarCandidateAt = 100.0,
            ),
        )

        assertFalse(decision.shouldShow)
        assertEquals(100.0, decision.menuBarCandidateAt, "停留起点不能被重置，否则永远等不到")
    }

    @Test
    fun `an already visible shelf is not shown twice`() {
        val decision = ShelfPresencePolicy.decide(
            input(
                now = 100.0 + ShelfPresencePolicy.MENU_BAR_DWELL_SECONDS,
                isVisible = true,
                isPointerInMenuBar = true,
                menuBarCandidateAt = 100.0,
            ),
        )

        assertFalse(decision.shouldShow, "已经显示时不该再调一次 show")
    }

    /** 指针在卡片上也走菜单栏那一条：卡片是工具栏的一部分。 */
    @Test
    fun `the pointer on a card counts as over the shelf`() {
        val decision = ShelfPresencePolicy.decide(
            input(
                now = 100.0 + ShelfPresencePolicy.MENU_BAR_DWELL_SECONDS,
                isPointerOnShelf = true,
                menuBarCandidateAt = 100.0,
            ),
        )

        assertTrue(decision.shouldShow)
    }

    // MARK: 收起

    @Test
    fun `the first pass outside only starts the exit clock`() {
        val decision = ShelfPresencePolicy.decide(input(now = 200.0, isVisible = true))

        assertFalse(decision.shouldHide, "刚离开就收起，缺了离开延迟")
        assertNull(decision.menuBarCandidateAt)
        assertEquals(200.0, decision.exitCandidateAt)
    }

    @Test
    fun `leaving for exactly the delay hides the shelf`() {
        val decision = ShelfPresencePolicy.decide(
            input(
                now = 200.0 + ShelfPresencePolicy.EXIT_DELAY_SECONDS,
                isVisible = true,
                exitCandidateAt = 200.0,
            ),
        )

        assertTrue(decision.shouldHide, "正好到阈值就该收起")
    }

    @Test
    fun `one epsilon short of the exit delay keeps the shelf`() {
        val decision = ShelfPresencePolicy.decide(
            input(
                now = 200.0 + ShelfPresencePolicy.EXIT_DELAY_SECONDS - 0.001,
                isVisible = true,
                exitCandidateAt = 200.0,
            ),
        )

        assertFalse(decision.shouldHide)
    }

    /** 工具栏没显示时不做收起动作，否则会白调一次 dismiss。 */
    @Test
    fun `a hidden shelf is never asked to hide`() {
        val decision = ShelfPresencePolicy.decide(
            input(now = 200.0 + 60.0, isVisible = false, exitCandidateAt = 200.0),
        )

        assertFalse(decision.shouldHide)
        assertNull(decision.menuBarCandidateAt, "不在菜单栏时停留计时作废")
    }

    // MARK: 两个候选时刻的互斥

    /** 回到菜单栏或卡片上，离开计时作废，否则回来一会儿又被收起。 */
    @Test
    fun `coming back clears the exit candidate`() {
        val decision = ShelfPresencePolicy.decide(
            input(
                now = 200.0 + ShelfPresencePolicy.EXIT_DELAY_SECONDS - 0.1,
                isVisible = true,
                isPointerInMenuBar = true,
                exitCandidateAt = 200.0,
            ),
        )

        assertNull(decision.exitCandidateAt, "离开计时应当被清掉")
        assertEquals(200.0 + ShelfPresencePolicy.EXIT_DELAY_SECONDS - 0.1, decision.menuBarCandidateAt)
        assertFalse(decision.shouldHide)
    }

    /** 离开菜单栏之后停留计时也要作废，否则下次进来会立刻展开。 */
    @Test
    fun `leaving clears the menu bar candidate`() {
        val decision = ShelfPresencePolicy.decide(
            input(now = 300.0, isVisible = true, menuBarCandidateAt = 100.0, exitCandidateAt = 200.0),
        )

        assertNull(decision.menuBarCandidateAt)
        assertEquals(200.0, decision.exitCandidateAt, "已经在计时就沿用原起点")
    }

    @Test
    fun `a decision never asks to show and hide at the same time`() {
        for (visible in listOf(true, false)) {
            for (inMenuBar in listOf(true, false)) {
                for (onShelf in listOf(true, false)) {
                    val decision = ShelfPresencePolicy.decide(
                        input(
                            now = 100.0,
                            isVisible = visible,
                            isPointerInMenuBar = inMenuBar,
                            isPointerOnShelf = onShelf,
                            menuBarCandidateAt = 0.0,
                            exitCandidateAt = 0.0,
                        ),
                    )
                    assertFalse(
                        decision.shouldShow && decision.shouldHide,
                        "visible=$visible inMenuBar=$inMenuBar onShelf=$onShelf",
                    )
                }
            }
        }
    }
}
