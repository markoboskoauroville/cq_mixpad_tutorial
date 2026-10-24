// start.swift [lesson]: tells CQ MixPad Tutorial to play from a lesson (1 by default), without the mouse.
//     swiftc -O -o build/start tools/start.swift && build/start 1
import Foundation
let lesson = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "1"
DistributedNotificationCenter.default().postNotificationName(Notification.Name("community.auroville.cqtutorial.play"), object: lesson, userInfo: nil, deliverImmediately: true)
print("asked CQ MixPad Tutorial to play from lesson \(lesson)")
