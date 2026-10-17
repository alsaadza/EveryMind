import SwiftUI
import Charts

/// Class-level patterns from essays and readings. Teacher-only; nothing here leaves the iPad.
struct TeacherInsightsView: View {
    @Environment(ClassroomStore.self) private var classroom
    @Environment(AppStore.self) private var app
    @Environment(TeacherNav.self) private var nav
    @State private var assignmentID: UUID?

    var essays: [Assignment] { classroom.assignments.filter { $0.kind == .essay && $0.status != .draft } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                VStack(alignment: .leading, spacing: 8) {
                    Eyebrow("Patterns, not surveillance")
                    Text("Class insights").font(.mLargeTitle)
                    Text("Where your class is as writers and readers, drawn from rubric levels and reading activity. Use it to plan tomorrow's mini-lesson.")
                        .font(.mBody).foregroundStyle(Palette.inkSoft).frame(maxWidth: 720, alignment: .leading)
                }
                if let a = essays.first(where: { $0.id == assignmentID }) ?? essays.first {
                    Picker("Assignment", selection: Binding(get: { a.id }, set: { assignmentID = $0 })) {
                        ForEach(essays) { Text($0.title).tag($0.id) }
                    }
                    .pickerStyle(.segmented).frame(maxWidth: 640)
                    writing(a)
                }
                reading
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(eyebrow: "Quest courses", title: "Mastery and misconceptions", subtitle: "Privacy-protected: groups under 5 are hidden and counts carry statistical noise.")
                    InsightsView().frame(minHeight: 600)
                }
            }
            .padding(40)
        }
        .background(PaperBackground())
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: Writing

    private func level(_ s: Submission, _ c: RubricCriterion) -> Int? {
        guard let sc = s.feedback?.scores.first(where: { $0.criterionID == c.id }) else { return nil }
        return sc.confirmed ?? sc.suggested
    }

    private func writing(_ a: Assignment) -> some View {
        let subs = classroom.submissions(for: a).filter { $0.feedback != nil }
        let avg: [(RubricCriterion, Double)] = a.rubric.map { c in
            let ls = subs.compactMap { level($0, c) }
            return (c, ls.isEmpty ? 0 : Double(ls.reduce(0, +)) / Double(ls.count))
        }
        let weakest = avg.min { $0.1 < $1.1 }
        let grows = subs.compactMap { $0.feedback?.grow }
        let growThemes = Dictionary(grouping: grows, by: theme).mapValues(\.count).sorted { $0.value > $1.value }

        return VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top, spacing: 20) {
                Surface {
                    VStack(alignment: .leading, spacing: 14) {
                        Eyebrow("Rubric levels · \(subs.count) essays")
                        heatmap(a, subs)
                        HStack(spacing: 14) {
                            ForEach(0..<4, id: \.self) { l in
                                HStack(spacing: 5) {
                                    RoundedRectangle(cornerRadius: 3).fill(color(l)).frame(width: 14, height: 14)
                                    Text(RubricCriterion.levelNames[l]).font(.mCaption).foregroundStyle(Palette.inkSoft)
                                }
                            }
                            Spacer()
                            Text("✓ = confirmed by you; others are AI suggestions awaiting review").font(.mCaption).foregroundStyle(Palette.inkMuted)
                        }
                    }
                }
                VStack(alignment: .leading, spacing: 20) {
                    if let weakest {
                        Surface(fill: Palette.ochreSoft.opacity(0.55)) {
                            VStack(alignment: .leading, spacing: 8) {
                                Eyebrow("Suggested mini-lesson", color: Palette.ochre)
                                Text(weakest.0.name).font(.mTitle2)
                                Text(lesson(for: weakest.0.name)).font(.mSubheadline).foregroundStyle(Palette.inkSoft).fixedSize(horizontal: false, vertical: true)
                                Text(String(format: "Class average %.1f of 4", weakest.1 + 1)).font(.mCaption).foregroundStyle(Palette.inkMuted)
                            }
                        }
                    }
                    Surface {
                        VStack(alignment: .leading, spacing: 10) {
                            Eyebrow("Most common next steps")
                            ForEach(growThemes.prefix(4), id: \.key) { k, v in
                                HStack {
                                    Text(k).font(.mSubheadline)
                                    Spacer()
                                    Text("\(v)").font(.ui(15, .semibold)).monospacedDigit()
                                }
                            }
                        }
                    }
                }
                .frame(width: 330)
            }
            Surface {
                VStack(alignment: .leading, spacing: 12) {
                    Eyebrow("Average level by criterion")
                    Chart(avg, id: \.0.id) { c, v in
                        BarMark(x: .value("Level", v + 1), y: .value("Criterion", c.name))
                            .foregroundStyle(Palette.forest.gradient).cornerRadius(4)
                            .annotation(position: .trailing) { Text(String(format: "%.1f", v + 1)).font(.mCaption).foregroundStyle(Palette.inkSoft) }
                    }
                    .chartXScale(domain: 0...4)
                    .frame(height: CGFloat(avg.count) * 38)
                }
            }
        }
    }

    private func heatmap(_ a: Assignment, _ subs: [Submission]) -> some View {
        Grid(alignment: .leading, horizontalSpacing: 6, verticalSpacing: 6) {
            GridRow {
                Text("")
                ForEach(a.rubric) { c in Text(c.name).font(.ui(11.5, .semibold)).foregroundStyle(Palette.inkSoft).lineLimit(2).frame(width: 92, alignment: .leading) }
            }
            ForEach(subs) { s in
                GridRow {
                    Button { nav.review(s.id) } label: {
                        HStack(spacing: 8) {
                            PersonAvatar(asset: classroom.student(s.studentID)?.avatar ?? "", name: classroom.student(s.studentID)?.name ?? "", size: 26)
                            Text(classroom.student(s.studentID)?.name ?? "").font(.ui(13.5, .medium)).lineLimit(1)
                        }
                        .frame(width: 170, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                    ForEach(a.rubric) { c in
                        let l = level(s, c)
                        let confirmed = s.feedback?.scores.first { $0.criterionID == c.id }?.confirmed != nil
                        RoundedRectangle(cornerRadius: 5).fill(l.map(color) ?? Palette.rule)
                            .frame(width: 92, height: 28)
                            .overlay { if confirmed { Image(systemName: "checkmark").font(.system(size: 10, weight: .bold)).foregroundStyle(Palette.onAccent) } }
                            .accessibilityLabel("\(c.name): \(l.map { RubricCriterion.levelNames[$0] } ?? "not scored")")
                    }
                }
            }
        }
    }

    private func color(_ l: Int) -> Color {
        [Palette.terracotta.opacity(0.85), Palette.ochre.opacity(0.8), Palette.forest.opacity(0.6), Palette.forest][min(3, max(0, l))]
    }

    private func theme(_ grow: String) -> String {
        let g = grow.lowercased()
        if g.contains("position") || g.contains("claim") && g.contains("introduction") { return "State a clear claim" }
        if g.contains("evidence") { return "Add specific evidence" }
        if g.contains("opposing") || g.contains("other side") || g.contains("counter") { return "Answer the other side" }
        if g.contains("paragraph") { return "Organise into paragraphs" }
        if g.contains("spelling") || g.contains("aloud") { return "Proofread" }
        if g.contains("sentences") { return "Sentence control" }
        return "Deepen analysis"
    }

    private func lesson(for criterion: String) -> String {
        let c = criterion.lowercased()
        if c.contains("evidence") { return "Model upgrading \"studies show\" into a named source with a number. Pairs then swap one vague claim each and upgrade it together." }
        if c.contains("claim") || c.contains("thesis") { return "Show three openings side by side: topic only, opinion, arguable claim. Students rewrite their own first paragraph's last sentence." }
        if c.contains("reason") || c.contains("counter") || c.contains("analysis") { return "Run a quick \"they say / I say\" drill: each student writes the strongest objection to their own claim, then a one-sentence answer." }
        if c.contains("organ") { return "Colour-code one essay on the board: claim, reasons, evidence, conclusion. Students highlight their own drafts the same way." }
        return "Five-minute proofreading routine: read aloud, circle any sentence over 30 words, check every \"i\"."
    }

    // MARK: Reading

    private var reading: some View {
        let readings = classroom.assignments.filter { $0.kind == .reading && $0.status != .draft }
        let subs = readings.flatMap { classroom.submissions(for: $0) }
        let byFormat = Dictionary(grouping: subs.compactMap { s in s.formatUsed.map { ($0, s.readingProgress) } }, by: { $0.0 })
        return Surface {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(eyebrow: "Reading", title: "Formats and completion", subtitle: "Same lesson in every format. Completion by format helps you see whether supports are working.")
                Chart(LessonFormat.allCases) { f in
                    let items = byFormat[f] ?? []
                    BarMark(x: .value("Format", f.title), y: .value("Students", items.count))
                        .foregroundStyle(Palette.slate.gradient).cornerRadius(4)
                        .annotation(position: .top) {
                            Text(items.isEmpty ? "" : "\(Int(items.map(\.1).reduce(0, +) / Double(items.count) * 100))% avg").font(.mCaption).foregroundStyle(Palette.inkSoft)
                        }
                }
                .frame(height: 180)
            }
        }
    }
}
