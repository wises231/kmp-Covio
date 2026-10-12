package com.wyz.covio.core

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue
import okio.FileSystem
import okio.Path.Companion.toPath

class ShelfStoreTest {
    @Test
    fun `store round trips items revealed state and screenshot snapshot`() =
        withTemporaryDirectory("shelf") { directory ->
            val first = directory.resolve("one.png")
            first.writeText("one")
            val store = ShelfStore(directory.resolve("shelf.json").toString())
            val expected = ShelfStoreState(
                items = listOf(ShelfItem(first.toString(), 12L)),
                revealed = false,
                preferenceSnapshot = ScreenshotInboxSnapshot("/tmp", null, true),
            )

            store.save(expected)

            assertEquals(expected, store.load())
        }

    @Test
    fun `normalization removes duplicate paths and missing files`() =
        withTemporaryDirectory("shelf") { directory ->
            val first = directory.resolve("one.png")
            val second = directory.resolve("two.png")
            first.writeText("one")
            second.writeText("two")
            val state = ShelfStoreState(
                items = listOf(
                    ShelfItem(first.toString(), 1L),
                    ShelfItem(first.toString(), 2L),
                    ShelfItem(second.toString(), 3L),
                    ShelfItem(directory.resolve("missing.png").toString(), 4L),
                ),
            )

            val loaded = ShelfStore.normalizeItems(state.items) { candidate -> candidate.toPath().exists }

            assertEquals(listOf(first.toString(), second.toString()), loaded.map(ShelfItem::path))
        }

    @Test
    fun `normalization keeps only the newest configured number of items`() =
        withTemporaryDirectory("shelf") { directory ->
            val items = (0 until 5).map { index ->
                val file = directory.resolve("$index.png")
                file.writeText(index.toString())
                ShelfItem(file.toString(), index.toLong())
            }

            val loaded = ShelfStore.normalizeItems(items, limit = 3) { it.toPath().exists }

            assertEquals(
                listOf("2.png", "3.png", "4.png"),
                loaded.map { it.path.toPath().name },
            )
        }

    @Test
    fun `clear removes the shelf file and load returns defaults`() =
        withTemporaryDirectory("shelf") { directory ->
            val path = directory.resolve("shelf.json")
            val store = ShelfStore(path.toString())
            store.save(ShelfStoreState(items = listOf(ShelfItem("/tmp/example.png"))))

            assertTrue(path.exists)
            assertTrue(store.clear())
            assertFalse(path.exists)
            assertEquals(ShelfStoreState(), store.load())
        }

    /// 保存时先写 `.tmp` 再原子改名，所以目录里不留临时文件。
    @Test
    fun `save leaves no temporary file behind`() =
        withTemporaryDirectory("shelf") { directory ->
            val store = ShelfStore(directory.resolve("shelf.json").toString())
            store.save(ShelfStoreState(items = listOf(ShelfItem("/tmp/example.png"))))

            val leftovers = FileSystem.SYSTEM.list(directory).map { it.name }.filter { it.endsWith(".tmp") }
            assertEquals(emptyList(), leftovers)
        }

    /// 规范路径只做词法处理，不做符号链接解析。
    @Test
    fun `canonical path makes relative paths absolute and removes dot segments`() {
        val canonical = ShelfStore.canonicalPath("some/./relative/../dir/file.png")
        assertTrue(canonical.startsWith("/"), "规范路径必须是绝对路径：$canonical")
        assertTrue(canonical.endsWith("/dir/file.png"), "规范路径的尾部不对：$canonical")
        assertFalse(canonical.contains("/./"), "规范路径不该留下 . 段：$canonical")
        assertFalse(canonical.contains("/../"), "规范路径不该留下 .. 段：$canonical")
        assertEquals(canonical, ShelfStore.canonicalPath(canonical), "规范路径必须是幂等的")
    }

    /**
     * 写不进去时不抛异常。
     *
     * Kotlin 的异常跨到 Swift 没有接收方，会直接终止进程。
     * 落盘是每次改卡片都会跑的一步，磁盘满或者目录被删就会走到这里。
     */
    @Test
    fun `save swallows write failures`() =
        withTemporaryDirectory("shelf") { directory ->
            // 拿一个普通文件当目录用，写它下面的路径一定失败。
            val blocker = directory.resolve("blocker")
            blocker.writeText("not a directory")

            // 卡片要指向一个真的存在的文件，否则规范化会把它滤掉。
            val picture = directory.resolve("one.png")
            picture.writeText("one")
            val store = ShelfStore(blocker.resolve("shelf.json").toString())
            val state = ShelfStoreState(items = listOf(ShelfItem(picture.toString(), 1L)))

            // 不抛异常，而且照常返回规范化之后的状态。
            assertEquals(1, store.save(state).items.size)
        }
}
