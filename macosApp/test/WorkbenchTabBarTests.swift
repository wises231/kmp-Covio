import SwiftUI
import XCTest
import kmpDomain
@testable import Covio

/// 顶栏与编辑模式的形态。
///
/// 顶栏是打样里替代左栏导航条的那一条，编辑模式是打样里的 S6。
/// 这里守的是「页签上的字与把手、编辑提示条上的计数、四个动作词的落点」。
@MainActor
final class WorkbenchTabBarTests: XCTestCase {
    private func panes() -> [PaneItem] {
        let model = WorkbenchModel()
        return model.panes
    }

    /// 每条页签都带自己的图标，图标与种类一一对应。
    func testEveryPaneCarriesItsOwnGlyph() {
        for pane in panes() {
            XCTAssertEqual(pane.glyph, pane.tab.glyph)
            XCTAssertFalse(pane.glyph.isEmpty, "\(pane.id) 没有图标")
        }
    }

    /// 页签的图标各不相同。两个页签长一样，用户分不出哪个是哪个。
    func testPaneGlyphsAreDistinct() {
        let glyphs = panes().map(\.glyph)
        XCTAssertEqual(Set(glyphs).count, glyphs.count, "有两个页签用了同一个图标")
    }

    /// 页签数量不超过模型的上限。
    func testTheTabCountStaysWithinTheModelLimit() {
        XCTAssertLessThanOrEqual(panes().count, Int(WorkbenchConfig.companion.MAX_PANES))
        XCTAssertLessThanOrEqual(panes().count, Int(WorkbenchConfig.companion.MAX_WIDGETS))
    }

    /// 编辑提示条上的计数来自配置：可见工作区数与组件数。
    func testTheEditBannerCountsComeFromTheConfig() {
        let model = WorkbenchModel()
        XCTAssertEqual(model.visiblePaneCount, model.panes.count)
        XCTAssertEqual(model.homeWidgets.count, 6)
    }

    /// 四个动作词都在合同里，且中英都有。
    func testThePageActionWordsComeFromTheContract() {
        for copy in [
            ContractCopy.copyHubActionHome,
            ContractCopy.copyHubActionEdit,
            ContractCopy.copyHubActionDone,
            ContractCopy.copyHubActionSettings,
            ContractCopy.copyHubActionBack,
        ] {
            XCTAssertFalse(copy.en.isEmpty, "\(copy.key ?? "?") 缺英文")
            XCTAssertFalse(copy.zhHans.isEmpty, "\(copy.key ?? "?") 缺中文")
        }
    }

    /// 编辑提示条与空态的文案都在合同里。
    func testTheEditingCopyComesFromTheContract() {
        for copy in [
            ContractCopy.copyHubEditBanner,
            ContractCopy.copyHubHomeEmptyTitle,
            ContractCopy.copyHubHomeEmptyHint,
            ContractCopy.copyHubHomeEmptyHintEditing,
        ] {
            XCTAssertFalse(copy.en.isEmpty, "\(copy.key ?? "?") 缺英文")
            XCTAssertFalse(copy.zhHans.isEmpty, "\(copy.key ?? "?") 缺中文")
        }
    }

    /// 四个尺寸档都有标签。
    func testEverySizeHasALabel() {
        for size in [WidgetSize.small, .wide, .tall, .large] {
            let copy = WidgetCatalog.sizeLabel(size)
            XCTAssertFalse(copy.en.isEmpty, "\(size.key) 缺英文标签")
            XCTAssertFalse(copy.zhHans.isEmpty, "\(size.key) 缺中文标签")
        }
    }

    /// 六种内置组件都有标题与底色，底色取自合同。
    func testEveryBuiltInWidgetHasATitleAndATint() {
        let kinds = ["w-clock", "w-battery", "w-transfer", "w-actions", "w-shots", "w-devices"]
        var tints: Set<String> = []
        for kind in kinds {
            let descriptor = WidgetCatalog.descriptor(for: kind, language: .simplifiedChinese)
            XCTAssertNotEqual(descriptor.title, kind, "\(kind) 没有走目录表，落到了兜底")
            XCTAssertFalse(descriptor.title.isEmpty)
            XCTAssertTrue(descriptor.tint.key.hasPrefix("token/color/widget-tint-"), "\(kind) 的底色不是组件色")
            tints.insert(descriptor.tint.key)
        }
        XCTAssertEqual(tints.count, kinds.count, "有两块组件用了同一个底色")
    }

    /// 认不出的种类也要显示。丢掉就丢了用户排好的位置。
    func testAnUnknownWidgetKindStillRenders() {
        let descriptor = WidgetCatalog.descriptor(for: "w-future", language: .simplifiedChinese)
        XCTAssertEqual(descriptor.title, "w-future")
        XCTAssertFalse(descriptor.tint.key.isEmpty)
    }

    /// 组件标题与尺寸标签都在合同里。
    func testTheWidgetCopyComesFromTheContract() {
        for copy in [
            ContractCopy.copyHubWidgetClockTitle,
            ContractCopy.copyHubWidgetBatteryTitle,
            ContractCopy.copyHubWidgetTransferTitle,
            ContractCopy.copyHubWidgetActionsTitle,
            ContractCopy.copyHubWidgetShotsTitle,
            ContractCopy.copyHubWidgetDevicesTitle,
        ] {
            XCTAssertFalse(copy.en.isEmpty, "\(copy.key ?? "?") 缺英文")
            XCTAssertFalse(copy.zhHans.isEmpty, "\(copy.key ?? "?") 缺中文")
        }
    }
}

/// 首页卡片的副标题。
///
/// 有真实数据的用真实数据，没有的显示占位符，不编。
@MainActor
final class WidgetDetailTests: XCTestCase {
    /// 没有数据源的三块显示占位符。打样里它们是写死的假数据，不能照搬。
    func testWidgetsWithoutADataSourceShowThePlaceholder() {
        for kind in ["w-transfer", "w-actions", "w-devices"] {
            XCTAssertEqual(
                WidgetDetail.text(for: kind, runtime: nil, language: .simplifiedChinese),
                WidgetDetail.missing,
                "\(kind) 没有数据源，应该显示占位符"
            )
        }
    }

    /// 钟表块显示时间与星期。
    func testTheClockShowsTheTimeAndTheWeekday() {
        let text = WidgetDetail.text(for: "w-clock", runtime: nil, language: .simplifiedChinese)
        XCTAssertNotEqual(text, WidgetDetail.missing)
        XCTAssertTrue(text.contains("·"), "钟表块应该同时给时间与星期：\(text)")
    }

    /// 认不出的种类显示占位符。
    func testAnUnknownKindShowsThePlaceholder() {
        XCTAssertEqual(
            WidgetDetail.text(for: "w-future", runtime: nil, language: .english),
            WidgetDetail.missing
        )
    }
}
