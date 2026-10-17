import Foundation

/// On-device privacy layer. Runs before anything is shared with an educator or sent to the cloud.
enum PrivacyFilter {
    struct Result { var text: String; var redactions: Int }

    private static let patterns: [(String, String)] = [
        ("[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}", "[email]"),
        ("\\b\\d{3}[-.\\s]?\\d{2}[-.\\s]?\\d{4}\\b", "[id-number]"),
        ("(\\+?\\d{1,2}[\\s.-]?)?\\(?\\d{3}\\)?[\\s.-]?\\d{3}[\\s.-]?\\d{4}\\b", "[phone]"),
        ("\\b\\d{1,5}\\s+([A-Z][a-z]+\\s){1,3}(Street|St|Avenue|Ave|Road|Rd|Lane|Ln|Drive|Dr|Boulevard|Blvd|Court|Ct)\\b", "[address]"),
        ("https?://\\S+", "[link]"),
        ("(?i)\\b(my name is|i am called|call me)\\s+[A-Z][a-z]+(\\s[A-Z][a-z]+)?", "$1 [name]"),
        ("(?i)\\b(teacher|mr\\.?|mrs\\.?|ms\\.?|dr\\.?|professor)\\s+[A-Z][a-z]+", "$1 [name]")
    ]

    static func scrub(_ input: String, extraNames: [String] = []) -> Result {
        var text = input
        var count = 0
        for (pattern, template) in patterns {
            guard let re = try? NSRegularExpression(pattern: pattern, options: pattern.hasPrefix("(?i)") ? [] : [.caseInsensitive]) else { continue }
            let range = NSRange(text.startIndex..., in: text)
            count += re.numberOfMatches(in: text, range: range)
            text = re.stringByReplacingMatches(in: text, range: range, withTemplate: template)
        }
        for name in extraNames where name.count > 1 {
            let escaped = NSRegularExpression.escapedPattern(for: name)
            if let re = try? NSRegularExpression(pattern: "\\b\(escaped)\\b", options: [.caseInsensitive]) {
                let range = NSRange(text.startIndex..., in: text)
                count += re.numberOfMatches(in: text, range: range)
                text = re.stringByReplacingMatches(in: text, range: range, withTemplate: "[name]")
            }
        }
        return Result(text: text, redactions: count)
    }

    /// Detects messages that need a human, not an AI. The app never tries to counsel these alone.
    static func needsUrgentHumanSupport(_ text: String) -> Bool {
        let t = text.lowercased()
        let signals = ["kill myself", "suicide", "end my life", "hurt myself", "self harm", "self-harm",
                       "want to die", "being abused", "abusing me", "hits me", "not safe at home", "unsafe at home"]
        return signals.contains { t.contains($0) }
    }

    static let urgentSupportMessage = """
    Thank you for telling me. What you shared matters, and you deserve support from a real person right now. \
    Please reach out to a trusted adult, school counselor or teacher today. If you are in the U.S., you can call or text 988 \
    (Suicide & Crisis Lifeline) any time. If you are in immediate danger, call your local emergency number. \
    I'm an AI and can't replace a person who can help you, but you don't have to handle this alone.
    """
}
