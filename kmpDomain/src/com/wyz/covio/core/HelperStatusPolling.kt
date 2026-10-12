package com.wyz.covio.core

/**
 * 等 helper 安装完成的节奏。
 *
 * 安装要用户批准管理员授权，耗时不确定。界面在这个窗口期里轮询状态，
 * 好显示「已安装」以外的中间态。
 *
 * 两个值放在共享层，是因为它们描述的是「helper 装好要多久」这个事实，
 * 不是某个界面的偏好。今天只有 Compose 宿主在轮询；
 * macOS 宿主查一次状态就返回，不读这两个值。
 */
object HelperStatusPolling {
    /** 最多等这么久。到点返回当时的状态，不当作失败。 */
    const val TIMEOUT_MILLIS = 5_000L

    /** 两次查询之间的间隔。 */
    const val POLL_INTERVAL_MILLIS = 200L
}
