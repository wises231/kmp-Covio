package com.wyz.covio.app.ui

import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlin.math.max
import kotlin.math.min
import kotlin.math.pow

internal data class MacTokens(
    val pageBackground: Color,
    val cardBackground: Color,
    val elevatedBackground: Color,
    val primaryText: Color,
    val secondaryText: Color,
    val tertiaryText: Color,
    val separator: Color,
    val brand: Color,
    val actionText: Color,
    val success: Color,
    val successText: Color,
    val warning: Color,
    val warningText: Color,
    val error: Color,
    val errorText: Color,
    val focusRing: Color,
    val disabled: Color,
    val darkBackground: Color,
    val darkCard: Color,
    val darkElevated: Color,
    val darkPrimaryText: Color,
    val darkSecondaryText: Color,
)

internal val LightMacTokens = MacTokens(
    pageBackground = Color(0xFFF2F2F7),
    cardBackground = Color(0xFFFFFFFF),
    elevatedBackground = Color(0xFFFFFFFF),
    primaryText = Color(0xFF1D1D1F),
    secondaryText = Color(0xFF6E6E73),
    tertiaryText = Color(0xFF8E8E93),
    separator = Color(0x1F000000),
    brand = Color(0xFF4656A4),
    actionText = Color(0xFF0066CC),
    success = Color(0xFF34C759),
    successText = Color(0xFF1E7A34),
    warning = Color(0xFFFF9F0A),
    warningText = Color(0xFF8A4B00),
    error = Color(0xFFD70015),
    errorText = Color(0xFFD70015),
    focusRing = Color(0xFF0A84FF),
    disabled = Color(0xFF98989D),
    darkBackground = Color(0xFF1C1C1E),
    darkCard = Color(0xFF2C2C2E),
    darkElevated = Color(0xFF3A3A3C),
    darkPrimaryText = Color(0xFFF5F5F7),
    darkSecondaryText = Color(0xFFAEAEB2),
)

internal object MacSpacing {
    val xs = 4.dp
    val sm = 8.dp
    val md = 12.dp
    val lg = 16.dp
    val xl = 20.dp
    val xxl = 24.dp
    val page = 32.dp
    val section = 40.dp
}

internal object MacRadius {
    val small = 8.dp
    val medium = 12.dp
    val large = 16.dp
    val pill = 999.dp
}

internal object MacLayoutSpec {
    val windowWidth = 960.dp
    val windowHeight = 640.dp
    val minimumWindowWidth = 800.dp
    val minimumWindowHeight = 560.dp
    val tabBarHeight = 52.dp
    val pageMargin = 32.dp
    val cardSpacing = 16.dp
    val cardPadding = 20.dp
    val cardRadius = 12.dp
}

internal object MacMotionSpec {
    const val FLY_IN_SECONDS = 0.65f
    const val LANDING_SWING_SECONDS = 0.42f
    const val HOVER_SCALE = 1.035f
    const val PRESSED_SCALE = 0.95f
    const val COPY_SWING_DEGREES = 3f
    const val COPY_TOAST_SECONDS = 1.2f
    const val BREEZE_MIN_SECONDS = 7
    const val BREEZE_MAX_SECONDS = 16
    const val BREEZE_MIN_DEGREES = 1.6f
    const val BREEZE_MAX_DEGREES = 3.4f
    const val FALLING_SECONDS = 0.55f
    const val FALLING_DISTANCE = 520f
    const val REDUCED_MOTION_OPACITY_MILLIS = 120L
}

private val DisplayFont = FontFamily.SansSerif
private val TextFont = FontFamily.SansSerif

internal object MacTypography {
    val windowTitle = TextStyle(
        fontFamily = DisplayFont,
        fontWeight = FontWeight.SemiBold,
        fontSize = 20.sp,
        color = LightMacTokens.primaryText,
    )
    val pageTitle = TextStyle(
        fontFamily = DisplayFont,
        fontWeight = FontWeight.SemiBold,
        fontSize = 26.sp,
        color = LightMacTokens.primaryText,
    )
    val sectionTitle = TextStyle(
        fontFamily = TextFont,
        fontWeight = FontWeight.SemiBold,
        fontSize = 16.sp,
        color = LightMacTokens.primaryText,
    )
    val body = TextStyle(
        fontFamily = TextFont,
        fontWeight = FontWeight.Normal,
        fontSize = 13.sp,
        color = LightMacTokens.primaryText,
    )
    val secondaryBody = body.copy(color = LightMacTokens.secondaryText)
    val caption = TextStyle(
        fontFamily = TextFont,
        fontWeight = FontWeight.Normal,
        fontSize = 11.sp,
        color = LightMacTokens.secondaryText,
    )
}

internal val LocalMacTokens = staticCompositionLocalOf { LightMacTokens }

@Composable
internal fun MacTheme(content: @Composable () -> Unit) {
    CompositionLocalProvider(LocalMacTokens provides LightMacTokens) {
        content()
    }
}

internal fun contrastRatio(foreground: Color, background: Color): Double {
    val lighter = max(relativeLuminance(foreground), relativeLuminance(background))
    val darker = min(relativeLuminance(foreground), relativeLuminance(background))
    return (lighter + 0.05) / (darker + 0.05)
}

private fun relativeLuminance(color: Color): Double {
    fun channel(value: Float): Double {
        val normalized = value.toDouble()
        return if (normalized <= 0.04045) normalized / 12.92 else ((normalized + 0.055) / 1.055).pow(2.4)
    }
    return 0.2126 * channel(color.red) + 0.7152 * channel(color.green) + 0.0722 * channel(color.blue)
}
