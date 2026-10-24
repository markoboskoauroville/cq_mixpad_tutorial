// THE READING HIGHLIGHT, the same as MA Reader Web (Marko, 24.10.2026: "I am dyslexic ... My eyes need to be guided";
// "Please don't do letter by letter. Read my application, MA. Read the web. Same highlights.").
// Taken from ~/.maread-web/static/index.html: the sentence being read is a yellow band (--sent #ffd93b) with dark ink
// (--sent-fg #10120a), semibold; the word being said is a red block (--wordbg #e23b4e) with white ink (--wordfg), whole
// words, following Speechify's exact word times. The rest of the text stays as it is. MANTRA_MANIFEST word-timing.md §4a.
import SwiftUI

let SENT_BG = Color(red: 0xFF/255, green: 0xD9/255, blue: 0x3B/255)
let SENT_FG = Color(red: 0x10/255, green: 0x12/255, blue: 0x0A/255)
let WORD_BG = Color(red: 0xE2/255, green: 0x3B/255, blue: 0x4E/255)

struct ReadingText: View {
    let text: String
    let marks: [[Double]]
    let time: Double

    var body: some View {
        Text(attributed).font(.system(size: 21)).lineSpacing(8).fixedSize(horizontal: false, vertical: true)
    }

    private var attributed: AttributedString {
        let t = text.split(whereSeparator: \.isWhitespace).joined(separator: " ")   // the text the marks were made on
        var a = AttributedString(t)
        a.foregroundColor = Color(white: 0.9)
        guard time >= 0, !marks.isEmpty, let m = marks.last(where: { $0[2] <= time + 0.03 }) else { return a }
        let ch = Array(t)
        let w0 = min(Int(m[0]), ch.count), w1 = min(Int(m[1]), ch.count)
        // the one sentence that holds the word (a word's mark may or may not include its full stop, so the sentences
        // are cut once and the word is looked up in them: only one is ever lit; Marko, 24.10.2026: "Only one sentence
        // at a time needs to be highlighted always")
        var sents: [Range<Int>] = [], start = 0
        for k in ch.indices where ".!?".contains(ch[k]) && (k + 1 == ch.count || ch[k + 1] == " ") { sents.append(start..<(k + 1)); start = k + 2 }
        if start < ch.count { sents.append(start..<ch.count) }
        let sent = sents.first { $0.contains(w0) } ?? (w0..<w1)
        let s0 = sent.lowerBound, s1 = sent.upperBound
        func range(_ x: Int, _ y: Int) -> Range<AttributedString.Index>? {
            guard x < y else { return nil }
            return a.index(a.startIndex, offsetByCharacters: x)..<a.index(a.startIndex, offsetByCharacters: y)
        }
        if let r = range(s0, s1) {
            a[r].backgroundColor = SENT_BG; a[r].foregroundColor = SENT_FG
            a[r].font = .system(size: 21, weight: .semibold)
        }
        if let r = range(w0, w1) { a[r].backgroundColor = WORD_BG; a[r].foregroundColor = .white }
        return a
    }
}
