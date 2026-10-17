import Foundation

// MARK: - Course content model
// Everything the AI generates is decoded into these types. The same JSON shape is used
// by the OCI gateway prompts, the offline engine and on-disk persistence.

enum SkillLevel: String, Codable, CaseIterable, Identifiable {
    case beginner, intermediate, advanced
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
    var blurb: String {
        switch self {
        case .beginner: return "New to this. Start from everyday examples."
        case .intermediate: return "Know the basics. Ready for formulas and multi-step problems."
        case .advanced: return "Comfortable. Bring on proofs, edge cases and tricky problems."
        }
    }
}

enum LearnerStage: String, Codable, CaseIterable, Identifiable {
    case k12 = "K-12", college = "Higher Ed", workforce = "Workforce", lifelong = "Lifelong"
    var id: String { rawValue }
}

enum ReviewStatus: String, Codable {
    case pendingReview, approved, flagged
    var label: String {
        switch self {
        case .pendingReview: return "AI draft, not yet reviewed by an educator"
        case .approved: return "Reviewed and approved by an educator"
        case .flagged: return "Flagged by an educator for revision"
        }
    }
}

enum LocationTheme: String, Codable, CaseIterable {
    case grove, tower, castle, harbor, observatory, garden, workshop, library
    var symbol: String {
        switch self {
        case .grove: return "tree.fill"
        case .tower: return "building.columns.fill"
        case .castle: return "crown.fill"
        case .harbor: return "sailboat.fill"
        case .observatory: return "moon.stars.fill"
        case .garden: return "leaf.fill"
        case .workshop: return "hammer.fill"
        case .library: return "books.vertical.fill"
        }
    }
}

struct NPC: Codable, Hashable {
    var name: String
    var role: String
    var greeting: String
    var emoji: String
}

enum IllustrationKind: String, Codable, CaseIterable {
    case coinFlip, diceRoll, spinner, cardDraw, venn, probabilityTree, numberLine, fractionBar, conceptCard, waterCycle
}

struct Illustration: Codable, Hashable {
    var kind: IllustrationKind
    var caption: String
    /// Optional numeric parameters, e.g. ["sides": 6], ["sectors": 4], ["numerator": 3, "denominator": 8].
    var params: [String: Double]? = nil
    /// Optional labels, e.g. venn set names or spinner sector names.
    var labels: [String]? = nil
}

struct QuickCheck: Codable, Hashable {
    var question: String
    var options: [String]
    var correctIndex: Int
    var explanation: String
}

struct LessonSection: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var heading: String
    /// Markdown-lite body. Paragraphs separated by blank lines; **bold** supported.
    var body: String
    var illustration: Illustration? = nil
    var checkpoint: QuickCheck? = nil
    /// True when this section was added by adaptive remediation.
    var isAdaptive: Bool = false
}

enum AnswerType: String, Codable {
    case numeric, multipleChoice, shortText
}

struct RubricItem: Codable, Hashable {
    /// What a good explanation should mention, written for the learner ("You named the total number of outcomes").
    var idea: String
    /// Keywords used by the offline evaluator. Any match counts.
    var keywords: [String]
}

struct Challenge: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var prompt: String
    var answerType: AnswerType
    var options: [String]? = nil
    /// Canonical answer. Numeric answers can be "1/6", "0.25" or "25%".
    var correctAnswer: String
    var tolerance: Double? = nil
    /// Three escalating hints: nudge, strategy, nearly-there.
    var hints: [String]
    var solution: String
    var rubric: [RubricItem]
    /// Labels for likely wrong answers -> misconception tag, e.g. ["1/2": "equally-likely-fallacy"].
    var misconceptions: [String: String]? = nil
    var isFollowUp: Bool = false
}

struct Chapter: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var index: Int
    var title: String
    var summary: String
    var locationName: String
    var theme: LocationTheme
    var npc: NPC
    var sections: [LessonSection]
    var keyIdeas: [String]
    var challenges: [Challenge]
    /// Discussion prompts for a study partner, teacher or family member.
    var discussionPrompts: [String] = []
}

struct Course: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var topic: String
    var level: SkillLevel
    var stage: LearnerStage = .lifelong
    var createdAt: Date = Date()
    var chapters: [Chapter]
    var reviewStatus: ReviewStatus = .pendingReview
    var educatorNote: String? = nil
    /// Which engine produced the content, shown in the transparency panel.
    var generatedBy: String
    /// Plain-language statement of what informed the content.
    var provenance: String
    var goals: String? = nil
}

struct CourseRequest: Codable {
    var topic: String
    var level: SkillLevel
    var stage: LearnerStage
    var goals: String
    var chapterCount: Int = 3
}

/// Adaptive help produced after a learner struggles.
struct Remediation: Codable, Hashable {
    var approach: String          // e.g. "Visual analogy", "Worked example"
    var section: LessonSection
    var followUp: Challenge
}
