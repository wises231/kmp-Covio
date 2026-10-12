package com.wyz.covio.core

import okio.FileSystem
import okio.Path.Companion.toPath

/**
 * 晾衣线的几何与拖放规则。
 *
 * 全部函数都把容器宽度当参数传入，因为同一套几何要服务两种形态：
 * 全宽的独立工具条面板，以及 Hub 面板内嵌的横向区域。
 *
 * 路径用 String 表示，文件操作走 okio。Kotlin/Native 没有 `java.nio.file.Path`。
 */
object ShelfLayout {
    const val PANEL_HEIGHT = 210f
    const val PHOTO_MAX_WIDTH = 136f
    const val PHOTO_MAX_HEIGHT = 104f
    const val CARD_PADDING = 4f
    const val CARD_WIDTH = PHOTO_MAX_WIDTH + CARD_PADDING * 2f
    const val CARD_HEIGHT = PHOTO_MAX_HEIGHT + CARD_PADDING * 2f
    const val CARD_RADIUS = 16f
    const val CARD_TOP_OFFSET = 4f
    const val SPACING = 164f
    const val CLOTHESPIN_WIDTH = 9f
    const val CLOTHESPIN_HEIGHT = 26f
    const val CLOTHESPIN_ABOVE_ROPE = 18f
    const val ROPE_BASE_Y = 20f
    const val MAX_SAG = 58f
    const val MIN_CAPACITY = 3
    const val MAX_CAPACITY = 12
    const val MIN_TILT_DEGREES = -2.5f
    const val MAX_TILT_DEGREES = 2.5f

    fun capacity(screenWidth: Float): Int {
        if (!screenWidth.isFinite() || screenWidth <= 0f) return MIN_CAPACITY
        val raw = (screenWidth / SPACING).toInt() + 1
        return raw.coerceIn(MIN_CAPACITY, MAX_CAPACITY)
    }

    fun sag(screenWidth: Float): Float {
        if (!screenWidth.isFinite() || screenWidth <= 0f) return 0f
        return minOf(MAX_SAG, screenWidth * 0.018f)
    }

    fun ropeY(x: Float, screenWidth: Float): Float {
        if (!screenWidth.isFinite() || screenWidth <= 0f) return ROPE_BASE_Y
        val fraction = (x / screenWidth).coerceIn(0f, 1f)
        return ROPE_BASE_Y + 4f * sag(screenWidth) * fraction * (1f - fraction)
    }

    fun slotX(index: Int, count: Int, screenWidth: Float): Float {
        if (count <= 0) return screenWidth / 2f
        val total = (count - 1).coerceAtLeast(0) * SPACING
        return screenWidth / 2f - total / 2f + index.coerceAtLeast(0) * SPACING
    }

    fun cardBounds(index: Int, count: Int, screenWidth: Float): ShelfCardBounds {
        val left = slotX(index, count, screenWidth) - CARD_WIDTH / 2f
        val top = ropeY(left + CARD_WIDTH / 2f, screenWidth) + CARD_TOP_OFFSET
        return ShelfCardBounds(left, top, CARD_WIDTH, CARD_HEIGHT)
    }

    fun cardIndexAt(x: Float, y: Float, count: Int, screenWidth: Float): Int? {
        if (count <= 0) return null
        return (0 until count).firstOrNull { index ->
            cardBounds(index, count, screenWidth).contains(x, y)
        }
    }

    fun clothespinBounds(index: Int, count: Int, screenWidth: Float): ShelfCardBounds {
        val left = slotX(index, count, screenWidth) - CLOTHESPIN_WIDTH / 2f
        val top = ropeY(slotX(index, count, screenWidth), screenWidth) - CLOTHESPIN_ABOVE_ROPE
        return ShelfCardBounds(left, top, CLOTHESPIN_WIDTH, CLOTHESPIN_HEIGHT)
    }

    fun fitImageSize(
        imageWidth: Int,
        imageHeight: Int,
        maxWidth: Float = PHOTO_MAX_WIDTH,
        maxHeight: Float = PHOTO_MAX_HEIGHT,
    ): ShelfImageSize {
        if (imageWidth <= 0 || imageHeight <= 0 || maxWidth <= 0f || maxHeight <= 0f) {
            return ShelfImageSize(PHOTO_MAX_WIDTH, PHOTO_MAX_HEIGHT)
        }
        val scale = minOf(maxWidth / imageWidth, maxHeight / imageHeight)
        return ShelfImageSize(imageWidth * scale, imageHeight * scale)
    }

    fun tiltDegrees(index: Int): Float {
        val safeIndex = index.coerceAtLeast(0)
        val pattern = listOf(-2.5f, -1.25f, 0.75f, 2.25f, -0.75f, 1.75f, -2f, 1.25f)
        return pattern[safeIndex % pattern.size]
    }
}

data class ShelfImageSize(
    val width: Float,
    val height: Float,
)

data class ShelfCardBounds(
    val left: Float,
    val top: Float,
    val width: Float,
    val height: Float,
) {
    val right: Float get() = left + width
    val bottom: Float get() = top + height

    fun contains(x: Float, y: Float): Boolean =
        x >= left && x <= right && y >= top && y <= bottom
}

enum class ShelfDropTarget { APPLICATION, FOLDER, DESKTOP, TRASH, INVALID }
enum class ShelfDropAction { COPY_AND_KEEP, MOVE_AND_REMOVE, TRASH_AND_REMOVE, CANCEL }

enum class ShelfDragResult { COPY, MOVE, DELETE, CANCEL }

const val NS_DRAG_OPERATION_COPY = 1L
const val NS_DRAG_OPERATION_MOVE = 2L
const val NS_DRAG_OPERATION_DELETE = 32L

fun shelfDragResultFor(operationMask: Long): ShelfDragResult = when {
    operationMask and NS_DRAG_OPERATION_DELETE != 0L -> ShelfDragResult.DELETE
    operationMask and NS_DRAG_OPERATION_MOVE != 0L -> ShelfDragResult.MOVE
    operationMask and NS_DRAG_OPERATION_COPY != 0L -> ShelfDragResult.COPY
    else -> ShelfDragResult.CANCEL
}

fun dropActionFor(target: ShelfDropTarget): ShelfDropAction = when (target) {
    ShelfDropTarget.APPLICATION -> ShelfDropAction.COPY_AND_KEEP
    ShelfDropTarget.FOLDER,
    ShelfDropTarget.DESKTOP,
    -> ShelfDropAction.MOVE_AND_REMOVE

    ShelfDropTarget.TRASH -> ShelfDropAction.TRASH_AND_REMOVE
    ShelfDropTarget.INVALID -> ShelfDropAction.CANCEL
}

val SHELF_IMAGE_EXTENSIONS: Set<String> = setOf(
    "png",
    "jpg",
    "jpeg",
    "heic",
    "tif",
    "tiff",
    "gif",
    "webp",
)

/** 按扩展名判断。只看文件名，不看目录。 */
fun isShelfImageFileName(fileName: String): Boolean =
    fileName.substringAfterLast('.', "").lowercase() in SHELF_IMAGE_EXTENSIONS

/** 按扩展名判断。路径的最后一段是文件名。 */
fun isShelfImageFile(path: String): Boolean {
    val name = runCatching { path.toPath().name }.getOrDefault(path.substringAfterLast('/'))
    return isShelfImageFileName(name)
}

/**
 * 判断某个文件是否该进晾衣线。
 *
 * 进入条件有两条，满足其一即可：
 * 1. 文件在专用目录里。
 * 2. 文件带系统的截图属性。
 *
 * 两条都不满足时不接收，例如桌面上的普通图片。
 */
fun acceptsShelfFile(
    path: String,
    dedicatedDirectory: String,
    hasScreenCaptureAttribute: (String) -> Boolean,
): Boolean {
    if (!isShelfImageFile(path)) return false
    if (isPathInside(path, dedicatedDirectory)) return true
    return hasScreenCaptureAttribute(path)
}

/**
 * 包含关系判断。
 *
 * 与 `java.nio.file.Path.startsWith` 一样按路径段比较，不是按字符串前缀。
 * 所以 `/a/bc` 不在 `/a/b` 内。
 */
fun isPathInside(path: String, directory: String): Boolean {
    val child = canonicalOrNull(path) ?: return false
    val parent = canonicalOrNull(directory) ?: return false
    if (child == parent) return true
    val relative = runCatching { child.relativeTo(parent) }.getOrNull() ?: return false
    return relative.segments.firstOrNull() != ".."
}

private fun canonicalOrNull(value: String) = runCatching {
    val path = value.toPath()
    (if (path.isAbsolute) path else ShelfStore.canonicalPath(value).toPath()).normalized()
}.getOrNull()

/**
 * 晾衣线的条目集合。
 *
 * 去重按规范路径算，所以同一个文件的不同写法只算一条。
 * 超过上限时丢最旧的一条。
 */
class ShelfCollection(
    initialItems: List<ShelfItem> = emptyList(),
    private val maxItems: Int = ShelfStore.MAX_ITEMS,
    private val exists: (String) -> Boolean = { FileSystem.SYSTEM.exists(it.toPath()) },
) {
    private val items = ArrayDeque<ShelfItem>()

    init {
        initialItems.forEach { add(it.path, it.addedAtEpochSeconds) }
    }

    fun snapshot(): List<ShelfItem> = items.toList()

    fun add(path: String, addedAtEpochSeconds: Long = 0L): Boolean {
        if (!exists(path)) return false
        val normalized = ShelfStore.canonicalPath(path)
        if (items.any { ShelfStore.canonicalPath(it.path) == normalized }) return false
        items.addLast(ShelfItem(normalized, addedAtEpochSeconds.coerceAtLeast(0L)))
        while (items.size > maxItems.coerceAtLeast(0)) items.removeFirst()
        return true
    }

    fun remove(path: String): Boolean {
        val normalized = ShelfStore.canonicalPath(path)
        return items.removeIf { ShelfStore.canonicalPath(it.path) == normalized }
    }

    fun prune(): List<ShelfItem> {
        val removed = items.filterNot { exists(it.path) }
        items.removeIf { !exists(it.path) }
        return removed
    }

    fun clear(): List<ShelfItem> {
        val previous = items.toList()
        items.clear()
        return previous
    }
}

private fun ArrayDeque<ShelfItem>.removeIf(predicate: (ShelfItem) -> Boolean): Boolean {
    val keep = filterNot(predicate)
    val changed = keep.size != size
    clear()
    addAll(keep)
    return changed
}
