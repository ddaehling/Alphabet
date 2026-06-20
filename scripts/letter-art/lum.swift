import Foundation
import AppKit
for path in CommandLine.arguments.dropFirst() {
    guard let img = NSImage(contentsOfFile: path), let tiff = img.tiffRepresentation,
          let bmp = NSBitmapImageRep(data: tiff) else { print("\(path) ERR"); continue }
    let w = bmp.pixelsWide, h = bmp.pixelsHigh
    let step = max(1, min(w, h) / 220)
    var sum = 0.0, cnt = 0, y = 0
    while y < h {
        var x = 0
        while x < w {
            if let c = bmp.colorAt(x: x, y: y)?.usingColorSpace(.sRGB), c.alphaComponent > 0.6 {
                sum += 0.2126*Double(c.redComponent) + 0.7152*Double(c.greenComponent) + 0.0722*Double(c.blueComponent)
                cnt += 1
            }
            x += step
        }
        y += step
    }
    let mean = cnt > 0 ? sum/Double(cnt) : 0
    let name = ((path as NSString).lastPathComponent as NSString).deletingPathExtension
    print(String(format: "%@\t%.3f\t%@", name, mean, mean > 0.62 ? "PALE" : ""))
}
