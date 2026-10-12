import AppKit
import Foundation
import UniformTypeIdentifiers
import kmpDomain

/// 工作区运行时要用的外部能力。测试传假的。
@MainActor
struct WorkspaceEnvironment {
    /// 当前时间，秒。
    var now: () -> Int64 = { Int64(Date().timeIntervalSince1970) }
    /// 放入方设备标识。配对落地之前一直是空串。
    var originDeviceId: () -> String = { "" }
    /// 文件的内容类型。认不出来给空串，分类再看扩展名。
    var contentType: (URL) -> String = { WorkspaceRuntime.contentType(of: $0) }
    /// 是不是普通文件。目录不能直接放入。
    var isRegularFile: (URL) -> Bool = { url in
        (try? url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) ?? false
    }
    /// 用默认应用打开内容。
    var open: (URL) -> Void = { NSWorkspace.shared.open($0) }
    /// 在访达里选中内容。
    var reveal: (URL) -> Void = { NSWorkspace.shared.activateFileViewerSelecting([$0]) }
}

/// 工作区的运行时。对应 P5 的数据与行为层。
///
/// 职责：
/// - 读工作区索引，按 Kotlin 那份顺序规则排出界面顺序。
/// - 放入文件、置顶、删除、清理过期。
/// - 取出内容给默认应用打开，或在访达里显示。
///
/// 索引与内容的读写全在 `kmpDomain` 的 `WorkspaceStore` 里，这里只管状态与提示。
/// 只跑在主线程。
@MainActor
@Observable
final class WorkspaceRuntime {
    /// 条目列表。置顶的在前，其余从新到旧。
    private(set) var entries: [WorkspaceEntry] = []
    /// 保留策略。
    private(set) var policy: WorkspacePolicy = WorkspacePolicy.companion.defaults()
    /// 本机内容占用的字节数。
    private(set) var totalBytes: Int64 = 0
    /// 最近一次失败。界面读完应调用 [clearMessages]。
    private(set) var errorMessage: LocalizedCopy?
    /// 最近一条说明，例如「工作区里已经有这份内容」。
    private(set) var infoMessage: LocalizedCopy?

    private let client: WorkspaceStoreClient
    private let environment: WorkspaceEnvironment
    private var state: WorkspaceState

    init(
        client: WorkspaceStoreClient = WorkspaceStoreClient(),
        environment: WorkspaceEnvironment = WorkspaceEnvironment(),
        policy: WorkspacePolicy? = nil
    ) {
        self.client = client
        self.environment = environment

        var loaded = client.load()
        // 传入的策略覆盖索引里的那一份。淘汰与放入都以索引里的策略为准。
        if let policy {
            loaded = client.save(loaded.doCopy(schemaVersion: loaded.schemaVersion, entries: loaded.entries, policy: policy))
        }

        // 启动时清一次过期内容。过期是隐私控制，不只是清理。
        let plan = client.sweep(policy: loaded.policy, nowEpochSeconds: environment.now())
        if plan.changed {
            loaded = client.load()
        }
        self.state = loaded
        self.entries = WorkspaceStoreClient.displayOrder(loaded)
        self.policy = loaded.policy
        self.totalBytes = WorkspaceStoreClient.localBytes(loaded)
    }

    /// 放入若干文件。返回被接受的条数。
    ///
    /// 同一份内容再放一次算成功，但只留一条，并给出说明。
    @discardableResult
    func intake(urls: [URL]) -> Int {
        guard !urls.isEmpty else { return 0 }
        var accepted = 0
        var failure: LocalizedCopy?
        var info: LocalizedCopy?
        var working = state

        for url in urls {
            guard environment.isRegularFile(url) else {
                failure = ContractCopy.copyHubFilesErrorImport
                continue
            }
            let result = client.putFile(
                state: working,
                sourcePath: url.path,
                displayName: url.lastPathComponent,
                contentType: environment.contentType(url),
                originDeviceId: environment.originDeviceId(),
                nowEpochSeconds: environment.now()
            )
            working = result.state

            if result.admission == WorkspaceAdmission.accepted {
                accepted += 1
            } else if result.admission == WorkspaceAdmission.duplicate {
                info = ContractCopy.copyHubFilesNoticeDuplicate
            } else if result.admission == WorkspaceAdmission.quotaExceeded {
                failure = ContractCopy.copyHubFilesErrorQuota
            } else if result.admission == WorkspaceAdmission.tooLarge {
                failure = ContractCopy.copyHubFilesErrorTooLarge
            } else {
                failure = ContractCopy.copyHubFilesErrorImport
            }
        }

        adopt(working)
        errorMessage = failure
        infoMessage = failure == nil ? info : nil
        return accepted
    }

    func togglePin(_ entryId: String) {
        guard let entry = entries.first(where: { $0.entryId == entryId }) else { return }
        adopt(client.setPinned(state: state, entryId: entryId, pinned: !entry.pinned))
    }

    func remove(_ entryId: String) {
        adopt(client.remove(state: state, entryId: entryId))
    }

    /// 清理过期与超出上限的条目。返回清掉的条数。
    @discardableResult
    func sweep() -> Int {
        let plan = client.sweep(policy: policy, nowEpochSeconds: environment.now())
        let reloaded = client.load()
        adopt(reloaded)
        if plan.changed {
            infoMessage = ContractCopy.copyHubFilesNoticeSwept
        }
        return plan.removed.count
    }

    /// 清空工作区。置顶的条目也删。
    func clearAll() {
        client.clear()
        adopt(WorkspaceStoreClient.emptyState)
    }

    func clearMessages() {
        errorMessage = nil
        infoMessage = nil
    }

    /// 一条条目内容的落盘位置。本机没有内容时返回 nil。
    func contentURL(_ entryId: String) -> URL? {
        guard let path = client.contentPath(entryId: entryId) else { return nil }
        return URL(fileURLWithPath: path)
    }

    func open(_ entryId: String) {
        guard let url = contentURL(entryId) else {
            errorMessage = ContractCopy.copyHubFilesErrorMissing
            return
        }
        environment.open(url)
    }

    func reveal(_ entryId: String) {
        guard let url = contentURL(entryId) else {
            errorMessage = ContractCopy.copyHubFilesErrorMissing
            return
        }
        environment.reveal(url)
    }

    private func adopt(_ next: WorkspaceState) {
        state = next
        entries = WorkspaceStoreClient.displayOrder(next)
        policy = next.policy
        totalBytes = WorkspaceStoreClient.localBytes(next)
    }

    /// 文件的内容类型。认出扩展名时给 MIME，认不出给空串。
    nonisolated static func contentType(of url: URL) -> String {
        guard let type = UTType(filenameExtension: url.pathExtension) else { return "" }
        return type.preferredMIMEType ?? ""
    }
}
