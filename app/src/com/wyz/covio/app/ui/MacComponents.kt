package com.wyz.covio.app.ui

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.OutlinedTextField
import androidx.compose.material.Surface
import androidx.compose.material.Switch
import androidx.compose.material.SwitchDefaults
import androidx.compose.material.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.IntRect
import androidx.compose.ui.unit.IntSize
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Popup
import androidx.compose.ui.window.PopupPositionProvider
import androidx.compose.ui.window.PopupProperties

internal enum class MacComponentState {
    DEFAULT,
    HOVER,
    PRESSED,
    FOCUSED,
    SELECTED,
    DISABLED,
    LOADING,
    SUCCESS,
    WARNING,
    ERROR,
}

internal enum class MacButtonStyle { PRIMARY, SECONDARY, PLAIN }
internal enum class MacAlertKind { INFO, SUCCESS, WARNING, ERROR }

@Composable
internal fun MacWindow(content: @Composable ColumnScope.() -> Unit) {
    MacTheme {
        Column(
            modifier = Modifier.fillMaxSize().background(LocalMacTokens.current.pageBackground),
            content = content,
        )
    }
}

@Composable
internal fun MacCard(
    modifier: Modifier = Modifier,
    padding: Dp = MacSpacing.xl,
    selected: Boolean = false,
    content: @Composable ColumnScope.() -> Unit,
) {
    val tokens = LocalMacTokens.current
    Surface(
        modifier = modifier
            .shadow(if (selected) 5.dp else 2.dp, RoundedCornerShape(MacRadius.medium))
            .border(
                width = 1.dp,
                color = if (selected) tokens.brand.copy(alpha = 0.45f) else tokens.separator,
                shape = RoundedCornerShape(MacRadius.medium),
            ),
        shape = RoundedCornerShape(MacRadius.medium),
        color = tokens.cardBackground,
    ) {
        Column(Modifier.padding(padding), verticalArrangement = Arrangement.spacedBy(MacSpacing.sm), content = content)
    }
}

@Composable
internal fun MacSettingRow(
    title: String,
    description: String? = null,
    enabled: Boolean = true,
    control: @Composable RowScope.() -> Unit,
) {
    val tokens = LocalMacTokens.current
    Row(
        modifier = Modifier.fillMaxWidth().padding(vertical = MacSpacing.sm),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(MacSpacing.lg),
    ) {
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text(title, color = if (enabled) tokens.primaryText else tokens.disabled, style = MacTypography.body)
            description?.let { Text(it, color = tokens.secondaryText, style = MacTypography.caption) }
        }
        control()
    }
}

@Composable
internal fun MacSwitch(
    checked: Boolean,
    enabled: Boolean = true,
    contentDescription: String,
    onCheckedChange: (Boolean) -> Unit,
) {
    val tokens = LocalMacTokens.current
    Switch(
        checked = checked,
        onCheckedChange = if (enabled) onCheckedChange else null,
        colors = SwitchDefaults.colors(
            checkedThumbColor = Color.White,
            checkedTrackColor = tokens.brand,
            uncheckedThumbColor = Color.White,
            uncheckedTrackColor = tokens.disabled.copy(alpha = 0.55f),
            disabledCheckedThumbColor = Color.White.copy(alpha = 0.72f),
            disabledCheckedTrackColor = tokens.brand.copy(alpha = 0.35f),
        ),
        modifier = Modifier.semantics { this.contentDescription = contentDescription },
    )
}

@Composable
internal fun MacButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    style: MacButtonStyle = MacButtonStyle.SECONDARY,
) {
    val tokens = LocalMacTokens.current
    val background = when (style) {
        MacButtonStyle.PRIMARY -> tokens.brand
        MacButtonStyle.SECONDARY -> tokens.cardBackground
        MacButtonStyle.PLAIN -> Color.Transparent
    }
    val contentColor = when {
        !enabled -> tokens.disabled
        style == MacButtonStyle.PRIMARY -> Color.White
        style == MacButtonStyle.PLAIN -> tokens.actionText
        else -> tokens.primaryText
    }
    Box(
        modifier = modifier
            .clip(RoundedCornerShape(MacRadius.small))
            .background(background)
            .then(
                if (style == MacButtonStyle.SECONDARY) Modifier.border(1.dp, tokens.separator, RoundedCornerShape(MacRadius.small))
                else Modifier,
            )
            .clickable(enabled = enabled, onClick = onClick)
            .semantics {
                role = Role.Button
                contentDescription = text
            }
            .padding(horizontal = MacSpacing.md, vertical = 7.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(text, color = contentColor, fontSize = 13.sp, fontWeight = FontWeight.Medium)
    }
}

@Composable
internal fun MacNumberField(
    label: String,
    value: String,
    onValueChange: (String) -> Unit,
    isError: Boolean,
    modifier: Modifier = Modifier,
) {
    OutlinedTextField(
        value = value,
        onValueChange = onValueChange,
        label = { Text(label, style = MacTypography.caption) },
        isError = isError,
        singleLine = true,
        modifier = modifier.fillMaxWidth(),
    )
}

@Composable
internal fun MacSegmented(
    options: List<String>,
    selectedIndex: Int,
    onSelect: (Int) -> Unit,
    modifier: Modifier = Modifier,
) {
    val tokens = LocalMacTokens.current
    Row(
        modifier = modifier
            .clip(RoundedCornerShape(MacRadius.small))
            .background(tokens.pageBackground)
            .border(1.dp, tokens.separator, RoundedCornerShape(MacRadius.small))
            .padding(2.dp),
        horizontalArrangement = Arrangement.spacedBy(2.dp),
    ) {
        options.forEachIndexed { index, option ->
            val selected = index == selectedIndex
            Box(
                modifier = Modifier
                    .clip(RoundedCornerShape(6.dp))
                    .background(if (selected) tokens.cardBackground else Color.Transparent)
                    .clickable { onSelect(index) }
                    .padding(horizontal = MacSpacing.md, vertical = 5.dp),
                contentAlignment = Alignment.Center,
            ) {
                Text(option, color = if (selected) tokens.primaryText else tokens.secondaryText, style = MacTypography.caption)
            }
        }
    }
}

@Composable
internal fun MacStatusBadge(text: String, color: Color) {
    Box(
        modifier = Modifier
            .clip(RoundedCornerShape(MacRadius.pill))
            .background(color.copy(alpha = 0.14f))
            .border(1.dp, color.copy(alpha = 0.45f), RoundedCornerShape(MacRadius.pill))
            .padding(horizontal = 10.dp, vertical = 4.dp),
    ) {
        Text(text, color = color, style = MacTypography.caption, fontWeight = FontWeight.Medium)
    }
}

@Composable
internal fun MacAlert(text: String, kind: MacAlertKind) {
    val tokens = LocalMacTokens.current
    val color = when (kind) {
        MacAlertKind.INFO -> tokens.actionText
        MacAlertKind.SUCCESS -> tokens.successText
        MacAlertKind.WARNING -> tokens.warningText
        MacAlertKind.ERROR -> tokens.errorText
    }
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(MacRadius.small))
            .background(color.copy(alpha = 0.12f))
            .border(1.dp, color.copy(alpha = 0.32f), RoundedCornerShape(MacRadius.small))
            .padding(MacSpacing.md),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(text, color = color, style = MacTypography.body)
    }
}

@Composable
internal fun MacToast(text: String, modifier: Modifier = Modifier) {
    val tokens = LocalMacTokens.current
    Surface(
        modifier = modifier.shadow(8.dp, RoundedCornerShape(MacRadius.medium)),
        color = tokens.darkElevated.copy(alpha = 0.96f),
        shape = RoundedCornerShape(MacRadius.medium),
    ) {
        Text(text, color = Color.White, style = MacTypography.body, modifier = Modifier.padding(horizontal = 14.dp, vertical = 8.dp))
    }
}

@Composable
internal fun MacDialog(
    title: String,
    body: String,
    modifier: Modifier = Modifier,
    content: @Composable ColumnScope.() -> Unit,
) {
    MacCard(modifier = modifier, padding = MacSpacing.xxl, selected = true) {
        Text(title, style = MacTypography.windowTitle)
        Text(body, style = MacTypography.secondaryBody)
        Spacer(Modifier.height(MacSpacing.md))
        content()
    }
}

@Composable
internal fun MacToolbar(content: @Composable RowScope.() -> Unit) {
    val tokens = LocalMacTokens.current
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(tokens.cardBackground)
            .border(1.dp, tokens.separator, RoundedCornerShape(MacRadius.small))
            .padding(horizontal = MacSpacing.md, vertical = MacSpacing.sm),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(MacSpacing.sm),
        content = content,
    )
}

@Composable
internal fun MacTabBar(
    labels: List<String>,
    selectedIndex: Int,
    onSelect: (Int) -> Unit,
) {
    val tokens = LocalMacTokens.current
    Row(
        modifier = Modifier.fillMaxWidth().height(52.dp).background(tokens.cardBackground),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Spacer(Modifier.width(MacSpacing.page))
        labels.forEachIndexed { index, label ->
            val selected = index == selectedIndex
            Box(
                modifier = Modifier
                    .clip(RoundedCornerShape(MacRadius.small))
                    .clickable { onSelect(index) }
                    .padding(horizontal = MacSpacing.md, vertical = 8.dp),
                contentAlignment = Alignment.Center,
            ) {
                Text(
                    text = label,
                    color = if (selected) tokens.brand else tokens.secondaryText,
                    fontWeight = if (selected) FontWeight.SemiBold else FontWeight.Normal,
                    fontSize = 13.sp,
                )
            }
            Spacer(Modifier.width(MacSpacing.xs))
        }
    }
}

@Composable
internal fun MacContextMenu(
    expanded: Boolean,
    onDismissRequest: () -> Unit,
    content: @Composable ColumnScope.() -> Unit,
) {
    if (!expanded) return
    val tokens = LocalMacTokens.current
    Popup(
        popupPositionProvider = MacMenuPositionProvider,
        onDismissRequest = onDismissRequest,
        properties = PopupProperties(focusable = true),
    ) {
        Surface(
            modifier = Modifier
                .width(220.dp)
                .shadow(14.dp, RoundedCornerShape(MacRadius.medium))
                .border(1.dp, tokens.separator, RoundedCornerShape(MacRadius.medium)),
            color = tokens.cardBackground,
            shape = RoundedCornerShape(MacRadius.medium),
        ) {
            Column(Modifier.padding(vertical = 6.dp), content = content)
        }
    }
}

private object MacMenuPositionProvider : PopupPositionProvider {
    override fun calculatePosition(
        anchorBounds: IntRect,
        windowSize: IntSize,
        layoutDirection: LayoutDirection,
        popupContentSize: IntSize,
    ): IntOffset {
        val x = anchorBounds.left.coerceIn(0, (windowSize.width - popupContentSize.width).coerceAtLeast(0))
        val below = anchorBounds.bottom + 4
        val y = if (below + popupContentSize.height <= windowSize.height) {
            below
        } else {
            (anchorBounds.top - popupContentSize.height - 4).coerceAtLeast(0)
        }
        return IntOffset(x, y)
    }
}

@Composable
internal fun MacMenuItem(text: String, enabled: Boolean = true, onClick: () -> Unit) {
    val tokens = LocalMacTokens.current
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(enabled = enabled, onClick = onClick)
            .semantics { role = Role.Button; contentDescription = text }
            .padding(horizontal = MacSpacing.md, vertical = 7.dp),
    ) {
        Text(text, color = if (enabled) tokens.primaryText else tokens.disabled, style = MacTypography.body)
    }
}

@Composable
internal fun ScreenshotCard(
    modifier: Modifier = Modifier,
    rotationDegrees: Float = 0f,
    scale: Float = 1f,
    shadow: Dp = 8.dp,
    content: @Composable BoxScope.() -> Unit,
) {
    val tokens = LocalMacTokens.current
    Box(
        modifier = modifier
            .graphicsLayer {
                rotationZ = rotationDegrees
                scaleX = scale
                scaleY = scale
            }
            .shadow(shadow, RoundedCornerShape(MacRadius.large))
            .clip(RoundedCornerShape(MacRadius.large))
            .background(tokens.cardBackground)
            .border(1.dp, tokens.separator, RoundedCornerShape(MacRadius.large)),
        content = content,
    )
}

@Composable
internal fun Clothespin(modifier: Modifier = Modifier) {
    val tokens = LocalMacTokens.current
    Canvas(modifier = modifier.size(9.dp, 26.dp)) {
        val ink = tokens.primaryText.copy(alpha = 0.92f)
        drawRoundRect(
            color = ink,
            topLeft = Offset(2.6f, 0.8f),
            size = Size(3.8f, 24.4f),
            cornerRadius = CornerRadius(1.8f, 1.8f),
        )
        drawLine(
            color = Color.White.copy(alpha = 0.75f),
            start = Offset(3.4f, 3.2f),
            end = Offset(3.4f, 22.2f),
            strokeWidth = 0.8f,
            cap = StrokeCap.Round,
        )
        drawRoundRect(
            color = ink,
            topLeft = Offset(1.2f, 10.5f),
            size = Size(6.6f, 4.2f),
            cornerRadius = CornerRadius(1.4f, 1.4f),
        )
    }
}
