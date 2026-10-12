import AppKit
import Foundation

/// 监视系统剪贴板。有新内容时回调。
///
/// **macOS 没有剪贴板变更通知。** 计划里写的是「用 `NSPasteboard` 变更通知」，
/// 但 AppKit 在 `NSPasteboard` 上只给了 `changeCount` 这一个计数器，
/// 没有任何通知、代理或 KVO。所以这里按固定间隔比对 `changeCount`。
///
/// 间隔取 0.5 秒：用户复制之后最多晚半秒出现在 Hub 里，
/// 而 `changeCount` 只是一次整数读取，每秒两次的开销可以忽略。
/// 真正的读剪贴板只在计数变了之后才做。
@MainActor
final class ClipboardMonitor {
    /// 读剪贴板默认间隔。
    static let defaultInterval: TimeInterval = 0.5

    private let pasteboard: NSPasteboard
    private let imageDirectory: URL
    private let interval: TimeInterval
    private let reader: (NSPasteboard, URL) -> ClipboardPayload?
    private let onCapture: (ClipboardPayload) -> Void

    private var timer: Timer?
    private var lastChangeCount: Int

    init(
        pasteboard: NSPasteboard = .general,
        imageDirectory: URL,
        interval: TimeInterval = ClipboardMonitor.defaultInterval,
        reader: @escaping (NSPasteboard, URL) -> ClipboardPayload? = {
            ClipboardPayloadReader.read($0, imageDirectory: $1)
        },
        onCapture: @escaping (ClipboardPayload) -> Void
    ) {
        self.pasteboard = pasteboard
        self.imageDirectory = imageDirectory
        self.interval = interval
        self.reader = reader
        self.onCapture = onCapture
        // 启动时不把剪贴板上已有的内容当成新复制。用户没按过复制。
        self.lastChangeCount = pasteboard.changeCount
    }

    var isRunning: Bool { timer != nil }

    func start() {
        guard timer == nil else { return }
        lastChangeCount = pasteboard.changeCount
        let timer = Timer(timeInterval: interval, repeats: true) { _ in
            // 定时器跑在主 run loop 上，但闭包是 `@Sendable`。
            // 与 `AppRuntime` 的心跳定时器同一个写法。
            MainActor.assumeIsolated { [weak self] in self?.poll() }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    // 不写 `deinit`：`Timer` 不是 `Sendable`，非隔离的 `deinit` 里读不到它。
    // 停机统一走 `stop()`，调用方是 `ClipboardRuntime`。

    /// 本应用自己写剪贴板之后调用。
    ///
    /// 把这次变更记成「自己的」，下次轮询不再上报。
    /// 不记的话，从 Hub 复制一条旧内容会立刻又被收成新条目。
    func ignoreOwnChange() {
        lastChangeCount = pasteboard.changeCount
    }

    private func poll() {
        let current = pasteboard.changeCount
        guard current != lastChangeCount else { return }
        lastChangeCount = current
        guard let payload = reader(pasteboard, imageDirectory) else { return }
        onCapture(payload)
    }
}
