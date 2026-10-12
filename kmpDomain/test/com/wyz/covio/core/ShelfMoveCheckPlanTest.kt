package com.wyz.covio.core

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * 移动完成检查的节奏。
 *
 * 数字本身没有对错，只是两侧必须一样。写死在这里，
 * 改的时候两边一起改。
 */
class ShelfMoveCheckPlanTest {
    @Test
    fun `the plan keeps its shipped values`() {
        assertEquals(0.120, ShelfMoveCheck.FLY_IN_DELAY_SECONDS)
        assertEquals(0.600, ShelfMoveCheck.plan.firstDelaySeconds)
        assertEquals(0.300, ShelfMoveCheck.plan.intervalSeconds)
        assertEquals(4, ShelfMoveCheck.plan.checkCount)
    }

    /** 检查次数为正，否则循环一次都不跑，卡片永远飞回来。 */
    @Test
    fun `the plan checks at least once`() {
        assertTrue(ShelfMoveCheck.plan.checkCount > 0, "检查次数必须为正，否则循环一次都不跑")
    }
}
