import SwiftUI
import UIKit

/// The essay as a selectable, non-editable text view with comment anchors highlighted.
/// Teachers can tap a highlight to focus its comment, or select any words to add their own.
struct EssayTextView: UIViewRepresentable {
    var text: String
    var comments: [FeedbackComment]
    var selectedID: UUID?
    var fontSize: CGFloat = 19
    var onTapComment: (UUID) -> Void = { _ in }
    var onSelect: (String) -> Void = { _ in }

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.isEditable = false
        tv.isSelectable = true
        tv.backgroundColor = .clear
        tv.textContainerInset = UIEdgeInsets(top: 8, left: 0, bottom: 80, right: 0)
        tv.textContainer.lineFragmentPadding = 0
        tv.delegate = context.coordinator
        tv.adjustsFontForContentSizeCategory = true
        tv.accessibilityIdentifier = "essay-text"
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.tapped(_:)))
        tap.delegate = context.coordinator
        tv.addGestureRecognizer(tap)
        return tv
    }

    func updateUIView(_ tv: UITextView, context: Context) {
        context.coordinator.parent = self
        let key = "\(text.hashValue)-\(comments.map { "\($0.id)\($0.state.rawValue)" }.joined())-\(selectedID?.uuidString ?? "")-\(tv.traitCollection.userInterfaceStyle.rawValue)"
        guard key != context.coordinator.lastKey else { return }
        context.coordinator.lastKey = key
        let sel = tv.selectedRange
        let (text, ranges) = attributed(style: tv.traitCollection)
        context.coordinator.ranges = ranges
        tv.attributedText = text
        if sel.length > 0 { tv.selectedRange = sel }
        if let id = selectedID, let r = context.coordinator.ranges[id] {
            DispatchQueue.main.async { tv.scrollRangeToVisible(r) }
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func attributed(style: UITraitCollection) -> (NSAttributedString, [UUID: NSRange]) {
        let font = UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont(name: Typeface.serif, size: fontSize) ?? .systemFont(ofSize: fontSize))
        let para = NSMutableParagraphStyle()
        para.lineSpacing = 9
        para.paragraphSpacing = 2
        let ink = UIColor(Palette.ink).resolvedColor(with: style)
        let s = NSMutableAttributedString(string: text, attributes: [.font: font, .paragraphStyle: para, .foregroundColor: ink])
        var ranges: [UUID: NSRange] = [:]
        let ns = text as NSString
        for c in comments where c.state != .rejected {
            var r = ns.range(of: c.quote)
            if r.location == NSNotFound { r = ns.range(of: c.quote, options: .caseInsensitive) }
            guard r.location != NSNotFound else { continue }
            ranges[c.id] = r
            let base = UIColor(Self.color(for: c.kind)).resolvedColor(with: style)
            let selected = c.id == selectedID
            s.addAttribute(.backgroundColor, value: base.withAlphaComponent(selected ? 0.32 : (c.state == .approved ? 0.10 : 0.16)), range: r)
            if selected {
                s.addAttribute(.underlineStyle, value: NSUnderlineStyle.thick.rawValue, range: r)
                s.addAttribute(.underlineColor, value: base, range: r)
            }
        }
        return (s, ranges)
    }

    static func color(for k: CommentKind) -> Color {
        switch k {
        case .strength: return Palette.forest
        case .suggestion: return Palette.ochre
        case .question: return Palette.slate
        case .conventions: return Palette.terracotta
        }
    }

    final class Coordinator: NSObject, UITextViewDelegate, UIGestureRecognizerDelegate {
        var parent: EssayTextView
        var lastKey = ""
        var ranges: [UUID: NSRange] = [:]
        init(_ p: EssayTextView) { parent = p }

        @objc func tapped(_ g: UITapGestureRecognizer) {
            guard let tv = g.view as? UITextView else { return }
            var pt = g.location(in: tv)
            pt.x -= tv.textContainerInset.left; pt.y -= tv.textContainerInset.top
            let idx = tv.layoutManager.characterIndex(for: pt, in: tv.textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
            // Smallest highlight containing the tap wins.
            if let hit = ranges.filter({ NSLocationInRange(idx, $0.value) }).min(by: { $0.value.length < $1.value.length }) {
                parent.onTapComment(hit.key)
            }
        }

        func gestureRecognizer(_ g: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool { true }

        func textViewDidChangeSelection(_ tv: UITextView) {
            let r = tv.selectedRange
            let s = r.length > 0 ? (tv.text as NSString).substring(with: r) : ""
            parent.onSelect(s.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }
}
