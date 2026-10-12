import Foundation
import Vision

/// 识别图片里的文字。
///
/// 复制一张截图之后，Hub 的剪切板页签里能按图上的字找到它。
/// Vision 的 `VNRecognizeTextRequest` 做这件事，不需要联网，也不需要额外权限。
///
/// **识别放后台。** 一张 6K 截图要几百毫秒，放主线程会让 Hub 面板卡住。
/// 结果回到主队列，调用方直接改界面状态。
enum ClipboardOCR {
    /// 识别语言。中文与英文两种，与产品的语言范围一致。
    static let languages = ["zh-Hans", "en-US"]

    /// 识别一个图片文件里的文字。识别不出或读不到文件时回调空串。
    ///
    /// 完成回调是主 actor 的：调用方拿到结果就直接改界面状态。
    static func recognizeText(in fileURL: URL, completion: @escaping @MainActor (String) -> Void) {
        DispatchQueue.global(qos: .utility).async {
            let text = recognizeTextSynchronously(in: fileURL)
            DispatchQueue.main.async {
                MainActor.assumeIsolated { completion(text) }
            }
        }
    }

    /// 同步版本。跑在调用它的线程上。
    static func recognizeTextSynchronously(in fileURL: URL) -> String {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.recognitionLanguages = languages
        // 语言纠正会把网址、路径这类内容改坏，关掉。
        request.usesLanguageCorrection = false

        let handler = VNImageRequestHandler(url: fileURL, options: [:])
        do {
            try handler.perform([request])
        } catch {
            return ""
        }

        let observations = request.results ?? []
        let lines = observations.compactMap { $0.topCandidates(1).first?.string }
        return lines.joined(separator: "\n")
    }
}
