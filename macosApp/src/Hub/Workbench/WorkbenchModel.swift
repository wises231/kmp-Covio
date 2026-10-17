import Foundation
import kmpDomain

/// 挂帘的工作台状态。
///
/// 持有工作台配置、当前目的地和编辑模式开关。视图只读它，改动都走这里的方法，
/// 方法改完配置就落盘。
///
/// **编辑模式不进 `HubStateMachine`。** 状态机的六个态由合同与
/// `DesignContractTests` 逐字钉死。扩态是 `docs/design/workbench-architecture.md`
/// 交给 ADR 的事，不该夹在界面对齐里做。
@MainActor
@Observable
final class WorkbenchModel {
    /// 工作台配置。改动一律走下面的方法，直接写会绕过落盘。
    private(set) var config: WorkbenchConfig
    /// 当前显示的位置。默认首页。
    var destination: HubDestination = .home {
        didSet {
            guard destination != oldValue else { return }
            // 换页就退出编辑模式。页签与卡片是两个页面的东西，一起编辑会串。
            isEditing = false
        }
    }
    /// 编辑模式。顶栏右端那个按钮切换它。
    var isEditing = false

    /// 界面语言。页签名字按合同取，换语言要重算一次。
    var language: AppLanguage = CopyLocale.language

    /// 落盘。为 nil 时不存（预览与测试）。
    private var store: WorkbenchStore?

    init(store: WorkbenchStore? = nil) {
        self.store = store
        self.config = store?.load() ?? WorkbenchConfig.companion.defaults()
    }

    /// 接上落盘，并立刻读一次盘。
    ///
    /// `AppDelegate` 在 `start()` 之前调。不在 `init` 里读盘，是因为控制器与
    /// 运行时都要先装配好；测试与预览则根本不接。
    func attach(store: WorkbenchStore) {
        self.store = store
        config = store.load()
    }

    // MARK: - 读

    /// 顶栏要画的页签。隐藏的工作区不出现。
    var panes: [PaneItem] {
        config.visiblePanes.compactMap { pane in
            guard let tab = HubTab(rawValue: pane.kind.key) else { return nil }
            let title = pane.title.isEmpty ? tab.title.text(for: language) : pane.title
            return PaneItem(id: pane.id, tab: tab, title: title)
        }
    }

    /// 界面上可见的工作区数量。编辑提示条用它。
    var visiblePaneCount: Int { config.visiblePanes.count }

    /// 首页的组件。
    var homeWidgets: [WidgetInstance] { config.homeWidgets }

    /// 首页网格几行。面板高度按它算。
    var homeRows: Int {
        BentoPacker.rows(BentoPacker.pack(config.homeWidgets, columns: HubMetrics.bentoColumns))
    }

    /// 某个目的地的种类。找不到时回落到占位页。
    func tab(for destination: HubDestination) -> HubTab {
        guard let id = destination.paneID, let pane = config.pane(id: id) else { return .now }
        return HubTab(rawValue: pane.kind.key) ?? .board
    }

    /// 页标题行里的标题与说明。首页没有标题行，所以返回 nil。
    func heading(for destination: HubDestination) -> (title: String, summary: String)? {
        guard let id = destination.paneID, let pane = config.pane(id: id) else { return nil }
        let tab = HubTab(rawValue: pane.kind.key) ?? .board
        let title = pane.title.isEmpty ? tab.title.text(for: language) : pane.title
        return (title, tab.summary.text(for: language))
    }

    /// 顶栏右端的动作。四个状态各一个词。
    var pageAction: LocalizedCopy {
        if isEditing { return ContractCopy.copyHubActionDone }
        switch destination {
        case .home: return ContractCopy.copyHubActionEdit
        case .pane(let id):
            return config.pane(id: id)?.kind.key == HubTab.settings.rawValue
                ? ContractCopy.copyHubActionBack
                : ContractCopy.copyHubActionSettings
        }
    }

    // MARK: - 写

    /// 顶栏右端按钮的动作。
    func performPageAction() {
        if isEditing {
            isEditing = false
            return
        }
        switch destination {
        case .home:
            isEditing = true
        case .pane(let id) where config.pane(id: id)?.kind.key == HubTab.settings.rawValue:
            destination = .home
        default:
            destination = .pane(id: PaneKind.settings.defaultId)
        }
    }

    /// 换一个工作区。编辑模式里不换，与打样一致。
    ///
    /// 配置里没有这个 id 时停在原地：换过去会显示一页没有标题行的占位内容。
    func select(paneID: String) {
        guard !isEditing, config.pane(id: paneID) != nil else { return }
        destination = .pane(id: paneID)
    }

    /// 换工作区的顺序。参数是可见工作区里的下标。
    func movePane(from: Int, to: Int) {
        let visible = config.visiblePanes
        guard visible.indices.contains(from), visible.indices.contains(to), from != to else { return }
        // `movePane` 要的是全量列表里的下标，隐藏的工作区也算数。
        guard let index = config.panes.firstIndex(where: { $0.id == visible[to].id }) else { return }
        update(config.movePane(id: visible[from].id, toIndex: Int32(index)))
    }

    /// 换两块组件的顺序。参数是配置里的下标。
    func moveWidget(from: Int, to: Int) {
        guard config.homeWidgets.indices.contains(from), from != to else { return }
        var widgets = config.homeWidgets
        let moved = widgets.remove(at: from)
        widgets.insert(moved, at: to.clamped(to: 0...widgets.count))
        update(replacingWidgets(widgets))
    }

    /// 改一块组件的档位。
    func resizeWidget(id: String, to size: WidgetSize) {
        let widgets = config.homeWidgets.map { widget in
            widget.id == id
                ? widget.doCopy(id: widget.id, kind: widget.kind, size: size, settings: widget.settings)
                : widget
        }
        update(replacingWidgets(widgets))
    }

    /// 删一块组件。
    func removeWidget(id: String) {
        update(replacingWidgets(config.homeWidgets.filter { $0.id != id }))
    }

    // MARK: - 落盘

    /// 换掉组件列表，其余字段照抄。
    private func replacingWidgets(_ widgets: [WidgetInstance]) -> WorkbenchConfig {
        config.doCopy(
            schemaVersion: config.schemaVersion,
            panes: config.panes,
            homeWidgets: widgets
        )
    }

    /// 改配置并落盘。
    ///
    /// `WorkbenchStore.save` 自己咽掉写盘失败，不抛异常，所以这里不需要接错误。
    /// 内存里的配置先改，界面立刻跟上；落不落得下是下一步的事。
    private func update(_ next: WorkbenchConfig) {
        config = next
        guard let store else { return }
        _ = store.save(config: next)
    }
}
