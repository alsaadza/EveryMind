import Foundation

// MARK: - Learning differences

/// A reading profile changes how content is *presented*, never what it says.
enum ReadingProfile: String, Codable, CaseIterable, Identifiable {
    case standard, dyslexia, focus, listen, visual
    var id: String { rawValue }
    var title: String {
        switch self {
        case .standard: return "Standard"
        case .dyslexia: return "Dyslexia-friendly"
        case .focus: return "Focus"
        case .listen: return "Listen"
        case .visual: return "Visual"
        }
    }
    var detail: String {
        switch self {
        case .standard: return "The lesson as written."
        case .dyslexia: return "Lexend or OpenDyslexic type, wider letter and line spacing, a tinted page and a reading ruler."
        case .focus: return "One small chunk at a time with a progress trail, key words in bold and an optional focus timer. Built for ADHD."
        case .listen: return "Read aloud with each word highlighted as it is spoken. Tap any sentence to start there."
        case .visual: return "Key terms as cards, processes as step diagrams and numbers pulled out as facts."
        }
    }
    var symbol: String {
        switch self {
        case .standard: return "text.alignleft"
        case .dyslexia: return "textformat.size"
        case .focus: return "scope"
        case .listen: return "waveform"
        case .visual: return "square.grid.2x2"
        }
    }
    var defaultFormat: LessonFormat {
        switch self {
        case .standard, .dyslexia: return .original
        case .focus: return .chunked
        case .listen: return .listen
        case .visual: return .visual
        }
    }
}

enum LessonFormat: String, Codable, CaseIterable, Identifiable {
    case original, chunked, listen, visual
    var id: String { rawValue }
    var title: String {
        switch self {
        case .original: return "Original"
        case .chunked: return "Chunked"
        case .listen: return "Read aloud"
        case .visual: return "Visual"
        }
    }
    var symbol: String {
        switch self {
        case .original: return "doc.text"
        case .chunked: return "square.stack"
        case .listen: return "waveform"
        case .visual: return "square.grid.2x2"
        }
    }
}

enum ReadingFont: String, Codable, CaseIterable, Identifiable {
    case serif, lexend, openDyslexic, atkinson
    var id: String { rawValue }
    var title: String {
        switch self {
        case .serif: return "Source Serif"
        case .lexend: return "Lexend"
        case .openDyslexic: return "OpenDyslexic"
        case .atkinson: return "Atkinson Hyperlegible"
        }
    }
    var note: String {
        switch self {
        case .serif: return "Classic book type."
        case .lexend: return "Designed to reduce visual stress and improve reading fluency."
        case .openDyslexic: return "Weighted letter bottoms help stop letters flipping."
        case .atkinson: return "Made by the Braille Institute so similar letters stay distinct."
        }
    }
}

enum PageTint: String, Codable, CaseIterable, Identifiable {
    case paper, cream, peach, mint, sky, night
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

struct ReadingPrefs: Codable, Hashable {
    var profile: ReadingProfile = .standard
    var font: ReadingFont = .serif
    var letterSpacing: Double = 0       // points of tracking
    var lineSpacing: Double = 8         // extra points between lines
    var wordSpacing: Double = 0         // extra spaces between words, 0...2
    var tint: PageTint = .paper
    var ruler = false                   // reading guide band
    var boldKeyTerms = true
    var chunkSentences = 2              // sentences per chunk in focus mode
    var focusMinutes = 0                // 0 = off
    var speechRate: Double = 0.46

    static func preset(_ p: ReadingProfile) -> ReadingPrefs {
        var r = ReadingPrefs(profile: p)
        switch p {
        case .standard: break
        case .dyslexia:
            r.font = .lexend; r.letterSpacing = 1.2; r.lineSpacing = 14; r.wordSpacing = 1; r.tint = .cream; r.ruler = true
        case .focus:
            r.font = .lexend; r.lineSpacing = 12; r.chunkSentences = 2; r.focusMinutes = 10
        case .listen:
            r.lineSpacing = 12
        case .visual:
            r.font = .lexend; r.lineSpacing = 10
        }
        return r
    }
}

// MARK: - Classroom

enum Accommodation: String, Codable, CaseIterable, Identifiable {
    case extendedTime, readAloud, chunkedText, dyslexiaFont, visualSupports, reducedLength
    var id: String { rawValue }
    var title: String {
        switch self {
        case .extendedTime: return "Extended time"
        case .readAloud: return "Read aloud"
        case .chunkedText: return "Chunked text"
        case .dyslexiaFont: return "Dyslexia-friendly type"
        case .visualSupports: return "Visual supports"
        case .reducedLength: return "Reduced length"
        }
    }
    var symbol: String {
        switch self {
        case .extendedTime: return "clock.badge.checkmark"
        case .readAloud: return "speaker.wave.2"
        case .chunkedText: return "square.stack"
        case .dyslexiaFont: return "textformat"
        case .visualSupports: return "square.grid.2x2"
        case .reducedLength: return "text.badge.minus"
        }
    }
}

struct Student: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    var avatar: String
    var prefs = ReadingPrefs()
    var accommodations: [Accommodation] = []
    /// Teacher-only. Never sent to an AI model.
    var supportNote: String = ""
    /// The learner who uses this iPad in student mode.
    var isDeviceLearner = false
    var firstName: String { name.split(separator: " ").first.map(String.init) ?? name }
    var initials: String { name.split(separator: " ").compactMap(\.first).prefix(2).map(String.init).joined() }
}

struct ClassGroup: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String          // "English 9"
    var period: String        // "Period 3"
    var gradeBand: String     // "Grade 9"
    var joinCode: String
    var studentIDs: [UUID]
    var art: String           // asset name of the cover art
}

enum AssignmentKind: String, Codable, CaseIterable, Identifiable {
    case essay, reading, quest
    var id: String { rawValue }
    var title: String {
        switch self {
        case .essay: return "Essay"
        case .reading: return "Reading"
        case .quest: return "Quest course"
        }
    }
    var symbol: String {
        switch self {
        case .essay: return "pencil.and.scribble"
        case .reading: return "book.pages"
        case .quest: return "map"
        }
    }
    var blurb: String {
        switch self {
        case .essay: return "A written response with a rubric. AI drafts feedback and you approve every comment."
        case .reading: return "A lesson every student can read in their own format: chunked, read aloud or visual."
        case .quest: return "A three-chapter interactive course with a map, an AI tutor and reasoning challenges."
        }
    }
}

struct RubricCriterion: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    var detail: String
    /// Four performance-level descriptors, from Beginning (index 0) to Exemplary (index 3).
    var levels: [String]
    static let levelNames = ["Beginning", "Developing", "Proficient", "Exemplary"]
}

enum AssignmentStatus: String, Codable { case draft, sent, closed }

struct Assignment: Codable, Identifiable, Hashable {
    var id = UUID()
    var classID: UUID
    var kind: AssignmentKind
    var title: String
    var instructions: String
    var art: String
    // Essay
    var prompt: String = ""
    var rubric: [RubricCriterion] = []
    var minWords: Int = 250
    var sourceText: String? = nil     // e.g. a poem students respond to
    // Reading
    var sections: [LessonSection] = []
    var keyTerms: [String] = []
    // Quest
    var courseID: UUID? = nil
    var topic: String = ""
    var level: SkillLevel = .beginner

    var standards: [String] = []
    var dueDate: Date
    var createdAt = Date()
    var sentAt: Date? = nil
    var status: AssignmentStatus = .draft
    var recipients: [UUID] = []
    var aiGenerated = true
    var provenance: String = ""
}

enum SubmissionStatus: String, Codable {
    case assigned, inProgress, submitted, returned
    var label: String {
        switch self {
        case .assigned: return "Not started"
        case .inProgress: return "In progress"
        case .submitted: return "Submitted"
        case .returned: return "Returned"
        }
    }
}

struct Submission: Codable, Identifiable, Hashable {
    var id = UUID()
    var assignmentID: UUID
    var studentID: UUID
    var text: String = ""
    var status: SubmissionStatus = .assigned
    var startedAt: Date? = nil
    var submittedAt: Date? = nil
    var version = 1
    var feedback: EssayFeedback? = nil
    /// Earlier versions, kept so teacher and student can see growth after revision.
    var history: [EssayVersion] = []
    /// Student's own essay plan (graphic organizer). Never sent to AI.
    var plan: [String]? = nil
    // Reading
    var readingProgress: Double = 0
    var formatUsed: LessonFormat? = nil
    var wordCount: Int { text.split(whereSeparator: { $0 == " " || $0 == "\n" }).count }
}

struct EssayVersion: Codable, Hashable {
    var version: Int
    var text: String
    var feedback: EssayFeedback?
    var date: Date
}

// MARK: - Essay feedback with teacher approval

enum CommentKind: String, Codable, CaseIterable, Identifiable {
    case strength, suggestion, question, conventions
    var id: String { rawValue }
    var title: String {
        switch self {
        case .strength: return "Strength"
        case .suggestion: return "Next step"
        case .question: return "Question"
        case .conventions: return "Conventions"
        }
    }
    var symbol: String {
        switch self {
        case .strength: return "hand.thumbsup"
        case .suggestion: return "arrow.up.forward"
        case .question: return "questionmark"
        case .conventions: return "textformat.abc"
        }
    }
}

enum CommentState: String, Codable { case pending, approved, rejected }
enum CommentOrigin: String, Codable { case ai, teacher }

struct FeedbackComment: Codable, Identifiable, Hashable {
    var id = UUID()
    /// The exact words in the essay this comment is anchored to.
    var quote: String
    var kind: CommentKind
    var criterionID: UUID? = nil
    /// The text as drafted (by AI or teacher).
    var draft: String
    /// Teacher's edited wording, if changed.
    var edited: String? = nil
    var state: CommentState = .pending
    var origin: CommentOrigin = .ai
    var studentReply: String? = nil
    var text: String { edited ?? draft }
    var wasEdited: Bool { edited != nil && edited != draft }
}

struct CriterionScore: Codable, Hashable, Identifiable {
    var criterionID: UUID
    var suggested: Int             // 0...3
    var rationale: String
    var confirmed: Int? = nil      // set by the teacher
    var id: UUID { criterionID }
}

struct EssayFeedback: Codable, Hashable {
    var comments: [FeedbackComment]
    var scores: [CriterionScore]
    var glow: String               // what is working
    var grow: String               // one next step
    var summaryEdited = false
    var summaryApproved = false
    var generatedBy: String
    var generatedAt = Date()
    /// What the safety layer removed or changed before the teacher saw the draft.
    var guardNotes: [String] = []
    var reviewSeconds: Double = 0
    var releasedAt: Date? = nil

    var pendingCount: Int { comments.filter { $0.state == .pending }.count }
    var approved: [FeedbackComment] { comments.filter { $0.state == .approved } }
    var allScoresConfirmed: Bool { scores.allSatisfy { $0.confirmed != nil } }
    var readyToRelease: Bool { pendingCount == 0 && allScoresConfirmed && summaryApproved }
}
