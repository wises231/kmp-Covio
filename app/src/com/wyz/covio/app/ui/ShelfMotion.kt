package com.wyz.covio.app.ui

internal enum class ShelfVisualState {
    DEFAULT,
    HOVER,
    PRESSED,
    COPIED,
    DRAGGING,
    FLYING,
    FALLING,
}

internal data class ShelfMotionPlan(
    val scale: Float,
    val rotationAdjustmentDegrees: Float,
    val opacity: Float,
    val verticalOffset: Float,
    val breezeEnabled: Boolean,
    val fallAnimationEnabled: Boolean,
)

internal fun shelfMotionPlan(
    state: ShelfVisualState,
    reduceMotion: Boolean,
): ShelfMotionPlan {
    val base = when (state) {
        ShelfVisualState.DEFAULT -> ShelfMotionPlan(1f, 0f, 1f, 0f, !reduceMotion, false)
        ShelfVisualState.HOVER -> ShelfMotionPlan(MacMotionSpec.HOVER_SCALE, 0f, 1f, 0f, false, false)
        ShelfVisualState.PRESSED -> ShelfMotionPlan(MacMotionSpec.PRESSED_SCALE, -0.6f, 0.96f, 0f, false, false)
        ShelfVisualState.COPIED -> ShelfMotionPlan(1.01f, MacMotionSpec.COPY_SWING_DEGREES, 1f, 0f, false, false)
        ShelfVisualState.DRAGGING -> ShelfMotionPlan(0.98f, 0f, 0.92f, 0f, false, false)
        ShelfVisualState.FLYING -> ShelfMotionPlan(1.02f, 4f, 0.88f, 0f, false, false)
        ShelfVisualState.FALLING -> ShelfMotionPlan(
            scale = 0.96f,
            rotationAdjustmentDegrees = -2f,
            opacity = if (reduceMotion) 0.35f else 0.15f,
            verticalOffset = if (reduceMotion) 0f else MacMotionSpec.FALLING_DISTANCE,
            breezeEnabled = false,
            fallAnimationEnabled = !reduceMotion,
        )
    }
    return if (reduceMotion && state != ShelfVisualState.FALLING) {
        base.copy(
            scale = if (state == ShelfVisualState.PRESSED) MacMotionSpec.PRESSED_SCALE else 1f,
            rotationAdjustmentDegrees = 0f,
            opacity = if (state == ShelfVisualState.DRAGGING) 0.88f else 1f,
            verticalOffset = 0f,
            breezeEnabled = false,
            fallAnimationEnabled = false,
        )
    } else {
        base
    }
}
