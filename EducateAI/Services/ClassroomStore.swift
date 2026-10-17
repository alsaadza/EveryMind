import Foundation
import Observation

enum AppRole: String, Codable { case student, teacher }

/// Classroom state: classes, rosters, assignments, submissions and the feedback approval workflow.
/// Persisted on device (Application Support, file protection on). Shared-iPad model: a student
/// signs in by picking their name, and their teacher-set reading accommodations follow them.
@Observable
final class ClassroomStore {
    var role: AppRole? = nil
    var currentStudentID: UUID? = nil
    var teacherName = "Ms. Ellis"
    var classes: [ClassGroup] = []
    var students: [Student] = []
    var assignments: [Assignment] = []
    var submissions: [Submission] = []
    /// Minutes a teacher typically spends hand-writing feedback on one essay (used for the time-saved estimate).
    var baselineMinutesPerEssay: Double = 12
    /// Teacher policy: let AI draft essay feedback (otherwise teachers write every comment themselves).
    var aiFeedbackEnabled = true
    /// Teacher policy: let AI suggest chunk boundaries for reading formats (always verified on device).
    var aiStructureEnabled = true

    private struct Snapshot: Codable {
        var role: AppRole?; var currentStudentID: UUID?; var teacherName: String
        var classes: [ClassGroup]; var students: [Student]; var assignments: [Assignment]; var submissions: [Submission]
        var baselineMinutesPerEssay: Double?
        var aiFeedbackEnabled: Bool?
        var aiStructureEnabled: Bool?
    }

    private let fileURL: URL = {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("margin-classroom.json")
    }()

    init() {
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-resetState") { try? FileManager.default.removeItem(at: fileURL) }
        load()
        if classes.isEmpty { seed() }
        if let i = args.firstIndex(of: "-role"), i + 1 < args.count { role = AppRole(rawValue: args[i + 1]) }
        if let i = args.firstIndex(of: "-student"), i + 1 < args.count, let s = students.first(where: { $0.firstName == args[i + 1] }) {
            currentStudentID = s.id; role = .student
        }
    }

    func load() {
        guard let data = try? Data(contentsOf: fileURL), let s = try? JSONDecoder().decode(Snapshot.self, from: data) else { return }
        role = s.role; currentStudentID = s.currentStudentID; teacherName = s.teacherName
        classes = s.classes; students = s.students; assignments = s.assignments; submissions = s.submissions
        baselineMinutesPerEssay = s.baselineMinutesPerEssay ?? 12
        aiFeedbackEnabled = s.aiFeedbackEnabled ?? true
        aiStructureEnabled = s.aiStructureEnabled ?? true
    }

    func save() {
        let s = Snapshot(role: role, currentStudentID: currentStudentID, teacherName: teacherName, classes: classes, students: students,
                         assignments: assignments, submissions: submissions, baselineMinutesPerEssay: baselineMinutesPerEssay,
                         aiFeedbackEnabled: aiFeedbackEnabled, aiStructureEnabled: aiStructureEnabled)
        if let data = try? JSONEncoder().encode(s) { try? data.write(to: fileURL, options: [.atomic, .completeFileProtection]) }
    }

    func resetDemo() {
        try? FileManager.default.removeItem(at: fileURL)
        classes = []; students = []; assignments = []; submissions = []; currentStudentID = nil
        seed()
    }

    // MARK: Lookup

    var currentStudent: Student? { students.first { $0.id == currentStudentID } }
    func student(_ id: UUID) -> Student? { students.first { $0.id == id } }
    func assignment(_ id: UUID) -> Assignment? { assignments.first { $0.id == id } }
    func classGroup(_ id: UUID) -> ClassGroup? { classes.first { $0.id == id } }
    func roster(_ c: ClassGroup) -> [Student] { c.studentIDs.compactMap(student) }
    func submissions(for a: Assignment) -> [Submission] { submissions.filter { $0.assignmentID == a.id } }
    func submission(_ id: UUID) -> Submission? { submissions.first { $0.id == id } }
    func submission(assignment: UUID, student: UUID) -> Submission? { submissions.first { $0.assignmentID == assignment && $0.studentID == student } }

    func assignments(for student: Student) -> [Assignment] {
        assignments.filter { $0.status != .draft && $0.recipients.contains(student.id) }.sorted { $0.dueDate < $1.dueDate }
    }

    /// Essays waiting for the teacher: submitted, with an AI draft that hasn't been released.
    var reviewQueue: [Submission] {
        submissions.filter { s in
            guard s.status == .submitted, let a = assignment(s.assignmentID), a.kind == .essay else { return false }
            return true
        }.sorted { ($0.submittedAt ?? .distantPast) < ($1.submittedAt ?? .distantPast) }
    }

    var releasedFeedback: [EssayFeedback] { submissions.compactMap { $0.status == .returned ? $0.feedback : nil } + submissions.flatMap { $0.history.compactMap(\.feedback) }.filter { $0.releasedAt != nil } }

    /// Honest estimate: baseline minutes per essay minus the minutes actually spent reviewing.
    var minutesSaved: Double {
        releasedFeedback.reduce(0) { $0 + max(0, baselineMinutesPerEssay - $1.reviewSeconds / 60) }
    }
    var averageReviewMinutes: Double {
        let r = releasedFeedback
        return r.isEmpty ? 0 : r.reduce(0) { $0 + $1.reviewSeconds } / Double(r.count) / 60
    }
    var approvalStats: (approved: Int, edited: Int, rejected: Int, teacherAdded: Int) {
        let cs = releasedFeedback.flatMap(\.comments)
        return (cs.filter { $0.state == .approved && !$0.wasEdited && $0.origin == .ai }.count,
                cs.filter { $0.state == .approved && $0.wasEdited && $0.origin == .ai }.count,
                cs.filter { $0.state == .rejected }.count,
                cs.filter { $0.origin == .teacher }.count)
    }

    /// Makes sure every quest assignment has its course in the learner store, so it can be reviewed and played.
    func ensureQuestCourses(_ app: AppStore) {
        for i in assignments.indices where assignments[i].kind == .quest {
            if let cid = assignments[i].courseID, app.course(cid) != nil { continue }
            let c = OfflineLibrary.course(for: CourseRequest(topic: assignments[i].topic, level: assignments[i].level, stage: .k12, goals: ""))
            app.add(c)
            assignments[i].courseID = c.id
        }
        save()
    }

    // MARK: Accommodations applied automatically

    func dueDate(_ a: Assignment, for s: Student) -> Date {
        s.accommodations.contains(.extendedTime) ? Calendar.current.date(byAdding: .day, value: 2, to: a.dueDate) ?? a.dueDate : a.dueDate
    }

    func minWords(_ a: Assignment, for s: Student) -> Int {
        s.accommodations.contains(.reducedLength) ? Int((Double(a.minWords) * 0.7 / 10).rounded()) * 10 : a.minWords
    }

    // MARK: Teacher actions

    func updateStudent(_ s: Student) {
        if let i = students.firstIndex(where: { $0.id == s.id }) { students[i] = s; save() }
    }

    func upsert(_ a: Assignment) {
        if let i = assignments.firstIndex(where: { $0.id == a.id }) { assignments[i] = a } else { assignments.insert(a, at: 0) }
        save()
    }

    func deleteAssignment(_ a: Assignment) {
        assignments.removeAll { $0.id == a.id }
        submissions.removeAll { $0.assignmentID == a.id }
        save()
    }

    func send(_ a: Assignment, to recipients: [UUID]) {
        var a = a
        a.recipients = recipients; a.status = .sent; a.sentAt = Date()
        upsert(a)
        for sid in recipients where submission(assignment: a.id, student: sid) == nil {
            submissions.append(Submission(assignmentID: a.id, studentID: sid))
        }
        save()
    }

    func mutate(_ id: UUID, _ change: (inout Submission) -> Void) {
        guard let i = submissions.firstIndex(where: { $0.id == id }) else { return }
        change(&submissions[i]); save()
    }

    func mutateFeedback(_ id: UUID, _ change: (inout EssayFeedback) -> Void) {
        mutate(id) { s in if var f = s.feedback { change(&f); s.feedback = f } }
    }

    func setComment(_ sub: UUID, _ comment: UUID, state: CommentState) {
        mutateFeedback(sub) { f in if let i = f.comments.firstIndex(where: { $0.id == comment }) { f.comments[i].state = state } }
    }

    func editComment(_ sub: UUID, _ comment: UUID, text: String) {
        mutateFeedback(sub) { f in
            if let i = f.comments.firstIndex(where: { $0.id == comment }) {
                f.comments[i].edited = text == f.comments[i].draft ? nil : text
                f.comments[i].state = .approved
            }
        }
    }

    func addTeacherComment(_ sub: UUID, quote: String, kind: CommentKind, text: String, criterion: UUID?) {
        mutateFeedback(sub) { f in
            f.comments.append(FeedbackComment(quote: quote, kind: kind, criterionID: criterion, draft: text, state: .approved, origin: .teacher))
        }
    }

    func confirmScore(_ sub: UUID, criterion: UUID, level: Int) {
        mutateFeedback(sub) { f in if let i = f.scores.firstIndex(where: { $0.criterionID == criterion }) { f.scores[i].confirmed = level } }
    }

    func setSummary(_ sub: UUID, glow: String, grow: String, approved: Bool) {
        mutateFeedback(sub) { f in
            if f.glow != glow || f.grow != grow { f.summaryEdited = true }
            f.glow = glow; f.grow = grow; f.summaryApproved = approved
        }
    }

    func addReviewTime(_ sub: UUID, seconds: Double) {
        guard seconds > 0 else { return }
        mutateFeedback(sub) { $0.reviewSeconds += seconds }
    }

    /// Only approved comments and teacher-confirmed scores are ever visible to the student.
    @discardableResult
    func release(_ sub: UUID) -> Bool {
        guard let s = submission(sub), let f = s.feedback, f.readyToRelease else { return false }
        mutate(sub) { $0.status = .returned; $0.feedback?.releasedAt = Date() }
        return true
    }

    // MARK: Student actions

    func signIn(_ s: Student) { currentStudentID = s.id; role = .student; save() }
    func signOut() { currentStudentID = nil; role = nil; save() }
    func becomeTeacher() { role = .teacher; currentStudentID = nil; save() }

    func updatePrefs(_ prefs: ReadingPrefs) {
        guard let id = currentStudentID, let i = students.firstIndex(where: { $0.id == id }) else { return }
        students[i].prefs = prefs; save()
    }

    func saveDraft(_ sub: UUID, text: String) {
        mutate(sub) { s in
            s.text = text
            if s.status == .assigned { s.status = .inProgress; s.startedAt = Date() }
        }
    }

    func studentReply(_ sub: UUID, comment: UUID, text: String) {
        mutateFeedback(sub) { f in if let i = f.comments.firstIndex(where: { $0.id == comment }) { f.comments[i].studentReply = text } }
    }

    /// Starts a revision: the returned version moves to history and the student keeps editing.
    func startRevision(_ sub: UUID) {
        mutate(sub) { s in
            s.history.append(EssayVersion(version: s.version, text: s.text, feedback: s.feedback, date: s.submittedAt ?? Date()))
            s.version += 1; s.feedback = nil; s.status = .inProgress; s.submittedAt = nil
        }
    }

    func markReading(_ sub: UUID, progress: Double, format: LessonFormat) {
        mutate(sub) { s in
            s.readingProgress = max(s.readingProgress, progress); s.formatUsed = format
            if s.status == .assigned { s.status = .inProgress; s.startedAt = Date() }
            if s.readingProgress >= 0.999 { s.status = .submitted; s.submittedAt = Date() }
        }
    }

    /// Submits the essay. The AI drafts feedback for the teacher straight away; the student sees nothing until it is released.
    func submit(_ sub: UUID, text: String, using app: AppStore) async {
        mutate(sub) { s in s.text = text; s.status = .submitted; s.submittedAt = Date() }
        await draftFeedback(sub, using: app)
    }

    func draftFeedback(_ sub: UUID, using app: AppStore) async {
        guard let s = submission(sub), let a = assignment(s.assignmentID), let c = classGroup(a.classID) else { return }
        guard aiFeedbackEnabled else {
            // Policy: no AI drafting. The teacher writes comments and chooses levels themselves.
            let scores = a.rubric.map { CriterionScore(criterionID: $0.id, suggested: 1, rationale: "AI drafting is turned off. Choose a level.") }
            await MainActor.run { mutate(sub) { $0.feedback = EssayFeedback(comments: [], scores: scores, glow: "", grow: "", generatedBy: "No AI draft (turned off in AI policies)") } }
            return
        }
        // The student's name is never sent; PII is scrubbed again by the gateway.
        let essay = PrivacyFilter.scrub(s.text).text
        let fb = await app.ai { try await $0.draftEssayFeedback(essay: essay, prompt: a.prompt, rubric: a.rubric, gradeBand: c.gradeBand, minWords: a.minWords) }
            ?? EssayCoach.draft(essay: s.text, rubric: a.rubric, minWords: a.minWords)
        await MainActor.run {
            // Re-anchor against the original text (scrubbing could change a quote).
            let g = EssayCoach.guardComments(fb.comments, essay: s.text)
            var f = fb; f.comments = g.kept; f.guardNotes += g.notes.filter { !fb.guardNotes.contains($0) }
            mutate(sub) { $0.feedback = f }
        }
    }

    // MARK: Seed

    func seed() {
        let cal = Calendar.current
        func day(_ d: Int, hour: Int = 15) -> Date { cal.date(bySettingHour: hour, minute: 0, second: 0, of: cal.date(byAdding: .day, value: d, to: Date())!)! }

        students = SeedEssays.roster.map { r in
            let profile = ReadingProfile(rawValue: r.profile) ?? .standard
            return Student(name: r.name, avatar: r.avatar, prefs: .preset(profile),
                           accommodations: r.accommodations.compactMap(Accommodation.init(rawValue:)), supportNote: r.supportNote)
        }
        let all = students.map(\.id)
        let english = ClassGroup(name: "English 9", period: "Period 3", gradeBand: "Grade 9", joinCode: "ELLIS-3K7", studentIDs: all, art: "art-essay")
        let writersIDs = students.filter { ["Amara", "Theo", "Sofia", "Maya", "Omar", "Lucas", "Zara"].contains($0.firstName) }.map(\.id)
        let writers = ClassGroup(name: "Poetry & Voice", period: "Period 6", gradeBand: "Grade 9", joinCode: "ELLIS-6P2", studentIDs: writersIDs, art: "art-literature")
        let science = ClassGroup(name: "Earth Science", period: "Period 2", gradeBand: "Grade 9", joinCode: "ELLIS-2W5", studentIDs: all, art: "art-water")
        classes = [english, writers, science]

        // 1. Argument essay with submissions waiting for review.
        let essayDraft = AssignmentStudio.essay(AssignmentRequest(kind: .essay, topic: "Should our high school start the day at 9:00 a.m. instead of 7:45 a.m.?", gradeBand: "Grade 9", genre: .argumentative, minWords: 300))
        var lateStart = Assignment(classID: english.id, kind: .essay, title: "Later Start, Better Learning?", instructions: essayDraft.instructions, art: "art-essay",
                                   prompt: "Should our high school start the day at 9:00 a.m. instead of 7:45 a.m.? Take a position and support it with evidence and reasoning. Address at least one counterargument.",
                                   rubric: essayDraft.rubric, minWords: 300, standards: essayDraft.standards, dueDate: day(2), createdAt: day(-6), sentAt: day(-5, hour: 8),
                                   status: .sent, recipients: all, aiGenerated: true, provenance: "Drafted with on-device templates, edited by \(teacherName).")
        lateStart.provenance = "Prompt and rubric drafted by AI from the topic, then edited and approved by \(teacherName)."
        assignments.append(lateStart)
        for sid in all { submissions.append(Submission(assignmentID: lateStart.id, studentID: sid)) }
        for (i, e) in SeedEssays.lateStart.enumerated() {
            guard let st = students.first(where: { $0.name == e.studentName }), let idx = submissions.firstIndex(where: { $0.assignmentID == lateStart.id && $0.studentID == st.id }) else { continue }
            submissions[idx].text = e.text
            submissions[idx].status = .submitted
            submissions[idx].startedAt = day(-4 + i % 2, hour: 10)
            submissions[idx].submittedAt = day(-3 + i / 3, hour: 9 + i)
            submissions[idx].feedback = EssayCoach.draft(essay: e.text, rubric: lateStart.rubric, minWords: 300)
        }
        // A couple of students still drafting.
        for name in ["Zara Haddad", "Lucas Moreau"] {
            if let st = students.first(where: { $0.name == name }), let idx = submissions.firstIndex(where: { $0.assignmentID == lateStart.id && $0.studentID == st.id }) {
                submissions[idx].status = .inProgress; submissions[idx].startedAt = day(-1)
                submissions[idx].text = name.hasPrefix("Zara") ? "School should start later because teenagers' sleep cycles are different from adults'.\n\n" : ""
            }
        }
        // Maya's essay has already been reviewed and returned, so the student view has an example.
        if let maya = students.first(where: { $0.firstName == "Maya" }), let idx = submissions.firstIndex(where: { $0.assignmentID == lateStart.id && $0.studentID == maya.id }), var f = submissions[idx].feedback {
            for i in f.comments.indices { f.comments[i].state = .approved }
            if let i = f.comments.firstIndex(where: { $0.kind == .conventions }) { f.comments[i].state = .rejected }
            if let i = f.comments.firstIndex(where: { $0.kind == .strength }) {
                f.comments[i].edited = f.comments[i].draft + " This is the sentence I'd show the class as a model."
            }
            f.comments.append(FeedbackComment(quote: "effect", kind: .conventions, draft: "Small one: \"affect\" is the verb here (\"affect\" = to influence).", state: .approved, origin: .teacher))
            f.comments = EssayCoach.guardComments(f.comments, essay: submissions[idx].text).kept
            for i in f.scores.indices { f.scores[i].confirmed = f.scores[i].suggested }
            f.summaryApproved = true
            f.reviewSeconds = 205
            f.releasedAt = day(-1, hour: 17)
            submissions[idx].feedback = f
            submissions[idx].status = .returned
        }

        // 2. Reading assignment in Earth Science, with per-student formats.
        let reading = AssignmentStudio.reading(AssignmentRequest(kind: .reading, topic: "The Water Cycle", gradeBand: "Grade 9"))
        let readAssign = Assignment(classID: science.id, kind: .reading, title: "How Water Moves", instructions: reading.instructions, art: "art-water",
                                    sections: reading.sections, keyTerms: reading.keyTerms, standards: ["NGSS MS-ESS2-4"], dueDate: day(1, hour: 8),
                                    createdAt: day(-2), sentAt: day(-2, hour: 9), status: .sent, recipients: all, aiGenerated: true,
                                    provenance: "Lesson text from the reviewed curated library. Formats are generated on each student's iPad and preserve every sentence.")
        assignments.append(readAssign)
        for (i, s) in students.enumerated() {
            var sub = Submission(assignmentID: readAssign.id, studentID: s.id)
            let p = [1.0, 0.6, 1.0, 0.3, 1.0, 0.0, 0.8, 1.0, 0.0, 0.5, 1.0, 0.2][i % 12]
            sub.readingProgress = p
            sub.formatUsed = p > 0 ? s.prefs.profile.defaultFormat : nil
            sub.status = p >= 1 ? .submitted : p > 0 ? .inProgress : .assigned
            sub.submittedAt = p >= 1 ? day(-1, hour: 18) : nil
            submissions.append(sub)
        }

        // 3. Poem response in the writers' class.
        let poemRubric = AssignmentStudio.rubric(for: .literary)
        let poem = Assignment(classID: writers.id, kind: .essay, title: "A Small Moment: \u{201C}Dust of Snow\u{201D}", instructions: "Read the poem twice, once silently and once aloud. Then write 150–250 words. Use at least one quotation.", art: "art-literature",
                              prompt: SeedEssays.poemResponsePrompt, rubric: poemRubric, minWords: 150, sourceText: SeedEssays.dustOfSnow,
                              standards: ["CCSS.ELA-LITERACY.RL.9-10.4"], dueDate: day(-1), createdAt: day(-8), sentAt: day(-7, hour: 9),
                              status: .sent, recipients: writersIDs, aiGenerated: false, provenance: "Written by \(teacherName).")
        assignments.append(poem)
        for sid in writersIDs { submissions.append(Submission(assignmentID: poem.id, studentID: sid)) }
        for (i, e) in SeedEssays.poemResponses.enumerated() {
            guard let st = students.first(where: { $0.name == e.studentName }), let idx = submissions.firstIndex(where: { $0.assignmentID == poem.id && $0.studentID == st.id }) else { continue }
            submissions[idx].text = e.text; submissions[idx].status = .submitted
            submissions[idx].submittedAt = day(-2, hour: 10 + i)
            submissions[idx].feedback = EssayCoach.draft(essay: e.text, rubric: poemRubric, minWords: 150)
        }

        // 4. A draft quest the teacher hasn't sent yet.
        let quest = Assignment(classID: english.id, kind: .quest, title: "Introduction to Probability", instructions: AssignmentStudio.draft(.init(kind: .quest, topic: "Introduction to Probability", gradeBand: "Grade 9")).instructions,
                               art: "art-probability", topic: "Introduction to Probability", level: .beginner, dueDate: day(9), createdAt: day(0), status: .draft,
                               aiGenerated: true, provenance: "Course generated from the topic. Review chapters before sending.")
        assignments.append(quest)
        save()
    }
}
