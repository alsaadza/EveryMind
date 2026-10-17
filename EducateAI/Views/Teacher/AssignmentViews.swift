import SwiftUI
import Charts

// MARK: - List

struct AssignmentsListView: View {
    @Environment(ClassroomStore.self) private var classroom
    @Environment(TeacherNav.self) private var nav
    @State private var classFilter: UUID?
    @State private var status: AssignmentStatus = .sent

    var body: some View {
        let items = classroom.assignments.filter { (classFilter == nil || $0.classID == classFilter) && $0.status == status }
            .sorted { $0.dueDate < $1.dueDate }
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 6) {
                        Eyebrow("\(classroom.assignments.count) assignments across \(classroom.classes.count) classes")
                        Text("Assignments").font(.mLargeTitle)
                    }
                    Spacer()
                    Button { nav.path.append(TeacherRoute.builder(nil)) } label: { Label("New assignment", systemImage: "plus") }
                        .buttonStyle(.primary)
                        .accessibilityIdentifier("new-assignment")
                }
                HStack(spacing: 10) {
                    Picker("Status", selection: $status) {
                        Text("Active").tag(AssignmentStatus.sent)
                        Text("Drafts").tag(AssignmentStatus.draft)
                        Text("Closed").tag(AssignmentStatus.closed)
                    }
                    .pickerStyle(.segmented).frame(width: 300)
                    Spacer()
                    chip("All classes", classFilter == nil) { classFilter = nil }
                    ForEach(classroom.classes) { c in chip(c.name, classFilter == c.id) { classFilter = c.id } }
                }
                if items.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "tray").font(.system(size: 30)).foregroundStyle(Palette.inkMuted)
                        Text(status == .draft ? "No drafts. Start one with AI in under a minute." : "Nothing here yet.").foregroundStyle(Palette.inkSoft)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 60)
                }
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 270), spacing: 20)], spacing: 20) {
                    ForEach(items) { a in
                        Button { nav.path.append(TeacherRoute.assignment(a.id)) } label: { AssignmentCard(assignment: a) }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("assignment-\(a.title)")
                    }
                }
            }
            .padding(40)
        }
        .background(PaperBackground())
        .toolbar(.hidden, for: .navigationBar)
    }

    private func chip(_ t: String, _ on: Bool, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(t).font(.ui(14, .semibold))
                .padding(.horizontal, 14).padding(.vertical, 8)
                .foregroundStyle(on ? Palette.onAccent : Palette.inkSoft)
                .background(Capsule().fill(on ? Palette.ink : Palette.surface))
                .overlay(Capsule().strokeBorder(on ? .clear : Palette.rule))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Builder

struct AssignmentBuilderView: View {
    var initialKind: AssignmentKind?
    var editing: Assignment? = nil
    @Environment(ClassroomStore.self) private var classroom
    @Environment(AppStore.self) private var app
    @Environment(TeacherNav.self) private var nav
    @Environment(\.dismiss) private var dismiss

    @State private var kind: AssignmentKind = .essay
    @State private var classID: UUID?
    @State private var topic = ""
    @State private var genre: EssayGenre = .argumentative
    @State private var level: SkillLevel = .beginner
    @State private var minWords = 300
    @State private var notes = ""
    @State private var drafting = false
    @State private var draft: Assignment?
    @State private var recipients: Set<UUID> = []
    @State private var due = Calendar.current.date(byAdding: .day, value: 5, to: Date())!
    @State private var previewProfile: ReadingProfile?
    @State private var toast: String?
    @State private var aiSource = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                HStack {
                    Button { dismiss() } label: { Label("Assignments", systemImage: "chevron.left") }.font(.mHeadline).foregroundStyle(Palette.inkSoft)
                    Spacer()
                }
                VStack(alignment: .leading, spacing: 6) {
                    Eyebrow("New assignment")
                    Text("What should your students work on?").font(.mLargeTitle)
                }
                step(1, "Choose a format") { kindPicker }
                step(2, "Describe it") { details }
                if let draft {
                    step(3, "Review the AI draft") { draftEditor(draft) }
                    step(4, "Send") { sendPanel }
                }
            }
            .padding(40)
            .frame(maxWidth: 980, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(PaperBackground())
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            if let k = initialKind { kind = k }
            if classID == nil { classID = classroom.classes.first?.id }
            if let e = editing { load(e) }
        }
        .sheet(item: $previewProfile) { p in
            if let d = draft {
                NavigationStack {
                    AdaptiveReader(sections: d.sections, keyTerms: d.keyTerms, prefs: .preset(p), initialFormat: p.defaultFormat, title: d.title, onProgress: { _ in })
                        .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { previewProfile = nil } } }
                        .navigationTitle("Preview: \(p.title)").navigationBarTitleDisplayMode(.inline)
                }
            }
        }
        .toast($toast)
    }

    private func step<C: View>(_ n: Int, _ title: String, @ViewBuilder _ content: () -> C) -> some View {
        HStack(alignment: .top, spacing: 20) {
            Text("\(n)").font(.display(20, .semibold)).foregroundStyle(Palette.forest)
                .frame(width: 38, height: 38).background(Circle().strokeBorder(Palette.forest.opacity(0.4)))
            VStack(alignment: .leading, spacing: 16) {
                Text(title).font(.mTitle3)
                content()
            }
        }
    }

    private var kindPicker: some View {
        HStack(spacing: 16) {
            ForEach(AssignmentKind.allCases) { k in
                Button { withAnimation(.snappy) { kind = k; draft = nil } } label: {
                    VStack(alignment: .leading, spacing: 0) {
                        ArtCover(asset: k == .essay ? "art-essay" : k == .reading ? "art-literature" : "art-probability", height: 96, radius: 0)
                        VStack(alignment: .leading, spacing: 6) {
                            Label(k.title, systemImage: k.symbol).font(.mHeadline)
                            Text(k.blurb).font(.mFootnote).foregroundStyle(Palette.inkSoft).fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(14)
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, minHeight: 210, alignment: .top)
                    .background(Palette.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(kind == k ? Palette.forest : Palette.rule, lineWidth: kind == k ? 2 : 1))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("kind-\(k.rawValue)")
            }
        }
    }

    private var details: some View {
        Surface {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 16) {
                    labeled("Class") {
                        Picker("Class", selection: $classID) {
                            ForEach(classroom.classes) { c in Text("\(c.name) · \(c.period)").tag(Optional(c.id)) }
                        }.pickerStyle(.menu).tint(Palette.ink)
                    }
                    if kind == .essay {
                        labeled("Genre") {
                            Picker("Genre", selection: $genre) { ForEach(EssayGenre.allCases) { Text($0.title).tag($0) } }.pickerStyle(.menu).tint(Palette.ink)
                        }
                        labeled("Minimum words") {
                            Stepper("\(minWords)", value: $minWords, in: 100...1200, step: 50).font(.mHeadline).frame(width: 170)
                        }
                    } else {
                        labeled("Level") {
                            Picker("Level", selection: $level) { ForEach(SkillLevel.allCases) { Text($0.label).tag($0) } }.pickerStyle(.segmented).frame(width: 300)
                        }
                    }
                    Spacer()
                }
                labeled(kind == .essay ? "Topic or question" : "Topic") {
                    TextField(kind == .essay ? "e.g. Should cities ban cars from downtown?" : "e.g. The Water Cycle", text: $topic)
                        .font(.ui(18)).padding(12)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Palette.paper))
                        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Palette.rule))
                        .accessibilityIdentifier("builder-topic")
                }
                if kind != .quest {
                    labeled("Notes for the AI (optional)") {
                        TextField("e.g. connect to our unit on public health; avoid graphic content", text: $notes)
                            .font(.ui(16)).padding(12)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Palette.paper))
                            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Palette.rule))
                    }
                }
                HStack(spacing: 14) {
                    Button { Task { await generate() } } label: {
                        Label(drafting ? "Drafting…" : (draft == nil ? "Draft with AI" : "Redraft"), systemImage: "sparkles")
                    }
                    .buttonStyle(.primary(Palette.plum))
                    .disabled(topic.trimmingCharacters(in: .whitespaces).count < 3 || drafting)
                    .accessibilityIdentifier("draft-with-ai")
                    if drafting { ProgressView() }
                    Spacer()
                    if kind == .essay {
                        HStack(spacing: 6) {
                            ForEach(["Should cities ban cars downtown?", "Is social media good for teens?", "Should homework be optional?"], id: \.self) { s in
                                Button(s) { topic = s }.font(.ui(12.5, .medium)).buttonStyle(.bordered).tint(Palette.inkSoft)
                            }
                        }
                    } else {
                        HStack(spacing: 6) {
                            ForEach(OfflineLibrary.curatedTopics, id: \.self) { s in
                                Button(s) { topic = s }.font(.ui(12.5, .medium)).buttonStyle(.bordered).tint(Palette.inkSoft)
                            }
                        }
                    }
                }
            }
        }
    }

    private func labeled<C: View>(_ title: String, @ViewBuilder _ c: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 6) { Eyebrow(title); c() }
    }

    @MainActor private func generate() async {
        guard let cid = classID, let cls = classroom.classGroup(cid) else { return }
        drafting = true; defer { drafting = false }
        let req = AssignmentRequest(kind: kind, topic: topic.trimmingCharacters(in: .whitespaces), gradeBand: cls.gradeBand, genre: genre, level: level, minWords: minWords, notes: notes)
        let d = await app.ai { try await $0.draftAssignment(req) } ?? AssignmentStudio.draft(req)
        aiSource = d.generatedBy
        var a = Assignment(classID: cid, kind: kind, title: d.title, instructions: d.instructions, art: ArtCatalog.cover(for: topic).asset,
                           prompt: d.prompt, rubric: d.rubric, minWords: d.minWords, sections: d.sections, keyTerms: d.keyTerms,
                           topic: topic, level: level, standards: d.standards, dueDate: due, aiGenerated: true,
                           provenance: "Drafted by \(d.generatedBy) from the topic\(notes.isEmpty ? "" : " and your notes"). Edited and approved by \(classroom.teacherName).")
        if kind == .quest {
            let course = await app.ai { try await $0.generateCourse(CourseRequest(topic: topic, level: level, stage: .k12, goals: notes)) }
                ?? OfflineLibrary.course(for: CourseRequest(topic: topic, level: level, stage: .k12, goals: notes))
            app.add(course)
            a.courseID = course.id
            a.title = course.topic
        }
        withAnimation(.snappy) {
            draft = a
            if recipients.isEmpty { recipients = Set(cls.studentIDs) }
        }
    }

    private func load(_ e: Assignment) {
        kind = e.kind; classID = e.classID; topic = e.topic.isEmpty ? e.title : e.topic; draft = e; due = e.dueDate
        recipients = Set(e.recipients.isEmpty ? (classroom.classGroup(e.classID)?.studentIDs ?? []) : e.recipients)
        aiSource = e.provenance
    }

    private func draftEditor(_ d: Assignment) -> some View {
        let binding = Binding(get: { draft ?? d }, set: { draft = $0 })
        return VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 10) {
                AIMark(text: "Drafted by AI")
                Text("Everything below is editable. Students see the final version only after you send it.").font(.mFootnote).foregroundStyle(Palette.inkSoft)
            }
            Surface {
                VStack(alignment: .leading, spacing: 16) {
                    TextField("Title", text: binding.title).font(.display(26, .semibold)).accessibilityIdentifier("draft-title")
                    Rule()
                    labeled("Instructions") { TextField("Instructions", text: binding.instructions, axis: .vertical).font(.mBody).lineLimit(2...6) }
                    if d.kind == .essay {
                        labeled("Prompt") { TextField("Prompt", text: binding.prompt, axis: .vertical).font(.custom(Typeface.serif, size: 18)).lineLimit(2...8) }
                    }
                    if !d.standards.isEmpty {
                        HStack(spacing: 6) { ForEach(d.standards, id: \.self) { Tag(text: $0, color: Palette.slate) } }
                    }
                }
            }
            if d.kind == .essay { rubricEditor(binding) }
            if d.kind == .reading { readingEditor(binding) }
            if d.kind == .quest, let cid = d.courseID, let c = app.course(cid) {
                Surface {
                    VStack(alignment: .leading, spacing: 10) {
                        Eyebrow("Course outline")
                        ForEach(c.chapters) { ch in
                            HStack(alignment: .top, spacing: 12) {
                                Text("\(ch.index + 1)").font(.display(18, .semibold)).foregroundStyle(Palette.forest).frame(width: 22)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(ch.title).font(.mHeadline)
                                    Text("\(ch.sections.count) pages · \(ch.challenges.count) reasoning challenges · \(ch.locationName)").font(.mFootnote).foregroundStyle(Palette.inkSoft)
                                }
                            }
                        }
                        Text("Approve or edit individual pages in Course review.").font(.mFootnote).foregroundStyle(Palette.inkMuted)
                    }
                }
            }
        }
    }

    private func rubricEditor(_ b: Binding<Assignment>) -> some View {
        Surface {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Eyebrow("Rubric · \(b.wrappedValue.rubric.count) criteria · 4 levels")
                    Spacer()
                    Button { b.wrappedValue.rubric.append(RubricCriterion(name: "New criterion", detail: "", levels: ["", "", "", ""])) } label: { Label("Add criterion", systemImage: "plus") }
                        .font(.ui(13.5, .semibold))
                }
                Grid(alignment: .topLeading, horizontalSpacing: 10, verticalSpacing: 10) {
                    GridRow {
                        Text("").gridColumnAlignment(.leading)
                        ForEach(RubricCriterion.levelNames, id: \.self) { Eyebrow($0) }
                    }
                    ForEach(b.rubric) { $c in
                        GridRow {
                            VStack(alignment: .leading, spacing: 2) {
                                TextField("Criterion", text: $c.name).font(.mHeadline)
                                TextField("What it measures", text: $c.detail, axis: .vertical).font(.mFootnote).foregroundStyle(Palette.inkSoft)
                            }
                            .frame(width: 170, alignment: .leading)
                            ForEach(0..<4, id: \.self) { i in
                                TextField("", text: Binding(get: { c.levels[safe: i] ?? "" }, set: { v in
                                    while c.levels.count < 4 { c.levels.append("") }
                                    c.levels[i] = v
                                }), axis: .vertical)
                                .font(.ui(13)).lineLimit(2...5)
                                .padding(8).background(RoundedRectangle(cornerRadius: 8).fill(Palette.paper))
                            }
                        }
                        Divider().gridCellUnsizedAxes(.horizontal)
                    }
                }
            }
        }
    }

    private func readingEditor(_ b: Binding<Assignment>) -> some View {
        let src = LessonAdapter.Source(sections: b.wrappedValue.sections, extraTerms: b.wrappedValue.keyTerms)
        let chunked = LessonAdapter.chunks(src, size: 2)
        let report = LessonAdapter.fidelity(src, adaptedSentenceIDs: LessonAdapter.chunkOrder(chunked))
        let visualReport = LessonAdapter.fidelity(src, adaptedSentenceIDs: LessonAdapter.visualOrder(LessonAdapter.visual(src)))
        return VStack(alignment: .leading, spacing: 14) {
            Surface {
                VStack(alignment: .leading, spacing: 12) {
                    Eyebrow("\(b.wrappedValue.sections.count) pages · \(src.sentences.count) sentences · \(src.keyTerms.count) key terms")
                    Text("Wrap a key term in **double asterisks** where it's defined. Formats emphasise it and the visual version turns it into a term card.")
                        .font(.mFootnote).foregroundStyle(Palette.inkMuted)
                    ForEach(b.sections) { $s in
                        VStack(alignment: .leading, spacing: 6) {
                            TextField("Heading", text: $s.heading).font(.display(19, .semibold))
                            TextField("Body", text: $s.body, axis: .vertical).font(.custom(Typeface.serif, size: 16)).lineLimit(3...12)
                                .foregroundStyle(Palette.inkSoft)
                        }
                        Rule()
                    }
                }
            }
            Surface(fill: Palette.forestSoft.opacity(0.5)) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: report.passed && visualReport.passed ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                            .foregroundStyle(report.passed && visualReport.passed ? Palette.forest : Palette.terracotta)
                        Text("Same-content check").font(.mHeadline)
                    }
                    Text(report.summary + " Checked for the chunked, read-aloud and visual formats.").font(.mSubheadline).foregroundStyle(Palette.inkSoft)
                    HStack(spacing: 8) {
                        Text("Preview as:").font(.mFootnote).foregroundStyle(Palette.inkSoft)
                        ForEach(ReadingProfile.allCases) { p in
                            Button { previewProfile = p } label: { Label(p.title, systemImage: p.symbol) }
                                .buttonStyle(.bordered).font(.ui(13, .semibold)).tint(Palette.forest)
                                .accessibilityIdentifier("preview-\(p.rawValue)")
                        }
                    }
                }
            }
        }
    }

    private var sendPanel: some View {
        let cls = classID.flatMap(classroom.classGroup)
        let roster = cls.map(classroom.roster) ?? []
        let extended = roster.filter { recipients.contains($0.id) && $0.accommodations.contains(.extendedTime) }
        let reduced = roster.filter { recipients.contains($0.id) && $0.accommodations.contains(.reducedLength) }
        return Surface {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Eyebrow("Recipients · \(recipients.count) of \(roster.count)")
                    Spacer()
                    Button(recipients.count == roster.count ? "Clear" : "Whole class") {
                        recipients = recipients.count == roster.count ? [] : Set(roster.map(\.id))
                    }.font(.ui(13.5, .semibold))
                }
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 200), spacing: 8)], spacing: 8) {
                    ForEach(roster) { s in
                        let on = recipients.contains(s.id)
                        Button { if on { recipients.remove(s.id) } else { recipients.insert(s.id) } } label: {
                            HStack(spacing: 8) {
                                PersonAvatar(asset: s.avatar, name: s.name, size: 28)
                                Text(s.name).font(.ui(13.5, .medium)).lineLimit(1)
                                Spacer(minLength: 0)
                                Image(systemName: on ? "checkmark.circle.fill" : "circle").foregroundStyle(on ? Palette.forest : Palette.inkMuted)
                            }
                            .padding(8)
                            .background(RoundedRectangle(cornerRadius: 10).fill(on ? Palette.forestSoft.opacity(0.6) : Palette.paper))
                        }
                        .buttonStyle(.plain)
                    }
                }
                HStack(spacing: 20) {
                    DatePicker("Due", selection: $due, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                        .font(.mHeadline).frame(maxWidth: 360)
                    Spacer()
                }
                if !extended.isEmpty || !reduced.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Accommodations apply automatically", systemImage: "accessibility").font(.mHeadline).foregroundStyle(Palette.slate)
                        if !extended.isEmpty {
                            Text("Extended time (+2 days): \(extended.map(\.firstName).joined(separator: ", "))").font(.mFootnote).foregroundStyle(Palette.inkSoft)
                        }
                        if kind == .essay, !reduced.isEmpty {
                            Text("Reduced length (70% of \(minWords) words): \(reduced.map(\.firstName).joined(separator: ", "))").font(.mFootnote).foregroundStyle(Palette.inkSoft)
                        }
                        Text("Reading formats follow each student's profile. Students can switch formats at any time.").font(.mFootnote).foregroundStyle(Palette.inkSoft)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Palette.slateSoft.opacity(0.6)))
                }
                HStack {
                    Button("Save as draft") { save(send: false) }.buttonStyle(.secondary)
                    Spacer()
                    Button { save(send: true) } label: { Label("Send to \(recipients.count) student\(recipients.count == 1 ? "" : "s")", systemImage: "paperplane.fill") }
                        .buttonStyle(.primary)
                        .disabled(recipients.isEmpty)
                        .accessibilityIdentifier("send-assignment")
                }
            }
        }
    }

    private func save(send: Bool) {
        guard var a = draft else { return }
        a.dueDate = due
        a.minWords = a.kind == .essay ? minWords : a.minWords
        if let cid = a.courseID, var c = app.course(cid), send {
            c.reviewStatus = .approved; c.educatorNote = "Assigned by \(classroom.teacherName)."
            app.update(c)
        }
        if send { classroom.send(a, to: Array(recipients)) } else { a.recipients = Array(recipients); classroom.upsert(a) }
        nav.path = NavigationPath()
        nav.path.append(TeacherRoute.assignment(a.id))
    }
}


// MARK: - Detail

struct AssignmentDetailView: View {
    var assignmentID: UUID
    @Environment(ClassroomStore.self) private var classroom
    @Environment(TeacherNav.self) private var nav
    @Environment(\.dismiss) private var dismiss
    @State private var showPrompt = true
    @State private var previewProfile: ReadingProfile?
    @State private var confirmDelete = false

    var body: some View {
        if let a = classroom.assignment(assignmentID) {
            let subs = classroom.submissions(for: a)
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    hero(a)
                    if a.status == .draft {
                        Surface(fill: Palette.ochreSoft.opacity(0.6)) {
                            HStack {
                                Label("This assignment is a draft. Students can't see it yet.", systemImage: "pencil.and.outline").font(.mHeadline)
                                Spacer()
                                Button("Edit and send") { nav.path.append(TeacherRoute.edit(a.id)) }.buttonStyle(.primary(Palette.forest, compact: true))
                            }
                        }
                    } else {
                        statusStrip(subs)
                    }
                    HStack(alignment: .top, spacing: 26) {
                        roster(a, subs).frame(maxWidth: .infinity)
                        VStack(alignment: .leading, spacing: 20) {
                            content(a)
                            if a.kind == .reading { formatsChart(subs) }
                        }
                        .frame(width: 360)
                    }
                }
                .padding(40)
            }
            .background(PaperBackground())
            .toolbar(.hidden, for: .navigationBar)
            .sheet(item: $previewProfile) { p in
                NavigationStack {
                    AdaptiveReader(sections: a.sections, keyTerms: a.keyTerms, prefs: .preset(p), initialFormat: p.defaultFormat, title: a.title, onProgress: { _ in })
                        .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { previewProfile = nil } } }
                        .navigationTitle("Preview: \(p.title)").navigationBarTitleDisplayMode(.inline)
                }
            }
            .confirmationDialog("Delete this assignment and all submissions?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Delete", role: .destructive) { classroom.deleteAssignment(a); dismiss() }
            }
        }
    }

    private func hero(_ a: Assignment) -> some View {
        let cls = classroom.classGroup(a.classID)
        return ZStack(alignment: .bottomLeading) {
            ArtCover(asset: a.art, height: 240, radius: 20, scrim: true)
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Tag(text: a.kind.title, symbol: a.kind.symbol, color: .white, fill: .white.opacity(0.2))
                    if a.aiGenerated { Tag(text: "AI-assisted, teacher-approved", symbol: "sparkle", color: .white, fill: .white.opacity(0.2)) }
                }
                Text(a.title).font(.display(36, .semibold)).foregroundStyle(.white).lineLimit(2).minimumScaleFactor(0.7)
                Text("\(cls?.name ?? "") · \(cls?.period ?? "") · \(a.status == .draft ? "Draft" : a.dueDate.dueLabel)").font(.mHeadline).foregroundStyle(.white.opacity(0.85))
            }
            .padding(28)
            VStack {
                HStack {
                    Button { dismiss() } label: { Image(systemName: "chevron.left").font(.system(size: 15, weight: .bold)).padding(10).background(Circle().fill(.ultraThinMaterial)) }
                        .foregroundStyle(.white).accessibilityLabel("Back")
                    Spacer()
                    Menu {
                        if a.status == .sent { Button { var x = a; x.status = .closed; classroom.upsert(x) } label: { Label("Close assignment", systemImage: "archivebox") } }
                        Button(role: .destructive) { confirmDelete = true } label: { Label("Delete", systemImage: "trash") }
                    } label: { Image(systemName: "ellipsis").font(.system(size: 15, weight: .bold)).padding(12).background(Circle().fill(.ultraThinMaterial)) }
                        .foregroundStyle(.white)
                }
                Spacer()
            }
            .padding(16)
            HStack { Spacer(); VStack { Spacer(); ArtCreditOverlay(asset: a.art) } }.padding(12)
        }
        .frame(height: 240)
    }

    private func statusStrip(_ subs: [Submission]) -> some View {
        let returned = subs.filter { $0.status == .returned }.count
        let submitted = subs.filter { $0.status == .submitted }.count
        let inProgress = subs.filter { $0.status == .inProgress }.count
        let notStarted = subs.filter { $0.status == .assigned }.count
        return Surface(padding: 22) {
            HStack(spacing: 0) {
                StatBlock(value: "\(submitted)", label: "Submitted", note: "Waiting for review")
                Rectangle().fill(Palette.rule).frame(width: 1).padding(.horizontal, 20)
                StatBlock(value: "\(returned)", label: "Returned", color: Palette.forest)
                Rectangle().fill(Palette.rule).frame(width: 1).padding(.horizontal, 20)
                StatBlock(value: "\(inProgress)", label: "In progress", color: Palette.ochre)
                Rectangle().fill(Palette.rule).frame(width: 1).padding(.horizontal, 20)
                StatBlock(value: "\(notStarted)", label: "Not started", color: Palette.terracotta)
            }
        }
    }

    private func roster(_ a: Assignment, _ subs: [Submission]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Students").font(.mTitle3)
            VStack(spacing: 0) {
                ForEach(subs.sorted { order($0) < order($1) }) { sub in
                    if let st = classroom.student(sub.studentID) {
                        row(a, sub, st)
                        Rule().padding(.leading, 64)
                    }
                }
            }
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Palette.surface))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Palette.rule))
        }
    }

    private func order(_ s: Submission) -> Int {
        switch s.status { case .submitted: return 0; case .inProgress: return 1; case .assigned: return 2; case .returned: return 3 }
    }

    private func row(_ a: Assignment, _ sub: Submission, _ st: Student) -> some View {
        HStack(spacing: 14) {
            PersonAvatar(asset: st.avatar, name: st.name, size: 38)
            VStack(alignment: .leading, spacing: 2) {
                Text(st.name).font(.mHeadline)
                HStack(spacing: 6) {
                    if a.kind == .reading {
                        Text(sub.formatUsed.map { "\($0.title) format" } ?? "Not opened").font(.mFootnote).foregroundStyle(Palette.inkSoft)
                    } else if a.kind == .essay {
                        Text(sub.wordCount > 0 ? "\(sub.wordCount) words" : "No text yet").font(.mFootnote).foregroundStyle(Palette.inkSoft)
                    }
                    if st.accommodations.contains(.extendedTime) {
                        Text("· due \(classroom.dueDate(a, for: st).formatted(.dateTime.month(.abbreviated).day()))").font(.mFootnote).foregroundStyle(Palette.slate)
                    }
                }
            }
            Spacer()
            if a.kind == .reading {
                Meter(value: sub.readingProgress, height: 5).frame(width: 110)
                Text("\(Int(sub.readingProgress * 100))%").font(.ui(13, .semibold)).monospacedDigit().frame(width: 42, alignment: .trailing)
            } else {
                statusTag(sub)
            }
            if a.kind == .essay && (sub.status == .submitted || sub.status == .returned) {
                Button { nav.review((sub.id)) } label: {
                    Text(sub.status == .submitted ? "Review" : "Open").font(.ui(13.5, .semibold))
                }
                .buttonStyle(.primary(sub.status == .submitted ? Palette.forest : Palette.inkSoft, compact: true))
                .accessibilityIdentifier("review-\(st.firstName)")
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
    }

    private func statusTag(_ s: Submission) -> some View {
        switch s.status {
        case .assigned: return Tag(text: "Not started", color: Palette.inkMuted)
        case .inProgress: return Tag(text: "Drafting", color: Palette.ochre)
        case .submitted: return Tag(text: "Needs review", color: Palette.terracotta)
        case .returned: return Tag(text: "Returned", symbol: "checkmark", color: Palette.forest)
        }
    }

    @ViewBuilder private func content(_ a: Assignment) -> some View {
        Surface {
            VStack(alignment: .leading, spacing: 12) {
                Eyebrow(a.kind == .essay ? "Prompt" : a.kind == .reading ? "Lesson" : "Course")
                if a.kind == .essay {
                    Text(a.prompt).font(.custom(Typeface.serif, size: 17)).fixedSize(horizontal: false, vertical: true)
                    if !a.rubric.isEmpty {
                        Rule()
                        Eyebrow("Rubric")
                        ForEach(a.rubric) { c in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(c.name).font(.mHeadline)
                                Text(c.detail).font(.mFootnote).foregroundStyle(Palette.inkSoft)
                            }
                        }
                    }
                } else if a.kind == .reading {
                    ForEach(a.sections) { s in Label(s.heading, systemImage: "doc.text").font(.mSubheadline) }
                    Rule()
                    Text("Preview as a student would see it:").font(.mFootnote).foregroundStyle(Palette.inkSoft)
                    FlowRow(spacing: 6) {
                        ForEach(ReadingProfile.allCases) { p in
                            Button { previewProfile = p } label: { Label(p.title, systemImage: p.symbol) }
                                .buttonStyle(.bordered).font(.ui(12.5, .semibold)).tint(Palette.forest)
                        }
                    }
                } else {
                    Text(a.instructions).font(.mCallout).foregroundStyle(Palette.inkSoft)
                }
                Rule()
                Text(a.provenance).font(.mFootnote).foregroundStyle(Palette.inkMuted).fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func formatsChart(_ subs: [Submission]) -> some View {
        let used = Dictionary(grouping: subs.compactMap(\.formatUsed), by: { $0 }).mapValues(\.count)
        return Surface {
            VStack(alignment: .leading, spacing: 12) {
                Eyebrow("Formats students chose")
                Chart(LessonFormat.allCases) { f in
                    BarMark(x: .value("Students", used[f] ?? 0), y: .value("Format", f.title))
                        .foregroundStyle(Palette.forest.gradient)
                        .cornerRadius(4)
                        .annotation(position: .trailing) { Text("\(used[f] ?? 0)").font(.mCaption).foregroundStyle(Palette.inkSoft) }
                }
                .chartXAxis(.hidden)
                .frame(height: 150)
                Text("Same lesson, same checkpoints. Only the presentation differs.").font(.mFootnote).foregroundStyle(Palette.inkMuted)
            }
        }
    }
}

struct ArtCreditOverlay: View {
    var asset: String
    var body: some View {
        let p = ArtCatalog.piece(asset)
        Text("\(p.title), \(p.artist)").font(.ui(10)).italic().foregroundStyle(.white.opacity(0.65)).lineLimit(1)
    }
}

/// Simple wrapping row of small views.
struct FlowRow: Layout {
    var spacing: CGFloat = 8
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 600
        var x: CGFloat = 0, y: CGFloat = 0, rowH: CGFloat = 0
        for v in subviews {
            let s = v.sizeThatFits(.unspecified)
            if x + s.width > width, x > 0 { x = 0; y += rowH + spacing; rowH = 0 }
            x += s.width + spacing; rowH = max(rowH, s.height)
        }
        return CGSize(width: width, height: y + rowH)
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowH: CGFloat = 0
        for v in subviews {
            let s = v.sizeThatFits(.unspecified)
            if x + s.width > bounds.maxX, x > bounds.minX { x = bounds.minX; y += rowH + spacing; rowH = 0 }
            v.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(s))
            x += s.width + spacing; rowH = max(rowH, s.height)
        }
    }
}
