// THE CONTENT, inside the app: Resources/content/lessons.built.json (the lessons, each spoken step with its mp3),
// content/audio/steps/*.mp3 (the voice, made before, never streamed), content/diagrams.json, content/images/.
// Marko, 24.10.2026: "rerun and skip steps of this tutorial without being connected to the internet".
import Foundation

let CONTENT: URL = {
    let inApp = Bundle.main.resourceURL!.appendingPathComponent("content")
    if FileManager.default.fileExists(atPath: inApp.path) { return inApp }
    return URL(fileURLWithPath: NSHomeDirectory() + "/Developer/CQ_MIXPAD_TUTORIAL/content")
}()

struct Step {
    let raw: [String: Any]
    var say: String? { raw["say"] as? String }
    var audio: URL? { (raw["audio"] as? String).map { CONTENT.appendingPathComponent($0) } }
    // Speechify's word marks beside the mp3: [char from, char to, seconds from, seconds to] on the text with single spaces
    var marks: [[Double]] {
        guard let a = audio, let d = try? Data(contentsOf: a.deletingPathExtension().appendingPathExtension("json")),
              let m = try? JSONSerialization.jsonObject(with: d) as? [[NSNumber]] else { return [] }
        return m.map { $0.map { $0.doubleValue } }
    }
    var show: String? { raw["show"] as? String }
    var light: [String] { raw["light"] as? [String] ?? [] }
    var image: String? { raw["image"] as? String }
    var point: [Double]? { (raw["point"] as? [NSNumber])?.map { $0.doubleValue } }
    var click: [Double]? { (raw["click"] as? [NSNumber])?.map { $0.doubleValue } }
    var app: String { raw["app"] as? String ?? "mixpad" }
    var front: String? { raw["front"] as? String }
    var live: String? { raw["live"] as? String }
    var wait: Double? { (raw["wait"] as? NSNumber)?.doubleValue }
    var label: String? { raw["label"] as? String }

    // one line for the step list
    var line: String {
        if let s = say { return "🗣 " + s }
        if let s = show { return "▦ " + (DIAGRAMS[s]?.title ?? s) + (light.isEmpty ? "" : " · " + light.joined(separator: ", ")) }
        if let i = image { return "▣ picture " + i }
        if click != nil { return "◉ click " + (app == "live" ? "in Live: " : "in MixPad: ") + (label ?? "") }
        if point != nil { return "○ show " + (app == "live" ? "in Live: " : "in MixPad: ") + (label ?? "") }
        if let f = front { return "⇄ bring " + (f == "live" ? "Ableton Live" : "CQ MixPad") + " to the front" }
        if let l = live { return "♪ Live: " + l + ((raw["track"] as? String).map { " " + $0 } ?? "") }
        if let w = wait { return "… \(Int(w)) s" }
        return "·"
    }
}
struct Lesson { let title: String; let steps: [Step]; let image: String? }   // image: a photo in content/images
struct Change { let when, whereAt, what: String }

struct El {
    let kind: String, id: String
    let x, y, w, h: Double
    let text, sub, label: String
    let from, to: CGPoint
    let points: [CGPoint]
    let dashed: Bool
}
struct Diagram { let title: String; let els: [El] }

var DIAGRAMS: [String: Diagram] = [:]

func loadContent() -> (title: String, lessons: [Lesson], changes: [Change]) {
    if let d = try? Data(contentsOf: CONTENT.appendingPathComponent("diagrams.json")),
       let j = (try? JSONSerialization.jsonObject(with: d)) as? [String: Any], let all = j["diagrams"] as? [String: [String: Any]] {
        for (id, dg) in all {
            let els: [El] = (dg["els"] as? [[String: Any]] ?? []).map { e in
                let kind = ["node", "edge", "note", "area", "curve"].first { e[$0] != nil } ?? "note"
                func n(_ k: String) -> Double { (e[k] as? NSNumber)?.doubleValue ?? 0 }
                func pt(_ k: String) -> CGPoint { let a = (e[k] as? [NSNumber]) ?? [0, 0]; return CGPoint(x: a[0].doubleValue, y: a[1].doubleValue) }
                let pts = (e["points"] as? [[NSNumber]] ?? []).map { CGPoint(x: $0[0].doubleValue, y: $0[1].doubleValue) }
                return El(kind: kind, id: e[kind] as? String ?? "", x: n("x"), y: n("y"), w: n("w"), h: n("h"),
                          text: e["text"] as? String ?? "", sub: e["sub"] as? String ?? "", label: e["label"] as? String ?? "",
                          from: pt("from"), to: pt("to"), points: pts, dashed: e["dashed"] as? Bool ?? false)
            }
            DIAGRAMS[id] = Diagram(title: dg["title"] as? String ?? id, els: els)
        }
    }
    guard let d = try? Data(contentsOf: CONTENT.appendingPathComponent("lessons.built.json")),
          let j = (try? JSONSerialization.jsonObject(with: d)) as? [String: Any] else { return ("No lessons found", [], []) }
    let lessons = (j["lessons"] as? [[String: Any]] ?? []).map { l in
        Lesson(title: l["title"] as? String ?? "", steps: (l["steps"] as? [[String: Any]] ?? []).map(Step.init), image: l["image"] as? String)
    }
    let changes = (j["changes"] as? [[String: String]] ?? []).map { Change(when: $0["when"] ?? "", whereAt: $0["where"] ?? "", what: $0["what"] ?? "") }
    return (j["title"] as? String ?? "", lessons, changes)
}
