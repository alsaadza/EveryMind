import Foundation

/// Deterministic answer checking. Correctness is never left to a language model:
/// numeric and multiple-choice answers are verified exactly on device, so the AI
/// can only add feedback on reasoning, not change whether an answer is right.
enum AnswerChecker {

    /// Parses "1/6", "0.25", "25%", "1 in 6", "1 out of 6", "one sixth" (common words) into a Double.
    static func parseNumber(_ raw: String) -> Double? {
        var s = raw.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        s = s.replacingOccurrences(of: "p =", with: "").replacingOccurrences(of: "p=", with: "")
        s = s.replacingOccurrences(of: "=", with: "").replacingOccurrences(of: ",", with: "")
        s = s.trimmingCharacters(in: .whitespaces)
        if s.isEmpty { return nil }

        let words: [String: Double] = [
            "zero": 0, "one": 1, "two": 2, "three": 3, "four": 4, "five": 5, "six": 6, "seven": 7,
            "eight": 8, "nine": 9, "ten": 10, "eleven": 11, "twelve": 12, "half": 0.5, "a half": 0.5,
            "one half": 0.5, "a quarter": 0.25, "one quarter": 0.25, "a third": 1.0/3, "one third": 1.0/3,
            "one sixth": 1.0/6, "a sixth": 1.0/6, "one fourth": 0.25, "certain": 1, "impossible": 0
        ]
        if let w = words[s] { return w }

        if s.hasSuffix("%") {
            return Double(s.dropLast().trimmingCharacters(in: .whitespaces)).map { $0 / 100 }
        }
        for sep in [" out of ", " in ", "/", ":"] where s.contains(sep) {
            let parts = s.components(separatedBy: sep).map { $0.trimmingCharacters(in: .whitespaces) }
            if parts.count == 2, let a = number(parts[0]), let b = number(parts[1]), b != 0 {
                return sep == ":" ? a / (a + b) : a / b   // "1:5" odds -> 1/6
            }
        }
        return number(s)
    }

    private static func number(_ s: String) -> Double? {
        if let d = Double(s) { return d }
        let small: [String: Double] = ["one": 1, "two": 2, "three": 3, "four": 4, "five": 5, "six": 6,
                                       "seven": 7, "eight": 8, "nine": 9, "ten": 10, "twelve": 12]
        return small[s]
    }

    static func normalize(_ s: String) -> String {
        s.lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    static func isCorrect(_ answer: String, for challenge: Challenge) -> Bool {
        let trimmed = answer.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        switch challenge.answerType {
        case .numeric:
            guard let a = parseNumber(trimmed), let c = parseNumber(challenge.correctAnswer) else {
                return normalize(trimmed) == normalize(challenge.correctAnswer)
            }
            let tol = challenge.tolerance ?? 0.01
            if abs(a - c) <= tol { return true }
            // "23" typed for an answer stored as "23%"
            if challenge.correctAnswer.contains("%") && !trimmed.contains("%") && abs(a / 100 - c) <= tol { return true }
            // relative tolerance for large values such as 1000
            return abs(c) > 10 && abs(a - c) / abs(c) < 0.01
        case .multipleChoice:
            return normalize(trimmed) == normalize(challenge.correctAnswer)
        case .shortText:
            // Short answers are judged by covering the rubric ideas or matching key terms of the model answer.
            if rubricCoverage(trimmed, rubric: challenge.rubric).met.count >= max(1, (challenge.rubric.count + 1) / 2) { return true }
            let key = Set(normalize(challenge.correctAnswer).split(separator: " ").map(String.init).filter { $0.count > 3 })
            let got = Set(normalize(trimmed).split(separator: " ").map(String.init))
            return !key.isEmpty && Double(key.intersection(got).count) / Double(key.count) >= 0.5
        }
    }

    static func misconception(for answer: String, in challenge: Challenge) -> String? {
        guard let map = challenge.misconceptions else { return nil }
        let n = normalize(answer)
        let value = parseNumber(answer)
        for (wrong, tag) in map {
            if normalize(wrong) == n { return tag }
            if let v = value, let w = parseNumber(wrong), abs(v - w) < 0.0005 { return tag }
        }
        return nil
    }

    /// Returns which rubric ideas a written explanation covers.
    static func rubricCoverage(_ text: String, rubric: [RubricItem]) -> (met: [RubricItem], missing: [RubricItem]) {
        let n = " " + normalize(text) + " "
        let raw = text.lowercased()
        var met: [RubricItem] = [], missing: [RubricItem] = []
        for item in rubric {
            let hit = item.keywords.contains { kw in
                let k = kw.lowercased()
                if k.rangeOfCharacter(from: CharacterSet.alphanumerics.inverted) != nil { return raw.contains(k) }
                return n.contains(" " + normalize(k) + " ") || (k.count > 4 && n.contains(normalize(k)))
            }
            hit ? met.append(item) : missing.append(item)
        }
        return (met, missing)
    }

    /// 0...1 score for an explanation: rubric coverage plus a small effort component.
    static func reasoningScore(_ text: String, rubric: [RubricItem]) -> Double {
        let words = text.split { $0.isWhitespace }.count
        guard words > 0 else { return 0 }
        let coverage = rubric.isEmpty ? 0.5 : Double(rubricCoverage(text, rubric: rubric).met.count) / Double(rubric.count)
        let effort = min(1, Double(words) / 25)
        let causal = ["because", "so", "since", "therefore", "means", "which", "then", "if"].contains { normalize(text).split(separator: " ").contains(Substring($0)) } ? 0.1 : 0
        return min(1, coverage * 0.75 + effort * 0.15 + causal)
    }
}
