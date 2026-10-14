package com.wyz.covio.preview.previews.workbench

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectDragGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlin.math.roundToInt

/**
 * 首页的 bento 网格。S4 与 F6。
 *
 * 卡片尺寸按内容分档，每张卡片带自己的底色。拖动后吸附到网格列。
 */

/** 网格上落好位置的一块卡片。 */
internal data class Placed(val widget: Widget, val col: Int, val row: Int, val order: Int)

/**
 * 按顺序把卡片摆进网格。先放先占，遇到放不下的就往下找一行。
 *
 * 这是最朴素的装箱。真正的排布规则还没定，打样先用它把 bento 的观感画出来。
 */
internal fun packWidgets(widgets: List<Widget>, columns: Int): List<Placed> {
    val occupied = mutableSetOf<Pair<Int, Int>>()
    val placed = mutableListOf<Placed>()

    widgets.forEachIndexed { order, widget ->
        val w = widget.size.columns
        val h = widget.size.rows
        var row = 0
        while (true) {
            val col = (0..(columns - w)).firstOrNull { c ->
                (0 until h).all { r -> (0 until w).all { x -> (c + x) to (row + r) !in occupied } }
            }
            if (col != null) {
                for (r in 0 until h) for (x in 0 until w) occupied += (col + x) to (row + r)
                placed += Placed(widget, col, row, order)
                break
            }
            row++
        }
    }
    return placed
}

/** 网格一共几行。 */
internal fun gridRows(placed: List<Placed>): Int =
    placed.maxOfOrNull { it.row + it.widget.size.rows } ?: 0

/** 列数与行数换成档位。 */
internal fun sizeOf(columns: Int, rows: Int): WidgetSize = when {
    columns >= 2 && rows >= 2 -> WidgetSize.LARGE
    columns >= 2 -> WidgetSize.WIDE
    rows >= 2 -> WidgetSize.TALL
    else -> WidgetSize.SMALL
}

/**
 * 首页。组件网格。
 *
 * [editing] 打开时卡片可拖动、缩放和删除。F6。
 * 拖动松手后卡片吸附到网格列：落点换算成格子，再跟那一格上的卡片换位置。
 */
@Composable
internal fun HomeGrid(
    widgets: List<Widget>,
    editing: Boolean,
    onMove: (from: Int, to: Int) -> Unit,
    onResize: (id: String, size: WidgetSize) -> Unit,
    onDelete: (id: String) -> Unit,
) {
    val density = LocalDensity.current.density
    val placed = remember(widgets) { packWidgets(widgets, Tokens.gridColumns) }
    val rows = gridRows(placed)
    val stepX = columnStepPx(density)
    val stepY = rowStepPx(density)

    var dragId by remember { mutableStateOf<String?>(null) }
    var dragDelta by remember { mutableStateOf(Offset.Zero) }
    var resizeId by remember { mutableStateOf<String?>(null) }
    var resizeDelta by remember { mutableStateOf(Offset.Zero) }
    var resizeBase by remember { mutableStateOf(WidgetSize.SMALL) }

    Box(
        Modifier
            .fillMaxWidth()
            .height(rowHeight * rows + Tokens.gridGap.dp * (rows - 1).coerceAtLeast(0)),
    ) {
        placed.forEach { spot ->
            val widget = spot.widget
            val dragging = dragId == widget.id
            val dx = if (dragging) dragDelta.x else 0f
            val dy = if (dragging) dragDelta.y else 0f

            WidgetCard(
                widget = widget,
                editing = editing,
                dragging = dragging,
                modifier = Modifier
                    .offset {
                        IntOffset(
                            x = (spot.col * stepX + dx).roundToInt(),
                            y = (spot.row * stepY + dy).roundToInt(),
                        )
                    }
                    .size(
                        width = columnWidth * widget.size.columns + Tokens.gridGap.dp * (widget.size.columns - 1),
                        height = rowHeight * widget.size.rows + Tokens.gridGap.dp * (widget.size.rows - 1),
                    ),
                onDragStart = {
                    dragId = widget.id
                    dragDelta = Offset.Zero
                },
                onDrag = { delta ->
                    if (dragId == widget.id) dragDelta += delta
                },
                onDragEnd = {
                    if (dragId == widget.id) {
                        // 松手的位置换算成格子，再找那一格上是谁。
                        val droppedX = spot.col * stepX + dragDelta.x
                        val droppedY = spot.row * stepY + dragDelta.y
                        val centerCol = ((droppedX + cardWidthPx(widget.size, density) / 2f) / stepX).toInt()
                        val centerRow = ((droppedY + cardHeightPx(widget.size, density) / 2f) / stepY).toInt()
                        val target = placed.firstOrNull { other ->
                            other.widget.id != widget.id &&
                                centerCol in other.col until (other.col + other.widget.size.columns) &&
                                centerRow in other.row until (other.row + other.widget.size.rows)
                        }
                        if (target != null) onMove(spot.order, target.order)
                        dragId = null
                        dragDelta = Offset.Zero
                    }
                },
                onResizeStart = {
                    resizeId = widget.id
                    resizeDelta = Offset.Zero
                    resizeBase = widget.size
                },
                onResize = { delta ->
                    if (resizeId == widget.id) {
                        resizeDelta += delta
                        val columns = ((cardWidthPx(resizeBase, density) + resizeDelta.x) / stepX)
                            .roundToInt().coerceIn(1, Tokens.gridColumns)
                        val rowCount = ((cardHeightPx(resizeBase, density) + resizeDelta.y) / stepY)
                            .roundToInt().coerceIn(1, 2)
                        onResize(widget.id, sizeOf(columns, rowCount))
                    }
                },
                onResizeEnd = {
                    resizeId = null
                    resizeDelta = Offset.Zero
                },
                onDelete = { onDelete(widget.id) },
            )
        }
    }
}

/** 一块组件卡片。 */
@Composable
private fun WidgetCard(
    widget: Widget,
    editing: Boolean,
    dragging: Boolean,
    modifier: Modifier,
    onDragStart: () -> Unit,
    onDrag: (Offset) -> Unit,
    onDragEnd: () -> Unit,
    onResizeStart: () -> Unit,
    onResize: (Offset) -> Unit,
    onResizeEnd: () -> Unit,
    onDelete: () -> Unit,
) {
    val shape = RoundedCornerShape(Tokens.cardRadius.dp)

    Box(
        modifier
            .shadow(if (dragging) 14.dp else 0.dp, shape)
            .clip(shape)
            .background(widget.tint)
            .then(
                if (editing) {
                    Modifier.pointerInput(widget.id) {
                        detectDragGestures(
                            onDragStart = { onDragStart() },
                            onDragEnd = { onDragEnd() },
                            onDragCancel = { onDragEnd() },
                        ) { _, delta -> onDrag(delta) }
                    }
                } else {
                    Modifier
                },
            )
            .then(if (dragging) Modifier.border(2.dp, Tokens.actionFill, shape) else Modifier),
    ) {
        Column(Modifier.fillMaxSize().padding(14.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text(widget.title, color = Tokens.textPrimary, fontSize = 13.sp, fontWeight = FontWeight.SemiBold)
            Text(widget.detail, color = Tokens.textSecondary, fontSize = 11.sp)
        }

        if (editing) {
            // 删除。F6。
            Box(
                Modifier
                    .align(Alignment.TopEnd)
                    .padding(8.dp)
                    .size(20.dp)
                    .clip(RoundedCornerShape(Tokens.pillRadius.dp))
                    .background(Color(0x66000000))
                    .clickable(onClick = onDelete),
                contentAlignment = Alignment.Center,
            ) {
                Text("✕", color = Color.White, fontSize = 11.sp)
            }

            // 缩放。拖右下角。F6。
            Box(
                Modifier
                    .align(Alignment.BottomEnd)
                    .size(26.dp)
                    .pointerInput(widget.id) {
                        detectDragGestures(
                            onDragStart = { onResizeStart() },
                            onDragEnd = { onResizeEnd() },
                            onDragCancel = { onResizeEnd() },
                        ) { _, delta -> onResize(delta) }
                    },
                contentAlignment = Alignment.Center,
            ) {
                Text("◢", color = Tokens.textSecondary, fontSize = 13.sp)
            }

            // 尺寸档位。评审时一眼看到档位对不对。
            Box(Modifier.align(Alignment.BottomStart).padding(10.dp)) {
                Text(widget.size.label, color = Tokens.textSecondary, fontSize = 10.sp)
            }
        }
    }
}

/** 首页为空时的提示。 */
@Composable
internal fun EmptyHome(editing: Boolean) {
    Box(
        Modifier
            .fillMaxWidth()
            .height(160.dp)
            .clip(RoundedCornerShape(Tokens.cardRadius.dp))
            .background(Color(0x33FFFFFF))
            .border(1.dp, Tokens.divider, RoundedCornerShape(Tokens.cardRadius.dp)),
        contentAlignment = Alignment.Center,
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(6.dp)) {
            Text("首页还没有组件", color = Tokens.textPrimary, fontSize = 13.sp, fontWeight = FontWeight.Medium)
            Text(
                if (editing) "从组件库里拖一块进来。" else "进入编辑模式可以添加组件。",
                color = Tokens.textSecondary,
                fontSize = 11.sp,
            )
        }
    }
}
