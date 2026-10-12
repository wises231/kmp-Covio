import Foundation
import kmpDomain

/// 晾衣线的文件操作：复制、移动、删除到废纸篓。
///
/// 对应 Compose 版的
/// `app/src/com/wyz/covio/app/platform/ShelfFileOperations.kt`。
///
/// 行为与 README 第 76 到 81 行一致：
/// 拖到应用是复制，拖到文件夹或桌面是移动，拖到废纸篓是删除。
enum ShelfFileOperations {
    /// 复制到目标目录。同名文件已存在时改名为「名字 2.扩展名」。
    static func copyTo(destination: URL, source: URL) -> Bool {
        guard isDirectory(destination) else { return false }
        let target = uniqueTarget(in: destination, name: source.lastPathComponent)
        do {
            try FileManager.default.copyItem(at: source, to: target)
            return true
        } catch {
            return false
        }
    }

    /// 移动到目标目录。跨卷时退回「先复制再删除」。
    static func moveTo(destination: URL, source: URL) -> Bool {
        guard isDirectory(destination) else { return false }
        let target = uniqueTarget(in: destination, name: source.lastPathComponent)
        do {
            try FileManager.default.moveItem(at: source, to: target)
            return true
        } catch {
            // 同一个卷内 `moveItem` 是原子的。跨卷会失败，改成复制加删除。
            return copyTo(destination: destination, source: source) && remove(source)
        }
    }

    /// 删除到废纸篓。
    ///
    /// 用系统接口，这样用户可以自己捞回来。系统接口不可用时退回 `~/.Trash`，
    /// 那时是直接移动，用户仍然能在废纸篓里看到。
    static func trash(_ source: URL) -> Bool {
        do {
            try FileManager.default.trashItem(at: source, resultingItemURL: nil)
            return true
        } catch {
            return fallbackTrash(source)
        }
    }

    /// 按拖放结果执行。`action` 由 `kmpDomain` 的 `dropActionFor` 从落点算出来。
    ///
    /// Compose 版还收一个 `destinationKind` 参数，但那个参数从头到尾没被读过，
    /// 所以这里不再收。落点的判断已经在 `dropActionFor` 里做完了。
    @discardableResult
    static func perform(action: ShelfDropAction, source: URL, destination: URL?) -> Bool {
        if action == ShelfDropAction.theCopyAndKeep {
            guard let destination else { return false }
            return copyTo(destination: destination, source: source)
        }
        if action == ShelfDropAction.moveAndRemove {
            guard let destination else { return false }
            return moveTo(destination: destination, source: source)
        }
        if action == ShelfDropAction.trashAndRemove {
            return trash(source)
        }
        // CANCEL：用户取消了拖拽，什么都不做，卡片留在晾衣线上。
        return false
    }

    /// 目标目录里没被占用的文件名。
    ///
    /// 「照片.png」被占用时依次试「照片 2.png」「照片 3.png」。
    /// 以点开头且没有其他点的文件名（例如 `.DS_Store`）当作没有扩展名。
    ///
    /// 编号规则住在 `kmpDomain` 的 `ShelfFileNaming` 里，与 Compose 版共用一份。
    /// 这里只把「这个名字在不在」的检查接上磁盘。
    ///
    /// Kotlin 的函数类型参数在 Swift 侧收 `KotlinBoolean`（ADR-001 实测 20），
    /// 所以装箱在这一处做完，调用点不必知道。
    static func uniqueTarget(in directory: URL, name: String) -> URL {
        let resolved = ShelfFileNaming.shared.uniqueName(name: name) { candidate in
            KotlinBoolean(
                bool: FileManager.default.fileExists(
                    atPath: directory.appendingPathComponent(candidate).path
                )
            )
        }
        return directory.appendingPathComponent(resolved)
    }

    /// 系统废纸篓不可用时的退路。
    private static func fallbackTrash(_ source: URL) -> Bool {
        let trash = ShelfPaths.trashDirectory
        do {
            try FileManager.default.createDirectory(at: trash, withIntermediateDirectories: true)
        } catch {
            return false
        }
        let target = uniqueTarget(in: trash, name: source.lastPathComponent)
        do {
            try FileManager.default.moveItem(at: source, to: target)
            return true
        } catch {
            return false
        }
    }

    private static func remove(_ url: URL) -> Bool {
        do {
            try FileManager.default.removeItem(at: url)
            return true
        } catch {
            return false
        }
    }

    private static func isDirectory(_ url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
            return false
        }
        return isDirectory.boolValue
    }
}
