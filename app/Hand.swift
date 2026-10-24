// THE HAND: the mouse in CQ MixPad and in Ableton Live, with a big amber ring around it (Marko, 24.10.2026: "put a
// circle around the mouse pointer so I understand where the mouse is, and enlarge it also to fit the user interface
// of the CQ Mix Pad, which is huge"; "You can also switch live and CQ MixPad ... like a professor demonstrating").
// Coordinates come in a 1600 x 900 picture of the app's window (title bar included) and are mapped onto the real one.
import AppKit
import ApplicationServices

// The word being said pops up right above the ring (Marko, 24.10.2026: "when you're driving the mouse with the circle,
// I want to see the popping up of the current red word right above the circle"): the ring's window is taller and wider
// than the ring, the ring at its bottom centre on the pointer, the word in a red block above it.
final class Ring {
    static let shared = Ring()
    let size: CGFloat = 170                    // the ring
    let W: CGFloat = 560, H: CGFloat = 170 + 86  // its window: the ring plus the word above
    private var win: NSWindow?
    private var timer: Timer?
    var on: Bool { win != nil }

    func show() {
        guard win == nil else { return }
        let w = NSWindow(contentRect: NSRect(x: 0, y: 0, width: W, height: H), styleMask: .borderless, backing: .buffered, defer: false)
        w.isOpaque = false; w.backgroundColor = .clear; w.hasShadow = false
        w.level = .screenSaver; w.ignoresMouseEvents = true
        w.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        w.contentView = RingView(frame: NSRect(x: 0, y: 0, width: W, height: H))
        w.orderFrontRegardless(); win = w
        follow()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60, repeats: true) { [weak self] _ in self?.follow() }
    }
    func hide() { timer?.invalidate(); timer = nil; win?.orderOut(nil); win = nil }
    func pulse() { (win?.contentView as? RingView)?.pulse() }
    func say(_ word: String) {
        guard let v = win?.contentView as? RingView, v.word != word else { return }
        v.word = word; v.needsDisplay = true
    }
    private func follow() {
        let p = NSEvent.mouseLocation
        win?.setFrameOrigin(NSPoint(x: p.x - W / 2, y: p.y - size / 2))
    }
}

final class RingView: NSView {
    private var flash: CGFloat = 0
    var word = ""
    func pulse() {
        flash = 1
        Timer.scheduledTimer(withTimeInterval: 1.0 / 30, repeats: true) { [weak self] t in
            guard let self = self else { t.invalidate(); return }
            self.flash = max(0, self.flash - 0.06); self.needsDisplay = true
            if self.flash == 0 { t.invalidate() }
        }
    }
    override func draw(_ r: NSRect) {
        let c = NSGraphicsContext.current!.cgContext
        let amber = NSColor(calibratedRed: 0.91, green: 0.64, blue: 0.24, alpha: 1)
        let ring = NSRect(x: (bounds.width - 170) / 2, y: 0, width: 170, height: 170)
        if flash > 0 {   // a click: the ring fills for a moment
            c.setFillColor(amber.withAlphaComponent(0.35 * flash).cgColor); c.fillEllipse(in: ring.insetBy(dx: 14, dy: 14))
        }
        c.setStrokeColor(NSColor.black.withAlphaComponent(0.55).cgColor); c.setLineWidth(14)
        c.strokeEllipse(in: ring.insetBy(dx: 12, dy: 12))
        c.setStrokeColor(amber.cgColor); c.setLineWidth(8)
        c.strokeEllipse(in: ring.insetBy(dx: 12, dy: 12))
        // the word being said, red as in the reader, in a dark bubble right above the ring
        guard !word.isEmpty else { return }
        // MA Reader's word: a red block (#e23b4e) with white ink
        let red = NSColor(calibratedRed: 0xE2 / 255.0, green: 0x3B / 255.0, blue: 0x4E / 255.0, alpha: 1)
        let font = NSFont.systemFont(ofSize: 40, weight: .semibold)
        let text = NSAttributedString(string: word, attributes: [.font: font, .foregroundColor: NSColor.white])
        let ts = text.size()
        let bw = min(bounds.width - 8, ts.width + 36), bh: CGFloat = 64
        let bubble = NSRect(x: (bounds.width - bw) / 2, y: 170 + 10, width: bw, height: bh)
        red.setFill(); NSBezierPath(roundedRect: bubble, xRadius: 10, yRadius: 10).fill()
        text.draw(at: NSPoint(x: bubble.midX - min(ts.width, bw - 36) / 2, y: bubble.midY - ts.height / 2))
    }
}

enum Hand {
    // "mixpad" = CQ MixPad (owner "CQ MixPad 1.2.2"), "live" = Ableton Live (owner "Live"): the biggest window
    static func window(_ app: String) -> (pid: pid_t, frame: CGRect)? {
        guard let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else { return nil }
        var best: (pid_t, CGRect)?
        for w in list {
            guard let o = w[kCGWindowOwnerName as String] as? String, app == "live" ? o == "Live" : o.contains("MixPad"),
                  (w[kCGWindowLayer as String] as? Int) == 0,
                  let b = w[kCGWindowBounds as String] as? [String: CGFloat],
                  let pid = w[kCGWindowOwnerPID as String] as? pid_t else { continue }
            let r = CGRect(x: b["X"]!, y: b["Y"]!, width: b["Width"]!, height: b["Height"]!)
            if best == nil || r.width * r.height > best!.1.width * best!.1.height { best = (pid, r) }
        }
        return best.map { (pid: $0.0, frame: $0.1) }
    }
    static func screenPoint(_ x: Double, _ y: Double, _ app: String) -> CGPoint? {
        guard let m = window(app) else { return nil }
        return CGPoint(x: m.frame.minX + CGFloat(x) / 1600 * m.frame.width, y: m.frame.minY + CGFloat(y) / 900 * m.frame.height)
    }
    static var allowed: Bool { AXIsProcessTrusted() }

    static func front(_ app: String) {
        guard let m = window(app), let a = NSRunningApplication(processIdentifier: m.pid) else { return }
        if !a.isActive { a.activate(); usleep(400_000) }
    }
    // the mouse glides, so the eye can follow it from where it was
    static func glide(to p: CGPoint, seconds: Double = 0.8) {
        let a = CGEvent(source: nil)?.location ?? p
        let steps = max(1, Int(seconds * 60))
        for i in 1...steps {
            let t = Double(i) / Double(steps), e = t < 0.5 ? 2 * t * t : 1 - pow(-2 * t + 2, 2) / 2
            let q = CGPoint(x: a.x + (p.x - a.x) * e, y: a.y + (p.y - a.y) * e)
            CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: q, mouseButton: .left)?.post(tap: .cghidEventTap)
            usleep(useconds_t(1_000_000 / 60))
        }
    }
    static func click(at p: CGPoint) {
        CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: p, mouseButton: .left)?.post(tap: .cghidEventTap)
        usleep(120_000)   // MixPad misses a click whose press and release come together
        CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: p, mouseButton: .left)?.post(tap: .cghidEventTap)
    }
    // one gesture; runs off the main thread (it sleeps while gliding). Returns nil or why it could not.
    static func gesture(click doClick: Bool, x: Double, y: Double, app: String) -> String? {
        guard allowed else { return "the hand needs Accessibility (System Settings › Privacy and Security)" }
        guard let p = screenPoint(x, y, app) else { return app == "live" ? "Ableton Live is not open" : "CQ MixPad is not open" }
        DispatchQueue.main.sync { Ring.shared.show() }
        front(app)
        glide(to: p)
        if doClick { click(at: p); DispatchQueue.main.sync { Ring.shared.pulse() }; usleep(700_000) }
        return nil
    }
}
