import XCTest
@testable import Covio

/// 文案只有一个来源：`Copy.swift`。
///
/// 生成文件与类型定义之外出现 `LocalizedCopy` 的构造调用就失败。
/// 这条规则拦住「顺手在界面里写一句文案」。
final class CopySingleSourceTests: XCTestCase {
    private static let repoRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()

    /// 允许出现字面量的文件，相对仓库根。
    ///
    /// `Copy.swift` 是文案的落点。`LocalizedCopy.swift` 定义类型本身，
    /// 它不写任何产品文案。
    private static let allowed: Set<String> = [
        "macosApp/src/Design/Copy.swift",
        "macosApp/src/Design/LocalizedCopy.swift",
    ]

    /// 要查的字面量。
    ///
    /// 拼出来而不是写成一整串：这个文件自己也在扫描范围里，
    /// 写成一整串会让它查到自己。
    private static let needle = "LocalizedCopy" + "("

    func testNoHandWrittenCopyOutsideTheGeneratedFile() throws {
        var offenders: [String] = []
        for url in try swiftFiles() {
            let relative = url.path.replacingOccurrences(
                of: Self.repoRoot.path + "/", with: ""
            )
            if Self.allowed.contains(relative) { continue }
            let text = try String(contentsOf: url, encoding: .utf8)
            guard text.contains(Self.needle) else { continue }
            for (index, line) in text.split(separator: "\n", omittingEmptySubsequences: false).enumerated()
            where line.contains(Self.needle) {
                offenders.append("\(relative):\(index + 1)")
            }
        }

        XCTAssertTrue(
            offenders.isEmpty,
            "这些地方手写了文案，应该读 Copy：\(offenders.sorted())"
        )
    }

    /// 扫描范围是 macOS 宿主的源码与测试。
    ///
    /// 路径算错时这个测试会失败，而不是让上一条在空集合上白过。
    func testScanSeesTheHostSources() throws {
        let scanned = Set(
            try swiftFiles().map {
                $0.path.replacingOccurrences(of: Self.repoRoot.path + "/", with: "")
            }
        )
        XCTAssertTrue(scanned.contains("macosApp/src/Design/Copy.swift"))
        XCTAssertTrue(scanned.contains("macosApp/test/CopySingleSourceTests.swift"))
        for allowed in Self.allowed {
            XCTAssertTrue(scanned.contains(allowed), "\(allowed) 不在扫描结果里")
        }
    }

    private func swiftFiles() throws -> [URL] {
        let root = Self.repoRoot.appendingPathComponent("macosApp")
        let enumerator = try XCTUnwrap(
            FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil)
        )
        return enumerator.compactMap { $0 as? URL }.filter { $0.pathExtension == "swift" }
    }
}
