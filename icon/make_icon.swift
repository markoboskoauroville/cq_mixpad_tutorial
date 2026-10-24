// The icon, drawn: a mixer's faders with the amber teaching ring around one fader cap; the version under them.
import AppKit
let S: CGFloat = 1024
let version = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "1"
let img = NSImage(size: NSSize(width: S, height: S)); img.lockFocus()
let ctx = NSGraphicsContext.current!.cgContext
ctx.addPath(CGPath(roundedRect: CGRect(x: 100, y: 100, width: 824, height: 824), cornerWidth: 180, cornerHeight: 180, transform: nil))
ctx.setFillColor(NSColor(calibratedRed: 0.11, green: 0.13, blue: 0.14, alpha: 1).cgColor); ctx.fillPath()
let amber = NSColor(calibratedRed: 0.91, green: 0.64, blue: 0.24, alpha: 1)
let teal = NSColor(calibratedRed: 0.20, green: 0.82, blue: 0.70, alpha: 1)
let caps: [CGFloat] = [0.55, 0.75, 0.4, 0.6]
for (i, c) in caps.enumerated() {
    let x = 260 + CGFloat(i) * 168
    ctx.setFillColor(NSColor(calibratedWhite: 0.32, alpha: 1).cgColor); ctx.fill(CGRect(x: x - 6, y: 300, width: 12, height: 470))
    ctx.setFillColor(teal.withAlphaComponent(0.8).cgColor); ctx.fill(CGRect(x: x + 22, y: 300, width: 10, height: 470 * c * 0.8))
    let y = 300 + c * 470 - 32
    ctx.addPath(CGPath(roundedRect: CGRect(x: x - 44, y: y, width: 88, height: 64), cornerWidth: 10, cornerHeight: 10, transform: nil))
    ctx.setFillColor(NSColor(calibratedWhite: 0.82, alpha: 1).cgColor); ctx.fillPath()
    if i == 1 {
        ctx.setStrokeColor(amber.cgColor); ctx.setLineWidth(26)
        ctx.strokeEllipse(in: CGRect(x: x - 120, y: y + 32 - 120, width: 240, height: 240))
    }
}
("v" + version as NSString).draw(at: NSPoint(x: 170, y: 150), withAttributes: [.font: NSFont.systemFont(ofSize: 92, weight: .semibold), .foregroundColor: NSColor(calibratedWhite: 0.78, alpha: 1)])
img.unlockFocus()
try! NSBitmapImageRep(data: img.tiffRepresentation!)!.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "icon_1024.png"))
