package com.wyz.covio

import com.wyz.covio.app.ui.MacMotionSpec
import com.wyz.covio.app.ui.ShelfVisualState
import com.wyz.covio.app.ui.shelfMotionPlan
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class ShelfMotionTest {
    @Test
    fun `card states map to the approved motion plan`() {
        assertEquals(1f, shelfMotionPlan(ShelfVisualState.DEFAULT, false).scale)
        assertTrue(shelfMotionPlan(ShelfVisualState.DEFAULT, false).breezeEnabled)
        assertEquals(MacMotionSpec.HOVER_SCALE, shelfMotionPlan(ShelfVisualState.HOVER, false).scale)
        assertEquals(MacMotionSpec.PRESSED_SCALE, shelfMotionPlan(ShelfVisualState.PRESSED, false).scale)
        assertEquals(MacMotionSpec.COPY_SWING_DEGREES, shelfMotionPlan(ShelfVisualState.COPIED, false).rotationAdjustmentDegrees)
        assertEquals(0.92f, shelfMotionPlan(ShelfVisualState.DRAGGING, false).opacity)
        assertFalse(shelfMotionPlan(ShelfVisualState.FLYING, false).breezeEnabled)
        assertEquals(MacMotionSpec.FALLING_DISTANCE, shelfMotionPlan(ShelfVisualState.FALLING, false).verticalOffset)
        assertTrue(shelfMotionPlan(ShelfVisualState.FALLING, false).fallAnimationEnabled)
    }

    @Test
    fun `reduced motion removes continuous and large travel effects`() {
        listOf(
            ShelfVisualState.DEFAULT,
            ShelfVisualState.HOVER,
            ShelfVisualState.PRESSED,
            ShelfVisualState.COPIED,
            ShelfVisualState.DRAGGING,
            ShelfVisualState.FLYING,
        ).forEach { state ->
            val plan = shelfMotionPlan(state, true)
            assertEquals(0f, plan.rotationAdjustmentDegrees)
            assertFalse(plan.breezeEnabled)
            assertFalse(plan.fallAnimationEnabled)
            if (state != ShelfVisualState.PRESSED) assertEquals(1f, plan.scale)
        }
        val falling = shelfMotionPlan(ShelfVisualState.FALLING, true)
        assertEquals(0f, falling.verticalOffset)
        assertEquals(0.35f, falling.opacity)
        assertFalse(falling.fallAnimationEnabled)
    }
}
