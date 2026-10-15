import Foundation

/// 面板当前显示的位置。
///
/// 首页不是工作区，所以它不在工作区列表里。顶栏左端的网格按钮选它。
/// 这一条与 `WorkbenchConfig` 一致：首页的组件单独放在 `homeWidgets`。
///
/// 工作区那一支只存 id，不存实例。名字与种类随时可能被配置改掉，
/// 存实例会让视图拿着过期的一份。
enum HubDestination: Hashable, Sendable {
    /// 首页。组件网格。
    case home
    /// 一个工作区。参数是 `PaneInstance.id`。
    case pane(id: String)

    /// 当前选中的工作区 id。首页时是 nil。
    var paneID: String? {
        switch self {
        case .home: nil
        case .pane(let id): id
        }
    }
}
