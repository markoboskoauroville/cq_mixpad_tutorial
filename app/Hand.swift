// THE HAND: the mouse in CQ MixPad and in Ableton Live, with a big amber ring around it (Marko, 24.10.2026: "put a
// circle around the mouse pointer so I understand where the mouse is, and enlarge it also to fit the user interface
// of the CQ Mix Pad, which is huge"; "You can also switch live and CQ MixPad ... like a professor demonstrating").
// Coordinates come in a 1600 x 900 picture of the app's window (title bar included) and are mapped onto the real one.
import AppKit
import ApplicationServices
import ImageIO

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

    // LIVE AND MIXPAD EACH IN ITS OWN FULL-SCREEN SPACE on the BenQ (Marko, 25.10.2026: "make them actually both full
    // screen when you run, and just swipe between workspaces"): the app is found among the running ones (its window is
    // not on screen while its space is away), made frontmost, and macOS slides to its space as a three-finger swipe does
    static func runningApp(_ app: String) -> NSRunningApplication? {
        NSWorkspace.shared.runningApplications.first { a in
            let n = a.localizedName ?? ""
            return app == "live" ? (n == "Live" || n.hasPrefix("Ableton Live")) : n.contains("MixPad") && !n.contains("Tutorial")
        }
    }
    static func front(_ app: String) {
        guard let a = runningApp(app) else { return }
        if !a.isActive { a.activate(options: [.activateIgnoringOtherApps]); usleep(400_000) }
        // macOS 14 may refuse an activate from an app in the background (measured 25.10.2026: Live stayed over MixPad);
        // the hand is trusted, so Accessibility makes it frontmost and raises its window
        if !a.isActive {
            let ax = AXUIElementCreateApplication(a.processIdentifier)
            AXUIElementSetAttributeValue(ax, kAXFrontmostAttribute as CFString, kCFBooleanTrue)
            var w: CFTypeRef?
            if AXUIElementCopyAttributeValue(ax, kAXMainWindowAttribute as CFString, &w) == .success, let w = w {
                AXUIElementPerformAction(w as! AXUIElement, kAXRaiseAction as CFString)
            }
        }
        // a full-screen app in another space: activate and Accessibility make it frontmost but may not slide to its space
        // (measured 25.10.2026: Live stayed away, "not open"); LaunchServices, as `open -a` does, always slides there
        if window(app)?.pid != a.processIdentifier, let url = a.bundleURL {
            let cfg = NSWorkspace.OpenConfiguration(); cfg.activates = true
            NSWorkspace.shared.openApplication(at: url, configuration: cfg)
        }
        // the slide between spaces takes about a second: wait until the window is on the screen, at most 2.5 s
        for _ in 0..<25 {
            if a.isActive, let m = window(app), m.pid == a.processIdentifier, ownerAt(CGPoint(x: m.frame.midX, y: m.frame.midY)).map({ app == "live" ? $0 == "Live" : $0.contains("MixPad") }) == true { break }
            usleep(100_000)
        }
        usleep(300_000)
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
    // LOOK BEFORE THE HAND MOVES (Marko, 24.10.2026: "Before you show anything on the screen or click on anything,
    // take the screenshot and check. Will your clicks land in the right application and the right position? If it's not
    // landing, you need to ask the user to adjust the user interface so it lands."). Three checks, after the app is
    // brought to the front: (1) its window is as big and as wide as when the positions were measured (16:9, at least
    // 1400 points wide); (2) the window at the spot is that app's, nothing covers it; (3) the spot looks as it did: the
    // first time a target is used its picture is kept (~/Library/Application Support/CQMixPadTutorial/targets), every
    // later time the picture is compared. A failed check returns "CHECK: ..." and the player pauses and asks.
    static let TARGETS = NSHomeDirectory() + "/Library/Application Support/CQMixPadTutorial/targets"
    static func appName(_ app: String) -> String { app == "live" ? "Ableton Live" : "CQ MixPad" }

    static func windowID(_ app: String) -> CGWindowID? {
        guard let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else { return nil }
        var best: (CGWindowID, CGFloat)?
        for w in list {
            guard let o = w[kCGWindowOwnerName as String] as? String, app == "live" ? o == "Live" : o.contains("MixPad"),
                  (w[kCGWindowLayer as String] as? Int) == 0, let b = w[kCGWindowBounds as String] as? [String: CGFloat],
                  let n = w[kCGWindowNumber as String] as? CGWindowID else { continue }
            let a = b["Width"]! * b["Height"]!
            if best == nil || a > best!.1 { best = (n, a) }
        }
        return best?.0
    }
    // the app whose window is on top at a screen point (top-left coordinates)
    static func ownerAt(_ p: CGPoint) -> String? {
        guard let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else { return nil }
        for w in list where (w[kCGWindowLayer as String] as? Int) == 0 {
            guard let b = w[kCGWindowBounds as String] as? [String: CGFloat] else { continue }
            if CGRect(x: b["X"]!, y: b["Y"]!, width: b["Width"]!, height: b["Height"]!).contains(p) { return w[kCGWindowOwnerName as String] as? String }
        }
        return nil
    }
    // a small grey picture (48 x 24) of the spot, from the target window alone (the ring never shows in it): the system's
    // screencapture of that one window, then the spot cut out of it
    static func patch(_ app: String, _ p: CGPoint) -> [UInt8]? {
        guard let id = windowID(app), let m = window(app) else { return nil }
        let file = NSTemporaryDirectory() + "cqtut-look.png"
        let t = Process(); t.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        t.arguments = ["-x", "-o", "-l", String(id), file]
        guard (try? t.run()) != nil else { return nil }
        t.waitUntilExit()
        guard let src = CGImageSourceCreateWithURL(URL(fileURLWithPath: file) as CFURL, nil),
              let full = CGImageSourceCreateImageAtIndex(src, 0, nil) else { return nil }
        let k = CGFloat(full.width) / m.frame.width
        let r = CGRect(x: (p.x - m.frame.minX - 60) * k, y: (p.y - m.frame.minY - 30) * k, width: 120 * k, height: 60 * k)
        guard let img = full.cropping(to: r) else { return nil }
        let w = 48, h = 24
        var px = [UInt8](repeating: 0, count: w * h)
        guard let ctx = CGContext(data: &px, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w, space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue) else { return nil }
        ctx.interpolationQuality = .medium
        ctx.draw(img, in: CGRect(x: 0, y: 0, width: w, height: h))
        return px
    }
    static func check(_ app: String, _ x: Double, _ y: Double, _ p: CGPoint, _ label: String) -> String? {
        guard let m = window(app) else { return "CHECK: \(appName(app)) is not open. Please open it, full screen on the BenQ, and press PLAY." }
        let aspect = m.frame.width / max(1, m.frame.height)
        if m.frame.width < 1400 || abs(aspect - 16.0 / 9.0) > 0.06 {
            return "CHECK: \(appName(app)) is not at the size the lessons were measured at (\(Int(m.frame.width)) x \(Int(m.frame.height))). Please make it full screen on the BenQ and press PLAY."
        }
        if let o = ownerAt(p), !(app == "live" ? o == "Live" : o.contains("MixPad")) {
            return "CHECK: at \"\(label)\" the hand would land on \(o), not on \(appName(app)). Please move \(o) away from the BenQ and press PLAY."
        }
        guard let now = patch(app, p) else { return nil }        // no picture possible: the first two checks must do
        let key = "\(app)-\(Int(x))-\(Int(y))-" + label.filter { $0.isLetter || $0.isNumber }.prefix(24)
        let file = TARGETS + "/" + key + ".gray"
        let moving = label.lowercased().contains("meter")         // a meter moves with the music: not compared
        if let ref = FileManager.default.contents(atPath: file), ref.count == now.count {
            if moving { return nil }
            let diff = zip(ref, now).reduce(0) { $0 + abs(Int($1.0) - Int($1.1)) } / now.count
            if diff > 38 {
                return "CHECK: \"\(label)\" does not look as it did when the lesson was made (difference \(diff)). Is \(appName(app)) on the right page, full screen on the BenQ? Please put it right and press PLAY; the step is done again."
            }
        } else {
            try? FileManager.default.createDirectory(atPath: TARGETS, withIntermediateDirectories: true)
            FileManager.default.createFile(atPath: file, contents: Data(now))       // learned now, compared from the next run on
        }
        return nil
    }

    static func gesture(click doClick: Bool, x: Double, y: Double, app: String, label: String = "") -> String? {
        guard allowed else { return "the hand needs Accessibility (System Settings › Privacy and Security)" }
        guard let p = screenPoint(x, y, app) else { return "CHECK: \(appName(app)) is not open. Please open it, full screen on the BenQ, and press PLAY." }
        front(app)
        if let why = check(app, x, y, p, label.isEmpty ? "\(Int(x)),\(Int(y))" : label) { return why }
        DispatchQueue.main.sync { Ring.shared.show() }
        glide(to: p)
        if doClick { click(at: p); DispatchQueue.main.sync { Ring.shared.pulse() }; usleep(700_000) }
        return nil
    }
}
