package com.wyz.covio.core

import okio.FileSystem
import okio.Path
import okio.Path.Companion.toPath
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

/**
 * 截图接管的状态迁移。
 *
 * 端口是假的，状态文件写在临时目录里，所以这里验的是「什么时候存快照、什么时候清快照」，
 * 不是 `defaults` 命令本身。
 */
class ScreenshotTakeoverTest {
    /** 记账用的假端口。记下被调用过几次，并可以按需失败。 */
    private class FakePort(
        var snapshot: ScreenshotInboxSnapshot = ScreenshotInboxSnapshot(),
        var applySucceeds: Boolean = true,
        var restoreSucceeds: Boolean = true,
    ) : ScreenshotPreferencePort {
        var applyCount = 0
        var restoreCount = 0
        var appliedDirectory: String? = null
        var restoredSnapshot: ScreenshotInboxSnapshot? = null

        override fun read(): ScreenshotInboxSnapshot = snapshot

        override fun apply(directory: String): Boolean {
            applyCount++
            appliedDirectory = directory
            return applySucceeds
        }

        override fun restore(snapshot: ScreenshotInboxSnapshot): Boolean {
            restoreCount++
            restoredSnapshot = snapshot
            return restoreSucceeds
        }
    }

    private fun <T> withStore(block: (ShelfStore) -> T): T =
        withTemporaryDirectory("takeover") { directory ->
            block(ShelfStore(path = directory.resolve("shelf.json").toString()))
        }

    @Test
    fun `enabling stores the snapshot and applies the directory`() {
        withStore { store ->
            val port = FakePort(
                snapshot = ScreenshotInboxSnapshot(
                    location = "/Users/someone/Desktop",
                    locationScreenshot = "/Users/someone/Desktop",
                    showThumbnail = true,
                ),
            )
            val takeover = ScreenshotTakeover(port, "/tmp/covio-shots", store)

            assertTrue(takeover.enable())
            assertTrue(takeover.isActive)
            assertEquals("/tmp/covio-shots", port.appliedDirectory)

            val stored = store.load().preferenceSnapshot
            assertEquals("/Users/someone/Desktop", stored?.location)
            assertEquals(true, stored?.showThumbnail, "原有设置要原样存下来")
        }
    }

    /** 已经有快照时不能覆盖：那会把用户真正的原始设置改成本应用的设置。 */
    @Test
    fun `enabling twice keeps the first snapshot`() {
        withStore { store ->
            val original = ScreenshotInboxSnapshot(location = "/Users/someone/Desktop")
            val port = FakePort(snapshot = original)
            val takeover = ScreenshotTakeover(port, "/tmp/covio-shots", store)

            assertTrue(takeover.enable())
            port.snapshot = ScreenshotInboxSnapshot(location = "/tmp/covio-shots")
            assertTrue(takeover.enable())

            assertEquals("/Users/someone/Desktop", store.load().preferenceSnapshot?.location)
            assertEquals(2, port.applyCount, "第二次仍然要重新写一遍设置")
        }
    }

    /**
     * 写设置失败时不能记成已开启，否则界面会显示接管开着而实际没开。
     *
     * 快照要留着：`apply` 写三个键，可能写成功前两个才失败，
     * 那时系统设置是半改状态，还原得靠这份快照。
     */
    @Test
    fun `a failed apply leaves the takeover off`() {
        withStore { store ->
            val port = FakePort(applySucceeds = false)
            val takeover = ScreenshotTakeover(port, "/tmp/covio-shots", store)

            assertFalse(takeover.enable())
            assertFalse(takeover.isActive)
            assertEquals(1, port.applyCount)
        }
    }

    @Test
    fun `disabling restores the snapshot and clears it`() {
        withStore { store ->
            val port = FakePort(
                snapshot = ScreenshotInboxSnapshot(location = "/Users/someone/Desktop"),
            )
            val takeover = ScreenshotTakeover(port, "/tmp/covio-shots", store)
            assertTrue(takeover.enable())

            assertTrue(takeover.disable())
            assertFalse(takeover.isActive)
            assertEquals(1, port.restoreCount)
            assertEquals("/Users/someone/Desktop", port.restoredSnapshot?.location)
            assertNull(store.load().preferenceSnapshot, "还原之后快照要清掉")
        }
    }

    /** 还原失败时快照留着，下次启动还能再试。 */
    @Test
    fun `a failed restore keeps the snapshot for the next launch`() {
        withStore { store ->
            val port = FakePort(
                snapshot = ScreenshotInboxSnapshot(location = "/Users/someone/Desktop"),
            )
            val takeover = ScreenshotTakeover(port, "/tmp/covio-shots", store)
            assertTrue(takeover.enable())

            port.restoreSucceeds = false
            assertFalse(takeover.disable())
            assertTrue(takeover.isActive, "还原没成功就还算开着")
            assertEquals("/Users/someone/Desktop", store.load().preferenceSnapshot?.location)
        }
    }

    /** 没有快照时还原算成功。首次启动就关掉接管会走到这里。 */
    @Test
    fun `restoring without a snapshot does nothing and succeeds`() {
        withStore { store ->
            val port = FakePort()
            val takeover = ScreenshotTakeover(port, "/tmp/covio-shots", store)

            assertTrue(takeover.restoreOnExit())
            assertFalse(takeover.isActive)
            assertEquals(0, port.restoreCount, "没有快照就不该动系统设置")
        }
    }

    /**
     * 应用崩过之后重启：快照还在磁盘上，接管状态是关的。
     *
     * 这时还原必须按磁盘上的快照走，不能再 `enable()` 一次。
     */
    @Test
    fun `a snapshot on disk can be restored after a restart`() {
        withStore { store ->
            val port = FakePort(
                snapshot = ScreenshotInboxSnapshot(location = "/Users/someone/Desktop"),
            )
            assertTrue(ScreenshotTakeover(port, "/tmp/covio-shots", store).enable())

            // 新实例模拟重启：内存里的开关是关的，磁盘上有快照。
            val afterRestart = ScreenshotTakeover(port, "/tmp/covio-shots", store)
            assertFalse(afterRestart.isActive)
            assertTrue(afterRestart.restoreOnExit())
            assertEquals("/Users/someone/Desktop", port.restoredSnapshot?.location)
            assertNull(store.load().preferenceSnapshot)
        }
    }

    /**
     * 接管共享晾衣线那份状态存储。
     *
     * 两边写的是同一个 `shelf.json`。各拿一个实例的话，接管存快照时
     * 会用自己那份内存状态覆盖掉刚上架的卡片。
     */
    @Test
    fun `enabling does not drop the cards already in the store`() {
        withStore { store ->
            // 卡片必须在磁盘上：读写都会滤掉不存在的文件。
            val card = store.path.substringBeforeLast("/") + "/card.png"
            FileSystem.SYSTEM.write(card.toPath()) { writeUtf8("x") }
            store.save(
                store.load().copy(items = listOf(ShelfItem(path = card, addedAtEpochSeconds = 1))),
            )

            val port = FakePort(
                snapshot = ScreenshotInboxSnapshot(location = "/Users/someone/Desktop"),
            )
            val takeover = ScreenshotTakeover(port, "/tmp/covio-shots", store)
            assertTrue(takeover.enable())

            val after = store.load()
            assertEquals(listOf(card), after.items.map { it.path }, "卡片被覆盖掉了")
            assertEquals("/Users/someone/Desktop", after.preferenceSnapshot?.location)
        }
    }
}
