package com.wyz.covio.app.helper

import com.wyz.covio.core.HelperStatus
import com.wyz.covio.core.HelperStatusPolling
import kotlinx.coroutines.delay

/**
 * 等 helper 的状态变成已安装。
 *
 * 安装 helper 要用户批准管理员授权，耗时不确定。
 * 界面在这个窗口期里要能显示「已安装」以外的中间态，所以这里轮询而不是一次性查询。
 *
 * 起手就是已安装时立刻返回，不等第一次轮询。
 * [timeoutMillis] 到了就返回当时的状态，不抛异常：超时不等于失败，
 * 调用方拿到的仍然是一个可用状态。
 *
 * 默认的两个节奏来自共享层，与宿主无关。
 */
internal suspend fun awaitHelperStatus(
    initialStatus: HelperStatus,
    timeoutMillis: Long = HelperStatusPolling.TIMEOUT_MILLIS,
    pollIntervalMillis: Long = HelperStatusPolling.POLL_INTERVAL_MILLIS,
    statusProvider: () -> HelperStatus,
): HelperStatus {
    if (initialStatus == HelperStatus.INSTALLED) return initialStatus
    val deadline = System.nanoTime() + timeoutMillis.coerceAtLeast(0L) * 1_000_000L
    var status = initialStatus
    while (status != HelperStatus.INSTALLED && System.nanoTime() < deadline) {
        delay(pollIntervalMillis.coerceAtLeast(1L))
        status = statusProvider()
    }
    return status
}
