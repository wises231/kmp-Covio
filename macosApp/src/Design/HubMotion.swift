import Foundation

/// Hub 的动效参数。
///
/// 数值来自 `Motion`。
/// 这里保留一层语义命名，便于按用途取用。
enum HubMotion {
    /// Hub 展开：220 至 280 毫秒，弹性曲线。
    static let expandRange: ClosedRange<TimeInterval> = 0.220...0.280
    static let expand: TimeInterval = Motion.tokenMotionHubExpand.seconds

    /// Hub 收起：160 至 220 毫秒，缓出曲线。
    static let collapseRange: ClosedRange<TimeInterval> = 0.160...0.220
    static let collapse: TimeInterval = Motion.tokenMotionHubCollapse.seconds

    /// 页签切换：160 毫秒，横向滑动加淡入。
    static let tabSwitch: TimeInterval = Motion.tokenMotionTabSwitch.seconds

    /// 截图捕获：650 毫秒。
    static let screenshotCapture: TimeInterval = Motion.tokenMotionScreenshotCapture.seconds

    /// 截图复制：1200 毫秒提示。
    static let screenshotCopy: TimeInterval = Motion.tokenMotionScreenshotCopy.seconds

    /// 传输开始：180 毫秒。
    static let transferStart: TimeInterval = Motion.tokenMotionTransferStart.seconds

    /// 传输完成：240 毫秒。
    static let transferComplete: TimeInterval = Motion.tokenMotionTransferComplete.seconds

    /// 错误出现：160 毫秒。
    static let errorAppear: TimeInterval = Motion.tokenMotionErrorAppear.seconds

    /// 减弱动态效果：120 毫秒，只改透明度。
    static let reducedMotion: TimeInterval = Motion.tokenMotionReducedMotion.seconds

    /// 指针移出 Hub 后收起的等待时间。来源是 `covio-product-master.md` 第 4.4 节。
    static let pointerExitCollapseDelay: TimeInterval = Motion.tokenMotionPointerExitCollapse.seconds

    /// 呼吸灯一次亮灭的时长。取值按肉眼可见的缓慢呼吸定。
    static let pulse: TimeInterval = 1.2

    /// 生效的展开时长。
    static func expandDuration(reduceMotion: Bool) -> TimeInterval {
        reduceMotion ? reducedMotion : expand
    }

    /// 生效的收起时长。
    static func collapseDuration(reduceMotion: Bool) -> TimeInterval {
        reduceMotion ? reducedMotion : collapse
    }
}
