import Foundation

enum ChapterStatus: String, Codable {
    case locked, unlocked, inProgress, mastered
}

struct ChallengeAttempt: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var challengeID: UUID
    var answer: String
    var reasoning: String
    var correct: Bool
    var reasoningScore: Double   // 0...1
    var hintsUsed: Int
    var misconception: String?
    var date: Date = Date()
}

struct ChapterProgress: Codable, Hashable {
    var status: ChapterStatus = .locked
    var sectionsRead: Set<UUID> = []
    var quickChecksCorrect: Set<UUID> = []
    var attempts: [ChallengeAttempt] = []
    var solvedChallenges: Set<UUID> = []
    var remediations: Int = 0
    var mastery: Double = 0      // 0...1
    var reflection: String = ""
    var confidence: Int? = nil   // learner self-rating 1...5 after the chapter
    var revealedSolutions: Set<UUID> = []
}

struct Badge: Codable, Hashable, Identifiable {
    var id: String
    var title: String
    var detail: String
    var symbol: String
    var earned: Date = Date()
}

struct ChatMessage: Codable, Identifiable, Hashable {
    enum Role: String, Codable { case learner, tutor, system }
    var id: UUID = UUID()
    var role: Role
    var text: String
    var date: Date = Date()
    /// Transparency: what the tutor used to answer.
    var sources: [String]? = nil
}

struct CourseProgress: Codable, Hashable {
    var courseID: UUID
    var chapters: [UUID: ChapterProgress] = [:]
    var xp: Int = 0
    var tutorLog: [UUID: [ChatMessage]] = [:]   // per chapter
    var avatarPosition: CodablePoint? = nil
}

struct CodablePoint: Codable, Hashable {
    var x: Double
    var y: Double
}

enum ConcernVisibility: String, Codable, CaseIterable, Identifiable {
    case privateOnly = "Keep private"
    case anonymous = "Share anonymously"
    case named = "Share with my name"
    var id: String { rawValue }
    var detail: String {
        switch self {
        case .privateOnly: return "Only you can see this. Nothing leaves this iPad."
        case .anonymous: return "Your educator sees the theme in a group summary, never your name. Identifying details are removed first."
        case .named: return "Your educator can see this note and follow up with you directly."
        }
    }
}

struct Concern: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var text: String           // already scrubbed of PII when shared
    var category: String
    var visibility: ConcernVisibility
    var date: Date = Date()
    var supportiveReply: String
}

enum HelpLevel: String, Codable, CaseIterable, Identifiable {
    case socratic = "Socratic"
    case balanced = "Balanced"
    case supportive = "Supportive"
    var id: String { rawValue }
    var detail: String {
        switch self {
        case .socratic: return "The tutor answers questions with questions and never gives answers away."
        case .balanced: return "The tutor guides with hints and explains concepts, but you solve the problems."
        case .supportive: return "The tutor explains more directly and shows worked examples on request."
        }
    }
}
