import SwiftUI
import XCTest
import kmpDomain
@testable import Covio

/// 截图页签的几何。
///
/// 页内容高度直接决定 Hub 面板窗口的高度。算少了页面底部会被裁掉，
/// 算多了卡片底部会多一条空白。所以这里把每一段拆开核对，
/// 而不是断言一个写死的数字。
///
/// 页标题与三个动作在顶部胶囊里，不在页内容里。
@MainActor
final class ScreenshotsTabTests: XCTestCase {
    /// 晾衣线区域与独立工具栏面板一样高，都用 `ShelfLayout` 的值。
    ///
    /// 两边不一样高的话，同一批卡片在 Hub 里和工具栏上的位置会对不上。
    func testTheClotheslineAreaMatchesThePanelHeight() {
        XCTAssertEqual(
            ScreenshotsTabView.areaHeight,
            CGFloat(ShelfLayout.shared.PANEL_HEIGHT)
        )
        XCTAssertGreaterThan(ScreenshotsTabView.areaHeight, 0)
    }

    /// 区域宽度等于右栏内容宽度减去左右内边距。
    func testTheClotheslineAreaWidthFitsInsideTheCard() {
        XCTAssertEqual(
            ScreenshotsTabView.areaWidth,
            HubMetrics.contentColumnWidth - MacTheme.space4 * 2
        )
        XCTAssertLessThan(ScreenshotsTabView.areaWidth, HubMetrics.contentColumnWidth)
        // 卡片按这个宽度排布，太窄就放不下 `ShelfLayout` 的边距。
        XCTAssertGreaterThan(ScreenshotsTabView.areaWidth, 400)
    }

    /// 页内容高度是各段之和。逐段重算一遍，防止改动时漏掉某一段。
    func testThePageContentHeightIsTheSumOfItsParts() {
        let expected = ScreenshotsTabView.areaHeight + MacTheme.space3 * 2
        XCTAssertEqual(HubMetrics.pageContentHeight(for: .screenshots), expected)
    }

    /// 高度要盖得住最高的那张卡片，否则卡片下沿会被裁掉。
    ///
    /// 卡片从绳子上垂下来，最高点是 `PANEL_HEIGHT` 加上页的上下内边距。
    func testThePageContentHeightCoversTheTallestCard() {
        let areaTop = MacTheme.space3
        XCTAssertGreaterThanOrEqual(
            HubMetrics.pageContentHeight(for: .screenshots),
            areaTop + ScreenshotsTabView.areaHeight
        )
    }

    /// 截图页比占位页高，但整张卡片不超过 Hub 的最大高度。
    ///
    /// 超出最大高度时面板会被屏幕裁掉，卡片就点不到了。
    func testTheCardHeightStaysWithinTheHubLimit() {
        XCTAssertGreaterThan(
            HubMetrics.pageContentHeight(for: .screenshots),
            HubMetrics.placeholderPageContentHeight
        )
        for height in [CGFloat(900), 1_080, 1_200] {
            XCTAssertLessThan(
                HubMetrics.contentHeight(for: .screenshots) + 60,
                HubMetrics.hubMaxHeight(screenHeight: height),
                "屏幕高 \(height) 时截图页放不下"
            )
        }
    }
}
