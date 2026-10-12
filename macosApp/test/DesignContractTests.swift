import XCTest
@testable import Covio

/// 把 Swift 侧的常量与两份权威文档对起来。
///
/// - `docs/covio-design-contract.json` 给组件的 `nativeSize` 与状态词汇。
/// - `docs/covio-product-master.md` 给页签顺序与动效时长。
///
/// 这些断言的作用是：文档改了而代码没跟上时，测试会失败。
final class DesignContractTests: XCTestCase {
    // MARK: - 文件定位

    /// 仓库根目录。测试源在 `<root>/macosApp/test/`。
    private static let repoRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()

    private func contractJSON() throws -> [String: Any] {
        let url = Self.repoRoot.appendingPathComponent("docs/covio-design-contract.json")
        let data = try Data(contentsOf: url)
        return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    private func productMaster() throws -> String {
        let url = Self.repoRoot.appendingPathComponent("docs/covio-product-master.md")
        return try String(contentsOf: url, encoding: .utf8)
    }

    /// 取出某个 `###` 小节的全部正文。
    private func section(_ number: String, in markdown: String) -> String {
        var collected: [String] = []
        var inside = false
        for line in markdown.components(separatedBy: .newlines) {
            if line.hasPrefix("### ") {
                if inside { break }
                inside = line.contains(number)
                continue
            }
            if inside { collected.append(line) }
        }
        return collected.joined(separator: "\n")
    }

    /// 解析 Markdown 表格。返回每行的单元格数组，跳过分隔行。
    private func tableRows(in section: String) -> [[String]] {
        section
            .components(separatedBy: .newlines)
            .filter { $0.hasPrefix("|") }
            .map { line in
                line.split(separator: "|", omittingEmptySubsequences: false)
                    .map { $0.trimmingCharacters(in: .whitespaces) }
            }
    }

    private func integers(in text: String) -> [Int] {
        text.split(whereSeparator: { !$0.isNumber }).compactMap { Int($0) }
    }

    // MARK: - 页签

    /// §4.2 的表格顺序就是页签顺序。
    func testTabOrderMatchesProductMaster() throws {
        let rows = tableRows(in: section("4.2", in: try productMaster()))
        let names = rows.compactMap { cells -> String? in
            guard cells.count >= 3, Int(cells[1]) != nil else { return nil }
            return cells[2].trimmingCharacters(in: CharacterSet(charactersIn: "`"))
        }
        XCTAssertEqual(names.count, 6, "§4.2 应该有 6 个页签")
        XCTAssertEqual(HubTab.allCases.map(\.rawValue), names)
    }

    func testEveryTabHasTitleAndSummary() {
        for tab in HubTab.allCases {
            XCTAssertFalse(tab.title.en.isEmpty, "\(tab.rawValue) 缺英文标题")
            XCTAssertFalse(tab.title.zhHans.isEmpty, "\(tab.rawValue) 缺中文标题")
            XCTAssertFalse(tab.summary.en.isEmpty, "\(tab.rawValue) 缺英文说明")
            XCTAssertFalse(tab.summary.zhHans.isEmpty, "\(tab.rawValue) 缺中文说明")
            XCTAssertFalse(tab.symbolName.isEmpty, "\(tab.rawValue) 缺图标")
        }
    }

    // MARK: - 组件尺寸

    private func nativeSize(_ key: String, in contract: [String: Any]) throws -> (Int, Int) {
        let components = try XCTUnwrap(contract["components"] as? [String: Any])
        let component = try XCTUnwrap(components[key] as? [String: Any], "合同缺少 \(key)")
        let size = try XCTUnwrap(component["nativeSize"] as? [String: Any], "\(key) 缺少 nativeSize")
        let width = try XCTUnwrap(size["width"] as? Int)
        let height = try XCTUnwrap(size["height"] as? Int)
        return (width, height)
    }

    /// 竖向导航栏的尺寸。合同 `component/tab-bar` 的 `nativeSize` 是 200 × 370。
    ///
    /// 高度也按各段相加核对一遍，见 `HubMetricsTests`。
    func testNavRailSizeMatchesContract() throws {
        let (width, height) = try nativeSize("component/tab-bar", in: try contractJSON())
        XCTAssertEqual(HubMetrics.navRailWidth, CGFloat(width))
        XCTAssertEqual(HubMetrics.navRailHeight, CGFloat(height))
    }

    /// 胶囊里的页标题。合同 `component/page-title` 的 `nativeSize` 是 420 × 40。
    ///
    /// 高度等于胶囊高度：标题填满胶囊。
    func testCapsuleTitleMatchesContract() throws {
        let (width, height) = try nativeSize("component/page-title", in: try contractJSON())
        XCTAssertEqual(HubMetrics.capsuleTitleWidth, CGFloat(width))
        XCTAssertEqual(HubMetrics.toolbarCapsuleHeight, CGFloat(height))
    }

    /// 合同给的是命中区，不是图形本身。`composeMapping.behavior` 说明图形是 22 点。
    func testTrayIconHitTargetMatchesContract() throws {
        let (width, height) = try nativeSize("component/tray-icon", in: try contractJSON())
        XCTAssertEqual(HubMetrics.trayIconHitTarget, CGFloat(width))
        XCTAssertEqual(HubMetrics.trayIconHitTarget, CGFloat(height))
    }

    /// 合同 `accessibilityRules` 的原文：不小于 24 点，主控件尽量 44 点。
    func testHitTargetRulesMatchContract() throws {
        let components = try XCTUnwrap(try contractJSON()["components"] as? [String: Any])
        let tabBar = try XCTUnwrap(components["component/tab-bar"] as? [String: Any])
        let rules = try XCTUnwrap(tabBar["accessibilityRules"] as? [String])
        let joined = rules.joined(separator: " ")

        XCTAssertTrue(joined.contains("at least 24 points"))
        XCTAssertTrue(joined.contains("44 points"))
        XCTAssertEqual(HubMetrics.minHitTarget, 24)
        XCTAssertEqual(HubMetrics.preferredHitTarget, 44)
    }

    // MARK: - 状态词汇

    func testHubStatesMatchContract() throws {
        let states = try XCTUnwrap(try contractJSON()["states"] as? [String: Any])
        let hub = try XCTUnwrap(states["menuBarAndNotchHub"] as? [String: Any])
        let entries = try XCTUnwrap(hub["hubStates"] as? [[String: Any]])

        let contractStates = entries.compactMap { $0["state"] as? String }
        XCTAssertEqual(HubState.allCases.map(\.rawValue), contractStates)

        // 每个状态的 copyKey 与 contractKey 都要与合同逐字一致。
        for entry in entries {
            let name = try XCTUnwrap(entry["state"] as? String)
            let state = try XCTUnwrap(HubState(rawValue: name))
            XCTAssertEqual(state.slug, entry["slug"] as? String, "\(name) 的 slug 不一致")
            XCTAssertEqual(state.copyKey, entry["copyKey"] as? String, "\(name) 的 copyKey 不一致")
            XCTAssertEqual(state.contractKey, entry["contractKey"] as? String, "\(name) 的 contractKey 不一致")
        }
    }

    func testOutputStatesMatchContract() throws {
        let states = try XCTUnwrap(try contractJSON()["states"] as? [String: Any])
        let output = try XCTUnwrap(states["notchOutputHub"] as? [String: Any])
        let entries = try XCTUnwrap(output["states"] as? [[String: Any]])

        let contractStates = entries.compactMap { $0["name"] as? String }
        XCTAssertEqual(HubOutputState.allCases.map(\.rawValue), contractStates)

        for entry in entries {
            let name = try XCTUnwrap(entry["name"] as? String)
            let state = try XCTUnwrap(HubOutputState(rawValue: name))
            XCTAssertEqual(state.slug, entry["slug"] as? String, "\(name) 的 slug 不一致")
            XCTAssertEqual(state.copyKey, entry["copyKey"] as? String, "\(name) 的 copyKey 不一致")
            XCTAssertEqual(state.contractKey, entry["contractKey"] as? String, "\(name) 的 contractKey 不一致")
        }
    }

    /// 合同给的页签文案键必须真实存在。文案表在 `copy` 段。
    func testStateCopyKeysExistInContract() throws {
        let copy = try XCTUnwrap(try contractJSON()["copy"] as? [String: Any])
        for state in HubState.allCases {
            XCTAssertNotNil(copy[state.copyKey], "合同缺少文案键 \(state.copyKey)")
        }
        for state in HubOutputState.allCases {
            XCTAssertNotNil(copy[state.copyKey], "合同缺少文案键 \(state.copyKey)")
        }
    }

    /// 菜单栏用到的文案键也必须存在。
    func testStatusItemAndTrayCopyKeysExist() throws {
        let copy = try XCTUnwrap(try contractJSON()["copy"] as? [String: Any])
        for key in ["copy/status-item/default", "copy/tray/action/show-shelf",
                    "copy/tray/action/settings", "copy/tray/action/quit"] {
            XCTAssertNotNil(copy[key], "合同缺少文案键 \(key)")
        }
    }

    // MARK: - 动效

    /// §6.4 的动效表。
    private func motionTable() throws -> [String: [Int]] {
        let rows = tableRows(in: section("6.4", in: try productMaster()))
        var table: [String: [Int]] = [:]
        for cells in rows where cells.count >= 3 {
            guard cells[2].contains("毫秒") else { continue }
            table[cells[1]] = integers(in: cells[2])
        }
        return table
    }

    func testMotionDurationsMatchProductMaster() throws {
        let table = try motionTable()
        XCTAssertEqual(table.count, 9, "§6.4 应该有 9 行动效")

        // 两条是区间。
        let expand = try XCTUnwrap(table["Hub 展开"])
        XCTAssertEqual(expand, [220, 280])
        XCTAssertTrue(
            expand[0]...expand[1] ~= Int(HubMotion.expand * 1000),
            "展开时长 \(HubMotion.expand * 1000) 毫秒不在 §6.4 的区间内"
        )

        let collapse = try XCTUnwrap(table["Hub 收起"])
        XCTAssertEqual(collapse, [160, 220])
        XCTAssertTrue(
            collapse[0]...collapse[1] ~= Int(HubMotion.collapse * 1000),
            "收起时长 \(HubMotion.collapse * 1000) 毫秒不在 §6.4 的区间内"
        )

        // 其余七条是定值。
        XCTAssertEqual(table["页签切换"], [Int(HubMotion.tabSwitch * 1000)])
        XCTAssertEqual(table["截图捕获"], [Int(HubMotion.screenshotCapture * 1000)])
        XCTAssertEqual(table["截图复制"], [Int(HubMotion.screenshotCopy * 1000)])
        XCTAssertEqual(table["传输开始"], [Int(HubMotion.transferStart * 1000)])
        XCTAssertEqual(table["传输完成"], [Int(HubMotion.transferComplete * 1000)])
        XCTAssertEqual(table["错误出现"], [Int(HubMotion.errorAppear * 1000)])
        XCTAssertEqual(table["减弱动态效果"], [Int(HubMotion.reducedMotion * 1000)])
    }

    /// §4.4：指针移出 Hub 后 500 毫秒收起。
    func testPointerExitDelayMatchesProductMaster() throws {
        let behaviour = section("4.4", in: try productMaster())
        let line = try XCTUnwrap(
            behaviour
                .components(separatedBy: .newlines)
                .first { $0.contains("移出") && $0.contains("毫秒") },
            "§4.4 里找不到指针移出的描述"
        )
        XCTAssertEqual(integers(in: line), [Int(HubMotion.pointerExitCollapseDelay * 1000)])
    }
}
