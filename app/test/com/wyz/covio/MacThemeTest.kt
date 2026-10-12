package com.wyz.covio.app.ui

import androidx.compose.ui.unit.dp
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class MacThemeTest {
    @Test
    fun `text tokens meet the contrast target on their surfaces`() {
        val lightPairs = listOf(
            LightMacTokens.primaryText to LightMacTokens.pageBackground,
            LightMacTokens.primaryText to LightMacTokens.cardBackground,
            LightMacTokens.secondaryText to LightMacTokens.pageBackground,
            LightMacTokens.secondaryText to LightMacTokens.cardBackground,
            LightMacTokens.brand to LightMacTokens.cardBackground,
            LightMacTokens.actionText to LightMacTokens.cardBackground,
            LightMacTokens.successText to LightMacTokens.cardBackground,
            LightMacTokens.warningText to LightMacTokens.cardBackground,
            LightMacTokens.errorText to LightMacTokens.cardBackground,
            LightMacTokens.darkSecondaryText to LightMacTokens.darkCard,
            LightMacTokens.darkSecondaryText to LightMacTokens.darkElevated,
        )
        lightPairs.forEach { (foreground, background) ->
            assertTrue(
                contrastRatio(foreground, background) >= 4.5,
                "Contrast was ${contrastRatio(foreground, background)} for $foreground on $background",
            )
        }
    }

    @Test
    fun `layout and motion tokens match the target specification`() {
        assertEquals(960.dp, MacLayoutSpec.windowWidth)
        assertEquals(640.dp, MacLayoutSpec.windowHeight)
        assertEquals(800.dp, MacLayoutSpec.minimumWindowWidth)
        assertEquals(560.dp, MacLayoutSpec.minimumWindowHeight)
        assertEquals(52.dp, MacLayoutSpec.tabBarHeight)
        assertEquals(32.dp, MacLayoutSpec.pageMargin)
        assertEquals(16.dp, MacLayoutSpec.cardSpacing)
        assertEquals(20.dp, MacLayoutSpec.cardPadding)
        assertEquals(12.dp, MacLayoutSpec.cardRadius)
        assertEquals(0.65f, MacMotionSpec.FLY_IN_SECONDS)
        assertEquals(0.42f, MacMotionSpec.LANDING_SWING_SECONDS)
        assertEquals(1.035f, MacMotionSpec.HOVER_SCALE)
        assertEquals(0.95f, MacMotionSpec.PRESSED_SCALE)
        assertEquals(0.55f, MacMotionSpec.FALLING_SECONDS)
        assertEquals(520f, MacMotionSpec.FALLING_DISTANCE)
    }
}
