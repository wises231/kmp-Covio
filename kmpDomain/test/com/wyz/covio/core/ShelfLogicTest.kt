package com.wyz.covio.core

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue
import okio.Path.Companion.toPath

class ShelfLogicTest {
    @Test
    fun `layout capacity is clamped and uses the approved card geometry`() {
        assertEquals(3, ShelfLayout.capacity(300f))
        assertEquals(9, ShelfLayout.capacity(1_440f))
        assertEquals(12, ShelfLayout.capacity(4_000f))
        assertEquals(144f, ShelfLayout.CARD_WIDTH)
        assertEquals(112f, ShelfLayout.CARD_HEIGHT)
        assertEquals(136f, ShelfLayout.PHOTO_MAX_WIDTH)
        assertEquals(104f, ShelfLayout.PHOTO_MAX_HEIGHT)
        assertEquals(164f, ShelfLayout.SPACING)
        assertEquals(210f, ShelfLayout.PANEL_HEIGHT)
        assertEquals(16f, ShelfLayout.CARD_RADIUS)
        assertEquals(9f, ShelfLayout.CLOTHESPIN_WIDTH)
        assertEquals(26f, ShelfLayout.CLOTHESPIN_HEIGHT)
    }

    @Test
    fun `rope follows a parabola and card slots center around the screen`() {
        assertEquals(20f, ShelfLayout.ropeY(0f, 1_000f))
        assertEquals(38f, ShelfLayout.ropeY(500f, 1_000f))
        assertEquals(20f, ShelfLayout.ropeY(1_000f, 1_000f))
        assertEquals(336f, ShelfLayout.slotX(0, 3, 1_000f))
        assertEquals(664f, ShelfLayout.slotX(2, 3, 1_000f))
    }

    @Test
    fun `drop actions keep copy move remove and cancel distinct`() {
        assertEquals(ShelfDropAction.COPY_AND_KEEP, dropActionFor(ShelfDropTarget.APPLICATION))
        assertEquals(ShelfDropAction.MOVE_AND_REMOVE, dropActionFor(ShelfDropTarget.FOLDER))
        assertEquals(ShelfDropAction.MOVE_AND_REMOVE, dropActionFor(ShelfDropTarget.DESKTOP))
        assertEquals(ShelfDropAction.TRASH_AND_REMOVE, dropActionFor(ShelfDropTarget.TRASH))
        assertEquals(ShelfDropAction.CANCEL, dropActionFor(ShelfDropTarget.INVALID))
    }

    @Test
    fun `drag operation masks map to copy move delete and cancel`() {
        assertEquals(ShelfDragResult.COPY, shelfDragResultFor(NS_DRAG_OPERATION_COPY))
        assertEquals(ShelfDragResult.MOVE, shelfDragResultFor(NS_DRAG_OPERATION_MOVE))
        assertEquals(ShelfDragResult.DELETE, shelfDragResultFor(NS_DRAG_OPERATION_DELETE))
        assertEquals(ShelfDragResult.CANCEL, shelfDragResultFor(0L))
    }

    @Test
    fun `card bounds hit testing clothespin and tilt stay inside the panel`() {
        val first = ShelfLayout.cardBounds(0, 3, 1_000f)
        val second = ShelfLayout.cardBounds(1, 3, 1_000f)

        assertEquals(264f, first.left)
        assertEquals(ShelfLayout.CARD_WIDTH, first.width)
        assertEquals(ShelfLayout.CARD_HEIGHT, first.height)
        assertTrue(first.contains(first.left + 10f, first.top + 10f))
        assertTrue(second.contains(second.left + 10f, second.top + 10f))
        assertFalse(first.contains(second.left + 10f, second.top + 10f))
        assertEquals(0, ShelfLayout.cardIndexAt(first.left + 10f, first.top + 10f, 3, 1_000f))
        assertEquals(1, ShelfLayout.cardIndexAt(second.left + 10f, second.top + 10f, 3, 1_000f))
        assertNull(ShelfLayout.cardIndexAt(0f, 0f, 3, 1_000f))
        assertTrue(first.bottom <= ShelfLayout.PANEL_HEIGHT)

        val pin = ShelfLayout.clothespinBounds(0, 3, 1_000f)
        assertEquals(ShelfLayout.CLOTHESPIN_WIDTH, pin.width)
        assertEquals(ShelfLayout.CLOTHESPIN_HEIGHT, pin.height)
        assertTrue(pin.bottom >= first.top)
        assertTrue(ShelfLayout.tiltDegrees(0) in ShelfLayout.MIN_TILT_DEGREES..ShelfLayout.MAX_TILT_DEGREES)
        assertTrue(ShelfLayout.tiltDegrees(7) in ShelfLayout.MIN_TILT_DEGREES..ShelfLayout.MAX_TILT_DEGREES)
    }

    @Test
    fun `image fitting preserves aspect ratio and stays within the photo box`() {
        val landscape = ShelfLayout.fitImageSize(1_366, 768)
        val portrait = ShelfLayout.fitImageSize(768, 1_366)
        val square = ShelfLayout.fitImageSize(512, 512)

        assertEquals(136f, landscape.width)
        assertTrue(landscape.height <= 104f)
        assertTrue(portrait.width <= 136f)
        assertEquals(104f, portrait.height, 0.001f)
        assertEquals(104f, square.width, 0.001f)
        assertEquals(104f, square.height, 0.001f)
    }

    @Test
    fun `dedicated folder accepts images while other folders require the screenshot tag`() =
        withTemporaryDirectory("accept") { root ->
            val fileSystem = okio.FileSystem.SYSTEM
            val dedicated = root.resolve("screenshots")
            fileSystem.createDirectories(dedicated)
            val inside = dedicated.resolve("capture.PNG")
            val outside = root.resolve("other.png")
            val notes = root.resolve("notes.txt")
            inside.writeText("image")
            outside.writeText("image")
            notes.writeText("image")

            // 专用目录里的大写扩展名也接收。
            assertTrue(acceptsShelfFile(inside.toString(), dedicated.toString()) { false })
            // 专用目录外的图片要有截图属性才接收。
            assertFalse(acceptsShelfFile(outside.toString(), dedicated.toString()) { false })
            assertTrue(acceptsShelfFile(outside.toString(), dedicated.toString()) { true })
            // 非图片扩展名一律不接收，即使带截图属性。
            assertFalse(acceptsShelfFile(notes.toString(), dedicated.toString()) { true })
            // 字符串前缀相同但不是子目录，不能算在专用目录里。
            val sibling = root.resolve("screenshots-backup")
            fileSystem.createDirectories(sibling)
            val siblingImage = sibling.resolve("shot.png")
            siblingImage.writeText("image")
            assertFalse(acceptsShelfFile(siblingImage.toString(), dedicated.toString()) { false })
        }

    @Test
    fun `collection deduplicates limits and removes missing files`() =
        withTemporaryDirectory("collection") { root ->
            val fileSystem = okio.FileSystem.SYSTEM
            val files = (0 until 5).map { index ->
                root.resolve("$index.png").also { it.writeText("image") }
            }
            val collection = ShelfCollection(maxItems = 3)

            files.forEach { path -> assertTrue(collection.add(path.toString())) }
            assertFalse(collection.add(files.last().toString(), 99L))
            // 超过上限时丢最旧的一条。
            assertEquals(
                listOf("2.png", "3.png", "4.png"),
                collection.snapshot().map { it.path.toPath().name },
            )

            fileSystem.delete(files[3])
            assertEquals(
                listOf("3.png"),
                collection.prune().map { it.path.toPath().name },
            )
            assertTrue(collection.remove(files[4].toString()))
            assertTrue(collection.remove(files[2].toString()))
            assertTrue(collection.snapshot().isEmpty())
        }

    @Test
    fun `image file detection reads only the last path segment`() {
        assertTrue(isShelfImageFile("/tmp/a/b/photo.HEIC"))
        assertTrue(isShelfImageFileName("photo.webp"))
        assertFalse(isShelfImageFileName("notes.txt"))
        assertFalse(isShelfImageFileName("noextension"))
        // 目录名里有扩展名不算。
        assertFalse(isShelfImageFile("/tmp/album.png/notes"))
    }
}
