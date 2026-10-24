// LIVE: orders to Ableton Live over OSC, offline and local. AbletonOSC answers only to UDP 11001, which Ableton Live
// Actions holds; its router on 127.0.0.1:11002 passes our messages on and copies the answers back to us
// (ABLETON_LIVE_ACTIONS v4). Without the router the orders go straight to 11000 and the track numbers come from the
// Santoshi set as it is (svemir VOC 0 … Venue L 10, Venue R 11).
import Foundation
import Darwin

enum Live {
    static let knownTracks = ["svemir VOC": 0, "bas": 1, "Mridangam": 2, "Mridangam Low": 3, "Djembe": 4, "Igor VOC": 5,
                              "Igor DI": 6, "tajana": 7, "snoopy DI": 8, "Igor MIC": 9, "Venue L": 10, "Venue R": 11]

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
    static func udp(_ d: Data, port: UInt16) -> Int32 {
        let s = socket(AF_INET, SOCK_DGRAM, 0)
        var to = sockaddr_in(); to.sin_family = sa_family_t(AF_INET); to.sin_port = port.bigEndian; to.sin_addr.s_addr = inet_addr("127.0.0.1")
        _ = d.withUnsafeBytes { p in withUnsafePointer(to: &to) { $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { sendto(s, p.baseAddress, d.count, 0, $0, socklen_t(MemoryLayout<sockaddr_in>.size)) } } }
        return s
    }
    static var routerUp: Bool {
        let s = socket(AF_INET, SOCK_DGRAM, 0); defer { close(s) }
        var a = sockaddr_in(); a.sin_family = sa_family_t(AF_INET); a.sin_port = UInt16(11002).bigEndian; a.sin_addr.s_addr = inet_addr("127.0.0.1")
        return withUnsafePointer(to: &a) { $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { bind(s, $0, socklen_t(MemoryLayout<sockaddr_in>.size)) } } != 0
    }
    static func send(_ addr: String, _ args: [Any] = []) {
        close(udp(message(addr, args), port: routerUp ? 11002 : 11000))
    }
    // the names of Live's tracks, asked through the router; nil without an answer
    static func trackNames() -> [String]? {
        guard routerUp else { return nil }
        let s = udp(message("/live/song/get/track_names", []), port: 11002); defer { close(s) }
        var tv = timeval(tv_sec: 1, tv_usec: 500_000); setsockopt(s, SOL_SOCKET, SO_RCVTIMEO, &tv, socklen_t(MemoryLayout<timeval>.size))
        var buf = [UInt8](repeating: 0, count: 65536)
        for _ in 0..<20 {
            let n = recv(s, &buf, buf.count, 0); if n <= 0 { return nil }
            let d = Array(buf[0..<n])
            func str(_ i: Int) -> (String, Int) { var j = i; while j < d.count && d[j] != 0 { j += 1 }; return (String(decoding: d[i..<j], as: UTF8.self), (j / 4 + 1) * 4) }
            let (addr, i1) = str(0); guard addr == "/live/song/get/track_names" else { continue }
            let (tags, i2) = str(i1); var pos = i2, names: [String] = []
            for _ in tags.dropFirst() { let (s, p) = str(pos); names.append(s); pos = p }
            return names
        }
        return nil
    }
    static func track(_ name: String) -> Int? { trackNames()?.firstIndex(of: name) ?? knownTracks[name] }

    // one number from Live (a float or an int answer), through the router; nil without an answer
    static func number(_ addr: String) -> Double? {
        guard routerUp else { return nil }
        let s = udp(message(addr, []), port: 11002); defer { close(s) }
        var tv = timeval(tv_sec: 1, tv_usec: 500_000); setsockopt(s, SOL_SOCKET, SO_RCVTIMEO, &tv, socklen_t(MemoryLayout<timeval>.size))
        var buf = [UInt8](repeating: 0, count: 4096)
        for _ in 0..<20 {
            let n = recv(s, &buf, buf.count, 0); if n <= 0 { return nil }
            let d = Array(buf[0..<n])
            var j = 0; while j < d.count && d[j] != 0 { j += 1 }
            guard String(decoding: d[0..<j], as: UTF8.self) == addr else { continue }
            let t = (j / 4 + 1) * 4; let tag = d[t + 1]; let v = ((t + 4) / 4) * 4
            if tag == UInt8(ascii: "T") { return 1 }        // a true or false carries no bytes after the tags
            if tag == UInt8(ascii: "F") { return 0 }
            guard v + 4 <= d.count else { return nil }
            let raw = UInt32(d[v]) << 24 | UInt32(d[v + 1]) << 16 | UInt32(d[v + 2]) << 8 | UInt32(d[v + 3])
            if tag == UInt8(ascii: "f") { return Double(Float(bitPattern: raw)) }
            if tag == UInt8(ascii: "i") || tag == UInt8(ascii: "T") || tag == UInt8(ascii: "F") { return tag == UInt8(ascii: "T") ? 1 : tag == UInt8(ascii: "F") ? 0 : Double(Int32(bitPattern: raw)) }
            return nil
        }
        return nil
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
        case "venue_stereo":
            for (name, pan, ch) in [("Venue L", -1.0, "13"), ("Venue R", 1.0, "14")] {
                guard let t = track(name) else { return "no track \(name) in Live" }
                send("/live/track/set/panning", [t, pan]); send("/live/track/set/output_routing_type", [t, "Ext. Out"])
                usleep(150_000); send("/live/track/set/output_routing_channel", [t, ch])
            }
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
