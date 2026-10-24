// CQ MixPad Tutorial (Mantra): the mixer taught by voice, diagrams and the hand, offline. Marko, 24.10.2026: "Teach me
// my mixer", "make a Swift app called CQ Tutorial", "you show me diagrams, and you show me inside my CQ Mix Pad what
// you changed and when you changed that", "The goal is to rerun and skip steps of this tutorial without being connected
// to the internet ... the whole tutorial as a software-only Swift." The Santoshi concert is the case study.
// This window sits on the MacBook's screen; CQ MixPad and Live stay on the BenQ, where the hand works with its ring.
import SwiftUI
import AppKit

let VERSION = 9
let GREEN = Color(red: 0x33/255, green: 0xD1/255, blue: 0x7A/255)
let GREY = Color(red: 0x7A/255, green: 0x80/255, blue: 0x87/255)
let AMBER = Color(red: 0xE8/255, green: 0xA3/255, blue: 0x3D/255)
let INK = Color(red: 0x0B/255, green: 0x0D/255, blue: 0x10/255)
let CARD = Color(red: 0x14/255, green: 0x1A/255, blue: 0x21/255)

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
struct Key: View {
    let symbol: String, label: String, action: () -> Void
    var body: some View {
        VStack(spacing: 3) {
            Image(systemName: symbol).font(.system(size: 22, weight: .bold)).foregroundColor(.white)
            Text(label).font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundColor(GREY)
        }
        .frame(width: 82, height: 58).background(CARD).cornerRadius(8).contentShape(Rectangle()).onTapGesture(perform: action)
    }
}

struct MainView: View {
    @ObservedObject var p: Player
    @State private var tick = 0
    let timer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 0) {
            // the first row: ON / OFF, the version, ✕ (MANTRA_MANIFEST swift-apps.md)
            HStack(spacing: 0) {
                Text("CQ MIXPAD TUTORIAL").font(.system(size: 12, weight: .bold, design: .monospaced)).foregroundColor(.white).padding(.trailing, 6)
                Word(text: "ON", on: true) {}
                Word(text: "OFF", on: false) { NSApp.terminate(nil) }
                Spacer()
                // the speed of the voice, at the top (Marko, 24.10.2026)
                HStack(spacing: 4) {
                    Text("SPEED").font(.system(size: 11, weight: .bold, design: .monospaced)).foregroundColor(GREY)
                    Image(systemName: "minus").font(.system(size: 13, weight: .bold)).foregroundColor(.white)
                        .frame(width: 26, height: 22).background(CARD).cornerRadius(4).onTapGesture { p.slower() }
                    Text(String(format: "%.2g×", p.rate)).font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(p.rate == 1 ? .white : AMBER).frame(width: 52)
                    Image(systemName: "plus").font(.system(size: 13, weight: .bold)).foregroundColor(.white)
                        .frame(width: 26, height: 22).background(CARD).cornerRadius(4).onTapGesture { p.faster() }
                }.padding(.trailing, 18)
                status
                Text("v\(VERSION)").font(.system(size: 11, design: .monospaced)).foregroundColor(GREY).padding(.horizontal, 8)
                CloseX()
            }
            .padding(.leading, 20).padding(.trailing, 10).padding(.vertical, 6)
            Divider()
            HStack(alignment: .top, spacing: 0) {
                lessonList.frame(width: 250)
                Divider()
                stage.frame(maxWidth: .infinity)
                Divider()
                stepList.frame(width: 360)
            }
        }
        .background(INK).preferredColorScheme(.dark)
        .onReceive(timer) { _ in tick += 1 }
    }

    var status: some View {
        let _ = tick
        let mix = Hand.window("mixpad") != nil, live = Hand.window("live") != nil
        return HStack(spacing: 14) {
            Text("MIXPAD " + (mix ? "●" : "○")).foregroundColor(mix ? GREEN : AMBER)
            Text("LIVE " + (live ? "●" : "○")).foregroundColor(live ? GREEN : AMBER)
            Text("HAND " + (Hand.allowed ? "●" : "○")).foregroundColor(Hand.allowed ? GREEN : AMBER)
            Text("RING " + (Ring.shared.on ? "ON" : "OFF")).foregroundColor(Ring.shared.on ? GREEN : GREY)
                .onTapGesture { Ring.shared.on ? Ring.shared.hide() : Ring.shared.show(); tick += 1 }
        }.font(.system(size: 11, weight: .bold, design: .monospaced))
    }

    var lessonList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 6) {
                Text("LESSONS").font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundColor(GREY).padding(.bottom, 4)
                ForEach(p.lessons.indices, id: \.self) { i in
                    Text(p.lessons[i].title).font(.system(size: 13, weight: i == p.lesson ? .bold : .regular, design: .monospaced))
                        .foregroundColor(i == p.lesson ? AMBER : Color(white: 0.85))
                        .frame(maxWidth: .infinity, alignment: .leading).padding(8)
                        .background(i == p.lesson ? CARD : Color.clear).cornerRadius(6)
                        .contentShape(Rectangle()).onTapGesture { p.play(from: i, 0) }
                }
            }.padding(14)
        }
    }

    var stage: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 16) {
                // the lesson's photo (Nano Banana), when it has one
                if let im = p.lessons.indices.contains(p.lesson) ? p.lessons[p.lesson].image : nil,
                   let ns = NSImage(contentsOf: CONTENT.appendingPathComponent("images/" + im)) {
                    Image(nsImage: ns).resizable().scaledToFill().frame(width: 260, height: 146).clipped().cornerRadius(10)
                }
                Text(p.lessons.indices.contains(p.lesson) ? p.lessons[p.lesson].title : "")
                    .font(.system(size: 22, weight: .bold, design: .monospaced)).foregroundColor(.white)
                Spacer()
            }
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(Color(white: 0.06))
                if let im = p.image, let ns = NSImage(contentsOf: CONTENT.appendingPathComponent("images/" + im)) {
                    Image(nsImage: ns).resizable().scaledToFit().cornerRadius(10).padding(10)
                } else if let d = p.diagram, let dg = DIAGRAMS[d] {
                    DiagramView(diagram: dg, lights: p.lights).padding(18)
                } else {
                    Text("Press ▶ to begin").font(.system(size: 16, design: .monospaced)).foregroundColor(GREY)
                }
            }
            .frame(maxHeight: .infinity)
            .overlay(alignment: .bottom) {
                // the manual's own words, marked as such
                if let q = p.quote {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(q.kind == "book" ? "FROM THE BOOK" : "FROM THE CQ MANUAL").font(.system(size: 11, weight: .bold, design: .monospaced)).foregroundColor(Color(red: 0.55, green: 0.75, blue: 1.0))
                        Text("“" + q.q + "”").font(.system(size: 20, weight: .medium, design: .serif)).foregroundColor(.white)
                        Text(q.from).font(.system(size: 11, design: .monospaced)).foregroundColor(GREY)
                    }
                    .padding(16).frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(red: 0.07, green: 0.10, blue: 0.16).opacity(0.96))
                    .overlay(Rectangle().frame(width: 4).foregroundColor(Color(red: 0.55, green: 0.75, blue: 1.0)), alignment: .leading)
                    .cornerRadius(8).padding(14)
                }
            }
            if let s = p.source, !p.subtitle.isEmpty {
                let tag: (String, Color) = s == "manual" ? ("FROM THE CQ MANUAL", Color(red: 0.55, green: 0.75, blue: 1.0))
                    : s == "book" ? ("FROM THE BOOK: STEVE SAVAGE, MIXING AND MASTERING IN THE BOX", Color(red: 0.80, green: 0.60, blue: 1.0))
                    : s == "measured" ? ("MEASURED ON YOUR CQ", GREEN)
                    : s == "santoshi" ? ("WHAT WAS DONE FOR SANTOSHI", AMBER)
                    : ("MIXING KNOWLEDGE, NOT FROM THE MANUAL", GREY)
                Text(tag.0).font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundColor(tag.1)
                    .padding(.horizontal, 8).padding(.vertical, 3).overlay(RoundedRectangle(cornerRadius: 4).stroke(tag.1, lineWidth: 1))
            }
            ReadingText(text: p.subtitle, marks: p.marks, time: p.speakTime)
                .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
            if !p.problem.isEmpty {
                Text(p.problem).font(.system(size: 12, weight: .bold, design: .monospaced)).foregroundColor(AMBER)
            }
            HStack(spacing: 10) {
                Key(symbol: "backward.fill", label: "BACK") { p.previous() }
                Key(symbol: "arrow.counterclockwise", label: "AGAIN") { p.replay() }
                Key(symbol: p.playing && !p.paused ? "pause.fill" : "play.fill", label: p.playing && !p.paused ? "PAUSE" : "PLAY") { p.pauseResume() }
                Key(symbol: "forward.fill", label: "SKIP") { p.next() }
                Key(symbol: "stop.fill", label: "STOP") { p.stop() }
                Spacer()
                Text(p.autoNext ? "NEXT LESSON: ON" : "NEXT LESSON: OFF").font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(p.autoNext ? GREEN : GREY).onTapGesture { p.autoNext.toggle() }
            }
        }.padding(20)
    }

    var stepList: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("STEPS · click one to start there").font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundColor(GREY).padding(14)
            ScrollViewReader { sv in
                ScrollView {
                    VStack(alignment: .leading, spacing: 3) {
                        ForEach(p.steps.indices, id: \.self) { i in
                            Text(p.steps[i].line).lineLimit(2)
                                .font(.system(size: 11, weight: i == p.step ? .bold : .regular, design: .monospaced))
                                .foregroundColor(i == p.step ? AMBER : (i < p.step ? GREY : Color(white: 0.8)))
                                .frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 5).padding(.horizontal, 8)
                                .background(i == p.step ? CARD : Color.clear).cornerRadius(5)
                                .contentShape(Rectangle()).onTapGesture { p.play(from: p.lesson, i) }
                                .id(i)
                        }
                    }.padding(.horizontal, 10)
                }
                .onChange(of: p.step) { _, s in withAnimation { sv.scrollTo(s, anchor: .center) } }
            }
            Divider().padding(.vertical, 6)
            Text("WHAT WAS CHANGED, AND WHEN").font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundColor(GREY).padding(.horizontal, 14)
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(p.changes.indices, id: \.self) { i in
                        let c = p.changes[i]
                        VStack(alignment: .leading, spacing: 2) {
                            Text(c.when + " · " + c.whereAt).font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundColor(AMBER)
                            Text(c.what).font(.system(size: 11, design: .monospaced)).foregroundColor(Color(white: 0.8)).fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }.padding(14)
            }.frame(height: 260)
        }
    }
}

let PLAYER = Player()

final class Delegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ n: Notification) {
        // started from outside, without the mouse (Marko, 24.10.2026: "When it comes to zero, the tutorial starts as a
        // demonstration"): the distributed notification community.auroville.cqtutorial.play starts lesson 1, or the
        // lesson number given as its object; tools/start.swift sends it
        DistributedNotificationCenter.default().addObserver(forName: Notification.Name("community.auroville.cqtutorial.play"), object: nil, queue: .main) { n in
            let l = max(0, (Int(n.object as? String ?? "1") ?? 1) - 1)
            NSApp.activate(ignoringOtherApps: true)
            PLAYER.autoNext = true
            PLAYER.play(from: min(l, PLAYER.lessons.count - 1), 0)
        }
        // macOS asks once for the hand; Marko answers it (never answered for him)
        _ = AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary)
        // the window on the MacBook's own screen (not the BenQ, where MixPad and Live are), filling it
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            guard let w = NSApp.windows.first(where: { $0.title.contains("CQ MixPad Tutorial") }) else { return }
            let screen = NSScreen.screens.first { $0.localizedName.contains("Built-in") } ?? NSScreen.screens.last ?? NSScreen.main!
            w.setFrame(screen.visibleFrame, display: true)
        }
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ s: NSApplication) -> Bool { false }
    func applicationShouldHandleReopen(_ s: NSApplication, hasVisibleWindows: Bool) -> Bool { true }
    func applicationWillTerminate(_ n: Notification) { PLAYER.stop() }
}

@main struct CQMixPadTutorial: App {
    @NSApplicationDelegateAdaptor(Delegate.self) var delegate
    var body: some Scene {
        WindowGroup("CQ MixPad Tutorial (Mantra)") { MainView(p: PLAYER).frame(minWidth: 1100, minHeight: 700) }
    }
}
