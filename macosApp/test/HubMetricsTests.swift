import SwiftUI
import XCTest
import kmpDomain
@testable import Covio

/// Hub 卡片的几何。
///
/// 卡片分两栏：左边是导航栏，右边是胶囊加页内容。
/// 这里的每一条都在核对「加法有没有漏项」，因为漏项的后果是内容被裁掉，
/// 而裁掉的部分在测试里看不出来。
@MainActor
final class HubMetricsTests: XCTestCase {
    /// 导航栏高度等于各段之和：上下内边距、搜索栏、六个页签、底部组。
    func testTheRailHeightIsTheSumOfItsParts() {
        let expected = HubMetrics.railPadding * 2
            + HubMetrics.railSearchHeight
            + HubMetrics.railSectionGap
            + CGFloat(HubTab.allCases.count) * HubMetrics.railItemHeight
            + HubMetrics.railSectionGap
            + HubMetrics.railStatusHeight
            + CGFloat(HubMetrics.railBottomRowCount) * HubMetrics.railItemHeight
            + CGFloat(HubMetrics.railBottomRowCount) * HubMetrics.railRowGap
        XCTAssertEqual(HubMetrics.navRailHeight, expected)
    }

    /// 底部组是三项：设置、语言、退出。
    func testTheRailHasThreeBottomRows() {
        XCTAssertEqual(HubMetrics.railBottomRowCount, 3)
    }

    /// 右栏宽度等于卡片宽度减去两边内边距、导航栏与栏间距。
    func testTheContentColumnFitsInsideTheCard() {
        XCTAssertEqual(
            HubMetrics.contentColumnWidth,
            HubMetrics.cardWidth
                - HubMetrics.cardPadding * 2
                - HubMetrics.navRailWidth
                - HubMetrics.columnGap
        )
        XCTAssertGreaterThan(HubMetrics.contentColumnWidth, 0)
        // 晾衣线的卡片按这个宽度排布，太窄就放不下。
        XCTAssertGreaterThan(HubMetrics.contentColumnWidth, 600)
    }

    /// 卡片内部高度取左栏与右栏的高者。
    func testTheInteriorHeightTakesTheTallerColumn() {
        for tab in HubTab.allCases {
            let right = HubMetrics.toolbarCapsuleHeight
                + HubMetrics.pageGap
                + HubMetrics.pageContentHeight(for: tab)
            XCTAssertEqual(HubMetrics.interiorHeight(for: tab), max(HubMetrics.navRailHeight, right))
        }
    }

    /// 卡片高度等于内部高度加上下内边距。面板窗口按这个值设高。
    func testTheCardHeightAddsTheCardPadding() {
        for tab in HubTab.allCases {
            XCTAssertEqual(
                HubMetrics.contentHeight(for: tab),
                HubMetrics.interiorHeight(for: tab) + HubMetrics.cardPadding * 2
            )
        }
    }

    /// 占位页的卡片高度由导航栏决定，不由页内容决定。
    ///
    /// 占位页内容只有 180 点，比 370 点的导航栏矮，所以卡片高度等于导航栏加内边距。
    func testThePlaceholderCardIsAsTallAsTheRail() {
        for tab in [HubTab.now, .devices] {
            XCTAssertGreaterThan(HubMetrics.navRailHeight, HubMetrics.placeholderPageContentHeight)
            XCTAssertEqual(
                HubMetrics.contentHeight(for: tab),
                HubMetrics.navRailHeight + HubMetrics.cardPadding * 2
            )
        }
    }

    /// 卡片宽度不超过 Hub 的宽度上限：面板窗口按卡片宽度居中，不会左右越界。
    func testTheCardWidthFitsTheHubWidth() {
        for screenWidth in [CGFloat(1_280), 1_440, 1_920, 2_560] {
            XCTAssertGreaterThanOrEqual(HubMetrics.hubWidth(screenWidth: screenWidth), HubMetrics.cardWidth)
        }
    }

    /// 页内容高度都比 0 大。零高度说明某一段漏算了。
    func testEveryTabHasAPositivePageContentHeight() {
        for tab in HubTab.allCases {
            XCTAssertGreaterThan(HubMetrics.pageContentHeight(for: tab), 0, "\(tab.rawValue) 的页内容高度为 0")
        }
    }

    /// 剪切板页高按各段相加。
    ///
    /// 提示条可能出现也可能不出现，所以按它出现算。
    /// 这一页的高度常数以前少算过一段，结果底部按钮行被裁。
    /// 见 `docs/adr/adr-0001-macos-ui-swiftui.md` 实测 33。
    /// 文件页的同一条断言在 `WorkspaceTests`。
    func testTheClipboardPageHeightIsTheSumOfItsParts() {
        let expected = ClipboardTabView.listHeight
            + MacTheme.space3 * 2
            + ClipboardTabView.noticeGap
            + ClipboardTabView.noticeHeight
        XCTAssertEqual(
            HubMetrics.pageContentHeight(for: .clipboard),
            expected,
            "剪切板页高不等于各段之和"
        )
        XCTAssertGreaterThan(
            HubMetrics.pageContentHeight(for: .clipboard),
            HubMetrics.placeholderPageContentHeight
        )
    }
}
