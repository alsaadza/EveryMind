import Foundation
import SwiftUI
import Observation

enum ProviderKind: String, Codable, CaseIterable, Identifiable {
    case offline = "On-device", oci = "OCI Generative AI"
    var id: String { rawValue }
}

struct AppSettings: Codable, Equatable {
    var learnerName: String = ""
    var avatarEmoji: String = "🧑‍🚀"
    var avatarColor: Int = 0
    var onboarded = false
    var provider: ProviderKind = .offline
    var gatewayURL: String = "http://localhost:8787"
    var modelLabel: String = "meta.llama-3.3-70b-instruct"
    var aiEnabled = true
    var helpLevel: HelpLevel = .balanced
    var shareSignals = false
    var cohortCode: String = "demo-class"
    // Educator policy (human oversight)
    var masteryThreshold: Double = 0.7
    var maxHelpLevel: HelpLevel = .supportive
    var hintsBeforeSolution: Int = 3
    var requireApproval = false
    var educatorPIN: String = "2468"
    // Accessibility
    var readAloudRate: Double = 0.48
    var dyslexiaFriendly = false
    var highContrast = false
    var reduceMotion = false
    var textScale: Double = 1.0
}

/// Single source of truth. Persists to JSON in Application Support. Nothing syncs anywhere by default.
@Observable
final class AppStore {
    var courses: [Course] = []
    var progress: [UUID: CourseProgress] = [:]
    var settings = AppSettings() { didSet { if settings != oldValue { save() } } }
    var concerns: [Concern] = []
    var badges: [Badge] = []
    var journal: [JournalEntry] = []
    var lastAIStatus: String = ""

    struct JournalEntry: Codable, Identifiable, Hashable {
        var id = UUID(); var date = Date(); var courseTopic: String; var chapterTitle: String; var text: String; var confidence: Int
    }

    private struct Snapshot: Codable {
        var courses: [Course]; var progress: [UUID: CourseProgress]; var settings: AppSettings
        var concerns: [Concern]; var badges: [Badge]; var journal: [JournalEntry]
    }

    private let fileURL: URL = {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("educateai-state.json")
    }()
    private var loading = false

    init() {
        if ProcessInfo.processInfo.arguments.contains("-resetState") { try? FileManager.default.removeItem(at: fileURL) }
        load()
        if ProcessInfo.processInfo.arguments.contains("-uiTesting") { settings.reduceMotion = true }
        if ProcessInfo.processInfo.arguments.contains("-autoDemo") && !settings.onboarded {
            settings.learnerName = "Sam"; settings.avatarEmoji = "🦊"; settings.onboarded = true
        }
    }

    func load() {
        loading = true; defer { loading = false }
        guard let data = try? Data(contentsOf: fileURL),
              let snap = try? JSONDecoder().decode(Snapshot.self, from: data) else { return }
        courses = snap.courses; progress = snap.progress; settings = snap.settings
        concerns = snap.concerns; badges = snap.badges; journal = snap.journal
    }

    func save() {
        guard !loading else { return }
        let snap = Snapshot(courses: courses, progress: progress, settings: settings, concerns: concerns, badges: badges, journal: journal)
        if let data = try? JSONEncoder().encode(snap) {
            try? data.write(to: fileURL, options: [.atomic, .completeFileProtection])
        }
    }

    func exportData() -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Margin-my-data.json")
        let snap = Snapshot(courses: courses, progress: progress, settings: settings, concerns: concerns, badges: badges, journal: journal)
        let enc = JSONEncoder(); enc.outputFormatting = [.prettyPrinted, .sortedKeys]; enc.dateEncodingStrategy = .iso8601
        try? enc.encode(snap).write(to: url)
        return url
    }

    func deleteAllData() {
        courses = []; progress = [:]; concerns = []; badges = []; journal = []
        let keepAccess = (settings.textScale, settings.dyslexiaFriendly, settings.highContrast, settings.reduceMotion)
        settings = AppSettings()
        (settings.textScale, settings.dyslexiaFriendly, settings.highContrast, settings.reduceMotion) = keepAccess
        Keychain.delete("gatewayToken")
        try? FileManager.default.removeItem(at: fileURL)
    }

    // MARK: Courses

    func add(_ course: Course) {
        courses.insert(course, at: 0)
        var p = CourseProgress(courseID: course.id)
        for (i, ch) in course.chapters.enumerated() {
            p.chapters[ch.id] = ChapterProgress(status: i == 0 ? .unlocked : .locked)
        }
        progress[course.id] = p
        save()
    }

    func course(_ id: UUID) -> Course? { courses.first { $0.id == id } }

    func update(_ course: Course) {
        if let i = courses.firstIndex(where: { $0.id == course.id }) { courses[i] = course; save() }
    }

    func delete(_ course: Course) {
        courses.removeAll { $0.id == course.id }
        progress[course.id] = nil
        save()
    }

    func chapterProgress(_ course: Course, _ chapter: Chapter) -> ChapterProgress {
        progress[course.id]?.chapters[chapter.id] ?? ChapterProgress()
    }

    func mutateProgress(_ course: Course, _ chapter: Chapter, _ change: (inout ChapterProgress) -> Void) {
        var cp = progress[course.id] ?? CourseProgress(courseID: course.id)
        var ch = cp.chapters[chapter.id] ?? ChapterProgress()
        change(&ch)
        cp.chapters[chapter.id] = ch
        progress[course.id] = cp
        save()
    }

    func addXP(_ course: Course, _ amount: Int) {
        progress[course.id, default: CourseProgress(courseID: course.id)].xp += amount
        save()
    }

    var totalXP: Int { progress.values.reduce(0) { $0 + $1.xp } }

    // MARK: Mastery

    /// Mastery blends reading, checkpoints and, mostly, challenge performance including reasoning quality.
    func recomputeMastery(_ course: Course, _ chapter: Chapter) {
        let current = course.chapters.first { $0.id == chapter.id } ?? chapter
        mutateProgress(course, current) { p in
            let sectionCount = max(1, current.sections.count)
            let read = Double(p.sectionsRead.intersection(Set(current.sections.map(\.id))).count) / Double(sectionCount)
            let checks = current.sections.compactMap { $0.checkpoint == nil ? nil : $0.id }
            let checkScore = checks.isEmpty ? 1 : Double(p.quickChecksCorrect.intersection(Set(checks)).count) / Double(checks.count)
            let core = current.challenges.filter { !$0.isFollowUp }
            var challengeScore = 0.0
            for ch in current.challenges where p.solvedChallenges.contains(ch.id) {
                let atts = p.attempts.filter { $0.challengeID == ch.id }
                guard let best = atts.filter(\.correct).max(by: { $0.reasoningScore < $1.reasoningScore }) else { continue }
                let hintPenalty = min(0.3, Double(best.hintsUsed) * 0.08)
                challengeScore += (1 - hintPenalty) * (0.6 + 0.4 * best.reasoningScore)
            }
            let challengePart = min(1, challengeScore / Double(max(1, core.count)))
            p.mastery = min(1, 0.15 * read + 0.15 * checkScore + 0.7 * challengePart)
            if p.status == .unlocked && (read > 0 || !p.attempts.isEmpty) { p.status = .inProgress }
        }
    }

    func isMastered(_ course: Course, _ chapter: Chapter) -> Bool {
        let p = chapterProgress(course, chapter)
        let coreSolved = chapter.challenges.filter { p.solvedChallenges.contains($0.id) }.count
        return p.mastery >= settings.masteryThreshold && coreSolved >= min(2, chapter.challenges.count)
    }

    /// Marks the chapter mastered and unlocks the next. Returns true if something new unlocked.
    @discardableResult
    func completeChapterIfMastered(_ course: Course, _ chapter: Chapter) -> Bool {
        guard isMastered(course, chapter), chapterProgress(course, chapter).status != .mastered else { return false }
        mutateProgress(course, chapter) { $0.status = .mastered }
        if let next = course.chapters.first(where: { $0.index == chapter.index + 1 }) {
            mutateProgress(course, next) { if $0.status == .locked { $0.status = .unlocked } }
        }
        addXP(course, 100)
        award("chapter-\(chapter.id)", "\(chapter.locationName) Master", "Mastered \"\(chapter.title)\"", chapter.theme.symbol)
        if course.chapters.allSatisfy({ chapterProgress(course, $0).status == .mastered }) {
            award("course-\(course.id)", "Course Champion", "Completed \(course.topic)", "trophy.fill")
        }
        return true
    }

    func award(_ id: String, _ title: String, _ detail: String, _ symbol: String) {
        guard !badges.contains(where: { $0.id == id }) else { return }
        badges.append(Badge(id: id, title: title, detail: detail, symbol: symbol))
        save()
    }

    // MARK: Signals (opt-in, de-identified)

    func emitSignal(course: Course, chapter: Chapter, kind: String, tag: String, value: Double) {
        guard settings.shareSignals else { return }
        SignalUploader.shared.enqueue(.init(topic: course.topic, chapter_index: chapter.index, kind: kind, tag: tag, value: value),
                                      cohort: settings.cohortCode, settings: settings)
    }

    // MARK: AI

    var effectiveHelpLevel: HelpLevel {
        let order: [HelpLevel] = [.socratic, .balanced, .supportive]
        let a = order.firstIndex(of: settings.helpLevel) ?? 1, b = order.firstIndex(of: settings.maxHelpLevel) ?? 2
        return order[min(a, b)]
    }

    var primaryProvider: AIProvider {
        if settings.provider == .oci, let url = URL(string: settings.gatewayURL), !settings.gatewayURL.isEmpty {
            return GatewayProvider(baseURL: url, token: Keychain.get("gatewayToken"), modelLabel: settings.modelLabel)
        }
        return OfflineProvider()
    }

    /// Runs an AI task on the chosen provider and falls back to the on-device engine on any failure,
    /// so a classroom demo never dead-ends on a network error.
    func ai<T>(_ work: (AIProvider) async throws -> T) async -> T? {
        let primary = primaryProvider
        do {
            let r = try await work(primary)
            await MainActor.run { lastAIStatus = primary.displayName }
            return r
        } catch {
            guard !primary.runsOnDevice else { return nil }
            let r = try? await work(OfflineProvider())
            await MainActor.run { lastAIStatus = "On-device engine (cloud unavailable: \(error.localizedDescription))" }
            return r
        }
    }
}
