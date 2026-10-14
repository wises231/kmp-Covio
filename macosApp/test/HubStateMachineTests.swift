import XCTest
@testable import Covio

/// `HubStateMachine` 的迁移测试。
///
/// 重点是把主路径的每一条边都走一遍，证明状态机没有偏离。
final class HubStateMachineTests: XCTestCase {
    func testInitialStateIsHidden() {
        XCTAssertEqual(HubStateMachine().state, .hidden)
    }

    /// 主路径：HIDDEN → HOVER → OPEN → ACTIVE → EXIT → HIDDEN。
    func testTheInteractionPathIsWalkable() {
        var machine = HubStateMachine()

        XCTAssertTrue(machine.handle(.pointerEnteredHotZone))
        XCTAssertEqual(machine.state, .hover)

        XCTAssertTrue(machine.handle(.expandFinished))
        XCTAssertEqual(machine.state, .open)

        XCTAssertTrue(machine.handle(.pointerEnteredHub))
        XCTAssertEqual(machine.state, .active)

        XCTAssertTrue(machine.handle(.collapseRequested))
        XCTAssertEqual(machine.state, .exit)

        XCTAssertTrue(machine.handle(.collapseFinished))
        XCTAssertEqual(machine.state, .hidden)
    }

    /// 主路径之外还有一条 ERROR → OPEN。
    func testTheErrorEdgeReturnsToOpen() {
        var machine = HubStateMachine()
        machine.handle(.pointerEnteredHotZone)
        machine.handle(.expandFinished)

        XCTAssertTrue(machine.handle(.failureRaised))
        XCTAssertEqual(machine.state, .error)

        XCTAssertTrue(machine.handle(.failureCleared))
        XCTAssertEqual(machine.state, .open)
    }

    /// 指针只是路过热区，没有停留。
    func testPointerPassingThroughHotZoneReturnsToHidden() {
        var machine = HubStateMachine()
        machine.handle(.pointerEnteredHotZone)
        XCTAssertTrue(machine.handle(.pointerExitedHotZone))
        XCTAssertEqual(machine.state, .hidden)
    }

    /// 展开途中指针就进了面板，直接进入 OPEN。
    func testPointerEnteringHubDuringExpansionOpens() {
        var machine = HubStateMachine()
        machine.handle(.pointerEnteredHotZone)
        XCTAssertTrue(machine.handle(.pointerEnteredHub))
        XCTAssertEqual(machine.state, .open)
    }

    /// 展开途中指针离开面板，走 EXIT。
    func testPointerLeavingHubDuringExpansionExits() {
        var machine = HubStateMachine()
        machine.handle(.pointerEnteredHotZone)
        XCTAssertTrue(machine.handle(.pointerExitedHub))
        XCTAssertEqual(machine.state, .exit)
    }

    /// §4.4：指针移出 Hub 后收起，所以 ACTIVE → OPEN 是一条真实存在的边。
    func testActiveReturnsToOpenWhenPointerLeaves() {
        var machine = HubStateMachine()
        machine.handle(.pointerEnteredHotZone)
        machine.handle(.expandFinished)
        machine.handle(.pointerEnteredHub)
        XCTAssertEqual(machine.state, .active)

        // OPEN 状态下指针离开不改状态，只由控制器启动 500 毫秒计时。
        XCTAssertTrue(machine.handle(.pointerExitedHub))
        XCTAssertEqual(machine.state, .open)
    }

    /// 收起途中指针又回到热区，重新展开。
    func testPointerReturningDuringExitReopens() {
        var machine = HubStateMachine()
        machine.handle(.pointerEnteredHotZone)
        machine.handle(.expandFinished)
        machine.handle(.collapseRequested)
        XCTAssertEqual(machine.state, .exit)

        XCTAssertTrue(machine.handle(.pointerEnteredHotZone))
        XCTAssertEqual(machine.state, .hover)
    }

    /// 错误可以从任何状态进入。
    func testFailureRaisedEntersErrorFromEveryState() {
        for state in HubState.allCases where state != .error {
            var machine = machineIn(state)
            XCTAssertTrue(machine.handle(.failureRaised), "从 \(state.rawValue) 进入 ERROR 失败")
            XCTAssertEqual(machine.state, .error)
        }
    }

    /// 非法事件不改变状态，并且 `canHandle` 返回 false。
    func testInvalidEventsAreRejected() {
        var machine = HubStateMachine()
        XCTAssertFalse(machine.canHandle(.expandFinished))
        XCTAssertFalse(machine.handle(.expandFinished))
        XCTAssertEqual(machine.state, .hidden)

        XCTAssertFalse(machine.canHandle(.pointerExitedHub))
        XCTAssertFalse(machine.canHandle(.collapseFinished))
    }

    /// 已经是 ERROR 时重复报错不算变化。
    func testRepeatedFailureDoesNotChangeState() {
        var machine = machineIn(.error)
        XCTAssertFalse(machine.handle(.failureRaised))
        XCTAssertEqual(machine.state, .error)
    }

    /// HIDDEN 是唯一不显示面板的状态。
    func testPanelVisibilityFollowsState() {
        XCTAssertFalse(HubState.hidden.isPanelVisible)
        for state in HubState.allCases where state != .hidden {
            XCTAssertTrue(state.isPanelVisible, "\(state.rawValue) 应该显示面板")
        }
    }

    /// 状态的小写名固定。
    func testStateSlugsAreStable() {
        XCTAssertEqual(HubState.hidden.slug, "hidden")
        XCTAssertEqual(HubState.exit.slug, "exit")
        XCTAssertEqual(HubOutputState.expandedOutput.slug, "expanded")
        XCTAssertEqual(HubOutputState.dragTarget.slug, "drag-target")
    }

    // MARK: - 辅助

    /// 把状态机推到指定状态。路径不唯一的用直接赋值会破坏封装，所以走真实迁移。
    private func machineIn(_ target: HubState) -> HubStateMachine {
        var machine = HubStateMachine()
        switch target {
        case .hidden:
            break
        case .hover:
            machine.handle(.pointerEnteredHotZone)
        case .open:
            machine.handle(.pointerEnteredHotZone)
            machine.handle(.expandFinished)
        case .active:
            machine.handle(.pointerEnteredHotZone)
            machine.handle(.expandFinished)
            machine.handle(.pointerEnteredHub)
        case .exit:
            machine.handle(.pointerEnteredHotZone)
            machine.handle(.expandFinished)
            machine.handle(.collapseRequested)
        case .error:
            machine.handle(.pointerEnteredHotZone)
            machine.handle(.failureRaised)
        }
        precondition(machine.state == target, "无法到达状态 \(target.rawValue)")
        return machine
    }
}
