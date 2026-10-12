package com.wyz.covio.core

/**
 * 拖拽移动完成后的检查节奏。
 *
 * 拖到文件夹或桌面时，文件是移动过去的，落点那边不会回调。
 * 所以先等一段时间，再看文件还在不在；看若干次都不消失，就认为移动没成功。
 *
 * 等待本身是宿主的事：Swift 用 `Task.sleep`，Compose 宿主用协程。
 * 这里只给出节奏，让两侧不会各写一套数字。
 */
data class ShelfMoveCheckPlan(
    /** 拖拽结束后第一次检查前的等待时间，秒。 */
    val firstDelaySeconds: Double,
    /** 两次检查之间的间隔，秒。 */
    val intervalSeconds: Double,
    /** 检查次数。 */
    val checkCount: Int,
)

/** 移动完成检查与飞入动画的时序常量。 */
object ShelfMoveCheck {
    /** 新截图飞进工具栏前的等待时间。先让系统写完文件再读图。 */
    const val FLY_IN_DELAY_SECONDS = 0.120

    /** 拖拽移动的检查节奏：等 600 毫秒，然后每 300 毫秒看一次，共四次。 */
    val plan = ShelfMoveCheckPlan(
        firstDelaySeconds = 0.600,
        intervalSeconds = 0.300,
        checkCount = 4,
    )
}
