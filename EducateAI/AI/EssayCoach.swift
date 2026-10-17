import Foundation
import NaturalLanguage
import UIKit

/// On-device essay feedback drafter. Every comment it writes is anchored to the student's
/// exact words, framed for the student ("you"), and is only a *draft*: nothing reaches the
/// student until a teacher approves it.
enum EssayCoach {

    // MARK: Text structure

    struct Sentence { let text: String; let paragraph: Int; let indexInParagraph: Int; var words: [String] }

    static func paragraphs(_ text: String) -> [String] {
        text.components(separatedBy: "\n").map { $0.trimmingCharacters(in: .whitespaces) }
            .split(whereSeparator: \.isEmpty)
            .map { $0.joined(separator: " ") }
    }

    static func sentences(_ text: String) -> [Sentence] {
        var out: [Sentence] = []
        for (pi, para) in paragraphs(text).enumerated() {
            for (si, s) in splitSentences(para).enumerated() {
                out.append(Sentence(text: s, paragraph: pi, indexInParagraph: si, words: words(s)))
            }
        }
        return out
    }

    static func splitSentences(_ text: String) -> [String] {
        let tok = NLTokenizer(unit: .sentence)
        tok.string = text
        var out: [String] = []
        tok.enumerateTokens(in: text.startIndex..<text.endIndex) { r, _ in
            let s = text[r].trimmingCharacters(in: .whitespacesAndNewlines)
            if !s.isEmpty { out.append(s) }
            return true
        }
        return out
    }

    static func words(_ s: String) -> [String] {
        s.lowercased().split(whereSeparator: { !$0.isLetter && $0 != "'" && !$0.isNumber }).map(String.init)
    }

    static func contains(_ s: String, any patterns: [String]) -> Bool {
        let l = " " + s.lowercased() + " "
        return patterns.contains { l.range(of: $0, options: .regularExpression) != nil }
    }

    // MARK: Signals

    static let claimPatterns = [#"\bshould\b"#, #"\bmust\b"#, #"\bneeds? to\b"#, #"\bought to\b"#, #"\bi (strongly )?believe\b"#, #"\bi think\b"#, #"\bit is clear\b"#, #"\bwould be (better|best)\b"#, #"\bis the (better|right) choice\b"#, #"\bshould not\b"#]
    /// "Should be talked about", "important topic": sounds like a claim but takes no position.
    static let vagueClaimPatterns = [#"should be (talked|discussed|considered|thought) about"#, #"should be (discussed|considered|debated)"#, #"\bimportant (topic|issue|question)\b"#, #"\bopinions about\b"#, #"\bboth sides\b"#, #"\bthere are (many|a lot of) (reasons|opinions|views)\b"#]
    /// Specific evidence: statistics, dated studies or named sources. Clock times ("7:45") don't count.
    static let evidenceSpecific = [#"\d+(\.\d+)?\s?%"#, #"\b\d+(\.\d+)?\s?(percent|hours|minutes|students|teens|teenagers|schools|districts|times|million|thousand)\b"#, #"\b(19|20)\d{2}\b"#, #"\baccording to\b"#, #"\bacademy\b"#, #"\bcdc\b"#, #"\buniversity\b"#, #"\bsurvey\b"#, #"\bstudy (by|from|in|at)\b"#, #"\bresearchers?\b"#, #"\bfound that\b"#, #"\breported\b"#, #"\bpolicy\b"#, #"\bdistrict\b"#, #"\brecommends?\b"#]
    static let evidenceVague = [#"\bstudies show\b"#, #"\bresearch shows\b"#, #"\bscientists say\b"#, #"\bexperts say\b"#, #"\beveryone knows\b"#, #"\bstudies say\b"#]
    static let counterPatterns = [#"\bsome people\b"#, #"\bothers (argue|say|think|believe)\b"#, #"\bcritics\b"#, #"\bopponents\b"#, #"\bon the other hand\b"#, #"\bsome (may|might) (say|argue)\b"#, #"\bpeople (may|might|could) (say|argue)\b"#, #"\bwhile it is true\b"#, #"\bit is true that\b"#, #"\bsome argue\b"#, #"\bthose who\b"#]
    static let rebuttalPatterns = [#"\bhowever\b"#, #"\bbut\b"#, #"\byet\b"#, #"\bstill\b"#, #"\beven so\b"#, #"\bnevertheless\b"#, #"\bthat said\b"#]
    static let reasoningPatterns = [#"\bbecause\b"#, #"\bthis means\b"#, #"\bwhich means\b"#, #"\btherefore\b"#, #"\bas a result\b"#, #"\bthis shows\b"#, #"\bso that\b"#, #"\bthis is why\b"#, #"\bwhich leads\b"#, #"\bconsequently\b"#]
    static let transitionPatterns = [#"^first"#, #"^second"#, #"^third"#, #"^finally"#, #"^furthermore"#, #"^in addition"#, #"^additionally"#, #"^moreover"#, #"^another"#, #"^also,"#, #"^for example"#, #"^for instance"#, #"^most importantly"#]
    static let conclusionPatterns = [#"^in conclusion"#, #"^to conclude"#, #"^overall"#, #"^in the end"#, #"^to sum up"#, #"^in summary"#, #"^ultimately"#, #"^all in all"#]
    static let fillerWords: Set<String> = ["really", "very", "so", "stuff", "things", "alot", "basically", "literally", "like"]

    struct Analysis {
        var sentences: [Sentence]
        var paragraphCount: Int
        var wordCount: Int
        var thesis: Sentence?
        var vagueOpening: Sentence?
        var specificEvidence: [Sentence]
        var vagueEvidence: [Sentence]
        var counter: Sentence?
        var rebuttal: Sentence?
        var reasoning: [Sentence]
        var transitions: [Sentence]
        var conclusion: Sentence?
        var longSentences: [Sentence]
        var filler: (word: String, count: Int, first: Sentence)?
        var misspellings: [(word: String, suggestion: String?)]
        var lowercaseI: String?
    }

    static func analyze(_ text: String) -> Analysis {
        let ss = sentences(text)
        let paras = paragraphs(text)
        let firstPara = ss.filter { $0.paragraph == 0 }
        func isClaim(_ s: Sentence) -> Bool { contains(s.text, any: claimPatterns) && !contains(s.text, any: vagueClaimPatterns) }
        let thesis = firstPara.last(where: isClaim) ?? ss.first(where: isClaim)
        let vagueOpening = firstPara.first(where: { contains($0.text, any: vagueClaimPatterns) })
        let specific = ss.filter { contains($0.text, any: evidenceSpecific) && !contains($0.text, any: evidenceVague) && $0.words.count > 6 }
        let vague = ss.filter { contains($0.text, any: evidenceVague) }
        var counter: Sentence?, rebuttal: Sentence?
        for (i, s) in ss.enumerated() where i > 0 && contains(s.text, any: counterPatterns) {
            counter = s
            rebuttal = ss[(i)..<min(ss.count, i + 3)].first(where: { contains($0.text, any: rebuttalPatterns) && $0.text != s.text })
                ?? (contains(s.text, any: [#"\bbut\b"#, #"\bhowever\b"#]) ? s : nil)
            break
        }
        let reasoning = ss.filter { contains($0.text, any: reasoningPatterns) }
        let transitions = ss.filter { contains($0.text.lowercased(), any: transitionPatterns.map { $0.replacingOccurrences(of: "^", with: "^ ") }) }
        let conclusion = ss.last(where: { $0.paragraph == paras.count - 1 && paras.count > 1 && contains($0.text.lowercased(), any: conclusionPatterns.map { $0.replacingOccurrences(of: "^", with: "^ ") }) })
        let long = ss.filter { $0.words.count >= 40 }.sorted { $0.words.count > $1.words.count }

        var counts: [String: Int] = [:]
        var firstSentence: [String: Sentence] = [:]
        for s in ss { for w in s.words where fillerWords.contains(w) { counts[w, default: 0] += 1; if firstSentence[w] == nil { firstSentence[w] = s } } }
        let topFiller = counts.filter { $0.value >= 4 && $0.key != "like" && $0.key != "so" }.max { $0.value < $1.value }
        let filler = topFiller.map { (word: $0.key, count: $0.value, first: firstSentence[$0.key]!) }

        // Lowercase pronoun "i"
        var lowerI: String?
        if let r = text.range(of: #"(\b\w+ )?\bi\b( \w+)?"#, options: .regularExpression) {
            let frag = String(text[r])
            if frag.split(separator: " ").contains("i") { lowerI = frag }
        }

        return Analysis(sentences: ss, paragraphCount: paras.count, wordCount: ss.reduce(0) { $0 + $1.words.count },
                        thesis: thesis, vagueOpening: vagueOpening, specificEvidence: specific, vagueEvidence: vague, counter: counter, rebuttal: rebuttal,
                        reasoning: reasoning, transitions: transitions, conclusion: conclusion, longSentences: long,
                        filler: filler, misspellings: misspellings(text), lowercaseI: lowerI)
    }

    /// Real spellcheck via the system dictionary, so the offline engine never invents errors.
    static func misspellings(_ text: String) -> [(word: String, suggestion: String?)] {
        let checker = UITextChecker()
        let ns = text as NSString
        var out: [(String, String?)] = []
        var seen = Set<String>()
        var offset = 0
        while offset < ns.length {
            let r = checker.rangeOfMisspelledWord(in: text, range: NSRange(location: 0, length: ns.length), startingAt: offset, wrap: false, language: "en_US")
            guard r.location != NSNotFound else { break }
            let w = ns.substring(with: r)
            offset = r.location + r.length
            // Skip capitalised words (likely names) and very short tokens.
            if w.first?.isUppercase == true || w.count < 3 || seen.contains(w.lowercased()) { continue }
            seen.insert(w.lowercased())
            let fixes: [String: String] = ["alot": "a lot", "becuase": "because", "definately": "definitely", "teh": "the", "tird": "tired", "untill": "until", "wich": "which", "thier": "their", "recieve": "receive", "beleive": "believe"]
            let guess = fixes[w.lowercased()] ?? checker.guesses(forWordRange: r, in: text, language: "en_US")?.first
            out.append((w, guess))
        }
        return out
    }

    // MARK: Drafting

    static func draft(essay: String, rubric: [RubricCriterion], minWords: Int = 0) -> EssayFeedback {
        let a = analyze(essay)
        var comments: [FeedbackComment] = []
        func crit(_ keys: [String]) -> UUID? {
            rubric.first { c in keys.contains { c.name.lowercased().contains($0) } }?.id
        }
        let claimC = crit(["claim", "thesis", "position", "argument", "idea"])
        let evidenceC = crit(["evidence", "support", "source"])
        let reasoningC = crit(["reason", "analysis", "counter", "explain", "insight"])
        let orgC = crit(["organ", "structure", "flow"])
        let convC = crit(["convention", "grammar", "language", "style", "mechanic"])

        // Claim
        if let v = a.vagueOpening, a.thesis == nil || a.thesis!.paragraph > 0 {
            comments.append(.init(quote: v.text, kind: .question, criterionID: claimC,
                draft: "You tell the reader this topic matters, but not what you think about it. What is your position? Try finishing the sentence \"Our school should…\" and put it at the end of this paragraph."))
            if let t = a.thesis {
                comments.append(.init(quote: t.text, kind: .suggestion, criterionID: claimC,
                    draft: "Here is your actual position, in paragraph \(t.paragraph + 1). Move it up to your introduction so every paragraph after it has a job."))
            }
        } else if let t = a.thesis {
            if t.paragraph == 0 {
                comments.append(.init(quote: t.text, kind: .strength, criterionID: claimC,
                    draft: "Your position is clear and it comes early, so the reader knows exactly what you are arguing from the start."))
            } else {
                comments.append(.init(quote: t.text, kind: .suggestion, criterionID: claimC,
                    draft: "This is your main claim, but it doesn't appear until paragraph \(t.paragraph + 1). Try stating it in your introduction so every paragraph after it has a job."))
            }
        } else if let first = a.sentences.first {
            comments.append(.init(quote: first.text, kind: .question, criterionID: claimC,
                draft: "What is your position? Try writing it as one clear sentence (for example, \"Our school should…\") and put it at the end of this first paragraph."))
        }

        // Evidence
        if let best = a.specificEvidence.max(by: { $0.words.count < $1.words.count }) {
            comments.append(.init(quote: best.text, kind: .strength, criterionID: evidenceC,
                draft: "Specific evidence like this, with a source or a number, makes your argument much harder to dismiss."))
        }
        if let v = a.vagueEvidence.first {
            comments.append(.init(quote: v.text, kind: .question, criterionID: evidenceC,
                draft: "Which studies? Naming who did the research and what they found would turn this into evidence your reader can trust."))
        } else if a.specificEvidence.isEmpty, let body = a.sentences.first(where: { $0.paragraph == 1 }) ?? a.sentences.dropFirst().first {
            comments.append(.init(quote: body.text, kind: .suggestion, criterionID: evidenceC,
                draft: "This point leans on personal experience. Can you add a fact, a statistic or an expert source that backs it up? Personal stories work best alongside evidence."))
        }

        // Reasoning & counterargument
        if let c = a.counter {
            if let r = a.rebuttal {
                comments.append(.init(quote: c.text == r.text ? c.text : r.text, kind: .strength, criterionID: reasoningC,
                    draft: "You take the other side seriously and then answer it. That is what makes an argument persuasive rather than one-sided."))
            } else {
                comments.append(.init(quote: c.text, kind: .suggestion, criterionID: reasoningC,
                    draft: "You raise the other side here. Add a sentence or two explaining why your position still holds, so the counterargument works for you."))
            }
        } else if let anchor = a.sentences.last(where: { $0.paragraph == max(0, a.paragraphCount - 2) && $0.indexInParagraph == 0 }) ?? a.sentences.last {
            comments.append(.init(quote: anchor.text, kind: .question, criterionID: reasoningC,
                draft: "The prompt asks you to address a counterargument. What would someone who disagrees with you say, and how would you answer them?"))
        }
        if a.counter == nil || a.rebuttal == nil, let r = a.reasoning.first(where: { s in !comments.contains { $0.quote == s.text } }) {
            comments.append(.init(quote: r.text, kind: .strength, criterionID: reasoningC,
                draft: "Good reasoning. You don't just state a point, you explain why it matters."))
        }

        // Organisation
        if a.paragraphCount < 3, let longestPara = (0..<a.paragraphCount).max(by: { p1, p2 in
            a.sentences.filter { $0.paragraph == p1 }.count < a.sentences.filter { $0.paragraph == p2 }.count }),
           let anchor = a.sentences.first(where: { $0.paragraph == longestPara }) {
            comments.append(.init(quote: anchor.text, kind: .suggestion, criterionID: orgC,
                draft: "This paragraph carries several ideas at once. Try giving each reason its own paragraph with a topic sentence, so the reader can follow your argument step by step."))
        } else if a.conclusion == nil, let last = a.sentences.last, a.paragraphCount >= 3 {
            comments.append(.init(quote: last.text, kind: .suggestion, criterionID: orgC,
                draft: "Your essay stops here rather than concluding. End by returning to your claim and telling the reader why it matters."))
        } else if let t = a.transitions.dropFirst().first ?? a.transitions.first {
            comments.append(.init(quote: t.text, kind: .strength, criterionID: orgC,
                draft: "Clear transitions like this one guide your reader from one reason to the next."))
        }

        // A body paragraph that tries to do too much usually drifts from the claim.
        let bodyParas = (1..<max(1, a.paragraphCount - 1))
        if a.paragraphCount >= 3, let crowded = bodyParas.first(where: { p in a.sentences.filter { $0.paragraph == p }.count >= 7 }),
           let anchor = a.sentences.first(where: { $0.paragraph == crowded }), !comments.contains(where: { $0.quote == anchor.text }) {
            comments.append(.init(quote: anchor.text, kind: .suggestion, criterionID: orgC,
                draft: "This paragraph covers a lot of ground. Which sentences directly support your claim? Keep those, and cut or move the details that wander off topic."))
        }

        // Conventions (max two comments)
        var conv = 0
        if let l = a.longSentences.first, conv < 2 {
            comments.append(.init(quote: l.text, kind: .conventions, criterionID: convC,
                draft: "This sentence is \(l.words.count) words long. Try splitting it into two or three sentences so each idea lands on its own."))
            conv += 1
        }
        if !a.misspellings.isEmpty, conv < 2 {
            let list = a.misspellings.prefix(5).map { m in m.suggestion.map { "\(m.word) → \($0)" } ?? m.word }.joined(separator: ", ")
            comments.append(.init(quote: a.misspellings[0].word, kind: .conventions, criterionID: convC,
                draft: "Check the spelling of a few words: \(list). Reading your essay aloud can help you catch these."))
            conv += 1
        }
        if let li = a.lowercaseI, conv < 2 {
            comments.append(.init(quote: li, kind: .conventions, criterionID: convC,
                draft: "When \"I\" refers to yourself, it is always a capital letter."))
            conv += 1
        }
        if let f = a.filler, conv < 2 {
            comments.append(.init(quote: f.first.text, kind: .conventions, criterionID: convC,
                draft: "You use \"\(f.word)\" \(f.count) times. Try swapping some for a more precise word, or cutting them. \"Exhausted\" is stronger than \"\(f.word) tired\"."))
            conv += 1
        }

        // Make sure there are at least two strengths, so feedback stays motivating.
        if comments.filter({ $0.kind == .strength }).count < 2,
           let vivid = a.sentences.first(where: { s in s.words.contains("i") && s.words.count > 10 && !comments.contains { $0.quote == s.text } }) {
            comments.append(.init(quote: vivid.text, kind: .strength, criterionID: evidenceC ?? claimC,
                draft: "This personal detail helps your reader picture the problem. It gives your argument a human voice."))
        }

        // Always offer at least one next step, so strong writers keep growing too.
        if !comments.contains(where: { $0.kind == .suggestion || $0.kind == .question }) {
            let target = a.specificEvidence.last ?? a.reasoning.last ?? a.sentences.dropFirst().first
            if let t = target {
                comments.append(.init(quote: t.text, kind: .question, criterionID: reasoningC ?? evidenceC,
                    draft: "To push this further: what does this prove about your claim? Add a sentence that spells out the connection for your reader."))
            }
        }

        // Scores
        let scores: [CriterionScore] = rubric.map { c in score(c, a, minWords: minWords) }

        // Summary
        let strengths = comments.filter { $0.kind == .strength }
        let glow = strengths.first.map { summaryGlow($0, a) } ?? "You took on a hard question and wrote a complete response."
        let grow = summaryGrow(a)

        let ordered = comments.enumerated().sorted { l, r in
            (essay.range(of: l.element.quote)?.lowerBound ?? essay.endIndex, l.offset) < (essay.range(of: r.element.quote)?.lowerBound ?? essay.endIndex, r.offset)
        }.map(\.element)
        return EssayFeedback(comments: ordered, scores: scores, glow: glow, grow: grow, generatedBy: "On-device feedback engine")
    }

    static func score(_ c: RubricCriterion, _ a: Analysis, minWords: Int) -> CriterionScore {
        let n = c.name.lowercased()
        func q(_ s: Sentence?) -> String { s.map { "\"\(String($0.text.prefix(80)))\($0.text.count > 80 ? "…" : "")\"" } ?? "" }
        if ["claim", "thesis", "position", "argument"].contains(where: n.contains) {
            guard let t = a.thesis else { return .init(criterionID: c.id, suggested: 0, rationale: "No clear claim sentence was found.") }
            let explicitReasons = t.text.lowercased().contains("because") || t.text.contains(",")
            let lvl = t.paragraph == 0 ? (explicitReasons ? 3 : 2) : 1
            return .init(criterionID: c.id, suggested: lvl, rationale: "Claim found in paragraph \(t.paragraph + 1): \(q(t))\(explicitReasons ? " It previews reasons." : "")")
        }
        if ["evidence", "support", "source"].contains(where: n.contains) {
            let k = a.specificEvidence.count
            let lvl = k >= 3 ? 3 : k == 2 ? 2 : (k == 1 || !a.vagueEvidence.isEmpty) ? 1 : 0
            return .init(criterionID: c.id, suggested: lvl, rationale: "\(k) sentence\(k == 1 ? "" : "s") with specific evidence (numbers or named sources); \(a.vagueEvidence.count) vague (\"studies show\").")
        }
        if ["reason", "analysis", "counter", "explain", "insight"].contains(where: n.contains) {
            let hasCounter = a.counter != nil, hasRebut = a.rebuttal != nil
            let r = a.reasoning.count
            let lvl = (hasCounter && hasRebut && r >= 2) ? 3 : (hasCounter || r >= 2) ? 2 : r >= 1 ? 1 : 0
            return .init(criterionID: c.id, suggested: lvl, rationale: "\(r) explanation link\(r == 1 ? "" : "s") (because, this means…). Counterargument: \(hasCounter ? (hasRebut ? "raised and answered" : "raised, not answered") : "not addressed").")
        }
        if ["organ", "structure", "flow"].contains(where: n.contains) {
            let p = a.paragraphCount, t = a.transitions.count, concl = a.conclusion != nil
            let crowded = (1..<max(1, p - 1)).contains { q in a.sentences.filter { $0.paragraph == q }.count >= 7 }
            let lvl = (p >= 4 && t >= 2 && concl && !crowded) ? 3 : p >= 3 ? 2 : p == 2 ? 1 : 0
            return .init(criterionID: c.id, suggested: lvl, rationale: "\(p) paragraph\(p == 1 ? "" : "s"), \(t) transition\(t == 1 ? "" : "s"), \(concl ? "clear conclusion" : "no clear conclusion").")
        }
        if ["convention", "grammar", "language", "style", "mechanic"].contains(where: n.contains) {
            let errors = a.misspellings.count + (a.lowercaseI == nil ? 0 : 2) + a.longSentences.count + (a.filler == nil ? 0 : 1)
            let lvl = errors <= 1 ? 3 : errors <= 3 ? 2 : errors <= 6 ? 1 : 0
            return .init(criterionID: c.id, suggested: lvl, rationale: "\(a.misspellings.count) spelling issue\(a.misspellings.count == 1 ? "" : "s"), \(a.longSentences.count) very long sentence\(a.longSentences.count == 1 ? "" : "s")\(a.lowercaseI == nil ? "" : ", lowercase \"i\"")\(a.filler.map { ", \"\($0.word)\" ×\($0.count)" } ?? "").")
        }
        // Unknown criterion: length and development as a cautious proxy.
        let dev = a.wordCount >= max(250, minWords) ? 2 : a.wordCount >= 150 ? 1 : 0
        return .init(criterionID: c.id, suggested: dev, rationale: "No specific signal for this criterion; suggestion based on development (\(a.wordCount) words). Please judge this one yourself.")
    }

    static func summaryGlow(_ c: FeedbackComment, _ a: Analysis) -> String {
        if a.counter != nil && a.rebuttal != nil { return "You built a real argument: a clear claim, and you answered the other side instead of ignoring it." }
        if a.specificEvidence.count >= 2 { return "Your evidence is specific. Sources and numbers make your reader take your claim seriously." }
        if a.thesis?.paragraph == 0 { return "Your position is clear from the first paragraph, which gives your whole essay direction." }
        return "Your voice comes through. You clearly care about this question, and that makes your writing engaging."
    }

    static func summaryGrow(_ a: Analysis) -> String {
        if a.thesis == nil { return "Next step: write your position as one clear sentence at the end of your introduction." }
        if a.specificEvidence.isEmpty { return "Next step: back up each reason with one piece of evidence: a statistic, a study or an expert." }
        if a.counter == nil { return "Next step: add a paragraph that presents the strongest opposing view and explains why your position still holds." }
        if a.rebuttal == nil { return "Next step: after you raise the other side, answer it. Explain why your claim still stands." }
        if a.paragraphCount < 3 { return "Next step: give each reason its own paragraph with a clear topic sentence." }
        if !a.misspellings.isEmpty || a.lowercaseI != nil { return "Next step: read your essay aloud once before submitting to catch spelling and capitalisation slips." }
        if !a.longSentences.isEmpty { return "Next step: split your longest sentences so each idea lands on its own." }
        return "Next step: push your analysis further. After each piece of evidence, add a sentence explaining exactly how it proves your claim."
    }

    // MARK: Safety for AI-drafted comments

    static let harsh = ["lazy", "stupid", "terrible", "awful", "careless", "dumb", "pathetic", "worst", "horrible", "sloppy", "bad writer", "you failed", "unacceptable", "poorly written", "makes no sense"]

    /// Keeps only comments anchored to real words in the essay, re-anchoring near-misses, and removes
    /// harsh wording. Returns notes describing anything removed so the teacher can see it.
    static func guardComments(_ comments: [FeedbackComment], essay: String) -> (kept: [FeedbackComment], notes: [String]) {
        var kept: [FeedbackComment] = []
        var unanchored = 0, harshCount = 0, reanchored = 0
        let ss = sentences(essay)
        for var c in comments {
            if harsh.contains(where: { c.draft.lowercased().contains($0) }) { harshCount += 1; continue }
            if let exact = findQuote(c.quote, in: essay) { c.quote = exact; kept.append(c); continue }
            // Re-anchor to the sentence that overlaps best with the claimed quote.
            let qw = Set(words(c.quote))
            if let best = ss.max(by: { overlap(qw, $0.words) < overlap(qw, $1.words) }), overlap(qw, best.words) >= 0.6 {
                c.quote = best.text; kept.append(c); reanchored += 1
            } else { unanchored += 1 }
        }
        var notes: [String] = []
        if unanchored > 0 { notes.append("\(unanchored) AI comment\(unanchored == 1 ? " was" : "s were") removed because \(unanchored == 1 ? "its" : "their") quote did not appear in the essay.") }
        if reanchored > 0 { notes.append("\(reanchored) comment\(reanchored == 1 ? " was" : "s were") re-anchored to the closest matching sentence.") }
        if harshCount > 0 { notes.append("\(harshCount) comment\(harshCount == 1 ? " was" : "s were") removed by the tone check.") }
        return (kept, notes)
    }

    static func overlap(_ q: Set<String>, _ w: [String]) -> Double {
        guard !q.isEmpty else { return 0 }
        return Double(q.intersection(w).count) / Double(q.count)
    }

    /// Finds the quote in the essay ignoring case, curly quotes and extra whitespace. Returns the essay's own spelling.
    static func findQuote(_ quote: String, in essay: String) -> String? {
        let q = quote.trimmingCharacters(in: CharacterSet(charactersIn: " \"'“”‘’.\n"))
        guard q.count >= 1 else { return nil }
        if let r = essay.range(of: q, options: [.caseInsensitive, .diacriticInsensitive]) { return String(essay[r]) }
        let norm = q.replacingOccurrences(of: "’", with: "'").replacingOccurrences(of: "“", with: "\"").replacingOccurrences(of: "”", with: "\"")
        let normEssay = essay.replacingOccurrences(of: "’", with: "'").replacingOccurrences(of: "“", with: "\"").replacingOccurrences(of: "”", with: "\"")
        if let r = normEssay.range(of: norm, options: [.caseInsensitive]) {
            let start = normEssay.distance(from: normEssay.startIndex, to: r.lowerBound)
            let len = normEssay.distance(from: r.lowerBound, to: r.upperBound)
            let s = essay.index(essay.startIndex, offsetBy: start)
            return String(essay[s..<essay.index(s, offsetBy: len)])
        }
        return nil
    }
}
