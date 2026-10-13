import Foundation

/// Hub 面板的生命周期状态。
///
/// 取值来自设计合同 `states.menuBarAndNotchHub.hubStates`，一个不多一个不少。
/// 合同的 `interactionPath` 给出 `HIDDEN → HOVER → OPEN → ACTIVE → EXIT → HIDDEN`
/// 与 `ERROR → OPEN`。本文件把这条路径补全为可执行的状态机。
enum HubState: String, CaseIterable, Sendable {
    case hidden = "HIDDEN"
    case hover = "HOVER"
    case open = "OPEN"
    case active = "ACTIVE"
    case exit = "EXIT"
    case error = "ERROR"

    /// 合同里的 slug。用于拼 `copyKey` 与 `contractKey`。
    var slug: String {
        switch self {
        case .hidden: "hidden"
        case .hover: "hover"
        case .open: "open"
        case .active: "active"
        case .exit: "exit"
        case .error: "error"
        }
    }

    /// 合同 `hubStates[].copyKey`。
    var copyKey: String { "copy/notch-hub/state/\(slug)" }

    /// 合同 `hubStates[].contractKey`。
    var contractKey: String { "state/notch-hub/\(slug)" }

    /// 面板窗口是否应该出现在屏幕上。
    var isPanelVisible: Bool { self != .hidden }
}

/// Hub 内容区的输出状态。
///
/// 取值来自设计合同 `states.notchOutputHub.states`。
/// 这台状态机与 `HubState` 正交：`HubState` 管窗口的可见性与生命周期，
/// `HubOutputState` 管内容区显示什么。合同给了两条独立的 `interactionPath`，
/// 说明设计上本来就是两台机器。
///
/// M1 只把内容区固定为 `collapsed`。M3 的截图与 M4 的剪贴板会驱动它。
enum HubOutputState: String, CaseIterable, Sendable {
    case collapsed = "COLLAPSED"
    case ready = "READY"
    case expandedOutput = "EXPANDED OUTPUT"
    case dragTarget = "DRAG TARGET"
    case processing = "PROCESSING"
    case error = "ERROR"

    /// 合同里的 slug。`EXPANDED OUTPUT` 的 slug 是 `expanded`，不是 `expanded-output`。
    var slug: String {
        switch self {
        case .collapsed: "collapsed"
        case .ready: "ready"
        case .expandedOutput: "expanded"
        case .dragTarget: "drag-target"
        case .processing: "processing"
        case .error: "error"
        }
    }

    /// 合同 `notchOutputHub.states[].copyKey`。
    var copyKey: String { "copy/notch-hub/state/\(slug)" }

    /// 合同 `notchOutputHub.states[].contractKey`。
    var contractKey: String { "review/notch-output-hub/state/\(slug)" }
}

/// 驱动 `HubState` 的事件。
///
/// 事件名不是合同词汇。合同只定义了状态与状态之间的路径，没有定义事件。
enum HubEvent: String, CaseIterable, Sendable {
    /// 指针进入顶部热区。
    case pointerEnteredHotZone
    /// 指针离开顶部热区。
    case pointerExitedHotZone
    /// 指针进入 Hub 面板。
    case pointerEnteredHub
    /// 指针离开 Hub 面板。
    case pointerExitedHub
    /// 请求收起。来自 500 毫秒计时、Escape，或 `Control+Option+T`。
    case collapseRequested
    /// 展开动画结束。
    case expandFinished
    /// 收起动画结束。
    case collapseFinished
    /// 出现可恢复的错误。
    case failureRaised
    /// 错误已处理。
    case failureCleared
}

/// `HubState` 的状态机。纯值类型，不碰窗口，不碰计时器。
///
/// 计时与动画由 `NotchShellController` 负责。控制器观察状态变化，再执行副作用。
struct HubStateMachine: Sendable {
    private(set) var state: HubState = .hidden

    /// 状态迁移表。
    ///
    /// 合同 `interactionPath` 里的 6 条边都在表内。其余边是这条路径的逆操作。
    private static let transitions: [HubState: [HubEvent: HubState]] = [
        .hidden: [
            .pointerEnteredHotZone: .hover,
        ],
        .hover: [
            // 指针只是路过，没有停留。
            .pointerExitedHotZone: .hidden,
            // 展开动画结束，面板完全打开。
            .expandFinished: .open,
            // 展开途中指针就进了面板。
            .pointerEnteredHub: .open,
            // 展开途中指针离开了面板。可能是从热区直接划走。
            .pointerExitedHub: .exit,
            // 展开途中用户按了 Escape 或快捷键。
            .collapseRequested: .exit,
        ],
        .open: [
            // 指针进入面板，内容变为可交互。
            .pointerEnteredHub: .active,
            // 指针离开面板。控制器同时启动 500 毫秒计时。
            .pointerExitedHub: .open,
            .collapseRequested: .exit,
        ],
        .active: [
            .pointerExitedHub: .open,
            .collapseRequested: .exit,
        ],
        .exit: [
            // 收起动画结束。
            .collapseFinished: .hidden,
            // 收起途中指针又回到热区。
            .pointerEnteredHotZone: .hover,
        ],
        .error: [
            // 合同的 `ERROR → OPEN`。
            .failureCleared: .open,
            .collapseRequested: .exit,
        ],
    ]

    /// 处理一个事件。返回状态是否改变。
    @discardableResult
    mutating func handle(_ event: HubEvent) -> Bool {
        // 错误可以从任何状态进入。合同的 `interactionPath` 只画了 `ERROR → OPEN`，
        // 没有画进入 ERROR 的边，所以这里单独处理。
        if event == .failureRaised {
            guard state != .error else { return false }
            state = .error
            return true
        }

        guard let next = Self.transitions[state]?[event], next != state else { return false }
        state = next
        return true
    }

    /// 某个事件在当前状态下是否有效。测试与调试用。
    func canHandle(_ event: HubEvent) -> Bool {
        if event == .failureRaised { return state != .error }
        return Self.transitions[state]?[event] != nil
    }

    /// 复位。进程退出或显示器配置变化时用。
    mutating func reset() {
        state = .hidden
    }
}
