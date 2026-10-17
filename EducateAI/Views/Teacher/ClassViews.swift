import SwiftUI

struct ClassesView: View {
    @Environment(ClassroomStore.self) private var classroom
    @Environment(TeacherNav.self) private var nav
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                VStack(alignment: .leading, spacing: 6) {
                    Eyebrow("\(classroom.students.count) students")
                    Text("Classes").font(.mLargeTitle)
                }
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 300), spacing: 20)], spacing: 20) {
                    ForEach(classroom.classes) { c in
                        Button { nav.path.append(TeacherRoute.classGroup(c.id)) } label: { classCard(c) }.buttonStyle(.plain)
                            .accessibilityIdentifier("class-\(c.name)")
                    }
                }
            }
            .padding(40)
        }
        .background(PaperBackground())
        .toolbar(.hidden, for: .navigationBar)
    }

    private func classCard(_ c: ClassGroup) -> some View {
        let roster = classroom.roster(c)
        let active = classroom.assignments.filter { $0.classID == c.id && $0.status == .sent }.count
        return VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                ArtCover(asset: c.art, height: 150, radius: 0, scrim: true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(c.name).font(.display(26, .semibold)).foregroundStyle(.white)
                    Text("\(c.period) · \(c.gradeBand)").font(.mSubheadline).foregroundStyle(.white.opacity(0.85))
                }.padding(16)
            }
            HStack {
                HStack(spacing: -10) {
                    ForEach(roster.prefix(6)) { s in PersonAvatar(asset: s.avatar, name: s.name, size: 32) }
                }
                if roster.count > 6 { Text("+\(roster.count - 6)").font(.mCaption).foregroundStyle(Palette.inkSoft).padding(.leading, 6) }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(active) active").font(.mHeadline)
                    Text("Join code \(c.joinCode)").font(.ui(12, .medium)).monospaced().foregroundStyle(Palette.inkMuted)
                }
            }
            .padding(16)
        }
        .background(Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Palette.rule))
    }
}

struct ClassDetailView: View {
    var classID: UUID
    @Environment(ClassroomStore.self) private var classroom
    @Environment(TeacherNav.self) private var nav
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        if let c = classroom.classGroup(classID) {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    ZStack(alignment: .bottomLeading) {
                        ArtCover(asset: c.art, height: 200, radius: 20, scrim: true)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(c.name).font(.display(38, .semibold)).foregroundStyle(.white)
                            Text("\(c.period) · \(c.gradeBand) · join code \(c.joinCode)").font(.mHeadline).foregroundStyle(.white.opacity(0.85))
                        }.padding(26)
                        VStack { HStack {
                            Button { dismiss() } label: { Image(systemName: "chevron.left").font(.system(size: 15, weight: .bold)).padding(10).background(Circle().fill(.ultraThinMaterial)) }
                                .foregroundStyle(.white).accessibilityLabel("Back")
                            Spacer() }; Spacer() }.padding(16)
                    }
                    .frame(height: 200)
                    Text("Roster").font(.mTitle3)
                    VStack(spacing: 0) {
                        ForEach(classroom.roster(c)) { s in
                            Button { nav.path.append(TeacherRoute.student(s.id)) } label: { StudentRow(student: s, classGroup: c) }.buttonStyle(.plain)
                            Rule().padding(.leading, 66)
                        }
                    }
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Palette.surface))
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Palette.rule))
                }
                .padding(40)
            }
            .background(PaperBackground())
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

struct StudentRow: View {
    var student: Student
    var classGroup: ClassGroup?
    @Environment(ClassroomStore.self) private var classroom
    var body: some View {
        let subs = classroom.submissions.filter { $0.studentID == student.id && (classGroup == nil || classroom.assignment($0.assignmentID)?.classID == classGroup?.id) }
        let done = subs.filter { $0.status == .submitted || $0.status == .returned }.count
        HStack(spacing: 14) {
            PersonAvatar(asset: student.avatar, name: student.name, size: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(student.name).font(.mHeadline)
                Text("\(done) of \(subs.count) assignments in").font(.mFootnote).foregroundStyle(Palette.inkSoft)
            }
            Spacer()
            if student.prefs.profile != .standard {
                Tag(text: student.prefs.profile.title, symbol: student.prefs.profile.symbol, color: Palette.slate)
            }
            ForEach(student.accommodations.prefix(3)) { a in
                Image(systemName: a.symbol).font(.system(size: 13)).foregroundStyle(Palette.inkMuted).help(a.title)
                    .accessibilityLabel(a.title)
            }
            Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundStyle(Palette.inkMuted)
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

struct StudentDetailView: View {
    var studentID: UUID
    @Environment(ClassroomStore.self) private var classroom
    @Environment(TeacherNav.self) private var nav
    @Environment(\.dismiss) private var dismiss
    @State private var preview = false

    var body: some View {
        if let s = classroom.student(studentID) {
            let binding = Binding(get: { classroom.student(studentID) ?? s }, set: { classroom.updateStudent($0) })
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    HStack {
                        Button { dismiss() } label: { Label("Back", systemImage: "chevron.left") }.font(.mHeadline).foregroundStyle(Palette.inkSoft)
                        Spacer()
                    }
                    HStack(spacing: 20) {
                        PersonAvatar(asset: s.avatar, name: s.name, size: 88)
                        VStack(alignment: .leading, spacing: 6) {
                            Text(s.name).font(.mLargeTitle)
                            Text(classroom.classes.filter { $0.studentIDs.contains(s.id) }.map { "\($0.name) · \($0.period)" }.joined(separator: "   ")).font(.mSubheadline).foregroundStyle(Palette.inkSoft)
                        }
                    }
                    HStack(alignment: .top, spacing: 26) {
                        VStack(alignment: .leading, spacing: 20) {
                            supports(binding)
                        }
                        .frame(maxWidth: .infinity)
                        VStack(alignment: .leading, spacing: 20) {
                            work(s)
                            note(binding)
                        }
                        .frame(width: 380)
                    }
                }
                .padding(40)
            }
            .background(PaperBackground())
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $preview) {
                NavigationStack {
                    AdaptiveReader(sections: Self.sample, keyTerms: [], prefs: binding.wrappedValue.prefs, initialFormat: binding.wrappedValue.prefs.profile.defaultFormat, title: "Sample lesson", onProgress: { _ in })
                        .navigationTitle("\(s.firstName)'s view").navigationBarTitleDisplayMode(.inline)
                        .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { preview = false } } }
                }
            }
        }
    }

    static var sample: [LessonSection] {
        let c = OfflineLibrary.course(for: CourseRequest(topic: "The Water Cycle", level: .beginner, stage: .k12, goals: ""))
        return Array(c.chapters.first?.sections.prefix(2) ?? [])
    }

    private func supports(_ b: Binding<Student>) -> some View {
        Surface {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Reading profile").font(.mTitle3)
                        Text("Sets the default format and typography. \(b.wrappedValue.firstName) can still switch formats, and nothing here changes lesson content.")
                            .font(.mFootnote).foregroundStyle(Palette.inkSoft)
                    }
                    Spacer()
                    Button { preview = true } label: { Label("Preview", systemImage: "eye") }.buttonStyle(.secondary(compact: true))
                        .accessibilityIdentifier("preview-student-view")
                }
                VStack(spacing: 8) {
                    ForEach(ReadingProfile.allCases) { p in
                        let on = b.wrappedValue.prefs.profile == p
                        Button { b.wrappedValue.prefs = .preset(p) } label: {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: p.symbol).frame(width: 24).foregroundStyle(on ? Palette.forest : Palette.inkSoft).padding(.top, 2)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(p.title).font(.mHeadline)
                                    Text(p.detail).font(.mFootnote).foregroundStyle(Palette.inkSoft).fixedSize(horizontal: false, vertical: true)
                                }
                                Spacer()
                                Image(systemName: on ? "largecircle.fill.circle" : "circle").foregroundStyle(on ? Palette.forest : Palette.inkMuted)
                            }
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 12).fill(on ? Palette.forestSoft.opacity(0.55) : .clear))
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("profile-\(p.rawValue)")
                    }
                }
                Rule()
                Text("Accommodations").font(.mTitle3)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(Accommodation.allCases) { a in
                        Toggle(isOn: Binding(get: { b.wrappedValue.accommodations.contains(a) }, set: { on in
                            if on { b.wrappedValue.accommodations.append(a) } else { b.wrappedValue.accommodations.removeAll { $0 == a } }
                        })) { Label(a.title, systemImage: a.symbol).font(.mSubheadline) }
                            .tint(Palette.forest)
                            .padding(10)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Palette.paper))
                    }
                }
                Text("Extended time moves due dates back 2 days. Reduced length lowers essay word targets to 70%. Both apply automatically.").font(.mFootnote).foregroundStyle(Palette.inkMuted)
            }
        }
    }

    private func work(_ s: Student) -> some View {
        let subs = classroom.submissions.filter { $0.studentID == s.id }
        return Surface {
            VStack(alignment: .leading, spacing: 12) {
                Eyebrow("Work")
                ForEach(subs) { sub in
                    if let a = classroom.assignment(sub.assignmentID) {
                        Button {
                            if a.kind == .essay && (sub.status == .submitted || sub.status == .returned) { nav.review((sub.id)) }
                            else { nav.path.append(TeacherRoute.assignment(a.id)) }
                        } label: {
                            HStack {
                                Image(systemName: a.kind.symbol).frame(width: 22).foregroundStyle(Palette.inkSoft)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(a.title).font(.mSubheadline.weight(.semibold)).lineLimit(1)
                                    Text(a.kind == .reading ? "\(Int(sub.readingProgress * 100))% read\(sub.formatUsed.map { " · \($0.title)" } ?? "")" : sub.status.label)
                                        .font(.mCaption).foregroundStyle(Palette.inkMuted)
                                }
                                Spacer()
                                Image(systemName: "chevron.right").font(.system(size: 11, weight: .semibold)).foregroundStyle(Palette.inkMuted)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func note(_ b: Binding<Student>) -> some View {
        Surface(fill: Palette.ochreSoft.opacity(0.45)) {
            VStack(alignment: .leading, spacing: 8) {
                Label("Private support note", systemImage: "lock").font(.mHeadline)
                TextField("e.g. 504 plan details, what helps", text: b.supportNote, axis: .vertical).font(.mSubheadline).lineLimit(3...8)
                Text("Visible to teachers only. Never shown to the student and never sent to an AI model.").font(.mCaption).foregroundStyle(Palette.inkMuted)
            }
        }
    }
}

struct SupportsView: View {
    @Environment(ClassroomStore.self) private var classroom
    @Environment(TeacherNav.self) private var nav
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 8) {
                    Eyebrow("Learning differences")
                    Text("Reading supports").font(.mLargeTitle)
                    Text("Students with dyslexia, ADHD or low vision usually get the same wall of text as everyone else. Margin presents every lesson five ways, without changing a word.")
                        .font(.mBody).foregroundStyle(Palette.inkSoft).frame(maxWidth: 720, alignment: .leading)
                }
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 200), spacing: 16)], spacing: 16) {
                    ForEach(ReadingProfile.allCases) { p in
                        let n = classroom.students.filter { $0.prefs.profile == p }.count
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: p.symbol).font(.system(size: 20)).foregroundStyle(Palette.forest)
                                Spacer()
                                Text("\(n)").font(.display(30)).monospacedDigit()
                            }
                            Text(p.title).font(.mHeadline)
                            Text(p.detail).font(.mFootnote).foregroundStyle(Palette.inkSoft).fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 0)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, minHeight: 190, alignment: .topLeading)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Palette.surface))
                        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Palette.rule))
                    }
                }
                Surface(fill: Palette.forestSoft.opacity(0.45)) {
                    HStack(alignment: .top, spacing: 14) {
                        Image(systemName: "checkmark.seal").font(.system(size: 24)).foregroundStyle(Palette.forest)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("The same-content guarantee").font(.mHeadline)
                            Text("Formats only regroup, highlight and read aloud the original sentences. When AI helps decide how to group them, it returns sentence numbers, never new text. Every format is then checked: every sentence, figure and key term must appear exactly once, or Margin falls back to the original.")
                                .font(.mSubheadline).foregroundStyle(Palette.inkSoft).fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                Text("Students").font(.mTitle3)
                VStack(spacing: 0) {
                    ForEach(classroom.students.sorted { ($0.prefs.profile == .standard ? 1 : 0, $0.name) < ($1.prefs.profile == .standard ? 1 : 0, $1.name) }) { s in
                        Button { nav.path.append(TeacherRoute.student(s.id)) } label: { StudentRow(student: s) }.buttonStyle(.plain)
                            .accessibilityIdentifier("support-\(s.firstName)")
                        Rule().padding(.leading, 66)
                    }
                }
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Palette.surface))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Palette.rule))
            }
            .padding(40)
        }
        .background(PaperBackground())
        .toolbar(.hidden, for: .navigationBar)
    }
}

struct FeedbackQueueView: View {
    @Environment(ClassroomStore.self) private var classroom
    @Environment(TeacherNav.self) private var nav
    var body: some View {
        let byAssignment = Dictionary(grouping: classroom.reviewQueue, by: \.assignmentID)
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 8) {
                    Eyebrow("\(classroom.reviewQueue.count) waiting")
                    Text("Feedback queue").font(.mLargeTitle)
                    Text("AI drafts margin comments, rubric scores and a glow-and-grow summary the moment a student submits. You approve, edit or reject each one. Students see only what you release.")
                        .font(.mBody).foregroundStyle(Palette.inkSoft).frame(maxWidth: 760, alignment: .leading)
                }
                if classroom.reviewQueue.isEmpty {
                    Surface {
                        HStack(spacing: 14) {
                            Image(systemName: "checkmark.circle").font(.system(size: 28)).foregroundStyle(Palette.forest)
                            Text("You're all caught up.").font(.mTitle3)
                        }
                    }
                }
                ForEach(Array(byAssignment.keys), id: \.self) { aid in
                    if let a = classroom.assignment(aid) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(a.title).font(.mTitle3)
                                Spacer()
                                if let first = byAssignment[aid]?.first {
                                    Button { nav.review((first.id)) } label: { Label("Start reviewing", systemImage: "play.fill") }
                                        .buttonStyle(.primary(Palette.forest, compact: true))
                                        .accessibilityIdentifier("start-reviewing")
                                }
                            }
                            VStack(spacing: 0) {
                                ForEach(byAssignment[aid] ?? []) { sub in
                                    QueueRow(submission: sub)
                                    Rule().padding(.leading, 72)
                                }
                            }
                            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Palette.surface))
                            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Palette.rule))
                        }
                    }
                }
            }
            .padding(40)
        }
        .background(PaperBackground())
        .toolbar(.hidden, for: .navigationBar)
    }
}
