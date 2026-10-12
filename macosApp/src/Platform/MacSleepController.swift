import Foundation
import IOKit.pwr_mgt
import kmpDomain

/// `SleepController` 端口的 macOS 实现。
///
/// 对应 Compose 版的 `app/src/com/wyz/covio/app/platform/MacSleepController.kt`。
///
/// 阻止空闲睡眠用 `NoIdleSleepAssertion`，这是唯一不需要 root 的机制。
/// 阻止合盖睡眠必须用 `pmset disablesleep`，那条路径由 helper 走。
///
/// **警告：** 断言没释放会让 Mac 无法空闲睡眠。`stop()` 与异常路径都要释放。
final class MacSleepController: NSObject, SleepController {
    private let lock = NSLock()
    private var assertion: IOPMAssertionID = 0

    /// 缓存实现只有一份，在 `kmpDomain` 的 `IdleSleepTimeoutCache` 里。
    ///
    /// Kotlin 的默认参数值不导出（ADR-001 实测 18），所以 `ttlMillis` 要显式传。
    private let timeoutCache: IdleSleepTimeoutCache

    init(
        clock: @escaping () -> Int64 = { Int64(Date().timeIntervalSince1970 * 1_000) },
        timeoutReader: @escaping () -> Int64? = { PmsetReader.systemIdleSleepTimeoutSeconds() }
    ) {
        timeoutCache = IdleSleepTimeoutCache(
            clock: { KotlinLong(longLong: clock()) },
            timeoutReader: { timeoutReader().map { KotlinLong(longLong: $0) } },
            ttlMillis: IdleSleepTimeoutCache.companion.DEFAULT_TTL_MILLIS
        )
        super.init()
    }

    func sleep() {
        PmsetCommand.run("sleepnow")
    }

    func displaySleep() {
        PmsetCommand.run("displaysleepnow")
    }

    func setIdleSleepPrevented(prevented: Bool) {
        lock.lock()
        defer { lock.unlock() }
        timeoutCache.invalidate()
        if prevented && assertion == 0 {
            var created: IOPMAssertionID = 0
            let result = IOPMAssertionCreateWithName(
                "NoIdleSleepAssertion" as CFString,
                IOPMAssertionLevel(kIOPMAssertionLevelOn),
                "Covio prevents idle sleep" as CFString,
                &created
            )
            assertion = result == kIOReturnSuccess ? created : 0
        } else if !prevented && assertion != 0 {
            IOPMAssertionRelease(assertion)
            assertion = 0
        }
    }

    func systemIdleSleepTimeoutSeconds() -> KotlinLong? {
        lock.lock()
        let held = assertion != 0
        lock.unlock()
        // 已经阻止空闲睡眠时，系统设置无关紧要。
        if held { return nil }
        // Kotlin 侧返回 KotlinLong?，端口要 KotlinLong?，原样返回。
        return timeoutCache.get()
    }

    deinit {
        if assertion != 0 {
            IOPMAssertionRelease(assertion)
        }
    }
}

/// 子进程调用的统一入口。用于不需要 root 的 `pmset` 与 `osascript`。
///
/// 只关心「跑完」还是「超时」，不收集输出。需要输出的用 `PmsetReader`。
enum PmsetCommand {
    static func run(
        _ arguments: String...,
        executable: String = "/usr/bin/pmset",
        timeout: TimeInterval = 10
    ) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        process.standardInput = FileHandle.nullDevice
        guard (try? process.run()) != nil else { return }
        wait(for: process, timeout: timeout)
    }

    /// 等到进程结束或超时。超时就发 SIGTERM，不无限等。
    static func wait(for process: Process, timeout: TimeInterval) {
        let deadline = Date().addingTimeInterval(timeout)
        while process.isRunning && Date() < deadline {
            usleep(20_000)
        }
        if process.isRunning { process.terminate() }
    }
}

extension PmsetReader {
    /// 读 `pmset -g` 里的 `sleep` 值，单位秒。取最小值，因为输出可能有多段。
    ///
    /// 解析规则住在 `kmpDomain` 的 `PmsetConfigParser` 里，与 Compose 版共用一份。
    static func systemIdleSleepTimeoutSeconds() -> Int64? {
        guard let text = readConfiguration() else { return nil }
        guard let seconds = PmsetConfigParser.shared.sleepTimeoutSeconds(text: text) else {
            return nil
        }
        return seconds.int64Value
    }
}
