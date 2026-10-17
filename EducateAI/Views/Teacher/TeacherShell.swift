import SwiftUI

enum TeacherSection: String, CaseIterable, Identifiable, Hashable {
    case today, feedback, assignments, classes, supports, insights, review, policies, settings
    var id: String { rawValue }
    var title: String {
        switch self {
        case .today: return "Today"
        case .feedback: return "Feedback queue"
        case .assignments: return "Assignments"
        case .classes: return "Classes"
        case .supports: return "Reading supports"
        case .insights: return "Class insights"
        case .review: return "Course review"
        case .policies: return "AI policies"
        case .settings: return "Settings"
        }
    }
    var symbol: String {
        switch self {
        case .today: return "sun.horizon"
        case .feedback: return "text.bubble"
        case .assignments: return "tray.full"
        case .classes: return "person.3"
        case .supports: return "accessibility"
        case .insights: return "chart.bar.xaxis"
        case .review: return "checkmark.shield"
        case .policies: return "slider.horizontal.3"
        case .settings: return "gearshape"
        }
    }
}

@Observable
final class TeacherNav {
    var section: TeacherSection? = .today
    var path = NavigationPath()
    /// The essay open in the full-screen review workspace.
    var reviewing: UUID?
    func review(_ id: UUID) { reviewing = id }
    func go(_ s: TeacherSection) { section = s; path = NavigationPath() }
}

enum TeacherRoute: Hashable {
    case review(UUID)          // submission
    case assignment(UUID)
    case builder(AssignmentKind?)
    case edit(UUID)
    case student(UUID)
    case classGroup(UUID)
}

struct TeacherShell: View {
    @Environment(ClassroomStore.self) private var classroom
    @Environment(AppStore.self) private var app
    @State private var nav = TeacherNav()
    @State private var visibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $visibility) {
            sidebar
                .navigationSplitViewColumnWidth(min: 250, ideal: 270, max: 300)
        } detail: {
            NavigationStack(path: $nav.path) {
                detail(nav.section ?? .today)
                    .navigationDestination(for: TeacherRoute.self) { r in
                        switch r {
                        case .review(let id): FeedbackReviewView(submissionID: id)
                        case .assignment(let id): AssignmentDetailView(assignmentID: id)
                        case .builder(let k): AssignmentBuilderView(initialKind: k)
                        case .edit(let id): AssignmentBuilderView(initialKind: nil, editing: classroom.assignment(id))
                        case .student(let id): StudentDetailView(studentID: id)
                        case .classGroup(let id): ClassDetailView(classID: id)
                        }
                    }
            }
        }
        .navigationSplitViewStyle(.balanced)
        .fullScreenCover(item: Binding(get: { nav.reviewing.map(IdentifiedID.init) }, set: { nav.reviewing = $0?.id })) { r in
            FeedbackReviewView(submissionID: r.id)
                .id(r.id)
                .environment(nav)
        }
        .environment(nav)
        .task { classroom.ensureQuestCourses(app); debugRoute() }
    }

    /// Demo/debug hooks: `-teacherOpen review Jonah`, `-teacherOpen section supports`, `-teacherOpen student Theo`, `-teacherOpen builder`, `-teacherOpen assignment Water`.
    private func debugRoute() {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-teacherOpen"), i + 1 < args.count else { return }
        let what = args[i + 1], target = i + 2 < args.count ? args[i + 2] : ""
        switch what {
        case "section": if let s = TeacherSection(rawValue: target) { nav.go(s) }
        case "review":
            if let st = classroom.students.first(where: { $0.firstName == target }),
               let sub = classroom.reviewQueue.first(where: { $0.studentID == st.id }) ?? classroom.submissions.first(where: { $0.studentID == st.id && $0.feedback != nil }) {
                nav.review((sub.id))
            }
        case "student": if let st = classroom.students.first(where: { $0.firstName == target }) { nav.path.append(TeacherRoute.student(st.id)) }
        case "builder": nav.path.append(TeacherRoute.builder(AssignmentKind(rawValue: target)))
        case "assignment": if let a = classroom.assignments.first(where: { $0.title.contains(target) }) { nav.path.append(TeacherRoute.assignment(a.id)) }
        default: break
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                Image("brand-mark").resizable().frame(width: 30, height: 30).clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                Text(Brand.name).font(.display(22, .semibold))
                Spacer()
                Tag(text: "Teacher", color: Palette.terracotta)
            }
            .padding(.horizontal, 20).padding(.top, 18).padding(.bottom, 22)

            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    group("Teach", [.today, .feedback, .assignments, .classes, .supports])
                    group("Oversee AI", [.insights, .review, .policies])
                    group("", [.settings])
                }
                .padding(.horizontal, 12)
            }
            Spacer(minLength: 0)
            Rule()
            HStack(spacing: 12) {
                PersonAvatar(asset: "avatar-15", name: classroom.teacherName, size: 38)
                VStack(alignment: .leading, spacing: 1) {
                    Text(classroom.teacherName).font(.mHeadline)
                    Text("\(classroom.classes.count) classes · \(classroom.students.count) students").font(.mCaption).foregroundStyle(Palette.inkMuted)
                }
                Spacer()
                Menu {
                    Button { withAnimation { classroom.role = .student; classroom.currentStudentID = nil } } label: { Label("Switch to student sign-in", systemImage: "backpack") }
                    Button { withAnimation { classroom.signOut() } } label: { Label("Sign out", systemImage: "rectangle.portrait.and.arrow.right") }
                } label: {
                    Image(systemName: "ellipsis.circle").font(.system(size: 20)).foregroundStyle(Palette.inkSoft)
                }
                .accessibilityLabel("Account")
                .accessibilityIdentifier("teacher-account")
            }
            .padding(16)
        }
        .background(Palette.paperDeep.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    private func group(_ title: String, _ items: [TeacherSection]) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            if !title.isEmpty { Eyebrow(title).padding(.horizontal, 10).padding(.top, 16).padding(.bottom, 6) } else { Spacer().frame(height: 16) }
            ForEach(items) { s in
                let selected = nav.section == s
                Button { nav.go(s) } label: {
                    HStack(spacing: 12) {
                        Image(systemName: s.symbol).font(.system(size: 15, weight: .medium)).frame(width: 22)
                            .foregroundStyle(selected ? Palette.forest : Palette.inkSoft)
                        Text(s.title).font(.ui(15.5, selected ? .semibold : .medium))
                        Spacer()
                        if s == .feedback, !classroom.reviewQueue.isEmpty {
                            Text("\(classroom.reviewQueue.count)").font(.ui(12, .bold)).monospacedDigit()
                                .padding(.horizontal, 7).padding(.vertical, 2)
                                .background(Capsule().fill(Palette.terracotta)).foregroundStyle(Palette.onAccent)
                        }
                    }
                    .padding(.horizontal, 10).padding(.vertical, 9)
                    .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(selected ? Palette.surface : .clear))
                    .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(selected ? Palette.rule : .clear))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("nav-\(s.rawValue)")
            }
        }
    }

    @ViewBuilder private func detail(_ s: TeacherSection) -> some View {
        switch s {
        case .today: TeacherTodayView()
        case .feedback: FeedbackQueueView()
        case .assignments: AssignmentsListView()
        case .classes: ClassesView()
        case .supports: SupportsView()
        case .insights: TeacherInsightsView()
        case .review: TeacherPage(title: "Course review", subtitle: "Approve, edit or flag AI-written course content before students rely on it.") { CourseReviewList() }
        case .policies: TeacherPage(title: "AI policies", subtitle: "Mastery thresholds, help levels and what the AI is allowed to do.") { PolicyView() }
        case .settings: TeacherPage(title: "Settings", subtitle: nil) { SettingsView(embedded: true) }
        }
    }
}

/// Hosts the older list-style screens inside the new paper chrome.
struct TeacherPage<Content: View>: View {
    var title: String
    var subtitle: String?
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title).font(.mTitle)
                if let subtitle { Text(subtitle).font(.mSubheadline).foregroundStyle(Palette.inkSoft) }
            }
            .padding(.horizontal, 40).padding(.top, 28).padding(.bottom, 12)
            content
                .scrollContentBackground(.hidden)
        }
        .background(PaperBackground())
        .toolbar(.hidden, for: .navigationBar)
    }
}

// MARK: - Today

struct TeacherTodayView: View {
    @Environment(ClassroomStore.self) private var classroom
    @Environment(TeacherNav.self) private var nav

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 36) {
                header
                stats
                HStack(alignment: .top, spacing: 28) {
                    VStack(alignment: .leading, spacing: 36) {
                        queuePreview
                        dueSoon
                    }
                    .frame(maxWidth: .infinity)
                    VStack(alignment: .leading, spacing: 28) {
                        checkIns
                        supportsSummary
                    }
                    .frame(width: 330)
                }
            }
            .padding(.horizontal, 40).padding(.vertical, 32)
        }
        .background(PaperBackground())
        .toolbar(.hidden, for: .navigationBar)
    }

    private var greeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        return h < 12 ? "Good morning" : h < 17 ? "Good afternoon" : "Good evening"
    }

    private var header: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 8) {
                Eyebrow(Date().formatted(.dateTime.weekday(.wide).month(.wide).day()))
                Text("\(greeting), \(classroom.teacherName).").font(.mLargeTitle)
                Text(classroom.reviewQueue.isEmpty ? "Your feedback queue is clear." : "\(classroom.reviewQueue.count) essays have AI-drafted feedback waiting for your review. Nothing reaches a student until you approve it.")
                    .font(.mBody).foregroundStyle(Palette.inkSoft)
            }
            Spacer()
            Button { nav.path.append(TeacherRoute.builder(nil)) } label: { Label("New assignment", systemImage: "plus") }
                .buttonStyle(.primary)
                .accessibilityIdentifier("today-new-assignment")
        }
    }

    private var stats: some View {
        let s = classroom.approvalStats
        let total = max(1, s.approved + s.edited + s.rejected)
        let hours = classroom.minutesSaved / 60
        return Surface(padding: 26) {
            HStack(alignment: .top, spacing: 0) {
                StatBlock(value: "\(classroom.reviewQueue.count)", label: "Essays to review", note: "Drafted the moment students submitted.")
                divider
                StatBlock(value: hours >= 1 ? String(format: "%.1f h", hours) : "\(Int(classroom.minutesSaved)) min", label: "Time back so far",
                          note: "vs. \(Int(classroom.baselineMinutesPerEssay)) min per essay by hand", color: Palette.forest)
                divider
                StatBlock(value: classroom.averageReviewMinutes == 0 ? "–" : String(format: "%.1f min", classroom.averageReviewMinutes), label: "Avg. review time", note: "Measured while you review.")
                divider
                StatBlock(value: "\(Int(Double(s.edited + s.rejected) / Double(total) * 100))%", label: "AI comments you changed",
                          note: "\(s.edited) edited · \(s.rejected) rejected · \(s.teacherAdded) added by you", color: Palette.terracotta)
            }
        }
    }

    private var divider: some View { Rectangle().fill(Palette.rule).frame(width: 1).padding(.horizontal, 22) }

    private var queuePreview: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(eyebrow: "Feedback", title: "Up next to review") {
                Button("See all") { nav.go(.feedback) }.font(.mHeadline)
            }
            if classroom.reviewQueue.isEmpty {
                Surface { Text("All caught up. New submissions appear here with a draft ready.").foregroundStyle(Palette.inkSoft) }
            } else {
                VStack(spacing: 0) {
                    ForEach(classroom.reviewQueue.prefix(5)) { sub in
                        QueueRow(submission: sub)
                        if sub.id != classroom.reviewQueue.prefix(5).last?.id { Rule().padding(.leading, 72) }
                    }
                }
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Palette.surface))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Palette.rule))
            }
        }
    }

    private var dueSoon: some View {
        let upcoming = classroom.assignments.filter { $0.status == .sent }.sorted { $0.dueDate < $1.dueDate }
        return VStack(alignment: .leading, spacing: 16) {
            SectionHeader(eyebrow: "This week", title: "Assignments in flight") {
                Button("All assignments") { nav.go(.assignments) }.font(.mHeadline)
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 250), spacing: 18)], spacing: 18) {
                ForEach(upcoming) { a in
                    Button { nav.path.append(TeacherRoute.assignment(a.id)) } label: { AssignmentCard(assignment: a) }
                        .buttonStyle(.plain)
                }
            }
        }
    }

    private var checkIns: some View {
        let soon = classroom.assignments.filter { $0.status == .sent && $0.dueDate.timeIntervalSinceNow < 3 * 86400 && $0.dueDate > Date() }
        let notStarted: [(Student, Assignment)] = soon.flatMap { a in
            classroom.submissions(for: a).filter { $0.status == .assigned }.compactMap { s in classroom.student(s.studentID).map { ($0, a) } }
        }
        return VStack(alignment: .leading, spacing: 14) {
            Eyebrow("Might need a check-in")
            if notStarted.isEmpty {
                Text("Everyone has started this week's work.").font(.mSubheadline).foregroundStyle(Palette.inkSoft)
            }
            ForEach(Array(notStarted.prefix(5).enumerated()), id: \.offset) { _, pair in
                Button { nav.path.append(TeacherRoute.student(pair.0.id)) } label: {
                    HStack(spacing: 12) {
                        PersonAvatar(asset: pair.0.avatar, name: pair.0.name, size: 34)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(pair.0.name).font(.mHeadline)
                            Text("Hasn't opened \u{201C}\(pair.1.title)\u{201D} · \(pair.1.dueDate.dueLabel)").font(.mFootnote).foregroundStyle(Palette.inkSoft).lineLimit(2)
                        }
                        Spacer(minLength: 0)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Palette.surface))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Palette.rule))
    }

    private var supportsSummary: some View {
        let counts = Dictionary(grouping: classroom.students, by: { $0.prefs.profile }).mapValues(\.count)
        return VStack(alignment: .leading, spacing: 14) {
            Eyebrow("Reading profiles in your classes")
            ForEach(ReadingProfile.allCases) { p in
                HStack(spacing: 10) {
                    Image(systemName: p.symbol).frame(width: 20).foregroundStyle(Palette.forest)
                    Text(p.title).font(.mSubheadline)
                    Spacer()
                    Text("\(counts[p] ?? 0)").font(.ui(15, .semibold)).monospacedDigit()
                }
            }
            Button("Manage supports") { nav.go(.supports) }.font(.mHeadline).padding(.top, 4)
            Text("Profiles change presentation only. Every format is checked against the original text.")
                .font(.mFootnote).foregroundStyle(Palette.inkMuted)
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Palette.surface))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Palette.rule))
    }
}

struct QueueRow: View {
    var submission: Submission
    @Environment(ClassroomStore.self) private var classroom
    @Environment(TeacherNav.self) private var nav
    var body: some View {
        let st = classroom.student(submission.studentID)
        let a = classroom.assignment(submission.assignmentID)
        let f = submission.feedback
        Button { nav.review((submission.id)) } label: {
            HStack(spacing: 14) {
                PersonAvatar(asset: st?.avatar ?? "", name: st?.name ?? "Student", size: 42)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(st?.name ?? "Student").font(.mHeadline)
                        if submission.version > 1 { Tag(text: "Revision \(submission.version)", color: Palette.slate) }
                    }
                    Text(a?.title ?? "").font(.mSubheadline).foregroundStyle(Palette.inkSoft).lineLimit(1)
                }
                Spacer()
                if let f {
                    VStack(alignment: .trailing, spacing: 4) {
                        if f.pendingCount < f.comments.count {
                            Tag(text: "\(f.comments.count - f.pendingCount)/\(f.comments.count) reviewed", color: Palette.ochre)
                        } else {
                            AIMark(text: "\(f.comments.count) draft comments")
                        }
                        Text("\(submission.wordCount) words · \(submission.submittedAt?.shortRelative ?? "")").font(.mCaption).foregroundStyle(Palette.inkMuted)
                    }
                } else {
                    ProgressView().controlSize(.small)
                }
                Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundStyle(Palette.inkMuted)
            }
            .padding(.horizontal, 16).padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("queue-\(st?.firstName ?? "")")
    }
}

struct AssignmentCard: View {
    var assignment: Assignment
    @Environment(ClassroomStore.self) private var classroom
    var body: some View {
        let subs = classroom.submissions(for: assignment)
        let done = subs.filter { $0.status == .submitted || $0.status == .returned }.count
        let cls = classroom.classGroup(assignment.classID)
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                ArtCover(asset: assignment.art, height: 120, radius: 0)
                Tag(text: assignment.kind.title, symbol: assignment.kind.symbol, color: Palette.ink, fill: Palette.surface.opacity(0.92))
                    .padding(12)
            }
            VStack(alignment: .leading, spacing: 8) {
                Text(assignment.title).font(.display(19, .semibold)).lineLimit(2).multilineTextAlignment(.leading)
                Text("\(cls?.name ?? "") · \(cls?.period ?? "")").font(.mFootnote).foregroundStyle(Palette.inkSoft)
                HStack {
                    Text(assignment.status == .draft ? "Draft, not sent" : assignment.dueDate.dueLabel).font(.mCaption).foregroundStyle(assignment.status == .draft ? Palette.ochre : Palette.inkSoft)
                    Spacer()
                    if assignment.status != .draft { Text("\(done)/\(subs.count) in").font(.mCaption).foregroundStyle(Palette.inkSoft).monospacedDigit() }
                }
                Meter(value: subs.isEmpty ? 0 : Double(done) / Double(subs.count), color: Palette.forest, height: 4)
            }
            .padding(16)
        }
        .background(Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Palette.rule))
        .contentShape(Rectangle())
    }
}

struct IdentifiedID: Identifiable { var id: UUID }
