import CoreGraphics
import Foundation
import kmpDomain

/// 晾衣线卡片的视觉状态。
///
/// 取值对应 `component/screenshot-card` 与 `component/clothespin` 的 `variants`，
/// 外加两个只在运行期存在的过渡态：`flying` 与 `falling`。
enum ShelfVisualState: String, CaseIterable, Sendable {
    case `default` = "DEFAULT"
    case hover = "HOVER"
    case pressed = "PRESSED"
    case copied = "COPIED"
    case dragging = "DRAGGING"
    case flying = "FLYING"
    case falling = "FALLING"
}

/// 一个状态对应的动效参数。
///
/// 每个字段都是相对基准值的增量，不是绝对值。基准来自 `ShelfLayout` 的几何与 `tiltDegrees`。
struct ShelfMotionPlan: Equatable, Sendable {
    let scale: CGFloat
    let rotationAdjustmentDegrees: CGFloat
    let opacity: CGFloat
    let verticalOffset: CGFloat
    let breezeEnabled: Bool
    let fallAnimationEnabled: Bool
}

/// 晾衣线的动效参数。
///
/// 数值来源是 `docs/covio-product-master.md` 第 6.4 节，以及 Compose 版
/// `app/src/com/wyz/covio/app/ui/MacTheme.kt` 的 `MacMotionSpec`。
/// 弹簧参数与微风的保持时长直接写在 `app/src/com/wyz/covio/app/ui/ShelfWindow.kt` 里，
/// 这里一并收拢，好让两个宿主的动画参数只有一处可查。
/// 这里是这些数值在 Swift 侧的唯一落点。
///
/// 捕获 0.65 秒与复制 1.2 秒已经在 `HubMotion` 里，这里不重复定义。
enum ShelfMotionSpec {
    /// 悬停放大。
    static let hoverScale: CGFloat = 1.035
    /// 按下缩小。
    static let pressedScale: CGFloat = 0.95
    /// 复制时的摆动角度。
    static let copySwingDegrees: CGFloat = 3
    /// 落地摆动时长。
    static let landingSwingSeconds: TimeInterval = 0.42
    /// 微风的最小与最大间隔。
    static let breezeMinSeconds: TimeInterval = 7
    static let breezeMaxSeconds: TimeInterval = 16
    /// 微风的最小与最大角度。
    static let breezeMinDegrees: CGFloat = 1.6
    static let breezeMaxDegrees: CGFloat = 3.4
    /// 移除时下落时长与距离。
    static let fallingSeconds: TimeInterval = 0.55
    static let fallingDistance: CGFloat = 520
    /// 减弱动态效果时只改透明度，用这个时长。
    static let reducedMotionSeconds: TimeInterval = 0.120
    /// 透明度与位移的常规过渡时长。减弱动态效果时换成 `reducedMotionSeconds`。
    static let stateChangeSeconds: TimeInterval = 0.180
    /// 一次微风摆动的过渡时长。
    static let breezeSwingSeconds: TimeInterval = 0.820
    /// 一次微风把角度保持住的时长。过了这段时间角度回到零。
    static let breezeHoldSeconds: TimeInterval = 0.900

    /// 缩放的弹簧参数。对应 Compose 的 `spring(dampingRatio = 0.78f, stiffness = 420f)`。
    ///
    /// SwiftUI 的 `interpolatingSpring(stiffness:damping:)` 用同一套参数，
    /// 质量两边都默认是 1，所以数值可以直接搬过来。
    static let scaleSpringStiffness: CGFloat = 420
    static let scaleSpringDamping: CGFloat = 0.78

    /// 旋转的弹簧参数。对应 Compose 的 `spring(dampingRatio = 0.62f, stiffness = 330f)`。
    ///
    /// 阻尼比缩放更低，是为了让卡片落地后多摆两下。
    static let rotationSpringStiffness: CGFloat = 330
    static let rotationSpringDamping: CGFloat = 0.62

    /// 卡片从屏幕外飞入的时长。等于 §6.4 的「截图捕获 650 毫秒」。
    static var flyInSeconds: TimeInterval { HubMotion.screenshotCapture }
    /// 复制提示的停留时长。等于 §6.4 的「截图复制 1200 毫秒提示」。
    static var copyToastSeconds: TimeInterval { HubMotion.screenshotCopy }
}

/// 某个状态对应的动效参数。
///
/// 与 Compose 版 `shelfMotionPlan` 逐值对齐。两个宿主必须表现得一样，
/// 否则同一台机器上换版本时用户会看到不同的动画。
func shelfMotionPlan(state: ShelfVisualState, reduceMotion: Bool) -> ShelfMotionPlan {
    let base: ShelfMotionPlan
    switch state {
    case .default:
        base = ShelfMotionPlan(
            scale: 1,
            rotationAdjustmentDegrees: 0,
            opacity: 1,
            verticalOffset: 0,
            breezeEnabled: !reduceMotion,
            fallAnimationEnabled: false
        )
    case .hover:
        base = ShelfMotionPlan(
            scale: ShelfMotionSpec.hoverScale,
            rotationAdjustmentDegrees: 0,
            opacity: 1,
            verticalOffset: 0,
            breezeEnabled: false,
            fallAnimationEnabled: false
        )
    case .pressed:
        base = ShelfMotionPlan(
            scale: ShelfMotionSpec.pressedScale,
            rotationAdjustmentDegrees: -0.6,
            opacity: 0.96,
            verticalOffset: 0,
            breezeEnabled: false,
            fallAnimationEnabled: false
        )
    case .copied:
        base = ShelfMotionPlan(
            scale: 1.01,
            rotationAdjustmentDegrees: ShelfMotionSpec.copySwingDegrees,
            opacity: 1,
            verticalOffset: 0,
            breezeEnabled: false,
            fallAnimationEnabled: false
        )
    case .dragging:
        base = ShelfMotionPlan(
            scale: 0.98,
            rotationAdjustmentDegrees: 0,
            opacity: 0.92,
            verticalOffset: 0,
            breezeEnabled: false,
            fallAnimationEnabled: false
        )
    case .flying:
        base = ShelfMotionPlan(
            scale: 1.02,
            rotationAdjustmentDegrees: 4,
            opacity: 0.88,
            verticalOffset: 0,
            breezeEnabled: false,
            fallAnimationEnabled: false
        )
    case .falling:
        // 下落是唯一在减弱动态效果时仍然保留位移意图的状态：位移换成只改透明度。
        base = ShelfMotionPlan(
            scale: 0.96,
            rotationAdjustmentDegrees: -2,
            opacity: reduceMotion ? 0.35 : 0.15,
            verticalOffset: reduceMotion ? 0 : ShelfMotionSpec.fallingDistance,
            breezeEnabled: false,
            fallAnimationEnabled: !reduceMotion
        )
        return base
    }

    guard reduceMotion else { return base }
    // 减弱动态效果：去掉缩放与旋转，只保留必要的透明度变化。
    return ShelfMotionPlan(
        scale: state == .pressed ? ShelfMotionSpec.pressedScale : 1,
        rotationAdjustmentDegrees: 0,
        opacity: state == .dragging ? 0.88 : 1,
        verticalOffset: 0,
        breezeEnabled: false,
        fallAnimationEnabled: false
    )
}
