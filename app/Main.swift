// CQ MixPad Tutorial (Mantra): the hand of the two-screen tutorial. Marko, 24.10.2026: "you show me inside my CQ Mix
// Pad what you changed and when you changed that. When you are showing demonstrations, you need to put a circle around
// the mouse pointer so I understand where the mouse is, and enlarge it also to fit the user interface of the CQ Mix
// Pad, which is huge." The lesson itself is a web page (MANTRA_PAGES, http://127.0.0.1:8800/cq-mixpad/) on the other
// screen; it asks this app, on 127.0.0.1:8801, to glide the mouse to a control of CQ MixPad, to click it, and to show
// the ring. Coordinates come in a 1600 x 900 picture of the MixPad window and are mapped onto the real window.
import SwiftUI
import AppKit
import Network
import ApplicationServices

let VERSION = 2
let PORT: UInt16 = 8801
let PAGE = "http://127.0.0.1:8800/cq-mixpad/"
let GREEN = Color(red: 0x33/255, green: 0xD1/255, blue: 0x7A/255)
let GREY = Color(red: 0x7A/255, green: 0x80/255, blue: 0x87/255)
let AMBER = Color(red: 0xE8/255, green: 0xA3/255, blue: 0x3D/255)
let INK = Color(red: 0x0B/255, green: 0x0D/255, blue: 0x10/255)

// MARK: the ring around the pointer: a click-through window that follows the mouse, sized for MixPad's big controls

final class Ring {
    static let shared = Ring()
    let size: CGFloat = 170
    private var win: NSWindow?
    private var timer: Timer?
    var on: Bool { win != nil }

    func show() {
        guard win == nil else { return }
        let w = NSWindow(contentRect: NSRect(x: 0, y: 0, width: size, height: size), styleMask: .borderless, backing: .buffered, defer: false)
        w.isOpaque = false; w.backgroundColor = .clear; w.hasShadow = false
        w.level = .screenSaver; w.ignoresMouseEvents = true
        w.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        w.contentView = RingView(frame: NSRect(x: 0, y: 0, width: size, height: size))
        w.orderFrontRegardless(); win = w
        follow()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60, repeats: true) { [weak self] _ in self?.follow() }
    }
    func hide() { timer?.invalidate(); timer = nil; win?.orderOut(nil); win = nil }
    func pulse() { (win?.contentView as? RingView)?.pulse() }
    private func follow() {
        let p = NSEvent.mouseLocation
        win?.setFrameOrigin(NSPoint(x: p.x - size / 2, y: p.y - size / 2))
    }
}

final class RingView: NSView {
    private var flash: CGFloat = 0
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
        if flash > 0 {   // a click: the ring fills for a moment
            c.setFillColor(amber.withAlphaComponent(0.35 * flash).cgColor); c.fillEllipse(in: bounds.insetBy(dx: 14, dy: 14))
        }
        c.setStrokeColor(NSColor.black.withAlphaComponent(0.55).cgColor); c.setLineWidth(14)
        c.strokeEllipse(in: bounds.insetBy(dx: 12, dy: 12))
        c.setStrokeColor(amber.cgColor); c.setLineWidth(8)
        c.strokeEllipse(in: bounds.insetBy(dx: 12, dy: 12))
    }
}

// MARK: CQ MixPad's window and the mouse

// the hand works in two apps (Marko, 24.10.2026: "You can also switch live and CQ MixPad ... like a professor
// demonstrating how to mix"): "mixpad" (CQ MixPad, owner "CQ MixPad 1.2.2") and "live" (Ableton Live, owner "Live")
func appWindow(_ app: String) -> (pid: pid_t, frame: CGRect)? {
    let owner = app == "live" ? "Live" : "MixPad"
    guard let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else { return nil }
    var best: (pid_t, CGRect)?
    for w in list {
        guard let o = w[kCGWindowOwnerName as String] as? String, app == "live" ? o == owner : o.contains(owner),
              (w[kCGWindowLayer as String] as? Int) == 0,
              let b = w[kCGWindowBounds as String] as? [String: CGFloat],
              let pid = w[kCGWindowOwnerPID as String] as? pid_t else { continue }
        let r = CGRect(x: b["X"]!, y: b["Y"]!, width: b["Width"]!, height: b["Height"]!)
        if best == nil || r.width * r.height > best!.1.width * best!.1.height { best = (pid, r) }
    }
    return best.map { (pid: $0.0, frame: $0.1) }
}
func mixpadWindow() -> (pid: pid_t, frame: CGRect)? { appWindow("mixpad") }

// a point of the 1600 x 900 picture -> a point on the screen (global, top-left origin, as CGEvent wants)
func screenPoint(_ x: Double, _ y: Double, _ app: String = "mixpad") -> CGPoint? {
    guard let m = appWindow(app) else { return nil }
    return CGPoint(x: m.frame.minX + CGFloat(x) / 1600 * m.frame.width, y: m.frame.minY + CGFloat(y) / 900 * m.frame.height)
}

func currentMouse() -> CGPoint { CGEvent(source: nil)?.location ?? .zero }

// the mouse glides, so the eye can follow it from where it was
func glide(to p: CGPoint, seconds: Double = 0.7) {
    let a = currentMouse()
    let steps = max(1, Int(seconds * 60))
    for i in 1...steps {
        let t = Double(i) / Double(steps), e = t < 0.5 ? 2 * t * t : 1 - pow(-2 * t + 2, 2) / 2
        let q = CGPoint(x: a.x + (p.x - a.x) * e, y: a.y + (p.y - a.y) * e)
        CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: q, mouseButton: .left)?.post(tap: .cghidEventTap)
        usleep(useconds_t(1_000_000 / 60))
    }
}

func click(at p: CGPoint) {
    CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: p, mouseButton: .left)?.post(tap: .cghidEventTap)
    usleep(120_000)   // MixPad misses a click whose press and release come together
    CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: p, mouseButton: .left)?.post(tap: .cghidEventTap)
}

func bringFront(_ name: String) {
    guard let m = appWindow(name), let app = NSRunningApplication(processIdentifier: m.pid) else { return }
    if !app.isActive { app.activate(); usleep(350_000) }
}

// MARK: the small HTTP door on 127.0.0.1:8801 the page talks to

final class Door {
    static let shared = Door()
    private var listener: NWListener?
    private let work = DispatchQueue(label: "hand")       // one gesture at a time, in order
    var state = "not started"

    func start() {
        do {
            let p = NWParameters.tcp
            p.requiredLocalEndpoint = NWEndpoint.hostPort(host: "127.0.0.1", port: NWEndpoint.Port(rawValue: PORT)!)
            let l = try NWListener(using: p)
            l.newConnectionHandler = { [weak self] c in self?.serve(c) }
            l.stateUpdateHandler = { [weak self] s in DispatchQueue.main.async { self?.state = "\(s)" == "ready" ? "listening on \(PORT)" : "\(s)" } }
            l.start(queue: .global()); listener = l
        } catch { state = "could not open \(PORT): \(error)" }
    }

    private func serve(_ c: NWConnection) {
        c.start(queue: .global())
        c.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, _, _ in
            guard let self = self, let data = data, let text = String(data: data, encoding: .utf8) else { c.cancel(); return }
            let head = text.components(separatedBy: "\r\n").first ?? ""
            let parts = head.split(separator: " ")
            let method = parts.first.map(String.init) ?? "", path = parts.count > 1 ? String(parts[1]) : "/"
            let body = text.components(separatedBy: "\r\n\r\n").dropFirst().joined(separator: "\r\n\r\n")
            let json = (try? JSONSerialization.jsonObject(with: Data(body.utf8))) as? [String: Any] ?? [:]
            if method == "OPTIONS" { self.reply(c, 204, [:]); return }
            self.work.async { self.reply(c, 200, self.handle(path, json)) }
        }
    }

    private func handle(_ path: String, _ j: [String: Any]) -> [String: Any] {
        let x = (j["x"] as? Double) ?? Double(j["x"] as? Int ?? 0), y = (j["y"] as? Double) ?? Double(j["y"] as? Int ?? 0)
        switch path {
        case "/status":
            return ["ok": true, "version": VERSION, "mixpad": mixpadWindow() != nil, "hands": AXIsProcessTrusted(), "ring": Ring.shared.on]
        case "/front":
            let app = j["app"] as? String ?? "mixpad"
            guard appWindow(app) != nil else { return ["ok": false, "error": "\(app) is not open"] }
            bringFront(app); return ["ok": true]
        case "/ring":
            let on = j["on"] as? Bool ?? true
            DispatchQueue.main.sync { on ? Ring.shared.show() : Ring.shared.hide() }
            return ["ok": true]
        case "/point", "/click":
            guard AXIsProcessTrusted() else { return ["ok": false, "error": "CQ MixPad Tutorial needs Accessibility (System Settings, Privacy and Security)"] }
            let app = j["app"] as? String ?? "mixpad"
            guard let p = screenPoint(x, y, app) else { return ["ok": false, "error": "\(app) is not open"] }
            DispatchQueue.main.sync { Ring.shared.show() }
            if path == "/click" || j["front"] as? Bool == true { bringFront(app) }
            glide(to: p, seconds: (j["seconds"] as? Double) ?? 0.7)
            if path == "/click" { click(at: p); DispatchQueue.main.sync { Ring.shared.pulse() } }
            return ["ok": true, "at": [p.x, p.y]]
        default:
            return ["ok": false, "error": "unknown \(path)"]
        }
    }

    private func reply(_ c: NWConnection, _ code: Int, _ obj: [String: Any]) {
        let body = (try? JSONSerialization.data(withJSONObject: obj)) ?? Data()
        var h = "HTTP/1.1 \(code) OK\r\nContent-Type: application/json\r\nContent-Length: \(body.count)\r\n"
        h += "Access-Control-Allow-Origin: *\r\nAccess-Control-Allow-Headers: Content-Type\r\nAccess-Control-Allow-Methods: GET, POST, OPTIONS\r\nConnection: close\r\n\r\n"
        c.send(content: Data(h.utf8) + body, completion: .contentProcessed { _ in c.cancel() })
    }
}

// MARK: the window

final class Model: ObservableObject {
    @Published var tick = 0
    init() { Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in self?.tick += 1 } }
}

struct Word: View {
    let text: String; let on: Bool; let action: () -> Void
    var body: some View {
        Text(text).font(.system(size: 13, weight: .bold, design: .monospaced)).foregroundColor(on ? GREEN : GREY)
            .padding(.horizontal, 6).padding(.vertical, 4).contentShape(Rectangle()).onTapGesture(perform: action)
    }
}
struct CloseX: View {
    @State private var window: NSWindow?
    var body: some View {
        Image(systemName: "xmark").font(.system(size: 14, weight: .bold)).foregroundColor(GREY)
            .frame(width: 28, height: 28).contentShape(Rectangle())
            .background(WindowReader { window = $0 })
            .onTapGesture { (window ?? NSApp.keyWindow)?.performClose(nil) }
            .help("close this window; the app stays on")
    }
}
struct WindowReader: NSViewRepresentable {
    let found: (NSWindow?) -> Void
    func makeNSView(context: Context) -> NSView { let v = NSView(); DispatchQueue.main.async { found(v.window) }; return v }
    func updateNSView(_ v: NSView, context: Context) {}
}
struct Row: View {
    let label: String, value: String, good: Bool
    var body: some View {
        HStack {
            Text(label).font(.system(size: 11, weight: .bold, design: .monospaced)).foregroundColor(GREY)
            Spacer()
            Text(value).font(.system(size: 13, weight: .bold, design: .monospaced)).foregroundColor(good ? GREEN : AMBER)
        }
    }
}

struct MainView: View {
    @ObservedObject var m: Model
    var body: some View {
        let _ = m.tick
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Text("CQ MIXPAD TUTORIAL").font(.system(size: 12, weight: .bold, design: .monospaced)).foregroundColor(.white).padding(.trailing, 6)
                Word(text: "ON", on: true) {}
                Word(text: "OFF", on: false) { NSApp.terminate(nil) }
                Spacer()
                Text("v\(VERSION)").font(.system(size: 11, design: .monospaced)).foregroundColor(GREY).padding(.trailing, 8)
                CloseX()
            }
            .padding(.leading, 24).padding(.trailing, 10).padding(.vertical, 8)
            Divider()
            VStack(alignment: .leading, spacing: 14) {
                Text("The lessons play as a web page on the MacBook screen; this app is the hand in CQ MixPad on the other screen: it moves the mouse with a big amber ring around it.")
                    .font(.system(size: 11, design: .monospaced)).foregroundColor(GREY).fixedSize(horizontal: false, vertical: true)
                Row(label: "CQ MIXPAD", value: mixpadWindow() != nil ? "OPEN" : "NOT OPEN", good: mixpadWindow() != nil)
                Row(label: "HANDS (ACCESSIBILITY)", value: AXIsProcessTrusted() ? "ALLOWED" : "NOT YET ALLOWED", good: AXIsProcessTrusted())
                Row(label: "DOOR FOR THE PAGE", value: Door.shared.state.uppercased(), good: Door.shared.state.hasPrefix("listening"))
                HStack {
                    Text("OPEN THE LESSONS").font(.system(size: 13, weight: .bold, design: .monospaced)).foregroundColor(.black)
                        .padding(.horizontal, 14).padding(.vertical, 8).background(AMBER).cornerRadius(6)
                        .onTapGesture { NSWorkspace.shared.open(URL(string: PAGE)!) }
                    Text(Ring.shared.on ? "RING ON" : "RING OFF").font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(Ring.shared.on ? GREEN : GREY).padding(.leading, 10)
                        .onTapGesture { Ring.shared.on ? Ring.shared.hide() : Ring.shared.show(); m.tick += 1 }
                }
                Text(PAGE).font(.system(size: 11, design: .monospaced)).foregroundColor(GREY).textSelection(.enabled)
            }
            .padding(24)
        }
        .frame(width: 560).background(INK).preferredColorScheme(.dark)
    }
}

let MODEL = Model()

final class Delegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ n: Notification) {
        Door.shared.start()
        // macOS asks once; Marko answers it (never answered for him)
        _ = AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary)
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ s: NSApplication) -> Bool { false }
    func applicationShouldHandleReopen(_ s: NSApplication, hasVisibleWindows: Bool) -> Bool { true }
}

@main struct CQMixPadTutorial: App {
    @NSApplicationDelegateAdaptor(Delegate.self) var delegate
    var body: some Scene {
        WindowGroup("CQ MixPad Tutorial (Mantra)") { MainView(m: MODEL) }.windowResizability(.contentSize)
    }
}
