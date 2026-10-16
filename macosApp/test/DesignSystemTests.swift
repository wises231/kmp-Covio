import XCTest
import kmpDomain
@testable import Covio

/// 十六进制色值的解析。`MacTheme` 用它把常量转成颜色。
final class MacThemeTests: XCTestCase {
    /// 六位是 `RRGGBB`，不带透明度。
    func testSixDigitHexIsOpaque() {
        let color = MacTheme.nsColor(hex: "#4656A4")
        XCTAssertEqual(color.redComponent, 0x46 / 255.0, accuracy: 0.001)
        XCTAssertEqual(color.greenComponent, 0x56 / 255.0, accuracy: 0.001)
        XCTAssertEqual(color.blueComponent, 0xA4 / 255.0, accuracy: 0.001)
        XCTAssertEqual(color.alphaComponent, 1, accuracy: 0.001)
    }

    /// 八位是 `RRGGBBAA`，与 CSS 一致。半透明令牌都是这个形式。
    func testEightDigitHexCarriesAlpha() {
        let color = MacTheme.nsColor(hex: "#0000002E")
        XCTAssertEqual(color.alphaComponent, 0x2E / 255.0, accuracy: 0.001)
        XCTAssertEqual(color.redComponent, 0, accuracy: 0.001)
    }

    /// 认不出的值返回洋红色，好让错误一眼可见。
    func testBadHexIsObvious() {
        XCTAssertEqual(MacTheme.nsColor(hex: "not a color"), .magenta)
        XCTAssertEqual(MacTheme.nsColor(hex: "#12345"), .magenta)
        XCTAssertEqual(MacTheme.nsColor(hex: ""), .magenta)
    }

    /// 每个色值都要能解析。解析失败会变成洋红色。
    func testEveryColorParses() {
        for token in TokenColors.all {
            for hex in [token.lightHex, token.darkHex] {
                XCTAssertNotEqual(MacTheme.nsColor(hex: hex), .magenta, "色值 \(hex) 解析失败")
            }
        }
    }
}

/// 设置页的六个分节。
final class SettingsSectionTests: XCTestCase {
    /// 分节的数量与顺序固定。
    func testSectionsKeepTheirOrder() {
        XCTAssertEqual(
            SettingsSection.allCases.map(\.rawValue),
            ["overview", "battery", "lid", "idle", "topShelf", "general"]
        )
    }

    /// 每节都要有自己的导航名、页标题与页说明。
    func testEachSectionHasCopy() {
        for section in SettingsSection.allCases {
            XCTAssertFalse(section.navTitle.en.isEmpty, "\(section.rawValue) 的导航名是空的")
            XCTAssertFalse(section.pageTitle.en.isEmpty, "\(section.rawValue) 的页标题是空的")
            XCTAssertFalse(section.pageSummary.zhHans.isEmpty, "\(section.rawValue) 的页说明是空的")
        }
    }

    /// 页签对应的内容高度。
    ///
    /// 卡片高度是各段之和，所以这里比的是页内容高度，不是卡片高度。
    /// 面板窗口的高度直接由卡片高度决定，改小了会把页面底部裁掉。
    func testEachTabContentHeightIsTheSumOfItsParts() {
        // 卡片高度 = 上下内边距 + 内部高度。
        for tab in HubTab.allCases {
            XCTAssertEqual(
                HubMetrics.contentHeight(for: tab),
                HubMetrics.interiorHeight(for: tab) + HubMetrics.cardPadding * 2,
                "\(tab.rawValue) 的卡片高度不等于各段之和"
            )
        }

        // 设置页最高，其次是剪切板页与文件页、截图页、占位页。
        XCTAssertEqual(HubMetrics.pageContentHeight(for: .settings), HubMetrics.settingsPageContentHeight)
        XCTAssertEqual(HubMetrics.pageContentHeight(for: .files), HubMetrics.filesPageContentHeight)
        XCTAssertGreaterThan(
            HubMetrics.settingsPageContentHeight,
            HubMetrics.clipboardPageContentHeight
        )
        XCTAssertGreaterThan(
            HubMetrics.clipboardPageContentHeight,
            HubMetrics.screenshotsPageContentHeight
        )
        XCTAssertGreaterThan(
            HubMetrics.screenshotsPageContentHeight,
            HubMetrics.placeholderPageContentHeight
        )

        // 两个还没落地的页签用占位高度。
        let placeholders: [HubTab] = [.now, .devices]
        for tab in placeholders {
            XCTAssertEqual(
                HubMetrics.pageContentHeight(for: tab),
                HubMetrics.placeholderPageContentHeight,
                "\(tab.rawValue) 应该用占位高度"
            )
        }
    }

    /// 卡片必须盖得住左栏：导航栏比右栏高时卡片会被裁。
    func testTheCardCoversTheNavigationRailOnEveryTab() {
        for tab in HubTab.allCases {
            XCTAssertGreaterThanOrEqual(
                HubMetrics.interiorHeight(for: tab),
                HubMetrics.navRailHeight,
                "\(tab.rawValue) 的卡片盖不住导航栏"
            )
            XCTAssertGreaterThanOrEqual(
                HubMetrics.interiorHeight(for: tab),
                HubMetrics.toolbarCapsuleHeight
                    + HubMetrics.pageGap
                    + HubMetrics.pageContentHeight(for: tab),
                "\(tab.rawValue) 的卡片盖不住胶囊加页内容"
            )
        }
    }
}

/// 设置页的格式化。纯函数，与 Compose 版逐字对齐。
final class SettingsFormatTests: XCTestCase {
    /// 时长的中文写法。
    func testChineseDuration() {
        XCTAssertEqual(SettingsFormat.duration(seconds: 300, language: .simplifiedChinese), "5分")
        XCTAssertEqual(SettingsFormat.duration(seconds: 3_600, language: .simplifiedChinese), "1小时0分")
        XCTAssertEqual(SettingsFormat.duration(seconds: 5_400, language: .simplifiedChinese), "1小时30分")
        XCTAssertEqual(SettingsFormat.duration(seconds: 86_400, language: .simplifiedChinese), "24小时0分")
    }

    /// 时长的英文写法。
    func testEnglishDuration() {
        XCTAssertEqual(SettingsFormat.duration(seconds: 300, language: .english), "5m")
        XCTAssertEqual(SettingsFormat.duration(seconds: 3_600, language: .english), "1h 0m")
        XCTAssertEqual(SettingsFormat.duration(seconds: 5_400, language: .english), "1h 30m")
        XCTAssertEqual(SettingsFormat.duration(seconds: 86_400, language: .english), "24h 0m")
    }

    /// 三种休眠模式都要有名字，且随语言变化。
    func testSleepModeLabelsCoverEverySupportedMode() {
        for mode in ModelsKt.SUPPORTED_HIBERNATE_MODES {
            let english = SettingsFormat.sleepModeLabel(mode.int32Value, language: .english)
            let chinese = SettingsFormat.sleepModeLabel(mode.int32Value, language: .simplifiedChinese)
            XCTAssertFalse(english.isEmpty)
            XCTAssertFalse(chinese.isEmpty)
            XCTAssertNotEqual(english, chinese, "模式 \(mode) 的中英文名字一样")
        }
    }

    /// 时间用系统时区渲染，格式与 Compose 版一致。
    func testWakeTimeUsesTheDocumentedFormat() {
        let text = SettingsFormat.wakeTime(epochSeconds: 1_700_000_000)
        XCTAssertEqual(text.count, 19, "格式应为 yyyy-MM-dd HH:mm:ss：\(text)")
        XCTAssertEqual(text.filter { $0 == "-" }.count, 2)
        XCTAssertEqual(text.filter { $0 == ":" }.count, 2)
    }

    /// 语言码与 Kotlin 的 `AppLanguage` 一致，空码回落系统语言。
    func testLanguageCodesMatchKotlin() {
        XCTAssertEqual(AppLanguage.english.rawValue, "en")
        XCTAssertEqual(AppLanguage.simplifiedChinese.rawValue, "zh-CN")
        XCTAssertEqual(AppLanguage.fromCode("en"), .english)
        XCTAssertEqual(AppLanguage.fromCode("zh-CN"), .simplifiedChinese)
        XCTAssertEqual(AppLanguage.fromCode(nil), CopyLocale.language)
        XCTAssertEqual(AppLanguage.fromCode("fr"), CopyLocale.language)
    }
}
