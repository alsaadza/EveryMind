import Foundation

/// Reformats a lesson for different learners *without changing its content*.
///
/// The rule: an adapted version may regroup, reorder within a section, emphasise and label the
/// original sentences, but it may not rewrite them. AI (when used) only returns sentence *indices*
/// plus short labels, and `FidelityReport` proves every original sentence is still present exactly once.
enum LessonAdapter {

    struct SourceSentence: Hashable, Identifiable {
        let id: Int             // global index
        let section: Int
        let paragraph: Int
        let text: String        // original markdown-lite text, untouched
        var plain: String { text.replacingOccurrences(of: "**", with: "") }
    }

    struct Source {
        let sections: [LessonSection]
        let sentences: [SourceSentence]
        let keyTerms: [String]

        init(sections: [LessonSection], extraTerms: [String] = []) {
            self.sections = sections
            var out: [SourceSentence] = []
            for (si, sec) in sections.enumerated() {
                let paras = sec.body.components(separatedBy: "\n\n").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
                for (pi, p) in paras.enumerated() {
                    for s in LessonAdapter.splitKeepingBold(p) {
                        out.append(SourceSentence(id: out.count, section: si, paragraph: pi, text: s))
                    }
                }
            }
            sentences = out
            var terms = extraTerms
            for s in sections {
                for m in s.body.matches(of: /\*\*(.+?)\*\*/) {
                    let t = String(m.1).trimmingCharacters(in: .punctuationCharacters)
                    if t.count <= 40, !terms.contains(where: { $0.caseInsensitiveCompare(t) == .orderedSame }) { terms.append(t) }
                }
            }
            keyTerms = terms
        }
    }

    /// Splits a paragraph into sentences without breaking inside **bold** spans or decimals like 0.5.
    static func splitKeepingBold(_ p: String) -> [String] {
        let parts = EssayCoach.splitSentences(p)
        // Merge back any split that left an unbalanced ** marker.
        var out: [String] = []
        var buffer = ""
        for part in parts {
            buffer = buffer.isEmpty ? part : buffer + " " + part
            if buffer.components(separatedBy: "**").count % 2 == 1 { out.append(buffer); buffer = "" }
        }
        if !buffer.isEmpty { out.append(buffer) }
        return out
    }

    // MARK: Chunked (Focus)

    struct Chunk: Identifiable, Hashable {
        let id: Int
        let section: Int
        let heading: String
        let sentenceIDs: [Int]
        var label: String?            // optional short AI label, shown as such
        var isLastInSection: Bool
    }

    static func chunks(_ src: Source, size: Int, plan: StructurePlan? = nil) -> [Chunk] {
        if let plan, let groups = plan.chunks, validPartition(groups, src) {
            return groups.enumerated().map { i, g in
                let sec = src.sentences[g[0]].section
                let nextSec = i + 1 < groups.count ? src.sentences[groups[i + 1][0]].section : -1
                return Chunk(id: i, section: sec, heading: src.sections[sec].heading, sentenceIDs: g, label: plan.labels?[safe: i], isLastInSection: nextSec != sec)
            }
        }
        var out: [Chunk] = []
        let n = max(1, size)
        for (si, sec) in src.sections.enumerated() {
            let ss = src.sentences.filter { $0.section == si }
            // Never let a chunk cross a paragraph boundary: paragraphs are meaningful units.
            var groups: [[Int]] = []
            for p in Set(ss.map(\.paragraph)).sorted() {
                let ids = ss.filter { $0.paragraph == p }.map(\.id)
                stride(from: 0, to: ids.count, by: n).forEach { groups.append(Array(ids[$0..<min(ids.count, $0 + n)])) }
            }
            for (gi, g) in groups.enumerated() {
                out.append(Chunk(id: out.count, section: si, heading: sec.heading, sentenceIDs: g, label: nil, isLastInSection: gi == groups.count - 1))
            }
        }
        return out
    }

    static func validPartition(_ groups: [[Int]], _ src: Source) -> Bool {
        let flat = groups.flatMap { $0 }
        return !groups.contains(where: \.isEmpty) && flat.sorted() == Array(0..<src.sentences.count)
    }

    // MARK: Visual

    enum VisualBlock: Hashable, Identifiable {
        case term(term: String, sentence: Int, symbol: String)
        case steps(title: String, sentences: [Int])
        case fact(figure: String, sentence: Int)
        case idea(sentence: Int, symbol: String)
        var id: String {
            switch self {
            case .term(let t, let s, _): return "t\(s)\(t)"
            case .steps(_, let s): return "s\(s.first ?? -1)"
            case .fact(_, let s): return "f\(s)"
            case .idea(let s, _): return "i\(s)"
            }
        }
        var sentenceIDs: [Int] {
            switch self {
            case .term(_, let s, _), .fact(_, let s), .idea(let s, _): return [s]
            case .steps(_, let s): return s
            }
        }
    }

    struct VisualSection: Identifiable, Hashable {
        let id: Int
        let heading: String
        let symbol: String
        let blocks: [VisualBlock]
        let illustration: Illustration?
    }

    static let sequenceWords = [#"^first\b"#, #"^then\b"#, #"^next\b"#, #"^after\b"#, #"^finally\b"#, #"^when\b"#, #"^once\b"#, #"^eventually\b"#, #"^later\b"#, #"^step\b"#, #"^second\b"#, #"^third\b"#, #"^afterwards?\b"#, #"^as (the|it|they)\b"#]

    static func visual(_ src: Source, plan: StructurePlan? = nil) -> [VisualSection] {
        var sections: [VisualSection] = []
        for (si, sec) in src.sections.enumerated() {
            let ss = src.sentences.filter { $0.section == si }
            var used = Set<Int>()
            // Process steps: a run of 2+ consecutive sentences that start with sequence words,
            // or that the AI plan marked as steps.
            let planned = Set(plan?.steps ?? [])
            var run: [Int] = []
            var pendingBlocks: [(Int, VisualBlock)] = []
            for s in ss {
                let lower = s.plain.lowercased()
                let isStep = planned.contains(s.id) || sequenceWords.contains { lower.range(of: $0, options: .regularExpression) != nil }
                if isStep { run.append(s.id) } else { if run.count >= 2 { pendingBlocks.append((run[0], .steps(title: "In order", sentences: run))); used.formUnion(run) }; run = [] }
            }
            if run.count >= 2 { pendingBlocks.append((run[0], .steps(title: "In order", sentences: run))); used.formUnion(run) }

            for s in ss where !used.contains(s.id) {
                if let term = definedTerm(s, src.keyTerms) {
                    pendingBlocks.append((s.id, .term(term: term, sentence: s.id, symbol: symbol(for: s.plain, fallback: "character.book.closed"))))
                } else if let fig = figure(in: s.plain) {
                    pendingBlocks.append((s.id, .fact(figure: fig, sentence: s.id)))
                } else {
                    pendingBlocks.append((s.id, .idea(sentence: s.id, symbol: symbol(for: s.plain, fallback: "lightbulb"))))
                }
                used.insert(s.id)
            }
            let blocks = pendingBlocks.sorted { $0.0 < $1.0 }.map(\.1)
            sections.append(VisualSection(id: si, heading: sec.heading, symbol: symbol(for: sec.heading + " " + sec.body, fallback: "book.closed"), blocks: blocks, illustration: sec.illustration))
        }
        return sections
    }

    /// "A **sample space** is…", "Evaporation is…", "X means…": the sentence defines a key term.
    static func definedTerm(_ s: SourceSentence, _ terms: [String]) -> String? {
        let p = s.plain
        for t in terms where p.range(of: t, options: .caseInsensitive) != nil {
            let pattern = "\\b" + NSRegularExpression.escapedPattern(for: t) + "\\b[^.]{0,40}\\b(is|are|means|refers to|is called|are called)\\b"
            if p.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil { return t.capitalizedFirst }
            let called = "\\b(is|are) (called|known as) (an? |the )?" + NSRegularExpression.escapedPattern(for: t)
            if p.range(of: called, options: [.regularExpression, .caseInsensitive]) != nil { return t.capitalizedFirst }
        }
        return nil
    }

    /// Pulls the most "visual" number out of a sentence: a fraction, percent or number with a unit.
    static func figure(in s: String) -> String? {
        let patterns = [#"\d+(\.\d+)?\s?%"#, #"\b\d+\s?/\s?\d+\b"#, #"\b\d+(\.\d+)?\s?(out of|in)\s?\d+\b"#, #"\b\d{1,3}(,\d{3})+\b"#, #"\b\d+(\.\d+)?\s?(percent|degrees|°C|°F|km|miles|years|minutes|hours|days|million|billion)\b"#, #"\b\d+(\.\d+)?\b"#]
        for p in patterns {
            if let r = s.range(of: p, options: [.regularExpression, .caseInsensitive]) {
                let f = String(s[r])
                if p == patterns.last, (Int(f) ?? 0) < 2 { continue }  // skip trivial "1"
                return f
            }
        }
        return nil
    }

    static func symbol(for text: String, fallback: String) -> String {
        let l = text.lowercased()
        let table: [(String, String)] = [
            ("rain", "cloud.rain"), ("cloud", "cloud"), ("evapor", "sun.max"), ("sun", "sun.max"), ("ocean", "water.waves"), ("water", "drop"),
            ("snow", "snowflake"), ("ice", "snowflake"), ("river", "water.waves"), ("plant", "leaf"), ("tree", "tree"),
            ("coin", "centsign.circle"), ("dice", "dice"), ("die ", "dice"), ("card", "suit.spade"), ("spinner", "circle.dashed"),
            ("probab", "percent"), ("chance", "percent"), ("likely", "chart.bar"), ("experiment", "flask"), ("trial", "repeat"),
            ("fraction", "circle.lefthalf.filled"), ("pizza", "circle.grid.cross"), ("divide", "divide"), ("equal", "equal"),
            ("number", "number"), ("sleep", "bed.double"), ("time", "clock"), ("school", "building.columns"), ("history", "scroll"),
            ("cell", "circle.hexagongrid"), ("energy", "bolt"), ("heat", "thermometer.sun"), ("temperature", "thermometer.medium"),
            ("cycle", "arrow.triangle.2.circlepath"), ("example", "lightbulb"), ("remember", "brain"), ("question", "questionmark.circle"),
            ("people", "person.2"), ("city", "building.2"), ("vote", "checkmark.seal"), ("write", "pencil"), ("read", "book")
        ]
        return table.first { l.contains($0.0) }?.1 ?? fallback
    }

    // MARK: AI structure plan

    /// What an AI is allowed to return for a reformat: indices and short labels only.
    struct StructurePlan: Codable, Hashable {
        var chunks: [[Int]]?
        var labels: [String]?
        var steps: [Int]?
    }

    // MARK: Fidelity

    struct FidelityReport: Hashable {
        var sentencesTotal: Int
        var sentencesPresent: Int
        var duplicated: Int
        var numbersTotal: Int
        var numbersPresent: Int
        var termsTotal: Int
        var termsPresent: Int
        var aiLabels: Int
        var passed: Bool { sentencesPresent == sentencesTotal && duplicated == 0 && numbersPresent == numbersTotal && termsPresent == termsTotal }
        var summary: String {
            passed ? "All \(sentencesTotal) sentences, \(numbersTotal) \(numbersTotal == 1 ? "figure" : "figures") and \(termsTotal) key \(termsTotal == 1 ? "term" : "terms") from the original are here, word for word."
                   : "Missing \(sentencesTotal - sentencesPresent) sentence(s), \(numbersTotal - numbersPresent) figure(s), \(termsTotal - termsPresent) term(s)."
        }
    }

    /// Verifies that `adaptedSentenceIDs` (in display order) reproduce the original exactly once each,
    /// and that every number and key term in the original still appears in the adapted text.
    static func fidelity(_ src: Source, adaptedSentenceIDs: [Int], aiLabels: Int = 0) -> FidelityReport {
        let counts = Dictionary(adaptedSentenceIDs.map { ($0, 1) }, uniquingKeysWith: +)
        let present = src.sentences.filter { counts[$0.id] != nil }.count
        let dup = counts.values.filter { $0 > 1 }.count
        let originalText = src.sentences.map(\.plain).joined(separator: " ")
        let adaptedText = adaptedSentenceIDs.compactMap { id in src.sentences.first { $0.id == id }?.plain }.joined(separator: " ")
        let nums = numbers(in: originalText)
        let adaptedNums = numbers(in: adaptedText)
        let numPresent = nums.filter { n in adaptedNums.contains(n) }.count
        let terms = src.keyTerms
        let termPresent = terms.filter { adaptedText.range(of: $0, options: .caseInsensitive) != nil }.count
        return FidelityReport(sentencesTotal: src.sentences.count, sentencesPresent: present, duplicated: dup,
                              numbersTotal: nums.count, numbersPresent: numPresent, termsTotal: terms.count, termsPresent: termPresent, aiLabels: aiLabels)
    }

    static func numbers(in s: String) -> [String] {
        s.matches(of: /\d+(?:[.,\/]\d+)?%?/).map { String($0.0) }
    }

    static func visualOrder(_ v: [VisualSection]) -> [Int] { v.flatMap { $0.blocks.flatMap(\.sentenceIDs) } }
    static func chunkOrder(_ c: [Chunk]) -> [Int] { c.flatMap(\.sentenceIDs) }
}

extension String {
    var capitalizedFirst: String { prefix(1).uppercased() + dropFirst() }
}

extension Array {
    subscript(safe i: Int) -> Element? { indices.contains(i) ? self[i] : nil }
}
