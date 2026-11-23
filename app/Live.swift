// LIVE: orders to Ableton Live over OSC, offline and local. AbletonOSC answers only to UDP 11011: a question takes the
// shared turn on it and lets it go (USE, LET GO, 31.10.2026, LiveTurn.swift). Without an answer the track numbers come
// from the Santoshi set as it is (svemir VOC 0 … Venue L 10, Venue R 11).
import Foundation
import Darwin

enum Live {
    static let knownTracks = ["svemir VOC": 0, "bas": 1, "Mridangam": 2, "Mridangam Low": 3, "Djembe": 4, "Igor VOC": 5,
                              "Igor DI": 6, "tajana": 7, "snoopy DI": 8, "Igor MIC": 9, "Venue Mix": 10]

    static func message(_ addr: String, _ args: [Any]) -> Data {
        func pad(_ d: inout Data) { repeat { d.append(0) } while d.count % 4 != 0 }
        var out = Data(addr.utf8); pad(&out)
        var tags = Data(","
            .utf8); for a in args { tags.append(a is String ? UInt8(ascii: "s") : a is Double || a is Float ? UInt8(ascii: "f") : UInt8(ascii: "i")) }
        pad(&tags); out.append(tags)
        for a in args {
            if let s = a as? String { var d = Data(s.utf8); pad(&d); out.append(d) }
            else if let f = a as? Double { var v = Float(f).bitPattern.bigEndian; out.append(Data(bytes: &v, count: 4)) }
            else if let b = a as? Bool { var v = Int32(b ? 1 : 0).bigEndian; out.append(Data(bytes: &v, count: 4)) }
            else if let i = a as? Int { var v = Int32(i).bigEndian; out.append(Data(bytes: &v, count: 4)) }
        }
        return out
    }
    // USE, LET GO (Marko, 31.10.2026): questions take the shared turn on Live's answer port 11011 and let it go
    // (LiveTurn.swift, the same rule as ABLETON_LIVE_ACTIONS helpers/liveosc.py); orders go straight to 11010. No router:
    // the answers come whether Ableton Live Actions runs or not.
    static func send(_ addr: String, _ args: [Any] = []) {
        let s = socket(AF_INET, SOCK_DGRAM, 0); guard s >= 0 else { return }
        defer { close(s) }
        var to = sockaddr_in(); to.sin_family = sa_family_t(AF_INET); to.sin_port = UInt16(11010).bigEndian; to.sin_addr.s_addr = inet_addr("127.0.0.1")
        let d = message(addr, args)
        _ = d.withUnsafeBytes { p in withUnsafePointer(to: &to) { $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { sendto(s, p.baseAddress, d.count, 0, $0, socklen_t(MemoryLayout<sockaddr_in>.size)) } } }
    }
    // the names of Live's tracks; nil without an answer
    static func trackNames() -> [String]? {
        guard let r = LiveTurn.ask("/live/song/get/track_names", [], wait: 1.5) else { return nil }
        return r.compactMap { $0 as? String }
    }
    static func track(_ name: String) -> Int? { trackNames()?.firstIndex(of: name) ?? knownTracks[name] }

    // one number from Live (a float, an int or a true/false answer); nil without an answer
    static func number(_ addr: String) -> Double? {
        guard let v = LiveTurn.ask(addr, [], wait: 1.5)?.first else { return nil }
        if let b = v as? Bool { return b ? 1 : 0 }
        if let i = v as? Int { return Double(i) }
        return v as? Double
    }
    // where Live was before a lesson moved it (Marko listens while he works: his place is given back)
    static var saved: (beat: Double, playing: Bool)?
    static var soloed = Set<Int>()        // tracks a lesson soloed and has not unsoloed yet

    // STOP, a skip or quitting in the middle of a lesson: no solo left behind, his place given back
    static func cleanup() {
        for t in soloed { send("/live/track/set/solo", [t, false]) }
        soloed.removeAll()
        if saved != nil { _ = run("stop", [:]) }
    }

    // the lessons' orders; returns nil or why it could not
    static func run(_ cmd: String, _ step: [String: Any]) -> String? {
        switch cmd {
        case "venue_house", "venue_stereo":
            // the venue's house mix in stereo on Ext. Out 11/12 -> the CQ's ST IN, named House, source SD/USB (Marko,
            // 24.10.2026: "leave it as a new default stereo in Eleven Twelve. Let that be the house mix")
            guard let t = track("Venue Mix") else { return "no track Venue Mix in Live" }
            send("/live/track/set/output_routing_type", [t, "Ext. Out"]); usleep(150_000)
            send("/live/track/set/output_routing_channel", [t, "11/12"])
        case "play_from_beats":
            // start first, then move: Live's start_playing begins at the start marker, so a time set before it is lost
            // (measured 24.10.2026: Jai Ganesha at beat 948 played from beat 0)
            if saved == nil, let b = number("/live/song/get/current_song_time") {
                saved = (b, (number("/live/song/get/is_playing") ?? 0) != 0)
            }
            send("/live/song/start_playing")
            usleep(250_000)
            send("/live/song/set/current_song_time", [(step["beats"] as? Double) ?? Double(step["beats"] as? Int ?? 0)])
        case "solo", "unsolo":
            let name = step["track"] as? String ?? ""
            guard let t = track(name) else { return "no track \(name) in Live" }
            send("/live/track/set/solo", [t, cmd == "solo"])
            if cmd == "solo" { soloed.insert(t) } else { soloed.remove(t) }
        case "stop":
            // back to where he was: the same beat, and playing if he was playing
            if let s = saved {
                send("/live/song/set/current_song_time", [s.beat])
                if !s.playing { send("/live/song/stop_playing") }
                saved = nil
            } else { send("/live/song/stop_playing") }
        default:
            return "unknown order \(cmd)"
        }
        return nil
    }
}
