import XCTest
import kmpDomain
@testable import Covio

/// 工作台模型：目的地、页签、首页组件与编辑模式。
///
/// 这些断言守着的是「视图读到的值与配置一致」。模型错了的后果是界面显示
/// 一个用户没存过的状态，而落盘的那一份还是旧的。
@MainActor
final class WorkbenchModelTests: XCTestCase {
    private func model() -> WorkbenchModel {
        WorkbenchModel()
    }

    // MARK: - 初始状态

    /// 初始停在首页，不在编辑模式。
    func testTheModelStartsOnTheHomePage() {
        let model = model()
        XCTAssertEqual(model.destination, .home)
        XCTAssertFalse(model.isEditing)
    }

    /// 默认配置里有六块组件，与打样一致。
    func testTheDefaultConfigHasSixWidgets() {
        XCTAssertEqual(model().homeWidgets.count, 6)
    }

    /// 默认配置里的内置工作区是六个。`board` 是用户自建的，不在默认里。
    func testTheDefaultConfigShowsEveryBuiltInPane() {
        let model = model()
        XCTAssertEqual(model.panes.count, 6)
        XCTAssertEqual(
            model.panes.map(\.tab),
            [.now, .clipboard, .files, .screenshots, .devices, .settings]
        )
        for pane in model.panes {
            XCTAssertFalse(pane.title.isEmpty, "\(pane.id) 没有标题")
            XCTAssertFalse(pane.glyph.isEmpty, "\(pane.id) 没有图标")
        }
    }

    /// 首页的行数由装箱算出来，不是写死的。
    func testHomeRowsComeFromThePacker() {
        let model = model()
        XCTAssertEqual(
            model.homeRows,
            BentoPacker.rows(BentoPacker.pack(model.homeWidgets, columns: HubMetrics.bentoColumns))
        )
        XCTAssertGreaterThan(model.homeRows, 0)
    }

    // MARK: - 换页

    /// 选中一个工作区就换到那一页。
    func testSelectingAPaneChangesTheDestination() {
        let model = model()
        model.select(paneID: PaneKind.clipboard.defaultId)
        XCTAssertEqual(model.destination, .pane(id: PaneKind.clipboard.defaultId))
        XCTAssertEqual(model.tab(for: model.destination), .clipboard)
    }

    /// 找不到的工作区停在原地，不崩也不换页。
    func testSelectingAnUnknownPaneDoesNothing() {
        let model = model()
        model.select(paneID: "no-such-pane")
        XCTAssertNotEqual(model.destination, .pane(id: "no-such-pane"))
    }

    /// 编辑模式里不换页。页签与卡片是两个页面的东西，一起编辑会串。
    func testSelectingAPaneIsIgnoredWhileEditing() {
        let model = model()
        model.isEditing = true
        model.select(paneID: PaneKind.clipboard.defaultId)
        XCTAssertEqual(model.destination, .home)
    }

    /// 换页就退出编辑模式。
    func testChangingThePageLeavesEditingMode() {
        let model = model()
        model.isEditing = true
        model.destination = .pane(id: PaneKind.files.defaultId)
        XCTAssertFalse(model.isEditing)
    }

    // MARK: - 顶栏右端的动作

    /// 首页上是「编辑」，设置页上是「返回」，其余是「设置」，编辑中是「完成」。
    func testThePageActionFollowsTheDestination() {
        let model = model()
        XCTAssertEqual(model.pageAction.text(for: .simplifiedChinese), ContractCopy.copyHubActionEdit.text(for: .simplifiedChinese))

        model.isEditing = true
        XCTAssertEqual(model.pageAction.text(for: .simplifiedChinese), ContractCopy.copyHubActionDone.text(for: .simplifiedChinese))

        model.isEditing = false
        model.destination = .pane(id: PaneKind.settings.defaultId)
        XCTAssertEqual(model.pageAction.text(for: .simplifiedChinese), ContractCopy.copyHubActionBack.text(for: .simplifiedChinese))

        model.destination = .pane(id: PaneKind.files.defaultId)
        XCTAssertEqual(model.pageAction.text(for: .simplifiedChinese), ContractCopy.copyHubActionSettings.text(for: .simplifiedChinese))
    }

    /// 首页上按一次进编辑模式，再按一次出来。
    func testThePageActionTogglesEditingOnTheHomePage() {
        let model = model()
        model.performPageAction()
        XCTAssertTrue(model.isEditing)
        model.performPageAction()
        XCTAssertFalse(model.isEditing)
    }

    /// 别处按一次进设置页，设置页上按一次回首页。
    func testThePageActionGoesToSettingsAndBack() {
        let model = model()
        model.destination = .pane(id: PaneKind.files.defaultId)
        model.performPageAction()
        XCTAssertEqual(model.destination, .pane(id: PaneKind.settings.defaultId))
        model.performPageAction()
        XCTAssertEqual(model.destination, .home)
    }

    // MARK: - 页标题行

    /// 首页没有页标题行。打样的首页直接从网格开始。
    func testTheHomePageHasNoHeading() {
        XCTAssertNil(model().heading(for: .home))
    }

    /// 每个工作区都有标题与说明。
    func testEveryPaneHasAHeading() {
        let model = model()
        for pane in model.panes {
            let heading = model.heading(for: .pane(id: pane.id))
            XCTAssertNotNil(heading, "\(pane.id) 没有页标题")
            XCTAssertFalse(heading?.title.isEmpty ?? true, "\(pane.id) 的标题为空")
            XCTAssertFalse(heading?.summary.isEmpty ?? true, "\(pane.id) 的说明为空")
        }
    }

    // MARK: - 编辑首页

    /// 换位把一块挪到目标位置，其余顺序不变。
    func testMovingAWidgetReordersTheList() {
        let model = model()
        let before = model.homeWidgets.map(\.id)
        model.moveWidget(from: 0, to: 2)
        var expected = before
        let moved = expected.remove(at: 0)
        expected.insert(moved, at: 2)
        XCTAssertEqual(model.homeWidgets.map(\.id), expected)
    }

    /// 越界的换位按打样的做法夹到两端，不崩也不丢组件。
    ///
    /// 打样 `WorkbenchPreview.kt` 的写法是 `list.add(to.coerceIn(0, list.size), moved)`，
    /// 所以拖过头是「放到最后」，不是「忽略」。
    func testMovingAWidgetOutOfRangeClampsToTheEnds() {
        let model = model()
        let count = model.homeWidgets.count

        model.moveWidget(from: 0, to: 99)
        XCTAssertEqual(model.homeWidgets.map(\.id).last, "w-clock")
        XCTAssertEqual(model.homeWidgets.count, count)

        model.moveWidget(from: count - 1, to: -5)
        XCTAssertEqual(model.homeWidgets.map(\.id).first, "w-clock")
        XCTAssertEqual(model.homeWidgets.count, count)
    }

    /// 起点越界时不动。起点越界说明调用方算错了，夹到两端反而会挪错一块。
    func testMovingAWidgetFromOutOfRangeIsIgnored() {
        let model = model()
        let before = model.homeWidgets.map(\.id)
        model.moveWidget(from: 99, to: 0)
        XCTAssertEqual(model.homeWidgets.map(\.id), before)
    }

    /// 缩放只改那一块的档位，别的字段照旧。
    func testResizingAWidgetKeepsItsOtherFields() {
        let model = model()
        let target = model.homeWidgets[0]
        model.resizeWidget(id: target.id, to: .large)
        let after = model.homeWidgets.first { $0.id == target.id }
        XCTAssertEqual(after?.size.key, "large")
        XCTAssertEqual(after?.kind, target.kind)
    }

    /// 删除只删那一块。
    func testRemovingAWidgetDropsOnlyThatOne() {
        let model = model()
        let target = model.homeWidgets[1]
        model.removeWidget(id: target.id)
        XCTAssertEqual(model.homeWidgets.count, 5)
        XCTAssertFalse(model.homeWidgets.contains { $0.id == target.id })
    }

    /// 删空之后首页是空态，行数为零。
    func testRemovingEveryWidgetLeavesAnEmptyHome() {
        let model = model()
        for widget in model.homeWidgets {
            model.removeWidget(id: widget.id)
        }
        XCTAssertTrue(model.homeWidgets.isEmpty)
        XCTAssertEqual(model.homeRows, 0)
    }

    // MARK: - 页签排序

    /// 页签换位按可见列表的下标走，隐藏的工作区不参与。
    func testMovingAPaneReordersTheVisibleTabs() {
        let model = model()
        let before = model.panes.map(\.id)
        model.movePane(from: 0, to: 1)
        var expected = before
        let moved = expected.remove(at: 0)
        expected.insert(moved, at: 1)
        XCTAssertEqual(model.panes.map(\.id), expected)
    }

    /// 越界的页签换位被忽略。
    func testMovingAPaneOutOfRangeIsIgnored() {
        let model = model()
        let before = model.panes.map(\.id)
        model.movePane(from: 0, to: 99)
        model.movePane(from: 99, to: 0)
        XCTAssertEqual(model.panes.map(\.id), before)
    }

    // MARK: - 落盘

    /// 接了落盘之后，改动写进文件，重建模型还能读回来。
    func testChangesSurviveAReload() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("covio-workbench-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let path = directory.appendingPathComponent("workbench.json").path
        let model = model()
        model.attach(store: WorkbenchStore.companion.create(path: path))
        let removed = model.homeWidgets[0].id
        model.removeWidget(id: removed)
        model.movePane(from: 0, to: 1)
        let expectedOrder = model.panes.map(\.id)

        let reloaded = WorkbenchModel()
        reloaded.attach(store: WorkbenchStore.companion.create(path: path))
        XCTAssertFalse(reloaded.homeWidgets.contains { $0.id == removed }, "删除没有落盘")
        XCTAssertEqual(reloaded.panes.map(\.id), expectedOrder, "页签顺序没有落盘")
    }
}
