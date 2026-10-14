import Cocoa
import WebKit

// usage: preview-shot <url> <out.png> [width] [height] [waitSeconds]
// 把页面渲染成 PNG，并打印页面里的 JS 错误。

let args = CommandLine.arguments
guard args.count >= 3 else {
    FileHandle.standardError.write("usage: preview-shot <url> <out.png> [width] [height] [wait]\n".data(using: .utf8)!)
    exit(2)
}
guard let target = URL(string: args[1]) else { exit(2) }
let outPath = args[2]
let width = CGFloat(Double(args.count > 3 ? args[3] : "1440") ?? 1440)
let height = CGFloat(Double(args.count > 4 ? args[4] : "900") ?? 900)
let wait = Double(args.count > 5 ? args[5] : "10") ?? 10

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

let config = WKWebViewConfiguration()
let controller = WKUserContentController()
controller.addUserScript(WKUserScript(source: """
window.__covioErrors = [];
window.addEventListener('error', function (e) {
  window.__covioErrors.push('error: ' + (e.message || String(e)));
});
window.addEventListener('unhandledrejection', function (e) {
  var r = e.reason;
  window.__covioErrors.push('rejection: ' + ((r && (r.message || r.stack)) || String(r)));
});
""", injectionTime: .atDocumentStart, forMainFrameOnly: true))
config.userContentController = controller

let webView = WKWebView(frame: NSRect(x: 0, y: 0, width: width, height: height), configuration: config)
let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: width, height: height),
                      styleMask: [.borderless], backing: .buffered, defer: false)
window.contentView = webView
window.orderFront(nil)

webView.load(URLRequest(url: target))

func finish(_ code: Int32) -> Never {
    exit(code)
}

DispatchQueue.main.asyncAfter(deadline: .now() + wait) {
    let probe = """
    JSON.stringify({
      canvases: document.querySelectorAll('canvas').length,
      canvasSize: (function(){var c=document.querySelector('canvas');return c? (c.width+'x'+c.height):'none';})(),
      errors: window.__covioErrors
    })
    """
    webView.evaluateJavaScript(probe) { result, error in
        if let error = error { print("PROBE-ERROR: \(error)") }
        if let s = result as? String { print("PROBE: \(s)") }

        let cfg = WKSnapshotConfiguration()
        cfg.rect = NSRect(x: 0, y: 0, width: width, height: height)
        webView.takeSnapshot(with: cfg) { image, error in
            if let error = error {
                print("SNAPSHOT-ERROR: \(error)")
                finish(1)
            }
            guard let image = image,
                  let tiff = image.tiffRepresentation,
                  let rep = NSBitmapImageRep(data: tiff),
                  let png = rep.representation(using: .png, properties: [:]) else {
                print("SNAPSHOT-ERROR: no image data")
                finish(1)
            }
            do {
                try png.write(to: URL(fileURLWithPath: outPath))
                print("WROTE \(outPath) \(png.count) bytes")
                finish(0)
            } catch {
                print("SNAPSHOT-ERROR: \(error)")
                finish(1)
            }
        }
    }
}

app.run()
