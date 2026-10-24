// THE PLAYER: runs a lesson step by step. Every spoken step plays its mp3 from inside the app (no streaming, no drops);
// play, pause, previous, next, replay and a click on any step of the list start from there. Nothing needs the internet.
import SwiftUI
import AVFoundation

final class Player: NSObject, ObservableObject, AVAudioPlayerDelegate {
    let title: String
    let lessons: [Lesson]
    let changes: [Change]
    @Published var lesson = 0
    @Published var step = 0
    @Published var playing = false
    @Published var paused = false
    @Published var diagram: String?
    @Published var image: String?          // a picture (content/images) shown instead of a diagram
    @Published var lights: [String] = []
    @Published var subtitle = ""
    @Published var marks: [[Double]] = []   // the words of the subtitle and when each is said
    @Published var speakTime: Double = -1   // where the voice is now (-1: not speaking)
    private var follow: Timer?
    @Published var problem = ""
    @Published var autoNext = true          // go on to the next lesson at the end
    private var audio: AVAudioPlayer?
    private var run = 0                     // a new run makes the old one stop at its next look
    private var audioDone: CheckedContinuation<Void, Never>?

    override init() {
        let c = loadContent(); title = c.title; lessons = c.lessons; changes = c.changes
        super.init()
        if !lessons.isEmpty { prepare(0, 0) }
    }
    var steps: [Step] { lessons.indices.contains(lesson) ? lessons[lesson].steps : [] }

    // the picture and the words a step would show, read back from the steps before it (so a jump lands right)
    func prepare(_ l: Int, _ s: Int) {
        lesson = l; step = s
        let st = lessons[l].steps
        diagram = nil; lights = []; subtitle = ""; image = nil; marks = []; speakTime = -1
        for i in 0...min(s, max(0, st.count - 1)) where i < st.count {
            if let d = st[i].show { diagram = d; lights = st[i].light; image = nil }
            if let im = st[i].image { image = im }
            if i < s, let t = st[i].say { subtitle = t }
        }
    }

    func play(from l: Int? = nil, _ s: Int? = nil) {
        stopAudio()
        if let l = l { prepare(l, s ?? 0) }
        run += 1; let me = run
        playing = true; paused = false; problem = ""
        Task { @MainActor in await self.loop(me) }
    }
    func stop() { run += 1; stopAudio(); playing = false; paused = false; Ring.shared.hide() }
    func pauseResume() {
        guard playing else { play(); return }
        paused.toggle()
        if paused { audio?.pause() } else { audio?.play() }
    }
    func next() { jump(lesson, step + 1) }
    func previous() {
        // back to the spoken step before the current one
        var s = max(0, step - 1)
        while s > 0 && steps[s].say == nil { s -= 1 }
        jump(lesson, s)
    }
    func replay() {
        var s = step
        while s > 0 && steps[s].say == nil { s -= 1 }
        jump(lesson, s)
    }
    func jump(_ l: Int, _ s: Int) {
        var l = l, s = s
        if s >= lessons[l].steps.count { if l + 1 < lessons.count { l += 1; s = 0 } else { stop(); return } }
        let was = playing
        stop(); prepare(l, s)
        if was { play() }
    }

    @MainActor private func loop(_ me: Int) async {
        while run == me {
            guard lessons.indices.contains(lesson) else { break }
            if step >= steps.count {
                if autoNext && lesson + 1 < lessons.count { prepare(lesson + 1, 0); continue }
                playing = false; Ring.shared.hide(); break
            }
            await doStep(steps[step], me)
            while paused && run == me { try? await Task.sleep(nanoseconds: 100_000_000) }
            if run != me { return }
            step += 1
        }
    }

    @MainActor private func doStep(_ s: Step, _ me: Int) async {
        if let d = s.show { diagram = d; lights = s.light; image = nil }
        if let im = s.image { image = im }
        if let t = s.say {
            subtitle = t; marks = s.marks; speakTime = 0
            if let u = s.audio, let a = try? AVAudioPlayer(contentsOf: u) {
                audio = a; a.delegate = self; a.prepareToPlay(); a.play()
                // the highlight follows the voice, every 60 ms (word-timing.md §4)
                follow?.invalidate()
                follow = Timer.scheduledTimer(withTimeInterval: 0.06, repeats: true) { [weak self] _ in
                    guard let self = self, let a = self.audio else { return }
                    self.speakTime = a.currentTime
                    // the word said now, also above the ring while the hand is out
                    if Ring.shared.on {
                        let t = self.subtitle.split(whereSeparator: \.isWhitespace).joined(separator: " ")
                        if let m = self.marks.last(where: { $0[2] <= a.currentTime + 0.03 }) {
                            let ch = Array(t), lo = min(Int(m[0]), ch.count), hi = min(Int(m[1]), ch.count)
                            Ring.shared.say(String(ch[lo..<hi]))
                        }
                    }
                }
                await withCheckedContinuation { c in audioDone = c }
                follow?.invalidate(); follow = nil; speakTime = -1; Ring.shared.say("")
                if run != me { return }            // skipped while speaking: the rest of this step is not done
            } else { problem = "no voice file for this step (run tools/build_audio.py)" }
        }
        if let f = s.front { await off { Hand.front(f) } }
        if let p = s.point ?? s.click {
            let isClick = s.click != nil, app = s.app
            if let why = await offResult({ Hand.gesture(click: isClick, x: p[0], y: p[1], app: app) }) { problem = why }
        }
        if let l = s.live { if let why = await offResult({ Live.run(l, s.raw) }) { problem = why } }
        if let w = s.wait {
            var left = w
            while left > 0 && run == me { try? await Task.sleep(nanoseconds: 100_000_000); if !paused { left -= 0.1 } }
        }
    }
    private func off(_ f: @escaping () -> Void) async { await withCheckedContinuation { c in DispatchQueue.global().async { f(); c.resume() } } }
    private func offResult(_ f: @escaping () -> String?) async -> String? {
        await withCheckedContinuation { c in DispatchQueue.global().async { c.resume(returning: f()) } }
    }

    private func stopAudio() {
        follow?.invalidate(); follow = nil; speakTime = -1
        audio?.stop(); audio = nil
        if let c = audioDone { audioDone = nil; c.resume() }
    }
    func audioPlayerDidFinishPlaying(_ p: AVAudioPlayer, successfully: Bool) {
        DispatchQueue.main.async { if let c = self.audioDone { self.audioDone = nil; c.resume() } }
    }
}
