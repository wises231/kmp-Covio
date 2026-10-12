import XCTest
import kmpDomain
@testable import Covio

/// 文件页与工作区运行时的行为。
///
/// 顺序、淘汰、过期的规则在 `kmpDomain` 里，由 Kotlin 的测试覆盖。
/// 这里只测 Swift 这一层：放入、提示、置顶、删除、清理，以及页高。
@MainActor
final class WorkspaceTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("covio-workspace-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    // MARK: - 放入

    /// 放入一个文件之后，条目在列表里，内容在本地。
    func testIntakePutsTheFileInTheWorkspace() throws {
        let source = try makeFile(named: "note.txt", contents: "hello")
        let runtime = makeRuntime()

        XCTAssertEqual(runtime.intake(urls: [source]), 1)
        XCTAssertEqual(runtime.entries.count, 1)
        XCTAssertEqual(runtime.entries.first?.displayName, "note.txt")
        XCTAssertEqual(runtime.entries.first?.kind, WorkspaceKind.text)
        XCTAssertNotNil(runtime.contentURL(runtime.entries[0].entryId))
        XCTAssertEqual(runtime.totalBytes, Int64("hello".utf8.count))
    }

    /// 同一份内容放两次只留一条，并给一条说明。
    func testIntakeReportsTheDuplicate() throws {
        let runtime = makeRuntime()

        XCTAssertEqual(runtime.intake(urls: [try makeFile(named: "a.txt", contents: "same")]), 1)
        XCTAssertEqual(runtime.intake(urls: [try makeFile(named: "b.txt", contents: "same")]), 0)

        XCTAssertEqual(runtime.entries.count, 1)
        XCTAssertNil(runtime.errorMessage)
        XCTAssertEqual(
            runtime.infoMessage?.text,
            ContractCopy.copyHubFilesNoticeDuplicate.text
        )
    }

    /// 认不出的来源给一条失败提示，不留半条数据。
    func testIntakeRefusesSomethingThatIsNotAFile() {
        let runtime = makeRuntime()
        let folder = directory.appendingPathComponent("folder", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        XCTAssertEqual(runtime.intake(urls: [folder]), 0)
        XCTAssertTrue(runtime.entries.isEmpty)
        XCTAssertEqual(
            runtime.errorMessage?.text,
            ContractCopy.copyHubFilesErrorImport.text
        )
    }

    /// 超过单条上限的文件被拒，并给出对应提示。
    func testIntakeRefusesAFileOverTheLimit() throws {
        let runtime = makeRuntime()
        let source = try makeFile(named: "big.bin", contents: String(repeating: "x", count: 4_096))

        XCTAssertEqual(runtime.intake(urls: [source]), 0)
        XCTAssertTrue(runtime.entries.isEmpty)
        XCTAssertEqual(
            runtime.errorMessage?.text,
            ContractCopy.copyHubFilesErrorTooLarge.text
        )
    }

    // MARK: - 置顶与删除

    func testTogglePinFlipsTheFlag() throws {
        let runtime = makeRuntime()
        runtime.intake(urls: [try makeFile(named: "note.txt", contents: "hello")])
        let entryId = runtime.entries[0].entryId

        runtime.togglePin(entryId)

        XCTAssertTrue(runtime.entries[0].pinned)
        // 换一个存储读一遍，证明落了盘。
        XCTAssertTrue(makeClient().load().entries[0].pinned)
    }

    /// 删除条目时内容也要删掉，磁盘上不留副本。
    func testRemoveAlsoDropsTheContent() throws {
        let runtime = makeRuntime()
        runtime.intake(urls: [try makeFile(named: "note.txt", contents: "hello")])
        let entryId = runtime.entries[0].entryId
        let content = try XCTUnwrap(runtime.contentURL(entryId))

        runtime.remove(entryId)

        XCTAssertTrue(runtime.entries.isEmpty)
        XCTAssertEqual(runtime.totalBytes, 0)
        XCTAssertFalse(FileManager.default.fileExists(atPath: content.path), "内容要一起删掉")
    }

    // MARK: - 过期

    /// 过期的条目在启动时就被清掉，内容也删掉。
    func testExpiredEntriesAreSweptOnLaunch() throws {
        let source = try makeFile(named: "note.txt", contents: "hello")
        var now: Int64 = 1_000
        let first = makeRuntime(now: { now })
        first.intake(urls: [source])
        let entryId = first.entries[0].entryId
        let content = try XCTUnwrap(first.contentURL(entryId))

        // 走到保留期之后，换一个运行时重新读。
        now += 7 * 24 * 3_600
        let second = makeRuntime(now: { now })

        XCTAssertTrue(second.entries.isEmpty, "过期的条目不该留在列表里")
        XCTAssertFalse(FileManager.default.fileExists(atPath: content.path), "过期内容要删掉")
    }

    /// 手动清理给出说明，剩下的条目不受影响。
    func testSweepKeepsLiveEntries() throws {
        var now: Int64 = 1_000
        let runtime = makeRuntime(now: { now })
        runtime.intake(urls: [try makeFile(named: "note.txt", contents: "hello")])

        now += 3_600
        XCTAssertEqual(runtime.sweep(), 0)
        XCTAssertEqual(runtime.entries.count, 1)
        XCTAssertNil(runtime.infoMessage)
    }

    // MARK: - 提示

    func testClearMessagesDropsBothNotices() throws {
        let runtime = makeRuntime()
        runtime.intake(urls: [try makeFile(named: "note.txt", contents: "hello")])
        runtime.intake(urls: [try makeFile(named: "copy.txt", contents: "hello")])
        XCTAssertNotNil(runtime.infoMessage)

        runtime.clearMessages()

        XCTAssertNil(runtime.infoMessage)
        XCTAssertNil(runtime.errorMessage)
    }

    // MARK: - 页高

    /// 文件页高按各段相加，与剪切板页的算法一致。
    func testTheFilesPageHeightIsTheSumOfItsParts() {
        let expected = FilesTabView.listHeight
            + MacTheme.space3 * 2
            + FilesTabView.noticeGap
            + FilesTabView.noticeHeight
        XCTAssertEqual(HubMetrics.pageContentHeight(for: .files), expected)
        XCTAssertGreaterThan(
            HubMetrics.pageContentHeight(for: .files),
            HubMetrics.placeholderPageContentHeight
        )
    }

    /// 卡片不超过 Hub 的最大高度，否则面板会被屏幕裁掉。
    func testTheFilesCardStaysWithinTheHubLimit() {
        for height in [CGFloat(900), 1_080, 1_200] {
            XCTAssertLessThan(
                HubMetrics.contentHeight(for: .files) + 60,
                HubMetrics.hubMaxHeight(screenHeight: height),
                "屏幕高 \(height) 时文件页放不下"
            )
        }
    }

    // MARK: - 工具

    private func makeClient() -> WorkspaceStoreClient {
        WorkspaceStoreClient(directory: directory.path)
    }

    /// 运行时。为了测边界，把单条上限压到 1 KB，保留期压到 1 天。
    private func makeRuntime(now: @escaping () -> Int64 = { 1_000 }) -> WorkspaceRuntime {
        var environment = WorkspaceEnvironment()
        environment.now = now
        let policy = WorkspacePolicy.companion.defaults().doCopy(
            maxTotalBytes: 64 * 1_024,
            maxEntryBytes: 1_024,
            retentionDays: 1,
            lazyFetchThresholdBytes: 50 * 1_024 * 1_024
        )
        return WorkspaceRuntime(client: makeClient(), environment: environment, policy: policy)
    }

    @discardableResult
    private func makeFile(named name: String, contents: String) throws -> URL {
        let url = directory.appendingPathComponent(name)
        try contents.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}
