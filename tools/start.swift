// start.swift [lesson[.step] | pause | resume]: tells CQ MixPad Tutorial to play from a lesson (1 by default) or a step
// of it ("2.5"), or to pause and resume, without the mouse or a key.
//     swiftc -O -o build/start tools/start.swift && build/start 2.5
import Foundation
let arg = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "1"
let name = arg == "pause" || arg == "resume" ? arg : "play"
DistributedNotificationCenter.default().postNotificationName(Notification.Name("community.auroville.cqtutorial." + name), object: name == "play" ? arg : nil, userInfo: nil, deliverImmediately: true)
print(name == "play" ? "asked CQ MixPad Tutorial to play from \(arg)" : "asked CQ MixPad Tutorial to \(name)")
