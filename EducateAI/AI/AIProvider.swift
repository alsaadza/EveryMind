import Foundation

struct TutorContext {
    var topic: String
    var level: SkillLevel
    var chapter: Chapter
    var currentSection: LessonSection?
    var helpLevel: HelpLevel
    /// The challenge the learner is working on, so the tutor can avoid giving away its answer.
    var activeChallenge: Challenge?
    var learnerName: String?
}

struct TutorReply {
    var text: String
    var sources: [String]
}

struct Evaluation {
    var correct: Bool
    var reasoningScore: Double
    var feedback: String
    var rubricMet: [String]
    var rubricMissing: [String]
    var misconception: String?
    /// A Socratic follow-up the NPC asks, to deepen understanding even when the learner is right.
    var probe: String?
    var source: String
}

struct ConcernTriage {
    var category: String
    var reply: String
    var urgent: Bool
}

struct InsightSummaryInput {
    var courseTopic: String
    var learnerCount: Int
    var chapterStats: [(title: String, masteryRate: Double, avgHints: Double)]
    var topMisconceptions: [(tag: String, count: Int)]
    var concernThemes: [(theme: String, count: Int)]
}

/// Every AI engine implements this. The app talks only to this protocol, so OCI Generative AI
/// and the on-device engine are interchangeable, and the app falls back gracefully when offline.
protocol AIProvider {
    var displayName: String { get }
    var runsOnDevice: Bool { get }
    func generateCourse(_ request: CourseRequest) async throws -> Course
    func tutor(_ context: TutorContext, history: [ChatMessage], question: String) async throws -> TutorReply
    func evaluate(challenge: Challenge, answer: String, reasoning: String, attempt: Int, context: TutorContext) async throws -> Evaluation
    func hint(challenge: Challenge, level: Int, answer: String, reasoning: String, context: TutorContext) async throws -> String
    func remediate(chapter: Chapter, topic: String, level: SkillLevel, struggledWith: Challenge, attempts: [ChallengeAttempt], round: Int) async throws -> Remediation
    func triageConcern(_ text: String) async throws -> ConcernTriage
    func summarizeInsights(_ input: InsightSummaryInput) async throws -> String
    // Classroom
    func draftEssayFeedback(essay: String, prompt: String, rubric: [RubricCriterion], gradeBand: String, minWords: Int) async throws -> EssayFeedback
    func draftAssignment(_ request: AssignmentRequest) async throws -> AssignmentDraft
    func planLessonStructure(_ sentences: [String], chunkSize: Int) async throws -> LessonAdapter.StructurePlan
}

enum AIError: LocalizedError {
    case notConfigured, badResponse(String), invalidJSON
    var errorDescription: String? {
        switch self {
        case .notConfigured: return "The OCI gateway URL is not set. Add it in Settings > AI Provider."
        case .badResponse(let m): return "The AI service returned an error: \(m)"
        case .invalidJSON: return "The AI response could not be read."
        }
    }
}

extension String {
    /// Extracts the first JSON object from model output that may include prose or code fences.
    var extractedJSON: String? {
        guard let start = firstIndex(of: "{"), let end = lastIndex(of: "}"), start < end else { return nil }
        return String(self[start...end])
    }
}
