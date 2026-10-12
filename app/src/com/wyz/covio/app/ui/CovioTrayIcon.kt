package com.wyz.covio.app.ui

import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.painter.Painter

internal class CovioTrayIcon(
    private val state: TrayIconState,
) : Painter() {
    override val intrinsicSize: Size = Size(22f, 22f)

    override fun DrawScope.onDraw() {
        val ink = Color(0xFF8E8E93)
        when (state) {
            TrayIconState.HELPER_ERROR -> drawHelperError(ink)
            TrayIconState.DISABLED -> drawDisabled(ink)
            TrayIconState.LOW_BATTERY -> drawBattery(ink, low = true)
            TrayIconState.CHARGING -> drawCharging(ink)
            TrayIconState.LID_PREVENTION -> drawLidPrevention(ink)
            TrayIconState.IDLE_PREVENTION -> drawIdlePrevention(ink)
            TrayIconState.DEFAULT -> drawDefault(ink)
        }
    }

    private fun DrawScope.drawDefault(ink: Color) {
        drawRope(ink)
        drawPin(ink, centerX = 11f, ropeY = 6f, open = false)
    }

    private fun DrawScope.drawDisabled(ink: Color) {
        val path = Path().apply {
            moveTo(2.5f, 5.5f)
            quadraticBezierTo(11f, 10.5f, 19.5f, 5.5f)
        }
        drawPath(path, ink, style = Stroke(width = 1.5f, cap = StrokeCap.Round))
        drawPin(ink, centerX = 11f, ropeY = 8f, open = true, tilt = 10f)
    }

    private fun DrawScope.drawBattery(ink: Color, low: Boolean) {
        drawRope(ink)
        drawPin(ink, centerX = 11f, ropeY = 6f, open = false, bodyAlpha = 0.55f)
        drawRoundRect(
            color = ink,
            topLeft = Offset(7.5f, 10.5f),
            size = Size(7f, 5.5f),
            cornerRadius = CornerRadius(1.2f, 1.2f),
            style = Stroke(width = 1.2f),
        )
        drawRoundRect(
            color = ink,
            topLeft = Offset(14.5f, 12f),
            size = Size(1.2f, 2.5f),
            cornerRadius = CornerRadius(0.4f, 0.4f),
        )
        if (low) {
            drawRoundRect(
                color = ink,
                topLeft = Offset(8.8f, 11.8f),
                size = Size(1.8f, 2.8f),
                cornerRadius = CornerRadius(0.5f, 0.5f),
            )
        }
    }

    private fun DrawScope.drawCharging(ink: Color) {
        drawRope(ink)
        drawPin(ink, centerX = 11f, ropeY = 6f, open = false, bodyAlpha = 0.55f)
        val bolt = Path().apply {
            moveTo(11.8f, 9.8f)
            lineTo(9.2f, 14.2f)
            lineTo(11.1f, 14.2f)
            lineTo(10.1f, 17.2f)
            lineTo(13.2f, 12.6f)
            lineTo(11.3f, 12.6f)
            close()
        }
        drawPath(bolt, ink)
    }

    private fun DrawScope.drawIdlePrevention(ink: Color) {
        drawRope(ink, y = 5.5f)
        drawRope(ink, y = 10.5f)
        drawPin(ink, centerX = 11f, ropeY = 8f, open = false)
        drawLine(
            color = ink,
            start = Offset(4f, 16.5f),
            end = Offset(18f, 16.5f),
            strokeWidth = 1.5f,
            cap = StrokeCap.Round,
        )
    }

    private fun DrawScope.drawLidPrevention(ink: Color) {
        drawRope(ink)
        val lid = Path().apply {
            moveTo(4.5f, 16.5f)
            lineTo(17.5f, 16.5f)
            lineTo(15.8f, 12.8f)
            lineTo(6.2f, 12.8f)
            close()
        }
        drawPath(lid, ink, style = Stroke(width = 1.4f, cap = StrokeCap.Round))
        drawPin(ink, centerX = 11f, ropeY = 6f, open = false, tilt = -18f)
    }

    private fun DrawScope.drawHelperError(ink: Color) {
        drawLine(
            color = ink,
            start = Offset(2.5f, 6f),
            end = Offset(8.2f, 8.2f),
            strokeWidth = 1.5f,
            cap = StrokeCap.Round,
        )
        drawLine(
            color = ink,
            start = Offset(13.8f, 8.2f),
            end = Offset(19.5f, 6f),
            strokeWidth = 1.5f,
            cap = StrokeCap.Round,
        )
        drawPin(ink, centerX = 11f, ropeY = 9f, open = true, tilt = 24f)
        drawLine(
            color = ink,
            start = Offset(7.5f, 17f),
            end = Offset(10f, 14.5f),
            strokeWidth = 1.4f,
            cap = StrokeCap.Round,
        )
        drawLine(
            color = ink,
            start = Offset(14.5f, 17f),
            end = Offset(12f, 14.5f),
            strokeWidth = 1.4f,
            cap = StrokeCap.Round,
        )
    }

    private fun DrawScope.drawRope(ink: Color, y: Float = 5.5f) {
        val path = Path().apply {
            moveTo(2.5f, y)
            quadraticBezierTo(11f, y + 4.5f, 19.5f, y)
        }
        drawPath(path, ink, style = Stroke(width = 1.5f, cap = StrokeCap.Round))
    }

    private fun DrawScope.drawPin(
        ink: Color,
        centerX: Float,
        ropeY: Float,
        open: Boolean,
        tilt: Float = 0f,
        bodyAlpha: Float = 1f,
    ) {
        val x = if (tilt == 0f) {
            centerX
        } else {
            val radians = Math.toRadians(tilt.toDouble())
            centerX + (ropeY - (ropeY + 15f)) * kotlin.math.sin(radians).toFloat()
        }
        val top = if (open) ropeY - 4f else ropeY - 1f
        drawRoundRect(
            color = ink.copy(alpha = bodyAlpha),
            topLeft = Offset(x - 2.1f, top),
            size = Size(4.2f, 15.5f),
            cornerRadius = CornerRadius(1.8f, 1.8f),
        )
        drawLine(
            color = ink.copy(alpha = bodyAlpha),
            start = Offset(x - 2.8f, top + 5.5f),
            end = Offset(x + 2.8f, top + 5.5f),
            strokeWidth = 1.4f,
            cap = StrokeCap.Round,
        )
    }
}
