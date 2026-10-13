import AppKit
import SwiftUI
import kmpDomain

/// 剪切板页签。
///
/// 一行一条记录。左边是类型图标与内容摘要，右边是这一条的动作。
/// 模块级动作（暂停记录、全部清除）在顶部胶囊里，见 `ClipboardCapsuleActions`。
/// 权限与快捷键冲突的提示留在页内，因为它属于内容。
///
/// 图片条的摘要用 OCR 结果。识别还没回来时显示文件名。
struct ClipboardTabView: View {
    let clipboard: ClipboardRuntime
    let runtime: AppRuntime

    private var language: AppLanguage { runtime.language }

    var body: some View {
        VStack(alignment: .leading, spacing: MacTheme.space3) {
            content

            // 权限被拒或快捷键冲突时给一条可见的说明。计划把这两条列为 P4 的完成判据。
            if let notice {
                MacAlert(message: notice, kind: .warning)
            }
        }
        .padding(.horizontal, MacTheme.space4)
        .padding(.vertical, MacTheme.space3)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private var content: some View {
        if clipboard.items.isEmpty {
            emptyState
        } else {
            list
        }
    }

    private var emptyState: some View {
        VStack(spacing: MacTheme.space2) {
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 22))
                .foregroundStyle(.tertiary)
            Text(ContractCopy.copyClipboardEmpty.text(for: language))
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: MacTheme.mediumRadius, style: .continuous)
                .fill(MacTheme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: MacTheme.mediumRadius, style: .continuous)
                .strokeBorder(MacTheme.divider, lineWidth: 1)
        )
    }

    private var list: some View {
        ScrollView {
            LazyVStack(spacing: MacTheme.space2) {
                ForEach(clipboard.items, id: \.id) { item in
                    ClipboardRow(
                        item: item,
                        language: language,
                        onCopy: { clipboard.copyToPasteboard(item.id) },
                        onPaste: { clipboard.paste(item.id) },
                        onPin: { clipboard.togglePin(item.id) },
                        onSave: { _ = runtime.workspace.save(clipItem: item) },
                        onRemove: { clipboard.remove(item.id) }
                    )
                }
            }
            .padding(MacTheme.space2)
        }
        .frame(height: Self.listHeight)
        .background(
            RoundedRectangle(cornerRadius: MacTheme.mediumRadius, style: .continuous)
                .fill(MacTheme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: MacTheme.mediumRadius, style: .continuous)
                .strokeBorder(MacTheme.divider, lineWidth: 1)
        )
    }

    private var statusText: String {
        let unpinned = clipboard.items.filter { !$0.pinned }.count
        return "\(unpinned) / \(Int(clipboard.policy.maxItems))"
    }

    /// 当前要提示的那一条。错误优先于权限提示。
    private var notice: String? {
        if let error = clipboard.errorMessage {
            return error.text(for: language)
        }
        if !clipboard.failedHotKeys.isEmpty {
            return ContractCopy.copyClipboardErrorHotKey.text(for: language)
        }
        return nil
    }

    /// 列表高度。`HubMetrics.clipboardPageContentHeight` 按它相加。
    nonisolated static let listHeight: CGFloat = 268

    /// 提示条的高度：`MacAlert` 的上下内边距加一行 11 点文字。
    nonisolated static let noticeHeight: CGFloat = 40

    /// 列表与提示条之间的间距。`HubMetrics` 按它相加。
    nonisolated static let noticeGap: CGFloat = MacTheme.space3
}

/// 剪切板页的胶囊动作：暂停记录、全部清除、条数。
///
/// 这三个动作原先在页内容底部。搬到胶囊后列表可以更高。
struct ClipboardCapsuleActions: View {
    let clipboard: ClipboardRuntime
    let language: AppLanguage

    var body: some View {
        HStack(spacing: MacTheme.space2) {
            MacButton(
                title: clipboard.isPaused
                    ? ContractCopy.copyClipboardStateResume.text(for: language)
                    : ContractCopy.copyClipboardStatePause.text(for: language)
            ) {
                clipboard.setPaused(!clipboard.isPaused)
            }
            MacButton(
                title: ContractCopy.copyClipboardActionClear.text(for: language),
                isEnabled: clipboard.items.contains { !$0.pinned }
            ) {
                clipboard.clearAll()
            }
            MacStatusLine(text: statusText)
        }
    }

    private var statusText: String {
        let unpinned = clipboard.items.filter { !$0.pinned }.count
        return "\(unpinned) / \(Int(clipboard.policy.maxItems))"
    }
}

/// 一条剪切板记录。
private struct ClipboardRow: View {
    let item: ClipItem
    let language: AppLanguage
    let onCopy: () -> Void
    let onPaste: () -> Void
    let onPin: () -> Void
    /// 把这一条存入工作区。图片与文件存它们的文件，其余存正文。
    let onSave: () -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: MacTheme.space3) {
            thumbnail
            details
            Spacer(minLength: 0)
            controls
        }
        .padding(MacTheme.space2)
        .background(
            RoundedRectangle(cornerRadius: MacTheme.smallRadius, style: .continuous)
                .fill(MacTheme.elevated)
        )
        .contentShape(Rectangle())
        .onTapGesture(count: 2, perform: onPaste)
    }

    /// 类型图标。图片条显示缩略图，缩略图读不出来时退回图标。
    @ViewBuilder
    private var thumbnail: some View {
        if item.kind == ClipKind.image, let image = NSImage(contentsOfFile: item.filePath) {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: Self.thumb, height: Self.thumb)
                .clipShape(RoundedRectangle(cornerRadius: MacTheme.compactRadius, style: .continuous))
        } else {
            Image(systemName: symbol)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .frame(width: Self.thumb, height: Self.thumb)
        }
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(summary)
                .font(.system(size: 12))
                .lineLimit(2)
                .foregroundStyle(MacTheme.textPrimary)
            HStack(spacing: MacTheme.space1) {
                if item.pinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(MacTheme.brand)
                }
                Text(ClipboardRow.subtitle(for: item, language: language))
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private var controls: some View {
        HStack(spacing: MacTheme.space1) {
            MacButton(title: ContractCopy.copyTopShelfActionCopy.text(for: language), kind: .plain, action: onCopy)
            MacButton(title: ContractCopy.copyClipboardActionPaste.text(for: language), kind: .plain, action: onPaste)
            MacButton(
                title: (item.pinned ? ContractCopy.copyClipboardActionUnpin : ContractCopy.copyClipboardActionPin).text(for: language),
                kind: .plain,
                action: onPin
            )
            MacButton(title: ContractCopy.copyClipboardActionWorkspace.text(for: language), kind: .plain, action: onSave)
            MacButton(title: ContractCopy.copyClipboardActionRemove.text(for: language), kind: .plain, action: onRemove)
        }
    }

    /// 一行摘要。图片用 OCR 出的字，其余用内容本身。多行只留第一行。
    private var summary: String {
        let body = item.text.isEmpty ? (item.filePath as NSString).lastPathComponent : item.text
        let firstLine = body.split(separator: "\n", maxSplits: 1).first.map(String.init) ?? body
        return firstLine.isEmpty ? ContractCopy.copyClipboardEmpty.text(for: language) : firstLine
    }

    private var symbol: String {
        if item.kind == ClipKind.link { return "link" }
        if item.kind == ClipKind.color { return "paintpalette" }
        if item.kind == ClipKind.files { return "folder" }
        if item.kind == ClipKind.image { return "photo" }
        return "text.alignleft"
    }

    private static func subtitle(for item: ClipItem, language: AppLanguage) -> String {
        let size = ByteCountFormatter.string(fromByteCount: item.byteSize, countStyle: .file)
        let bundle = item.sourceBundleId.isEmpty ? "-" : item.sourceBundleId
        return "\(bundle) · \(size)"
    }

    private static let thumb: CGFloat = 30
}
