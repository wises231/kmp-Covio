import Foundation

/// 晾衣线用到的路径。
///
/// 与 `kmpDomain/src/com/wyz/covio/core/AppDirectories.kt` 一致。
///
/// 注意晾衣线目录用的是应用名 `Covio`，配置目录用的是 bundle id `com.wyz.covio`。
/// 两者不同，这是 0.4.2 的既有布局，不能改，否则老用户的截图和晾衣线会找不到。
enum ShelfPaths {
    /// 晾衣线目录名。用应用名，不用 bundle id。
    static let directoryName = "Covio"
    static let screenshotsDirectoryName = "Screenshots"
    /// 晾衣线状态文件名。
    static let storeFileName = "shelf.json"

    static var home: URL {
        URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)
    }

    /// `~/Library/Application Support/Covio/Screenshots`。
    ///
    /// 截图接管打开时，系统截图也存到这里。
    static var screenshotsDirectory: URL {
        home
            .appendingPathComponent("Library/Application Support", isDirectory: true)
            .appendingPathComponent(directoryName, isDirectory: true)
            .appendingPathComponent(screenshotsDirectoryName, isDirectory: true)
    }

    /// `~/Library/Application Support/Covio/Screenshots/shelf.json`。
    static var storeFile: URL {
        screenshotsDirectory.appendingPathComponent(storeFileName)
    }

    /// `~/Desktop`。系统截图默认存这里。
    static var desktopDirectory: URL {
        home.appendingPathComponent("Desktop", isDirectory: true)
    }

    /// `~/.Trash`。系统回收站不可用时的退路。
    static var trashDirectory: URL {
        home.appendingPathComponent(".Trash", isDirectory: true)
    }
}
