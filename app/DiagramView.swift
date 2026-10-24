// THE DIAGRAMS, drawn from content/diagrams.json on a 1000 x 560 board; the elements a step lights turn amber.
import SwiftUI

struct DiagramView: View {
    let diagram: Diagram
    let lights: [String]
    func lit(_ id: String) -> Bool { lights.contains { id.hasPrefix($0) } }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(diagram.title).font(.system(size: 15, weight: .bold, design: .monospaced)).foregroundColor(.white)
            GeometryReader { g in
                let k = min(g.size.width / 1000, g.size.height / 560)
                Canvas { c, _ in
                    c.scaleBy(x: k, y: k)
                    for e in diagram.els { draw(e, in: &c) }
                }
                .frame(width: 1000 * k, height: 560 * k)
                .animation(.easeInOut(duration: 0.3), value: lights)
            }
        }
    }

    private func draw(_ e: El, in c: inout GraphicsContext) {
        let on = lit(e.id)
        let ink = on ? AMBER : Color(white: 0.75)
        let line = on ? AMBER : Color(white: 0.38)
        switch e.kind {
        case "node":
            let r = CGRect(x: e.x, y: e.y, width: e.w, height: e.h)
            let p = Path(roundedRect: r, cornerRadius: 10)
            c.fill(p, with: .color(on ? AMBER.opacity(0.16) : Color(white: 0.11)))
            c.stroke(p, with: .color(line), lineWidth: on ? 3 : 1.5)
            let short = r.height < 90          // a one-line box: the title and its small note side by side in height
            c.draw(Text(e.text).font(.system(size: short ? 17 : 19, weight: .bold, design: .monospaced)).foregroundColor(on ? AMBER : .white),
                   at: CGPoint(x: r.midX, y: short ? (e.sub.isEmpty ? r.midY : r.midY - 9) : r.minY + 24), anchor: .center)
            // the small text, each line centred (a Canvas draws a Text as given, so the lines are placed one by one)
            let size: CGFloat = short ? 11 : 14, top = short ? r.midY + 13 : r.minY + 54
            for (i, l) in e.sub.components(separatedBy: "\n").enumerated() where !l.isEmpty {
                c.draw(Text(l).font(.system(size: size, design: .monospaced)).foregroundColor(ink),
                       at: CGPoint(x: r.midX, y: top + CGFloat(i) * (size + 6)), anchor: .center)
            }
        case "edge":
            var p = Path(); p.move(to: e.from); p.addLine(to: e.to)
            c.stroke(p, with: .color(line), style: StrokeStyle(lineWidth: on ? 4 : 2, dash: e.dashed ? [8, 6] : []))
            let a = atan2(e.to.y - e.from.y, e.to.x - e.from.x)
            var h = Path(); h.move(to: e.to)
            h.addLine(to: CGPoint(x: e.to.x - 14 * cos(a - 0.45), y: e.to.y - 14 * sin(a - 0.45)))
            h.addLine(to: CGPoint(x: e.to.x - 14 * cos(a + 0.45), y: e.to.y - 14 * sin(a + 0.45))); h.closeSubpath()
            c.fill(h, with: .color(line))
            if !e.label.isEmpty {
                c.draw(Text(e.label).font(.system(size: 13, weight: .bold, design: .monospaced)).foregroundColor(ink),
                       at: CGPoint(x: (e.from.x + e.to.x) / 2, y: (e.from.y + e.to.y) / 2 - 14), anchor: .center)
            }
        case "area":
            let r = CGRect(x: e.x, y: e.y, width: e.w, height: e.h)
            c.fill(Path(r), with: .color(on ? AMBER.opacity(0.30) : Color(white: 0.16)))
            c.stroke(Path(r), with: .color(line), lineWidth: on ? 2.5 : 1)
            if !e.label.isEmpty {
                c.draw(Text(e.label).font(.system(size: 14, weight: .bold, design: .monospaced)).foregroundColor(ink),
                       at: CGPoint(x: r.midX, y: r.midY), anchor: .center)
            }
        case "curve":
            guard let f = e.points.first else { return }
            var p = Path(); p.move(to: f); for q in e.points.dropFirst() { p.addLine(to: q) }
            c.stroke(p, with: .color(on ? AMBER : (e.dashed ? Color(white: 0.35) : GREEN)), style: StrokeStyle(lineWidth: 3.5, dash: e.dashed ? [8, 6] : []))
        default:   // note
            c.draw(Text(e.text).font(.system(size: 14, weight: on ? .bold : .regular, design: .monospaced)).foregroundColor(on ? AMBER : GREY),
                   at: CGPoint(x: e.x, y: e.y), anchor: .center)
        }
    }
}
