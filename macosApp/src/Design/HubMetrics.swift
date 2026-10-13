import CoreGraphics

/// Hub 的几何参数。
///
/// 来源有两处：
/// - `docs/covio-design-contract.json` 给组件的 `nativeSize`。
/// - `MacTheme` 的间距令牌，用来把高度按各段相加。
///
/// 冲突时以合同为准。`DesignContractTests` 会逐值比对。
///
/// 卡片的组成是「左栏导航栏 + 右栏（胶囊 + 页内容）」。
/// 高度按各段相加，不写死一个数：少算一段会把底部裁掉。
enum HubMetrics {
    /// Hub 最小宽度 720 点。
    static let minWidth: CGFloat = 720

    /// Hub 最大宽度是屏幕宽度减 80 点。
    static let horizontalScreenMargin: CGFloat = 80

    /// Hub 最大高度是屏幕高度减 120 点。
    static let verticalScreenMargin: CGFloat = 120

    /// Hub 边框 1 点。
    static let borderWidth: CGFloat = 1

    /// 卡片宽度 960 点。与合同 `component/window-bar` 同宽。
    static let cardWidth: CGFloat = 960

    // MARK: - 卡片内边距与栏间距

    /// 卡片四边内边距。合同 `token/space/4`。
    static let cardPadding: CGFloat = MacTheme.space4

    /// 左栏与右栏之间的间距。
    static let columnGap: CGFloat = MacTheme.space4

    /// 右栏里胶囊与页内容之间的间距。合同 `token/space/3`。
    static let pageGap: CGFloat = MacTheme.space3

    /// 右栏宽度。等于卡片宽度减去两边内边距、左栏与栏间距。
    static var contentColumnWidth: CGFloat {
        cardWidth - cardPadding * 2 - navRailWidth - columnGap
    }

    // MARK: - 左栏：导航栏

    /// 导航栏宽度。来源是合同 `components["component/tab-bar"].nativeSize`。
    static let navRailWidth: CGFloat = 200

    /// 导航栏高度。合同给的是 370，这里按各段相加算出同一个数。
    /// `HubMetricsTests` 会核对两边相等。
    static var navRailHeight: CGFloat { navRailComposition }

    /// 导航栏上下内边距。
    static let railPadding: CGFloat = MacTheme.space3
    /// 搜索框行高。
    static let railSearchHeight: CGFloat = 26
    /// 呼吸灯行高。
    static let railStatusHeight: CGFloat = 20
    /// 导航项与底部每一行的高度。
    static let railItemHeight: CGFloat = 28
    /// 搜索栏、导航项、底部组之间的间距。
    static let railSectionGap: CGFloat = MacTheme.space3
    /// 底部组各行之间的间距。
    static let railRowGap: CGFloat = MacTheme.space2

    /// 导航栏底部的行数：设置、语言、退出。
    static let railBottomRowCount = 3

    /// 导航栏高度按各段相加。
    static var navRailComposition: CGFloat {
        railPadding * 2
            + railSearchHeight
            + railSectionGap
            + CGFloat(HubTab.allCases.count) * railItemHeight
            + railSectionGap
            + railStatusHeight
            + CGFloat(railBottomRowCount) * railItemHeight
            + CGFloat(railBottomRowCount) * railRowGap
    }

    // MARK: - 右栏：胶囊与页内容

    /// 顶部胶囊高度。来源是合同 `components["component/toolbar"].nativeSize.height`。
    static let toolbarCapsuleHeight: CGFloat = 40

    /// 胶囊里标题区的宽度。来源是合同 `components["component/page-title"].nativeSize.width`。
    ///
    /// 合同的 `nativeSize.height` 也是 40，与胶囊等高：标题填满胶囊的高度。
    static let capsuleTitleWidth: CGFloat = 420

    /// 搜索结果一行的行高。要满足合同 `accessibilityRules` 的 24 点下限。
    static let searchRowHeight: CGFloat = MacControlSize.settingRowHeight - MacTheme.space4

    /// 占位页的内容高度。占位页只有标题与提示，不需要更多。
    static let placeholderPageContentHeight: CGFloat = 180

    /// 设置页的内容高度。六个分节共用，内容超出时页内滚动。
    static let settingsPageContentHeight: CGFloat = 500

    /// 截图页的内容高度：晾衣线区域加上下内边距。
    ///
    /// 晾衣线区域与独立工具栏面板一样高，都用 `ShelfLayout` 的值。
    /// `ScreenshotsTabTests` 逐段核对这个和。
    static var screenshotsPageContentHeight: CGFloat {
        ScreenshotsTabView.areaHeight + MacTheme.space3 * 2
    }

    /// 剪切板页的内容高度：列表区、提示条与上下内边距。
    ///
    /// 提示条可能出现也可能不出现，所以按它出现算，宁可多留一点也不裁掉。
    static var clipboardPageContentHeight: CGFloat {
        ClipboardTabView.listHeight
            + MacTheme.space3 * 2
            + ClipboardTabView.noticeGap
            + ClipboardTabView.noticeHeight
    }

    /// 文件页的内容高度：列表区、提示条与上下内边距。
    ///
    /// 与剪切板页同理：提示条可能不出现，按它出现算，宁可多留一点也不裁掉。
    static var filesPageContentHeight: CGFloat {
        FilesTabView.listHeight
            + MacTheme.space3 * 2
            + FilesTabView.noticeGap
            + FilesTabView.noticeHeight
    }

    /// 某个页签的右栏内容高度，不含胶囊。
    static func pageContentHeight(for tab: HubTab) -> CGFloat {
        switch tab {
        case .now, .devices: placeholderPageContentHeight
        case .settings: settingsPageContentHeight
        case .screenshots: screenshotsPageContentHeight
        case .clipboard: clipboardPageContentHeight
        case .files: filesPageContentHeight
        }
    }

    /// 卡片内部高度。左栏与右栏取高者。
    static func interiorHeight(for tab: HubTab) -> CGFloat {
        max(navRailHeight, toolbarCapsuleHeight + pageGap + pageContentHeight(for: tab))
    }

    /// 某个页签的卡片高度。面板窗口的高度由它决定。
    static func contentHeight(for tab: HubTab) -> CGFloat {
        interiorHeight(for: tab) + cardPadding * 2
    }

    // MARK: - 屏幕

    /// 菜单栏图标的命中区。来源是合同 `components["component/tray-icon"].nativeSize`。
    static let trayIconHitTarget: CGFloat = 44

    /// 合同 `accessibilityRules`：交互目标不小于 24 点，主控件尽量 44 点。
    static let minHitTarget: CGFloat = 24
    static let preferredHitTarget: CGFloat = 44

    /// 非刘海屏的热区尺寸。热区在菜单栏下方，所以做得又窄又薄。
    static let notchlessHotZoneWidth: CGFloat = 200
    static let notchlessHotZoneHeight: CGFloat = 6

    /// Hub 宽度。以卡片宽度为基准，限制在最小宽度与屏幕宽度减 80 之间。
    static func hubWidth(screenWidth: CGFloat) -> CGFloat {
        let maximum = max(minWidth, screenWidth - horizontalScreenMargin)
        return min(max(cardWidth, minWidth), maximum)
    }

    /// Hub 的最大高度。
    static func hubMaxHeight(screenHeight: CGFloat) -> CGFloat {
        max(0, screenHeight - verticalScreenMargin)
    }

    /// 展开态的面板高度。
    ///
    /// 不给 `contentHeight` 时用占位页的高度。
    static func expandedHeight(
        safeAreaTop: CGFloat,
        screenHeight: CGFloat,
        contentHeight: CGFloat = HubMetrics.contentHeight(for: .now)
    ) -> CGFloat {
        let chrome = safeAreaTop + contentHeight
        return min(chrome, hubMaxHeight(screenHeight: screenHeight))
    }
}
