// 원본 이미지를 참조하지 않고 자체 문서·잠금 도형으로 배포 PNG 리소스를 생성한다.
import AppKit
import Foundation

/// 픽셀 크기를 받아 새 문서·잠금 도형의 PNG를 반환한다.
func icon(size: Int) throws -> Data {
    guard let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
        bytesPerRow: 0, bitsPerPixel: 0), let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
        throw CocoaError(.fileWriteUnknown)
    }
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    let transform = NSAffineTransform()
    transform.scale(by: CGFloat(size) / 128)
    transform.concat()
    NSColor(calibratedRed: 0.08, green: 0.24, blue: 0.43, alpha: 1).setFill()
    NSBezierPath(roundedRect: NSRect(x: 4, y: 4, width: 120, height: 120), xRadius: 25, yRadius: 25).fill()
    NSColor.white.setFill()
    NSBezierPath(roundedRect: NSRect(x: 28, y: 20, width: 67, height: 89), xRadius: 6, yRadius: 6).fill()
    NSColor(calibratedRed: 0.14, green: 0.39, blue: 0.58, alpha: 1).setFill()
    for y in [83, 69, 55] { NSBezierPath(rect: NSRect(x: 39, y: y, width: 40, height: 5)).fill() }
    NSColor(calibratedRed: 0.15, green: 0.72, blue: 0.60, alpha: 1).setStroke()
    let shackle = NSBezierPath(roundedRect: NSRect(x: 76, y: 29, width: 23, height: 29), xRadius: 10, yRadius: 10)
    shackle.lineWidth = 6
    shackle.stroke()
    NSColor(calibratedRed: 0.15, green: 0.72, blue: 0.60, alpha: 1).setFill()
    NSBezierPath(roundedRect: NSRect(x: 67, y: 13, width: 42, height: 28), xRadius: 5, yRadius: 5).fill()
    NSGraphicsContext.restoreGraphicsState()
    guard let png = bitmap.representation(using: .png, properties: [:]) else { throw CocoaError(.fileWriteUnknown) }
    return png
}

let root = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? FileManager.default.currentDirectoryPath)
let catalog = root.appendingPathComponent("CotEditor/Resources/Assets.xcassets")
let appIcon = catalog.appendingPathComponent("AppIcon.appiconset")
try FileManager.default.createDirectory(at: appIcon, withIntermediateDirectories: true)
var images: [[String: String]] = []
for size in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let name = "icon_\(size)x\(size)@\(scale)x.png"
        try icon(size: size * scale).write(to: appIcon.appendingPathComponent(name))
        images.append(["filename": name, "idiom": "mac", "size": "\(size)x\(size)", "scale": "\(scale)x"])
    }
}
let contents: [String: Any] = ["images": images, "info": ["author": "DocumentSafer Text", "version": 1]]
try JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys]).write(to: appIcon.appendingPathComponent("Contents.json"))
// 설정·문서 아이콘의 기존 픽셀 규격만 유지하고 모든 픽셀은 새 도형으로 생성한다.
if let enumerator = FileManager.default.enumerator(at: catalog, includingPropertiesForKeys: nil) {
    for case let file as URL in enumerator where file.pathExtension == "png" && !file.path.contains("AppIcon.appiconset") {
        let name = file.deletingPathExtension().lastPathComponent
        let base = Int(name.split(separator: "_").last?.split(separator: "x").first ?? "128") ?? 128
        try icon(size: min(1024, base * (name.contains("@2x") ? 2 : 1))).write(to: file)
    }
}
