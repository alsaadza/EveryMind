import SwiftUI

enum Route: Hashable {
    case create
    case world(UUID)
    case essay(UUID)       // submission
    case feedback(UUID)    // submission
    case reading(UUID)     // submission
}

struct StudentShell: View {
    var student: Student
    @Environment(AppStore.self) private var store
    @Environment(ClassroomStore.self) private var classroom
    @State private var path: [Route] = []
    @State private var sheet: StudentSheet?

    enum StudentSheet: String, Identifiable { case settings, library, badges, reading; var id: String { rawValue } }

    var body: some View {
        NavigationStack(path: $path) {
            StudentHome(student: student, path: $path, sheet: $sheet)
                .navigationDestination(for: Route.self) { r in
                    switch r {
                    case .create: CreateCourseView(path: $path)
                    case .world(let id): WorldView(courseID: id)
                    case .essay(let id): EssayWorkspaceView(submissionID: id, path: $path)
                    case .feedback(let id): StudentFeedbackView(submissionID: id, path: $path)
                    case .reading(let id): ReadingAssignmentView(submissionID: id)
                    }
                }
        }
        .sheet(item: $sheet) { s in
            switch s {
            case .settings: SettingsView().pageSheet()
            case .library: LibraryView(course: nil).pageSheet()
            case .badges: BadgesView()
            case .reading: MyReadingView().pageSheet()
            }
        }
        .task {
            // Debug/demo hook: `-autoDemo` builds the Probability course and jumps into the world.
            let args = ProcessInfo.processInfo.arguments
            if let i = args.firstIndex(of: "-studentSheet"), i + 1 < args.count { sheet = StudentSheet(rawValue: args[i + 1]); return }
            if let i = args.firstIndex(of: "-studentOpen"), i + 1 < args.count, path.isEmpty {
                let kind: AssignmentKind = args[i + 1] == "reading" ? .reading : args[i + 1] == "quest" ? .quest : .essay
                let subs = classroom.submissions.filter { $0.studentID == student.id && classroom.assignment($0.assignmentID)?.kind == kind }
                if args[i + 1] == "feedback", let s = subs.first(where: { $0.status == .returned }) { path = [.feedback(s.id)] }
                else if let s = subs.first(where: { $0.status != .returned && $0.status != .submitted }) ?? subs.first {
                    path = [kind == .reading ? .reading(s.id) : .essay(s.id)]
                }
                return
            }
            guard args.contains("-autoDemo"), path.isEmpty else { return }
            if store.courses.isEmpty {
                store.add(OfflineLibrary.course(for: CourseRequest(topic: "Introduction to Probability", level: .beginner, stage: .k12, goals: "")))
            }
            if let c = store.courses.first { path = [.world(c.id)] }
        }
    }
}

struct StudentHome: View {
    var student: Student
    @Binding var path: [Route]
    @Binding var sheet: StudentShell.StudentSheet?
    @Environment(AppStore.self) private var store
    @Environment(ClassroomStore.self) private var classroom

    var body: some View {
        let mine = classroom.assignments(for: student)
        let open = mine.filter { a in classroom.submission(assignment: a.id, student: student.id).map { $0.status != .returned && $0.status != .submitted } ?? true }
        let returned = mine.compactMap { a in classroom.submission(assignment: a.id, student: student.id).flatMap { $0.status == .returned ? ($0, a) : nil } }
        let waiting = mine.compactMap { a in classroom.submission(assignment: a.id, student: student.id).flatMap { $0.status == .submitted ? ($0, a) : nil } }

        ScrollView {
            VStack(alignment: .leading, spacing: 40) {
                header
                if !returned.isEmpty { feedbackBanner(returned) }
                VStack(alignment: .leading, spacing: 16) {
                    SectionHeader(eyebrow: "From \(classroom.teacherName)", title: open.isEmpty ? "You're all caught up" : "To do")
                    if open.isEmpty {
                        Text("Nothing due. Why not start a quest of your own below?").font(.mBody).foregroundStyle(Palette.inkSoft)
                    }
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 300), spacing: 20)], spacing: 20) {
                        ForEach(open) { a in todoCard(a) }
                    }
                    if !waiting.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(waiting, id: \.0.id) { sub, a in
                                Label {
                                    Text(a.kind == .reading ? "You finished \(a.title). Nice work." : "\(a.title) is with \(classroom.teacherName). Feedback arrives once they've reviewed it.")
                                } icon: { Image(systemName: a.kind == .reading ? "checkmark.circle" : "hourglass") }
                                .font(.mSubheadline).foregroundStyle(Palette.inkSoft)
                            }
                        }
                        .padding(.top, 4)
                    }
                }
                questSection
                readingCard
            }
            .padding(.horizontal, 44).padding(.vertical, 32)
        }
        .background(PaperBackground())
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 18) {
            PersonAvatar(asset: student.avatar, name: student.name, size: 68)
            VStack(alignment: .leading, spacing: 4) {
                Eyebrow(Date().formatted(.dateTime.weekday(.wide).month(.wide).day()))
                Text("Hi, \(student.firstName).").font(.mLargeTitle)
            }
            Spacer()
            HStack(spacing: 10) {
                Button { sheet = .reading } label: { Label(student.prefs.profile.title, systemImage: student.prefs.profile.symbol) }
                    .buttonStyle(.secondary(compact: true))
                    .accessibilityIdentifier("my-reading")
                iconButton("books.vertical", "Library: private help") { sheet = .library }
                iconButton("rosette", "Badges") { sheet = .badges }
                iconButton("gearshape", "Settings") { sheet = .settings }
                Menu {
                    Button { withAnimation { classroom.currentStudentID = nil } } label: { Label("Not \(student.firstName)? Switch student", systemImage: "person.2") }
                    Button { withAnimation { classroom.signOut() } } label: { Label("Sign out", systemImage: "rectangle.portrait.and.arrow.right") }
                } label: { circleIcon("person.crop.circle") }
                .accessibilityLabel("Account")
                .accessibilityIdentifier("student-account")
            }
        }
    }

    private func iconButton(_ symbol: String, _ label: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) { circleIcon(symbol) }.buttonStyle(.plain).accessibilityLabel(label)
    }

    private func circleIcon(_ symbol: String) -> some View {
        Image(systemName: symbol).font(.system(size: 17, weight: .medium)).foregroundStyle(Palette.ink)
            .frame(width: 42, height: 42)
            .background(Circle().fill(Palette.surface))
            .overlay(Circle().strokeBorder(Palette.rule))
    }

    private func feedbackBanner(_ items: [(Submission, Assignment)]) -> some View {
        let (sub, a) = items[0]
        return Button { path.append(.feedback(sub.id)) } label: {
            HStack(spacing: 22) {
                ArtCover(asset: a.art, height: 110, radius: 12).frame(width: 150)
                VStack(alignment: .leading, spacing: 8) {
                    Eyebrow("Feedback returned", color: Palette.forest)
                    Text(a.title).font(.display(24, .semibold)).multilineTextAlignment(.leading)
                    Text("\(classroom.teacherName) left \(sub.feedback?.approved.count ?? 0) comments on your writing\(sub.feedback?.releasedAt.map { ", \($0.shortRelative)" } ?? "").")
                        .font(.mSubheadline).foregroundStyle(Palette.inkSoft)
                }
                Spacer()
                Label("Read feedback", systemImage: "arrow.right").font(.mHeadline).foregroundStyle(Palette.forest)
            }
            .padding(18)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Palette.forestSoft.opacity(0.6)))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Palette.forest.opacity(0.25)))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("feedback-banner")
    }

    private func todoCard(_ a: Assignment) -> some View {
        let sub = classroom.submission(assignment: a.id, student: student.id)
        let due = classroom.dueDate(a, for: student)
        let extended = due != a.dueDate
        return Button { open(a, sub) } label: {
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .topLeading) {
                    ArtCover(asset: a.art, height: 140, radius: 0)
                    Tag(text: a.kind.title, symbol: a.kind.symbol, color: Palette.ink, fill: Palette.surface.opacity(0.92)).padding(12)
                }
                VStack(alignment: .leading, spacing: 10) {
                    Text(a.title).font(.display(21, .semibold)).multilineTextAlignment(.leading).lineLimit(2)
                    HStack(spacing: 6) {
                        Image(systemName: "calendar").font(.system(size: 12))
                        Text(due.dueLabel).font(.mFootnote.weight(.semibold))
                        if extended { Text("· extended time").font(.mFootnote).foregroundStyle(Palette.slate) }
                    }
                    .foregroundStyle(due.timeIntervalSinceNow < 86400 * 1.5 ? Palette.terracotta : Palette.inkSoft)
                    if a.kind == .reading, let sub {
                        HStack(spacing: 8) {
                            Meter(value: sub.readingProgress, height: 5)
                            Text("\(Int(sub.readingProgress * 100))%").font(.mCaption).monospacedDigit().foregroundStyle(Palette.inkSoft)
                        }
                    } else if a.kind == .essay {
                        Text("\(sub?.wordCount ?? 0) / \(classroom.minWords(a, for: student)) words\(sub?.version ?? 1 > 1 ? " · revision \(sub!.version)" : "")")
                            .font(.mCaption).foregroundStyle(Palette.inkSoft)
                    }
                    HStack {
                        Spacer()
                        Text(sub?.status == .inProgress ? "Continue" : "Start").font(.mHeadline).foregroundStyle(Palette.forest)
                        Image(systemName: "arrow.right").font(.system(size: 13, weight: .bold)).foregroundStyle(Palette.forest)
                    }
                }
                .padding(16)
            }
            .background(Palette.surface)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Palette.rule))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("todo-\(a.title)")
    }

    private func open(_ a: Assignment, _ sub: Submission?) {
        guard let sub else { return }
        switch a.kind {
        case .essay: path.append(.essay(sub.id))
        case .reading: path.append(.reading(sub.id))
        case .quest:
            if let cid = a.courseID, store.course(cid) != nil {
                classroom.mutate(sub.id) { if $0.status == .assigned { $0.status = .inProgress; $0.startedAt = Date() } }
                path.append(.world(cid))
            }
        }
    }

    private var questSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(eyebrow: "Learn anything", title: "Your quests", subtitle: "Turn any topic into a three-chapter book and a world to explore.")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 260), spacing: 20)], spacing: 20) {
                Button { path.append(.create) } label: {
                    VStack(alignment: .leading, spacing: 12) {
                        Image(systemName: "plus").font(.system(size: 22, weight: .medium)).foregroundStyle(Palette.forest)
                            .frame(width: 48, height: 48).background(Circle().fill(Palette.forestSoft))
                        Spacer()
                        Text("Create a quest").font(.display(22, .semibold))
                        Text("Pick a topic and a level. AI writes the book; you explore it.").font(.mFootnote).foregroundStyle(Palette.inkSoft).multilineTextAlignment(.leading)
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, minHeight: 210, alignment: .topLeading)
                    .background(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Palette.ruleStrong, style: StrokeStyle(lineWidth: 1.5, dash: [6, 5])))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("create-quest")
                ForEach(visibleCourses) { c in courseCard(c) }
            }
        }
    }

    /// Quests the student made, plus courses a teacher has actually sent them. Unsent drafts stay hidden.
    private var visibleCourses: [Course] {
        let teacherCourses = Dictionary(classroom.assignments.compactMap { a in a.courseID.map { ($0, a) } }, uniquingKeysWith: { a, _ in a })
        return store.courses.filter { c in
            guard let a = teacherCourses[c.id] else { return true }
            return a.status != .draft && a.recipients.contains(student.id)
        }
    }

    private func courseCard(_ c: Course) -> some View {
        let p = store.progress[c.id]
        let mastered = c.chapters.filter { p?.chapters[$0.id]?.status == .mastered }.count
        let art = ArtCatalog.cover(for: c.topic).asset
        return Button { path.append(.world(c.id)) } label: {
            ZStack(alignment: .bottomLeading) {
                ArtCover(asset: art, height: 210, radius: 18, scrim: true)
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Tag(text: c.level.label, color: .white, fill: .white.opacity(0.2))
                        if c.reviewStatus == .approved { Tag(text: "Teacher approved", symbol: "checkmark.shield", color: .white, fill: .white.opacity(0.2)) }
                    }
                    Text(c.topic).font(.display(24, .semibold)).foregroundStyle(.white).multilineTextAlignment(.leading).lineLimit(2)
                    HStack(spacing: 6) {
                        ForEach(c.chapters) { ch in
                            Capsule().fill(p?.chapters[ch.id]?.status == .mastered ? Palette.ochre : .white.opacity(0.35)).frame(height: 5)
                        }
                    }
                    Text("\(mastered) of \(c.chapters.count) chapters mastered · \(p?.xp ?? 0) XP").font(.mCaption).foregroundStyle(.white.opacity(0.85))
                }
                .padding(18)
            }
        }
        .buttonStyle(.plain)
        .contextMenu { Button(role: .destructive) { store.delete(c) } label: { Label("Delete quest", systemImage: "trash") } }
        .accessibilityLabel("\(c.topic), \(mastered) of \(c.chapters.count) chapters mastered")
    }

    private var readingCard: some View {
        Button { sheet = .reading } label: {
            HStack(alignment: .top, spacing: 18) {
                Image(systemName: student.prefs.profile.symbol).font(.system(size: 24)).foregroundStyle(Palette.forest)
                    .frame(width: 56, height: 56).background(Circle().fill(Palette.forestSoft))
                VStack(alignment: .leading, spacing: 6) {
                    Eyebrow("How you read")
                    Text("\(student.prefs.profile.title) · \(student.prefs.font.title)").font(.mTitle3)
                    Text("Every lesson can be read original, chunked, aloud or visual, with the same content in each. Change it any time.")
                        .font(.mSubheadline).foregroundStyle(Palette.inkSoft).multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(Palette.inkMuted)
            }
            .padding(20)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Palette.surface))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Palette.rule))
        }
        .buttonStyle(.plain)
    }
}

/// Student's own reading settings, with a live sample.
struct MyReadingView: View {
    @Environment(ClassroomStore.self) private var classroom
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            if let s = classroom.currentStudent {
                AdaptiveReader(sections: StudentDetailView.sample, keyTerms: [], prefs: s.prefs, initialFormat: s.prefs.profile.defaultFormat,
                               title: "Try it out", onProgress: { _ in }, onPrefsChange: { classroom.updatePrefs($0) })
                    .navigationTitle("How I read best")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            }
        }
    }
}

// MARK: - Reading assignment

struct ReadingAssignmentView: View {
    var submissionID: UUID
    @Environment(ClassroomStore.self) private var classroom
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        if let sub = classroom.submission(submissionID), let a = classroom.assignment(sub.assignmentID), let st = classroom.student(sub.studentID) {
            VStack(spacing: 0) {
                HStack(spacing: 14) {
                    Button { dismiss() } label: { Image(systemName: "chevron.left").font(.system(size: 17, weight: .semibold)) }
                        .foregroundStyle(Palette.inkSoft).accessibilityLabel("Back")
                    VStack(alignment: .leading, spacing: 1) {
                        Text(a.title).font(.display(20, .semibold))
                        Text("\(classroom.dueDate(a, for: st).dueLabel) · \(Int(sub.readingProgress * 100))% read").font(.mCaption).foregroundStyle(Palette.inkSoft)
                    }
                    Spacer()
                    Meter(value: sub.readingProgress, height: 5).frame(width: 160)
                }
                .padding(.horizontal, 22).padding(.vertical, 12)
                .background(Palette.surface)
                Rule()
                AdaptiveReader(sections: a.sections, keyTerms: a.keyTerms, prefs: st.prefs, initialFormat: sub.formatUsed ?? st.prefs.profile.defaultFormat,
                               title: a.title,
                               onProgress: { e in classroom.markReading(submissionID, progress: e.progress, format: e.format) },
                               onPrefsChange: { classroom.updatePrefs($0) },
                               allowAIStructure: classroom.aiStructureEnabled)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}
