import SwiftUI
import Charts

struct InsightsView: View {
    @Environment(AppStore.self) private var store
    @State private var courseIndex = 0
    @State private var epsilon = 1.0
    @State private var summary: String?
    @State private var summarizing = false
    @State private var gateway: InsightsEngine.GatewayInsights?

    var body: some View {
        if store.courses.isEmpty {
            ContentUnavailableView("No courses yet", systemImage: "chart.bar", description: Text("Create a course to see class insights."))
        } else {
            let course = store.courses[min(courseIndex, store.courses.count - 1)]
            let ins = InsightsEngine.build(course: course, store: store, k: 5, epsilon: epsilon)
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Picker("Course", selection: $courseIndex) {
                            ForEach(store.courses.indices, id: \.self) { Text(store.courses[$0].topic).tag($0) }
                        }
                        Spacer()
                        Label("~\(ins.learnerCount) learners · k ≥ \(ins.k) · ε = \(String(format: "%.1f", ins.epsilon))", systemImage: "lock.shield.fill").font(.mSubheadline).foregroundStyle(Theme.mint)
                    }
                    Text("Demo cohort: synthetic, de-identified learners\(ins.includesThisDevice ? " plus this device's opted-in signals" : ""). No individual data is shown.")
                        .font(.mFootnote).foregroundStyle(Palette.inkSoft)

                    HStack(alignment: .top, spacing: 20) {
                        Card {
                            VStack(alignment: .leading) {
                                Text("Mastery by chapter").font(.mHeadline)
                                Chart(ins.chapters) { c in
                                    BarMark(x: .value("Chapter", "Ch \(c.index + 1)"), y: .value("Mastery", c.masteryRate)).foregroundStyle(Theme.mint.gradient)
                                        .annotation(position: .top) { Text("\(Int(c.masteryRate * 100))%").font(.ui(12, .bold)) }
                                }
                                .chartYScale(domain: 0...1).frame(height: 200)
                            }
                        }
                        Card {
                            VStack(alignment: .leading) {
                                Text("Average hints per learner").font(.mHeadline)
                                Chart(ins.chapters) { c in
                                    BarMark(x: .value("Chapter", "Ch \(c.index + 1)"), y: .value("Hints", c.avgHints)).foregroundStyle(Theme.sun.gradient)
                                }
                                .frame(height: 200)
                            }
                        }
                    }

                    HStack(alignment: .top, spacing: 20) {
                        Card {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Common misconceptions").font(.mHeadline)
                                ForEach(ins.misconceptions.prefix(6)) { m in privRow(m.label.replacingOccurrences(of: "-", with: " "), m) }
                                if ins.misconceptions.isEmpty { Text("None detected").foregroundStyle(Palette.inkSoft) }
                            }
                        }
                        Card {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Anonymous concern themes").font(.mHeadline)
                                ForEach(ins.concernThemes) { m in privRow(m.label, m) }
                                Text("Urgent safety messages are never aggregated. Learners are routed to trusted adults directly.").font(.mCaption).foregroundStyle(Palette.inkSoft)
                            }
                        }
                    }

                    Card {
                        VStack(alignment: .leading) {
                            Text("Confidence vs. mastery (Chapter 1)").font(.mHeadline)
                            Chart(Array(ins.confidenceVsMastery.enumerated()), id: \.offset) { _, p in
                                PointMark(x: .value("Self-rated confidence", p.confidence), y: .value("Mastery", p.mastery)).foregroundStyle(Theme.accent.opacity(0.7))
                            }
                            .chartXScale(domain: 0.5...5.5).chartYScale(domain: 0...1).frame(height: 200)
                            Text("Learners in the lower right feel confident but haven't mastered it yet. A quick discussion can surface hidden misconceptions.").font(.mFootnote).foregroundStyle(Palette.inkSoft)
                        }
                    }

                    Card {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("AI teaching suggestions").font(.mHeadline)
                                Spacer()
                                AIBadge(detail: "Generated from the aggregated, noised statistics above only. No individual learner data. Suggestions are advisory; you decide what to do.")
                            }
                            if let summary { ReadingText(text: summary, size: 16) }
                            Button(summarizing ? "Thinking…" : (summary == nil ? "Summarize for me" : "Refresh")) { Task { await summarize(ins, course) } }
                                .buttonStyle(.borderedProminent).disabled(summarizing)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Privacy budget (ε): \(String(format: "%.1f", epsilon))").font(.ui(14, .semibold))
                        Slider(value: $epsilon, in: 0.2...3, step: 0.2)
                        Text("Lower ε means more noise and stronger privacy.").font(.mCaption).foregroundStyle(Palette.inkSoft)
                    }

                    if let gateway {
                        Card {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Live cohort from the gateway: \(gateway.cohort)").font(.mHeadline)
                                ForEach(gateway.items) { it in
                                    HStack {
                                        Text("\(it.kind) · \(it.tag)")
                                        Spacer()
                                        Text(it.suppressed ? "suppressed (< \(gateway.k))" : "\(it.count ?? 0)").monospacedDigit().foregroundStyle(it.suppressed ? .secondary : .primary)
                                    }
                                }
                                if let note = gateway.note { Text(note).font(.mCaption).foregroundStyle(Palette.inkSoft) }
                            }
                        }
                    }
                }
                .padding(24)
            }
            .task(id: store.settings.provider) { gateway = await InsightsEngine.fetchGateway(settings: store.settings) }
        }
    }

    private func privRow(_ label: String, _ item: ClassInsights.CountItem) -> some View {
        HStack {
            Text(label.capitalized)
            Spacer()
            if item.suppressed {
                Label("< 5, hidden", systemImage: "eye.slash").font(.mCaption).foregroundStyle(Palette.inkSoft)
            } else {
                Text("≈ \(item.count ?? 0)").monospacedDigit().bold()
            }
        }
    }

    private func summarize(_ ins: ClassInsights, _ course: Course) async {
        summarizing = true; defer { summarizing = false }
        let input = InsightSummaryInput(courseTopic: course.topic, learnerCount: ins.learnerCount,
                                        chapterStats: ins.chapters.map { (title: $0.title, masteryRate: $0.masteryRate, avgHints: $0.avgHints) },
                                        topMisconceptions: ins.misconceptions.compactMap { m in m.count.map { (tag: m.label, count: $0) } },
                                        concernThemes: ins.concernThemes.compactMap { m in m.count.map { (theme: m.label, count: $0) } })
        summary = await store.ai { try await $0.summarizeInsights(input) }
    }
}

// MARK: - Course review (human oversight)

struct CourseReviewList: View {
    @Environment(AppStore.self) private var store
    var body: some View {
        List {
            if store.courses.isEmpty { Text("No courses to review.").foregroundStyle(Palette.inkSoft) }
            ForEach(store.courses) { c in
                NavigationLink { CourseReviewDetail(courseID: c.id) } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(c.topic).font(.mHeadline)
                            Text("\(c.level.label) · \(c.generatedBy)").font(.mCaption).foregroundStyle(Palette.inkSoft)
                        }
                        Spacer()
                        Text(c.reviewStatus == .approved ? "Approved" : c.reviewStatus == .flagged ? "Flagged" : "Needs review")
                            .font(.ui(12, .bold)).padding(6)
                            .background(Capsule().fill((c.reviewStatus == .approved ? Theme.mint : c.reviewStatus == .flagged ? Theme.coral : Theme.sun).opacity(0.2)))
                    }
                }
            }
        }
    }
}

struct CourseReviewDetail: View {
    @Environment(AppStore.self) private var store
    var courseID: UUID
    @State private var note = ""

    var body: some View {
        if let course = store.course(courseID) {
            Form {
                Section {
                    LabeledContent("Status", value: course.reviewStatus.label)
                    LabeledContent("Engine", value: course.generatedBy)
                    Text(course.provenance).font(.mFootnote).foregroundStyle(Palette.inkSoft)
                    TextField("Note to learners (optional)", text: $note, axis: .vertical)
                    HStack {
                        Button { set(.approved) } label: { Label("Approve", systemImage: "checkmark.shield.fill") }.buttonStyle(.borderedProminent).tint(Theme.mint)
                        Button { set(.flagged) } label: { Label("Flag for revision", systemImage: "flag.fill") }.buttonStyle(.bordered).tint(Theme.coral)
                    }
                } header: { Text("Review decision") }
                ForEach(course.chapters.indices, id: \.self) { ci in
                    Section("Chapter \(ci + 1): \(course.chapters[ci].title)") {
                        ForEach(course.chapters[ci].sections.indices, id: \.self) { si in
                            NavigationLink {
                                SectionEditor(courseID: courseID, chapterIndex: ci, sectionIndex: si)
                            } label: {
                                HStack {
                                    Text(course.chapters[ci].sections[si].heading)
                                    if course.chapters[ci].sections[si].isAdaptive { Image(systemName: "sparkles").foregroundStyle(Theme.accent) }
                                }
                            }
                        }
                        ForEach(course.chapters[ci].challenges.indices, id: \.self) { qi in
                            NavigationLink {
                                ChallengeEditor(courseID: courseID, chapterIndex: ci, challengeIndex: qi)
                            } label: {
                                Label(course.chapters[ci].challenges[qi].prompt, systemImage: "flag.checkered").lineLimit(2)
                            }
                        }
                    }
                }
            }
            .navigationTitle(course.topic)
            .onAppear { note = course.educatorNote ?? "" }
        }
    }

    private func set(_ s: ReviewStatus) {
        guard var c = store.course(courseID) else { return }
        c.reviewStatus = s
        c.educatorNote = note.isEmpty ? nil : note
        store.update(c)
    }
}

struct SectionEditor: View {
    @Environment(AppStore.self) private var store
    var courseID: UUID; var chapterIndex: Int; var sectionIndex: Int
    @State private var heading = ""
    @State private var bodyText = ""
    @State private var saved = false
    var body: some View {
        Form {
            TextField("Heading", text: $heading)
            TextEditor(text: $bodyText).frame(minHeight: 400)
            Button(saved ? "Saved" : "Save changes") {
                guard var c = store.course(courseID) else { return }
                c.chapters[chapterIndex].sections[sectionIndex].heading = heading
                c.chapters[chapterIndex].sections[sectionIndex].body = bodyText
                store.update(c); saved = true
            }
            .buttonStyle(.borderedProminent)
        }
        .navigationTitle("Edit lesson")
        .onAppear {
            if let s = store.course(courseID)?.chapters[chapterIndex].sections[sectionIndex] { heading = s.heading; bodyText = s.body }
        }
    }
}

struct ChallengeEditor: View {
    @Environment(AppStore.self) private var store
    var courseID: UUID; var chapterIndex: Int; var challengeIndex: Int
    @State private var ch: Challenge?
    @State private var saved = false
    var body: some View {
        Form {
            if let binding = Binding($ch) {
                Section("Problem") {
                    TextField("Prompt", text: binding.prompt, axis: .vertical)
                    TextField("Correct answer", text: binding.correctAnswer)
                    LabeledContent("Type", value: binding.wrappedValue.answerType.rawValue)
                }
                Section("Hints (escalating)") {
                    ForEach(binding.wrappedValue.hints.indices, id: \.self) { i in TextField("Hint \(i + 1)", text: binding.hints[i], axis: .vertical) }
                }
                Section("Reasoning rubric (used to score explanations)") {
                    ForEach(binding.wrappedValue.rubric.indices, id: \.self) { i in
                        VStack(alignment: .leading) {
                            TextField("Idea", text: binding.rubric[i].idea)
                            Text("Keywords: " + binding.wrappedValue.rubric[i].keywords.joined(separator: ", ")).font(.mCaption).foregroundStyle(Palette.inkSoft)
                        }
                    }
                }
                Section("Worked solution") { TextField("Solution", text: binding.solution, axis: .vertical) }
                Button(saved ? "Saved" : "Save changes") {
                    guard var c = store.course(courseID), let ch else { return }
                    c.chapters[chapterIndex].challenges[challengeIndex] = ch
                    store.update(c); saved = true
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .navigationTitle("Edit challenge")
        .onAppear { ch = store.course(courseID)?.chapters[chapterIndex].challenges[challengeIndex] }
    }
}

// MARK: - Policy

struct PolicyView: View {
    @Environment(AppStore.self) private var store
    @Environment(ClassroomStore.self) private var classroom
    var body: some View {
        @Bindable var store = store
        @Bindable var classroom = classroom
        Form {
            Section {
                Toggle("AI drafts essay feedback for my review", isOn: $classroom.aiFeedbackEnabled)
                Toggle("AI may suggest chunk boundaries for reading formats", isOn: $classroom.aiStructureEnabled)
                VStack(alignment: .leading) {
                    Text("Minutes I'd spend writing feedback on one essay by hand: \(Int(classroom.baselineMinutesPerEssay))")
                    Slider(value: $classroom.baselineMinutesPerEssay, in: 3...30, step: 1)
                }
            } header: { Text("Feedback and formats") } footer: {
                Text("Whatever you choose, no comment reaches a student without your approval, and every reading format is checked against the original text. The baseline is only used for your \"time back\" estimate.")
            }
            Section {
                VStack(alignment: .leading) {
                    Text("Mastery needed to unlock the next chapter: \(Int(store.settings.masteryThreshold * 100))%")
                    Slider(value: $store.settings.masteryThreshold, in: 0.4...0.95, step: 0.05)
                }
                Stepper("Hints before the worked solution: \(store.settings.hintsBeforeSolution)", value: $store.settings.hintsBeforeSolution, in: 1...3)
                Picker("Most help the tutor may give", selection: $store.settings.maxHelpLevel) {
                    ForEach(HelpLevel.allCases) { Text($0.rawValue).tag($0) }
                }
                Toggle("Learners need approval before starting an AI-written course", isOn: $store.settings.requireApproval)
            } header: { Text("Learning policy") } footer: {
                Text("AI recommends; you decide. These settings apply on this device. In a school rollout they would be set centrally through the gateway.")
            }
            Section("Security") {
                LabeledContent("Teacher PIN") {
                    SecureField("4 digits", text: $store.settings.educatorPIN).keyboardType(.numberPad).multilineTextAlignment(.trailing)
                }
            }
        }
        .onChange(of: classroom.aiFeedbackEnabled) { _, _ in classroom.save() }
        .onChange(of: classroom.aiStructureEnabled) { _, _ in classroom.save() }
        .onChange(of: classroom.baselineMinutesPerEssay) { _, _ in classroom.save() }
    }
}
