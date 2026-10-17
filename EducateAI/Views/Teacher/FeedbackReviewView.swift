import SwiftUI

struct FeedbackReviewView: View {
    var submissionID: UUID
    @Environment(ClassroomStore.self) private var classroom
    @Environment(AppStore.self) private var app
    @Environment(TeacherNav.self) private var nav
    @Environment(\.dismiss) private var dismiss

    enum Pane: String, CaseIterable { case comments = "Comments", rubric = "Rubric", summary = "Summary" }
    @State private var pane: Pane = .comments
    @State private var selected: UUID?
    @State private var editing: FeedbackComment?
    @State private var selection = ""
    @State private var addingOnSelection: String?
    @State private var showRelease = false
    @State private var showPrompt = false
    @State private var openedAt = Date()
    @State private var regenerating = false
    @State private var toast: String?
    @FocusState private var focused: Bool

    var body: some View {
        if let sub = classroom.submission(submissionID), let a = classroom.assignment(sub.assignmentID) {
            let st = classroom.student(sub.studentID)
            VStack(spacing: 0) {
                topBar(sub, a, st)
                Rule()
                HStack(spacing: 0) {
                    essayColumn(sub, a)
                    Rectangle().fill(Palette.rule).frame(width: 1)
                    margin(sub, a)
                        .frame(width: 430)
                        .background(Palette.paperDeep)
                }
            }
            .background(PaperBackground())
            .toolbar(.hidden, for: .navigationBar)
            .focusable()
            .focused($focused)
            .focusEffectDisabled()
            .onKeyPress(phases: .down) { press in handleKey(press, sub) }
            .onAppear { openedAt = Date(); focused = true; if selected == nil { selected = sub.feedback?.comments.first(where: { $0.state == .pending })?.id } }
            .onDisappear { classroom.addReviewTime(submissionID, seconds: Date().timeIntervalSince(openedAt)) }
            .sheet(item: $editing) { c in CommentEditor(comment: c, rubric: a.rubric) { text in classroom.editComment(submissionID, c.id, text: text) } }
            .sheet(item: Binding(get: { addingOnSelection.map { IdentifiedString(value: $0) } }, set: { addingOnSelection = $0?.value })) { q in
                NewCommentSheet(quote: q.value, rubric: a.rubric) { kind, text, crit in
                    classroom.addTeacherComment(submissionID, quote: q.value, kind: kind, text: text, criterion: crit)
                    toast = "Comment added"
                }
            }
            .sheet(isPresented: $showRelease) { ReleasePreview(submissionID: submissionID) { released in if released { advance(after: sub) } }.pageSheet() }
            .toast($toast)
        } else {
            ContentUnavailableView("Submission not found", systemImage: "doc.questionmark")
        }
    }

    // MARK: Top bar

    private func topBar(_ sub: Submission, _ a: Assignment, _ st: Student?) -> some View {
        let f = sub.feedback
        return HStack(spacing: 16) {
            Button { dismiss() } label: { Image(systemName: "chevron.left").font(.system(size: 17, weight: .semibold)) }
                .foregroundStyle(Palette.inkSoft).accessibilityLabel("Back")
            PersonAvatar(asset: st?.avatar ?? "", name: st?.name ?? "", size: 40)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(st?.name ?? "Student").font(.display(21, .semibold))
                    if let st, !st.accommodations.isEmpty {
                        Tag(text: st.prefs.profile.title, symbol: st.prefs.profile.symbol, color: Palette.slate)
                    }
                }
                Text("\(a.title) · \(sub.wordCount) words · submitted \(sub.submittedAt?.shortRelative ?? "")").font(.mFootnote).foregroundStyle(Palette.inkSoft)
            }
            Spacer()
            if let f {
                let decided = f.comments.count - f.pendingCount
                VStack(alignment: .trailing, spacing: 5) {
                    Text("\(decided) of \(f.comments.count) comments · \(f.scores.filter { $0.confirmed != nil }.count)/\(f.scores.count) scores · summary \(f.summaryApproved ? "✓" : "–")")
                        .font(.mCaption).foregroundStyle(Palette.inkSoft).monospacedDigit()
                    Meter(value: progress(f), color: f.readyToRelease ? Palette.forest : Palette.ochre, height: 4).frame(width: 220)
                }
            }
            queueNav(sub)
            Button { showRelease = true } label: { Label("Release to \(st?.firstName ?? "student")", systemImage: "paperplane") }
                .buttonStyle(.primary(Palette.forest, compact: true))
                .disabled(!(f?.readyToRelease ?? false))
                .accessibilityIdentifier("release")
        }
        .padding(.horizontal, 24).padding(.vertical, 14)
        .background(Palette.surface)
    }

    private func progress(_ f: EssayFeedback) -> Double {
        let total = Double(f.comments.count + f.scores.count + 1)
        let done = Double(f.comments.count - f.pendingCount + f.scores.filter { $0.confirmed != nil }.count + (f.summaryApproved ? 1 : 0))
        return done / max(1, total)
    }

    private func queueNav(_ sub: Submission) -> some View {
        let q = classroom.reviewQueue
        let i = q.firstIndex { $0.id == sub.id }
        return HStack(spacing: 4) {
            Button { if let i, i > 0 { open(q[i - 1]) } } label: { Image(systemName: "chevron.up") }
                .disabled(i == nil || i == 0)
            Button { if let i, i + 1 < q.count { open(q[i + 1]) } } label: { Image(systemName: "chevron.down") }
                .disabled(i == nil || i! + 1 >= q.count)
        }
        .font(.system(size: 15, weight: .semibold))
        .buttonStyle(.bordered)
        .accessibilityLabel("Previous or next essay")
    }

    private func open(_ s: Submission) {
        classroom.addReviewTime(submissionID, seconds: Date().timeIntervalSince(openedAt))
        nav.review(s.id)
    }

    private func advance(after sub: Submission) {
        if let next = classroom.reviewQueue.first(where: { $0.id != sub.id }) { open(next) } else { dismiss() }
    }

    // MARK: Essay column

    private func essayColumn(_ sub: Submission, _ a: Assignment) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 10) {
                Button { withAnimation(.snappy) { showPrompt.toggle() } } label: {
                    HStack {
                        Eyebrow("Prompt")
                        Image(systemName: showPrompt ? "chevron.up" : "chevron.down").font(.system(size: 10, weight: .bold)).foregroundStyle(Palette.inkMuted)
                        Spacer()
                        legend
                    }
                }
                .buttonStyle(.plain)
                if showPrompt {
                    Text(a.prompt).font(.mCallout).foregroundStyle(Palette.inkSoft).fixedSize(horizontal: false, vertical: true)
                    if let src = a.sourceText {
                        Text(src).font(.displayItalic(16)).foregroundStyle(Palette.inkSoft).padding(.leading, 14)
                            .overlay(alignment: .leading) { Rectangle().fill(Palette.ruleStrong).frame(width: 2) }
                    }
                }
            }
            .padding(.horizontal, 56).padding(.top, 24).padding(.bottom, 12)

            if let prev = sub.history.last {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "arrow.triangle.2.circlepath").foregroundStyle(Palette.slate)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Revision \(sub.version). Last time's next step:").font(.ui(13.5, .semibold))
                        Text(prev.feedback?.grow ?? "–").font(.mFootnote).foregroundStyle(Palette.inkSoft)
                        let replies = prev.feedback?.comments.compactMap(\.studentReply) ?? []
                        if !replies.isEmpty {
                            Text("Student replied: \(replies.map { "\u{201C}\($0)\u{201D}" }.joined(separator: " "))").font(.mFootnote).foregroundStyle(Palette.slate)
                        }
                        Text("\(prev.text.split(separator: " ").count) → \(sub.wordCount) words").font(.mCaption).foregroundStyle(Palette.inkMuted)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 10).fill(Palette.slateSoft.opacity(0.6)))
                .padding(.horizontal, 56).padding(.bottom, 8)
            }

            ZStack(alignment: .bottom) {
                EssayTextView(text: sub.text, comments: sub.feedback?.comments ?? [], selectedID: selected,
                              onTapComment: { id in withAnimation(.snappy) { selected = id; pane = .comments } },
                              onSelect: { s in selection = s })
                    .padding(.horizontal, 56)
                    .frame(maxWidth: 820)
                    .frame(maxWidth: .infinity)
                if selection.count >= 2 {
                    Button { addingOnSelection = selection } label: {
                        Label("Comment on \u{201C}\(selection.prefix(36))\(selection.count > 36 ? "…" : "")\u{201D}", systemImage: "text.bubble")
                    }
                    .buttonStyle(.primary(Palette.ink, compact: true))
                    .shadow(color: .black.opacity(0.15), radius: 10, y: 4)
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.snappy, value: selection.count >= 2)
        }
        .background(Palette.surface.opacity(0.6))
    }

    private var legend: some View {
        HStack(spacing: 12) {
            ForEach(CommentKind.allCases) { k in
                HStack(spacing: 5) {
                    RoundedRectangle(cornerRadius: 2).fill(EssayTextView.color(for: k).opacity(0.4)).frame(width: 14, height: 10)
                    Text(k.title).font(.mCaption).foregroundStyle(Palette.inkMuted)
                }
            }
        }
    }

    // MARK: Margin

    private func margin(_ sub: Submission, _ a: Assignment) -> some View {
        VStack(spacing: 0) {
            Picker("Pane", selection: $pane) {
                ForEach(Pane.allCases, id: \.self) { p in Text(p.rawValue).tag(p) }
            }
            .pickerStyle(.segmented)
            .padding(16)
            if let f = sub.feedback {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 14) {
                            switch pane {
                            case .comments: commentsPane(f, a)
                            case .rubric: rubricPane(f, a)
                            case .summary: summaryPane(f, sub)
                            }
                        }
                        .padding(.horizontal, 16).padding(.bottom, 40)
                    }
                    .onChange(of: selected) { _, id in if let id { withAnimation { proxy.scrollTo(id, anchor: .center) } } }
                }
            } else {
                VStack(spacing: 14) {
                    ProgressView()
                    Text("Drafting feedback…").font(.mSubheadline).foregroundStyle(Palette.inkSoft)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .task { await classroom.draftFeedback(submissionID, using: app) }
            }
        }
    }

    private func commentsPane(_ f: EssayFeedback, _ a: Assignment) -> some View {
        Group {
            provenance(f)
            ForEach(f.comments) { c in
                CommentCard(comment: c, criterion: a.rubric.first { $0.id == c.criterionID }?.name, selected: selected == c.id,
                            onSelect: { withAnimation(.snappy) { selected = c.id } },
                            onApprove: { decide(c, .approved, f) },
                            onReject: { decide(c, .rejected, f) },
                            onEdit: { editing = c },
                            onUndo: { classroom.setComment(submissionID, c.id, state: .pending) })
                    .id(c.id)
            }
            Text("Tip: select any words in the essay to add your own comment. Keyboard: ↑ ↓ to move, A approve, R reject, E edit.")
                .font(.mFootnote).foregroundStyle(Palette.inkMuted).padding(.top, 6)
        }
    }

    private func provenance(_ f: EssayFeedback) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack { AIMark(text: "Drafted by AI"); Spacer(); Text(f.generatedAt.shortRelative).font(.mCaption).foregroundStyle(Palette.inkMuted) }
            Text("\(f.generatedBy). The model saw the essay text only, never the student's name or support plan. Every comment is anchored to the student's exact words.")
                .font(.mFootnote).foregroundStyle(Palette.inkSoft).fixedSize(horizontal: false, vertical: true)
            ForEach(f.guardNotes, id: \.self) { n in
                Label(n, systemImage: "shield.lefthalf.filled").font(.mFootnote).foregroundStyle(Palette.terracotta)
            }
            Button {
                Task {
                    regenerating = true
                    await classroom.draftFeedback(submissionID, using: app)
                    regenerating = false; toast = "New draft ready"
                }
            } label: { Label(regenerating ? "Drafting…" : "Redraft with AI", systemImage: "arrow.clockwise") }
                .font(.ui(13, .semibold)).disabled(regenerating)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 12).fill(Palette.plumSoft.opacity(0.5)))
    }

    private func decide(_ c: FeedbackComment, _ s: CommentState, _ f: EssayFeedback) {
        withAnimation(.snappy) {
            classroom.setComment(submissionID, c.id, state: s)
            // Move to the next undecided comment.
            if let next = f.comments.first(where: { $0.state == .pending && $0.id != c.id }) { selected = next.id }
        }
    }

    private func rubricPane(_ f: EssayFeedback, _ a: Assignment) -> some View {
        ForEach(a.rubric) { crit in
            let score = f.scores.first { $0.criterionID == crit.id }
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(crit.name).font(.mHeadline)
                    Spacer()
                    if score?.confirmed != nil { Image(systemName: "checkmark.circle.fill").foregroundStyle(Palette.forest) }
                }
                Text(crit.detail).font(.mFootnote).foregroundStyle(Palette.inkSoft)
                HStack(spacing: 6) {
                    ForEach(0..<4, id: \.self) { lvl in
                        let isSuggested = score?.suggested == lvl
                        let isConfirmed = score?.confirmed == lvl
                        Button { classroom.confirmScore(submissionID, criterion: crit.id, level: lvl) } label: {
                            VStack(spacing: 3) {
                                Text("\(lvl + 1)").font(.display(18, .semibold))
                                Text(RubricCriterion.levelNames[lvl]).font(.ui(9.5, .semibold)).lineLimit(1).minimumScaleFactor(0.7)
                                Image(systemName: "sparkle").font(.system(size: 8, weight: .bold)).opacity(isSuggested ? 1 : 0)
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, 8)
                            .foregroundStyle(isConfirmed ? Palette.onAccent : isSuggested ? Palette.plum : Palette.inkSoft)
                            .background(RoundedRectangle(cornerRadius: 9).fill(isConfirmed ? Palette.forest : isSuggested ? Palette.plumSoft : Palette.surface))
                            .overlay(RoundedRectangle(cornerRadius: 9).strokeBorder(isConfirmed ? .clear : Palette.rule))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(crit.name): \(RubricCriterion.levelNames[lvl])\(isSuggested ? ", AI suggestion" : "")")
                        .accessibilityIdentifier("score-\(crit.name)-\(lvl)")
                    }
                }
                if let score {
                    Text(crit.levels[safe: score.confirmed ?? score.suggested] ?? "").font(.mFootnote).italic().foregroundStyle(Palette.inkSoft)
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Image(systemName: "sparkle").font(.system(size: 9)).foregroundStyle(Palette.plum)
                        Text("Suggested \(RubricCriterion.levelNames[score.suggested]). \(score.rationale)").font(.mFootnote).foregroundStyle(Palette.inkSoft)
                    }
                }
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 12).fill(Palette.surface))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Palette.rule))
        }
    }

    private func summaryPane(_ f: EssayFeedback, _ sub: Submission) -> some View {
        SummaryEditor(feedback: f) { glow, grow, ok in classroom.setSummary(submissionID, glow: glow, grow: grow, approved: ok) }
            .id(sub.id)
    }

    // MARK: Keyboard

    private func handleKey(_ press: KeyPress, _ sub: Submission) -> KeyPress.Result {
        guard let f = sub.feedback, pane == .comments, editing == nil, addingOnSelection == nil else { return .ignored }
        let ids = f.comments.map(\.id)
        let i = selected.flatMap { ids.firstIndex(of: $0) }
        switch press.key {
        case .downArrow: selected = ids[safe: (i ?? -1) + 1] ?? selected; return .handled
        case .upArrow: selected = ids[safe: (i ?? 1) - 1] ?? selected; return .handled
        default: break
        }
        guard let id = selected, let c = f.comments.first(where: { $0.id == id }) else { return .ignored }
        switch press.characters.lowercased() {
        case "a": decide(c, .approved, f); return .handled
        case "r": decide(c, .rejected, f); return .handled
        case "e": editing = c; return .handled
        default: return .ignored
        }
    }
}

struct IdentifiedString: Identifiable { var value: String; var id: String { value } }

struct CommentCard: View {
    var comment: FeedbackComment
    var criterion: String?
    var selected: Bool
    var onSelect: () -> Void
    var onApprove: () -> Void
    var onReject: () -> Void
    var onEdit: () -> Void
    var onUndo: () -> Void

    var body: some View {
        let color = EssayTextView.color(for: comment.kind)
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Tag(text: comment.kind.title, symbol: comment.kind.symbol, color: color)
                if let criterion { Text(criterion).font(.mCaption).foregroundStyle(Palette.inkMuted).lineLimit(1) }
                Spacer()
                if comment.origin == .teacher { Tag(text: "You", symbol: "person.fill", color: Palette.ink) }
                else if comment.wasEdited { Tag(text: "Edited", symbol: "pencil", color: Palette.ink) }
                else { AIMark() }
            }
            Text("\u{201C}\(comment.quote.prefix(110))\(comment.quote.count > 110 ? "…" : "")\u{201D}")
                .font(.custom(Typeface.serifItalic, size: 14)).foregroundStyle(Palette.inkSoft).lineLimit(3)
                .padding(.leading, 10)
                .overlay(alignment: .leading) { Rectangle().fill(color.opacity(0.6)).frame(width: 2) }
            Text(comment.text).font(.ui(15.5)).fixedSize(horizontal: false, vertical: true)
                .strikethrough(comment.state == .rejected, color: Palette.inkMuted)
                .foregroundStyle(comment.state == .rejected ? Palette.inkMuted : Palette.ink)
            if let reply = comment.studentReply {
                Label(reply, systemImage: "arrowshape.turn.up.left").font(.mFootnote).foregroundStyle(Palette.slate)
            }
            actions
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Palette.surface))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(selected ? color : Palette.rule, lineWidth: selected ? 2 : 1))
        .opacity(comment.state == .rejected ? 0.7 : 1)
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder private var actions: some View {
        switch comment.state {
        case .pending:
            HStack(spacing: 8) {
                Button(action: onApprove) { Label("Approve", systemImage: "checkmark") }
                    .buttonStyle(.primary(Palette.forest, compact: true))
                    .accessibilityIdentifier("approve-comment")
                Button(action: onEdit) { Label("Edit", systemImage: "pencil") }
                    .buttonStyle(.secondary(compact: true))
                Spacer()
                Button(action: onReject) { Label("Reject", systemImage: "xmark") }
                    .buttonStyle(.secondary(compact: true))
                    .accessibilityIdentifier("reject-comment")
            }
        case .approved:
            HStack {
                Label("Approved", systemImage: "checkmark.circle.fill").font(.ui(13.5, .semibold)).foregroundStyle(Palette.forest)
                Spacer()
                Button("Edit", action: onEdit).font(.ui(13.5, .semibold))
                Button("Undo", action: onUndo).font(.ui(13.5, .semibold)).foregroundStyle(Palette.inkSoft)
            }
        case .rejected:
            HStack {
                Label("Won't be shown", systemImage: "eye.slash").font(.ui(13.5, .semibold)).foregroundStyle(Palette.inkMuted)
                Spacer()
                Button("Undo", action: onUndo).font(.ui(13.5, .semibold))
            }
        }
    }
}

struct CommentEditor: View {
    var comment: FeedbackComment
    var rubric: [RubricCriterion]
    var onSave: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("\u{201C}\(comment.quote)\u{201D}").font(.custom(Typeface.serifItalic, size: 16)).foregroundStyle(Palette.inkSoft)
                TextEditor(text: $text)
                    .font(.ui(17))
                    .scrollContentBackground(.hidden)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Palette.surface))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Palette.rule))
                    .frame(minHeight: 160)
                    .accessibilityIdentifier("comment-editor")
                if comment.origin == .ai {
                    VStack(alignment: .leading, spacing: 4) {
                        Eyebrow("Original AI draft")
                        Text(comment.draft).font(.mFootnote).foregroundStyle(Palette.inkMuted)
                    }
                }
                Text("Saving approves the comment with your wording. The student sees it as your comment.").font(.mFootnote).foregroundStyle(Palette.inkMuted)
                Spacer()
            }
            .padding(24)
            .background(PaperBackground())
            .navigationTitle("Edit comment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save & approve") { onSave(text.trimmingCharacters(in: .whitespacesAndNewlines)); dismiss() }
                        .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
                        .accessibilityIdentifier("save-comment")
                }
            }
        }
        .onAppear { text = comment.text }
        .presentationDetents([.medium, .large])
    }
}

struct NewCommentSheet: View {
    var quote: String
    var rubric: [RubricCriterion]
    var onAdd: (CommentKind, String, UUID?) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var kind: CommentKind = .suggestion
    @State private var text = ""
    @State private var crit: UUID?

    var body: some View {
        NavigationStack {
            Form {
                Section("On") { Text("\u{201C}\(quote)\u{201D}").font(.custom(Typeface.serifItalic, size: 16)) }
                Section("Type") {
                    Picker("Type", selection: $kind) { ForEach(CommentKind.allCases) { Label($0.title, systemImage: $0.symbol).tag($0) } }
                        .pickerStyle(.segmented)
                    Picker("Rubric criterion", selection: $crit) {
                        Text("None").tag(UUID?.none)
                        ForEach(rubric) { Text($0.name).tag(Optional($0.id)) }
                    }
                }
                Section("Comment") {
                    TextEditor(text: $text).frame(minHeight: 120).font(.ui(17))
                }
            }
            .scrollContentBackground(.hidden)
            .background(PaperBackground())
            .navigationTitle("Your comment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { onAdd(kind, text.trimmingCharacters(in: .whitespacesAndNewlines), crit); dismiss() }
                        .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

struct SummaryEditor: View {
    var feedback: EssayFeedback
    var onChange: (String, String, Bool) -> Void
    @State private var glow = ""
    @State private var grow = ""
    @State private var loaded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Students read this first. Keep it to one strength and one next step, the \u{201C}glow and grow\u{201D} format.")
                .font(.mFootnote).foregroundStyle(Palette.inkSoft)
            field("Glow: what's working", $glow, Palette.forest)
            field("Grow: one next step", $grow, Palette.ochre)
            Toggle(isOn: Binding(get: { feedback.summaryApproved }, set: { onChange(glow, grow, $0) })) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Approve summary").font(.mHeadline)
                    Text(feedback.summaryEdited ? "Edited by you" : "AI draft").font(.mCaption).foregroundStyle(Palette.inkMuted)
                }
            }
            .tint(Palette.forest)
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 12).fill(Palette.surface))
            .accessibilityIdentifier("approve-summary")
        }
        .onAppear { if !loaded { glow = feedback.glow; grow = feedback.grow; loaded = true } }
        .onChange(of: glow) { _, _ in if loaded { onChange(glow, grow, feedback.summaryApproved) } }
        .onChange(of: grow) { _, _ in if loaded { onChange(glow, grow, feedback.summaryApproved) } }
    }

    private func field(_ title: String, _ text: Binding<String>, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) { Circle().fill(color).frame(width: 7, height: 7); Eyebrow(title) }
            TextEditor(text: text)
                .font(.ui(16)).frame(minHeight: 90)
                .scrollContentBackground(.hidden)
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 12).fill(Palette.surface))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Palette.rule))
        }
    }
}

/// Shows the teacher exactly what the student will see, then releases it.
struct ReleasePreview: View {
    var submissionID: UUID
    var onDone: (Bool) -> Void
    @Environment(ClassroomStore.self) private var classroom
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if let sub = classroom.submission(submissionID), let a = classroom.assignment(sub.assignmentID), let f = sub.feedback {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("This is exactly what \(classroom.student(sub.studentID)?.firstName ?? "the student") will see. Rejected comments, AI rationales and your private notes are not included.")
                                .font(.mSubheadline).foregroundStyle(Palette.inkSoft)
                            FeedbackSummaryCard(feedback: f, rubric: a.rubric, teacher: classroom.teacherName)
                            Eyebrow("\(f.approved.count) margin comments")
                            ForEach(f.approved) { c in StudentCommentRow(comment: c, teacher: classroom.teacherName) }
                        }
                        .padding(28)
                    }
                }
            }
            .background(PaperBackground())
            .navigationTitle("Student preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Keep reviewing") { dismiss(); onDone(false) } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Release") {
                        classroom.release(submissionID)
                        dismiss(); onDone(true)
                    }
                    .fontWeight(.semibold)
                    .accessibilityIdentifier("confirm-release")
                }
            }
        }
    }
}
