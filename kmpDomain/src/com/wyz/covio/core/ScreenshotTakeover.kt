package com.wyz.covio.core

import com.wyz.covio.domain.EngineLock
import okio.FileSystem
import okio.Path.Companion.toPath

/**
 * 系统截图偏好的读写端口。
 *
 * 读写要走 `/usr/bin/defaults`，那是 OS 调用，由各宿主实现。
 * 共享层只规定三个动作与它们的成败语义。
 */
interface ScreenshotPreferencePort {
    /**
     * 读当前设置。
     *
     * 三个键都要保留「键不存在」与「值是空」的区别，
     * 否则还原时会把一个不存在的键写回成空串。
     */
    fun read(): ScreenshotInboxSnapshot

    /** 把截图落盘目录改成 [directory]。三个键都改成功才算成功。 */
    fun apply(directory: String): Boolean

    /** 按 [snapshot] 还原。快照里没有的键要删掉。 */
    fun restore(snapshot: ScreenshotInboxSnapshot): Boolean
}

/**
 * 截图接管的开关。
 *
 * 打开前先把系统原有设置存进晾衣线状态文件。这样应用崩了也能在下次启动时还原：
 * 快照在磁盘上，不在内存里。
 *
 * **状态存储必须是同一个实例。** 接管与晾衣线都写 `shelf.json`，
 * 各拿一个实例会互相覆盖。
 */
class ScreenshotTakeover(
    private val port: ScreenshotPreferencePort,
    private val directory: String,
    private val store: ShelfStore,
) {
    /** `activeFlag` 会被不同线程读写，用锁保护。可重入，与 `Engine` 用同一把。 */
    private val lock = EngineLock()
    private var activeFlag = false

    /** 接管是不是开着。 */
    val isActive: Boolean
        get() = lock.withLock { activeFlag }

    /** 打开接管。没有快照时先存一份。 */
    fun enable(): Boolean {
        // 目录建不出来不算失败：写 preference 仍然可能成功，截图落盘时再报错更准确。
        runCatching { FileSystem.SYSTEM.createDirectories(directory.toPath()) }
        val state = store.load()
        if (state.preferenceSnapshot == null) {
            store.save(state.copy(preferenceSnapshot = port.read()))
        }
        if (!port.apply(directory)) return false
        lock.withLock { activeFlag = true }
        return true
    }

    /** 关闭接管，还原系统设置。 */
    fun disable(): Boolean = restore()

    /** 正常退出时还原。与 [disable] 是同一件事，名字不同是为了调用点读起来清楚。 */
    fun restoreOnExit(): Boolean = restore()

    /**
     * 还原系统设置并清掉快照。
     *
     * 没有快照时什么都不做，算成功。这可能发生在首次启动就关闭接管的时候。
     * 还原失败时快照留着，下次启动还能再试一次。
     */
    private fun restore(): Boolean {
        val snapshot = store.load().preferenceSnapshot
        if (snapshot == null) {
            lock.withLock { activeFlag = false }
            return true
        }
        if (!port.restore(snapshot)) return false
        val latest = store.load()
        store.save(latest.copy(preferenceSnapshot = null))
        lock.withLock { activeFlag = false }
        return true
    }
}
