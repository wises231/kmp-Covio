import XCTest
import kmpDomain
@testable import Covio

/// 晾衣线卡片的动效参数。
///
/// 与 Compose 版 `ShelfMotion.kt` 的 `shelfMotionPlan` 逐值对齐。
/// 两个宿主必须表现得一样，否则同一台机器上换版本时用户会看到不同的动画。
/// 所以这里把七个状态乘以减弱动态效果开与关，一共十四种组合全部钉住。
final class ShelfMotionTests: XCTestCase {
    /// 七个状态的基准值。这是 Compose 版 `shelfMotionPlan` 的完整展开。
    ///
    /// 每一行是：状态、缩放、角度增量、透明度、位移、是否摆动、是否播放下落。
    private static let expectedNormal: [(ShelfVisualState, CGFloat, CGFloat, CGFloat, CGFloat, Bool, Bool)] = [
        (.default, 1, 0, 1, 0, true, false),
        (.hover, ShelfMotionSpec.hoverScale, 0, 1, 0, false, false),
        (.pressed, ShelfMotionSpec.pressedScale, -0.6, 0.96, 0, false, false),
        (.copied, 1.01, ShelfMotionSpec.copySwingDegrees, 1, 0, false, false),
        (.dragging, 0.98, 0, 0.92, 0, false, false),
        (.flying, 1.02, 4, 0.88, 0, false, false),
        (.falling, 0.96, -2, 0.15, ShelfMotionSpec.fallingDistance, false, true),
    ]

    /// 减弱动态效果时的取值。下落态不在表里，它有自己的规则。
    private static let expectedReduced: [(ShelfVisualState, CGFloat, CGFloat)] = [
        (.default, 1, 1),
        (.hover, 1, 1),
        (.pressed, ShelfMotionSpec.pressedScale, 1),
        (.copied, 1, 1),
        (.dragging, 1, 0.88),
        (.flying, 1, 1),
    ]

    /// 上面两张表覆盖了全部七个状态。
    func testTheTablesCoverEveryState() {
        XCTAssertEqual(Self.expectedNormal.count, ShelfVisualState.allCases.count)
        XCTAssertEqual(
            Set(Self.expectedNormal.map(\.0)), Set(ShelfVisualState.allCases),
            "基准值表漏了状态或者多了不存在的状态"
        )
        XCTAssertEqual(
            Set(Self.expectedReduced.map(\.0)),
            Set(ShelfVisualState.allCases).subtracting([.falling]),
            "减弱动态效果的表应当覆盖除下落以外的全部状态"
        )
    }

    /// 逐个状态比对基准值。
    func testNormalPlansMatchTheTable() {
        for (state, scale, rotation, opacity, offset, breeze, fall) in Self.expectedNormal {
            let plan = shelfMotionPlan(state: state, reduceMotion: false)
            XCTAssertEqual(plan.scale, scale, accuracy: 0.0001, "\(state.rawValue) 的缩放")
            XCTAssertEqual(plan.rotationAdjustmentDegrees, rotation, accuracy: 0.0001, "\(state.rawValue) 的角度")
            XCTAssertEqual(plan.opacity, opacity, accuracy: 0.0001, "\(state.rawValue) 的透明度")
            XCTAssertEqual(plan.verticalOffset, offset, accuracy: 0.0001, "\(state.rawValue) 的位移")
            XCTAssertEqual(plan.breezeEnabled, breeze, "\(state.rawValue) 的摆动开关")
            XCTAssertEqual(plan.fallAnimationEnabled, fall, "\(state.rawValue) 的下落开关")
        }
    }

    /// 逐个状态比对减弱动态效果时的取值。
    func testReducedPlansMatchTheTable() {
        for (state, scale, opacity) in Self.expectedReduced {
            let plan = shelfMotionPlan(state: state, reduceMotion: true)
            XCTAssertEqual(plan.scale, scale, accuracy: 0.0001, "\(state.rawValue) 的缩放")
            XCTAssertEqual(plan.opacity, opacity, accuracy: 0.0001, "\(state.rawValue) 的透明度")
            XCTAssertEqual(plan.rotationAdjustmentDegrees, 0, "\(state.rawValue) 不该旋转")
            XCTAssertEqual(plan.verticalOffset, 0, "\(state.rawValue) 不该位移")
            XCTAssertFalse(plan.breezeEnabled, "\(state.rawValue) 不该摆动")
            XCTAssertFalse(plan.fallAnimationEnabled, "\(state.rawValue) 不该播放下落")
        }
    }

    /// 只有常态会自己摆动。一直摆会让人分心。
    func testOnlyDefaultStateBreezes() {
        for state in ShelfVisualState.allCases {
            XCTAssertEqual(
                shelfMotionPlan(state: state, reduceMotion: false).breezeEnabled,
                state == .default,
                "\(state.rawValue) 的摆动开关不对"
            )
        }
    }

    /// 按下态在减弱动态效果时保留缩放。
    ///
    /// 缩到 0.95 是按下唯一还看得见的反馈。去掉它用户就不知道点中没有。
    func testPressedKeepsItsScaleUnderReduceMotion() {
        XCTAssertEqual(
            shelfMotionPlan(state: .pressed, reduceMotion: true).scale,
            ShelfMotionSpec.pressedScale,
            accuracy: 0.0001
        )
    }

    /// 下落态是唯一在减弱动态效果时仍然要表达「掉下去了」的状态。
    ///
    /// 位移换成透明度：不动，但明显变淡。
    func testFallingAlwaysFadesOut() {
        let normal = shelfMotionPlan(state: .falling, reduceMotion: false)
        let reduced = shelfMotionPlan(state: .falling, reduceMotion: true)

        XCTAssertEqual(normal.verticalOffset, ShelfMotionSpec.fallingDistance)
        XCTAssertEqual(reduced.verticalOffset, 0, "减弱动态效果时不该位移")
        XCTAssertTrue(normal.fallAnimationEnabled)
        XCTAssertFalse(reduced.fallAnimationEnabled)
        XCTAssertLessThan(normal.opacity, 1)
        XCTAssertLessThan(reduced.opacity, 1)
        XCTAssertLessThan(normal.opacity, reduced.opacity, "不减弱时落得更淡")
    }

    /// 拖动与飞行都半透明，好让底下的东西看得见。
    func testDraggingAndFlyingAreTranslucent() {
        XCTAssertLessThan(shelfMotionPlan(state: .dragging, reduceMotion: false).opacity, 1)
        XCTAssertLessThan(shelfMotionPlan(state: .flying, reduceMotion: false).opacity, 1)
    }

    /// 复制态往一侧摆，角度等于 `copySwingDegrees`，并轻微放大作为成功反馈。
    func testCopiedSwingsAndGrows() {
        let plan = shelfMotionPlan(state: .copied, reduceMotion: false)
        XCTAssertEqual(plan.rotationAdjustmentDegrees, ShelfMotionSpec.copySwingDegrees, accuracy: 0.0001)
        XCTAssertGreaterThan(plan.scale, 1)
    }

    /// 悬停放大，按下缩小，两者方向相反。
    func testHoverGrowsAndPressShrinks() {
        XCTAssertGreaterThan(ShelfMotionSpec.hoverScale, 1)
        XCTAssertLessThan(ShelfMotionSpec.pressedScale, 1)
    }

    /// 减弱动态效果时去掉连续动作与大位移。
    func testReduceMotionRemovesContinuousAndLargeTravel() {
        for state in ShelfVisualState.allCases where state != .falling {
            let plan = shelfMotionPlan(state: state, reduceMotion: true)
            XCTAssertEqual(plan.rotationAdjustmentDegrees, 0)
            XCTAssertFalse(plan.breezeEnabled)
            XCTAssertFalse(plan.fallAnimationEnabled)
            XCTAssertEqual(plan.verticalOffset, 0)
        }
    }

    // MARK: - 时长

    /// 两个时长与 `HubMotion` 是同一个值。
    ///
    /// `HubMotion` 是 Hub 与晾衣线共用的来源。这里断言它们相等，
    /// 免得以后有人只改一边，让同一次动画在两个界面里快慢不一。
    func testTimingsMatchHubMotion() {
        XCTAssertEqual(ShelfMotionSpec.flyInSeconds, 0.650, accuracy: 0.0001, "截图捕获")
        XCTAssertEqual(ShelfMotionSpec.copyToastSeconds, 1.200, accuracy: 0.0001, "截图复制")
        XCTAssertEqual(ShelfMotionSpec.reducedMotionSeconds, 0.120, accuracy: 0.0001, "减弱动态效果")
        XCTAssertEqual(HubMotion.screenshotCapture, ShelfMotionSpec.flyInSeconds)
        XCTAssertEqual(HubMotion.screenshotCopy, ShelfMotionSpec.copyToastSeconds)
    }

    /// 时长都是正的，并且顺序合理。
    ///
    /// 淡出比下落快，下落比复制提示短，否则会出现「提示还没看清就消失」。
    func testTimingsAreOrdered() {
        XCTAssertGreaterThan(ShelfMotionSpec.stateChangeSeconds, 0)
        XCTAssertLessThan(ShelfMotionSpec.stateChangeSeconds, ShelfMotionSpec.fallingSeconds)
        XCTAssertLessThan(ShelfMotionSpec.fallingSeconds, ShelfMotionSpec.flyInSeconds)
        XCTAssertLessThan(ShelfMotionSpec.flyInSeconds, ShelfMotionSpec.copyToastSeconds)
        XCTAssertGreaterThan(ShelfMotionSpec.breezeSwingSeconds, 0)
        XCTAssertGreaterThan(ShelfMotionSpec.breezeHoldSeconds, ShelfMotionSpec.breezeSwingSeconds)
    }

    /// 微风的间隔为正，且有上下限之分。
    func testBreezeIntervalsAreOrdered() {
        XCTAssertGreaterThan(ShelfMotionSpec.breezeMinSeconds, 0)
        XCTAssertLessThan(ShelfMotionSpec.breezeMinSeconds, ShelfMotionSpec.breezeMaxSeconds)
        XCTAssertGreaterThan(ShelfMotionSpec.breezeMinDegrees, 0)
        XCTAssertLessThan(ShelfMotionSpec.breezeMinDegrees, ShelfMotionSpec.breezeMaxDegrees)
    }

    /// **已知不一致：** 微风的幅度上限比复制摆动还大。
    ///
    /// 微风最大 3.4 度，复制摆动 3 度。两个数都来自 Compose 版的 `MacMotionSpec`，
    /// 所以这个不一致在 Compose 宿主上已经存在，不是迁移引入的。
    ///
    /// 后果是复制反馈不一定看得出来：卡片本来就在微风里摆，摆到 3.4 度时
    /// 复制那 3 度就没有对照。要么把微风上限压到 3 度以下，要么把复制摆动加大。
    /// 两个数都是产品参数，改哪个都是设计决定，所以这里只记录，不改。
    ///
    /// 修好之后这条用例会失败，那时把实测值一起改掉。
    func testBreezeCanExceedTheCopySwing() {
        XCTAssertGreaterThan(
            ShelfMotionSpec.breezeMaxDegrees, ShelfMotionSpec.copySwingDegrees,
            "微风与复制摆动的幅度关系变了，重新评估这条已知不一致"
        )
        XCTAssertEqual(ShelfMotionSpec.breezeMaxDegrees, 3.4, accuracy: 0.0001)
        XCTAssertEqual(ShelfMotionSpec.copySwingDegrees, 3, accuracy: 0.0001)
    }

    // MARK: - 弹簧

    /// 弹簧参数是正的，且旋转的阻尼比缩放低。
    ///
    /// 阻尼比低摆得久，这是卡片落地后还要晃两下的原因。
    func testSpringParametersAreUsable() {
        XCTAssertGreaterThan(ShelfMotionSpec.scaleSpringStiffness, 0)
        XCTAssertGreaterThan(ShelfMotionSpec.rotationSpringStiffness, 0)
        XCTAssertGreaterThan(ShelfMotionSpec.scaleSpringDamping, 0)
        XCTAssertGreaterThan(ShelfMotionSpec.rotationSpringDamping, 0)
        XCTAssertLessThan(ShelfMotionSpec.scaleSpringDamping, 1, "阻尼比到 1 就没有回弹")
        XCTAssertLessThan(
            ShelfMotionSpec.rotationSpringDamping, ShelfMotionSpec.scaleSpringDamping,
            "旋转应当比缩放多摆一会儿"
        )
    }
}
