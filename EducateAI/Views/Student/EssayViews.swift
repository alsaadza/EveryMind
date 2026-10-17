import SwiftUI

// MARK: - Writing

struct EssayWorkspaceView: View {
    var submissionID: UUID
    @Binding var path: [Route]
    @Environment(ClassroomStore.self) private var classroom
    @Environment(AppStore.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @State private var loaded = false
    @State private var confirm = false
    @State private var submitting = false
    @State private var showRubric = false
    @State private var speech = Speech.shared
    @State private var saveTask: Task<Void, Never>?
    @State private var focusWriting: Bool?

    var body: some View {
        if let sub = classroom.submission(submissionID), let a = classroom.assignment(sub.assignmentID), let st = classroom.student(sub.studentID) {
            let target = classroom.minWords(a, for: st)
            let words = text.split(whereSeparator: { $0 == " " || $0 == "\n" }).count
            let focusing = focusWriting ?? (st.prefs.profile == .focus)
            HStack(spacing: 0) {
                if !focusing {
                    brief(a, st, sub, target)
                        .frame(width: 380)
                        .background(Palette.paperDeep)
                        .transition(.move(edge: .leading))
                    Rectangle().fill(Palette.rule).frame(width: 1)
                }
                VStack(spacing: 0) {
                    HStack(spacing: 14) {
                        Button { withAnimation(.snappy) { focusWriting = !focusing } } label: {
                            Image(systemName: focusing ? "sidebar.left" : "rectangle.center.inset.filled")
                                .font(.system(size: 17, weight: .medium)).frame(width: 36, height: 32)
                        }
                        .accessibilityLabel(focusing ? "Show the prompt and plan" : "Focus: hide everything but my writing")
                        .accessibilityIdentifier("focus-writing")
                        if focusing {
                            Button { dismiss() } label: { Image(systemName: "chevron.left").font(.system(size: 16, weight: .semibold)) }
                                .accessibilityLabel("Home")
                        }
                        Text(words == 0 ? "Start writing" : "\(words) words").font(.ui(14, .semibold)).monospacedDigit()
                        Meter(value: Double(words) / Double(max(1, target)), color: words >= target ? Palette.forest : Palette.ochre, height: 5).frame(width: 140)
                        Text("target \(target)").font(.mCaption).foregroundStyle(Palette.inkMuted)
                        Spacer()
                        Button { speech.toggle(text, id: "draft", rate: st.prefs.speechRate) } label: {
                            Label(speech.speakingID == "draft" ? "Stop" : "Read my draft aloud", systemImage: speech.speakingID == "draft" ? "stop.fill" : "speaker.wave.2")
                        }
                        .buttonStyle(.secondary(compact: true)).disabled(text.isEmpty)
                        Button { confirm = true } label: { Label(submitting ? "Submitting…" : "Submit", systemImage: "paperplane") }
                            .buttonStyle(.primary(Palette.forest, compact: true))
                            .disabled(words < 20 || submitting)
                            .accessibilityIdentifier("submit-essay")
                    }
                    .padding(.horizontal, 28).padding(.vertical, 12)
                    .background(Palette.surface)
                    Rule()
                    if focusing {
                        Text(a.prompt).font(.reading(st.prefs.font, 15)).foregroundStyle(Palette.inkSoft).lineLimit(2)
                            .padding(.horizontal, 60).padding(.top, 16)
                            .frame(maxWidth: 820, alignment: .leading).frame(maxWidth: .infinity)
                    }
                    ZStack(alignment: .topLeading) {
                        if text.isEmpty {
                            Text("Begin with your position. What do you think, and why?")
                                .font(.reading(st.prefs.font == .serif ? .serif : st.prefs.font, 20))
                                .foregroundStyle(Palette.inkMuted).padding(.top, 8).padding(.leading, 5)
                                .allowsHitTesting(false)
                        }
                        TextEditor(text: $text)
                            .font(.reading(st.prefs.font, 20))
                            .tracking(st.prefs.letterSpacing)
                            .lineSpacing(st.prefs.lineSpacing)
                            .scrollContentBackground(.hidden)
                            .accessibilityIdentifier("essay-editor")
                    }
                    .padding(.horizontal, 60).padding(.vertical, 28)
                    .frame(maxWidth: 820).frame(maxWidth: .infinity)
                    .background(Palette.tint(st.prefs.tint == .night ? .paper : st.prefs.tint))
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .onAppear { if !loaded { text = sub.text; loaded = true } }
            .onChange(of: text) { _, t in
                saveTask?.cancel()
                saveTask = Task { try? await Task.sleep(nanoseconds: 600_000_000); if !Task.isCancelled { classroom.saveDraft(submissionID, text: t) } }
            }
            .onDisappear { classroom.saveDraft(submissionID, text: text); speech.stop() }
            .confirmationDialog("Submit to \(classroom.teacherName)?", isPresented: $confirm, titleVisibility: .visible) {
                Button("Submit") {
                    Task {
                        submitting = true
                        await classroom.submit(submissionID, text: text, using: app)
                        submitting = false
                        dismiss()
                    }
                }
            } message: {
                Text("Your teacher reads your essay and reviews every comment before you see feedback.\(words < target ? " You're \(target - words) words under the target." : "")")
            }
        }
    }

    private func brief(_ a: Assignment, _ st: Student, _ sub: Submission, _ target: Int) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Button { dismiss() } label: { Label("Home", systemImage: "chevron.left") }.font(.mHeadline).foregroundStyle(Palette.inkSoft)
                ArtCover(asset: a.art, height: 130, radius: 12)
                VStack(alignment: .leading, spacing: 6) {
                    Text(a.title).font(.display(26, .semibold))
                    Text("\(classroom.dueDate(a, for: st).dueLabel) · \(target)+ words\(sub.version > 1 ? " · revision \(sub.version)" : "")").font(.mFootnote).foregroundStyle(Palette.inkSoft)
                }
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Eyebrow("Prompt")
                        Spacer()
                        Button { speech.toggle(a.prompt, id: "prompt", rate: st.prefs.speechRate) } label: {
                            Image(systemName: speech.speakingID == "prompt" ? "stop.circle" : "speaker.wave.2.circle").font(.system(size: 20))
                        }.accessibilityLabel("Read prompt aloud")
                    }
                    Text(a.prompt).font(.reading(st.prefs.font, 17)).lineSpacing(4).fixedSize(horizontal: false, vertical: true)
                }
                if let src = a.sourceText {
                    VStack(alignment: .leading, spacing: 8) {
                        Eyebrow("Text")
                        Text(src).font(.displayItalic(17)).lineSpacing(4).fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Palette.surface))
                }
                Text(a.instructions).font(.mSubheadline).foregroundStyle(Palette.inkSoft).fixedSize(horizontal: false, vertical: true)
                EssayPlanner(submissionID: submissionID, startOpen: st.accommodations.contains(.visualSupports) || st.prefs.profile == .visual, genre: a.rubric.first?.name == "Claim" && a.sourceText == nil ? .argumentative : .literary)
                if let prev = sub.history.last?.feedback {
                    VStack(alignment: .leading, spacing: 8) {
                        Eyebrow("Your next step from last time", color: Palette.ochre)
                        Text(prev.grow).font(.mSubheadline).fixedSize(horizontal: false, vertical: true)
                        ForEach(prev.approved.filter { $0.kind != .strength }) { c in
                            Text("• \(c.text)").font(.mFootnote).foregroundStyle(Palette.inkSoft).fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Palette.ochreSoft.opacity(0.7)))
                }
                DisclosureGroup(isExpanded: $showRubric) {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(a.rubric) { c in
                            VStack(alignment: .leading, spacing: 3) {
                                Text(c.name).font(.mHeadline)
                                Text("Proficient: \(c.levels[safe: 2] ?? "")").font(.mFootnote).foregroundStyle(Palette.inkSoft)
                                Text("Exemplary: \(c.levels[safe: 3] ?? "")").font(.mFootnote).foregroundStyle(Palette.inkSoft)
                            }
                        }
                    }
                    .padding(.top, 8)
                } label: { Text("What your teacher looks for").font(.mHeadline) }
                .tint(Palette.ink)
                Label("This is your writing. Margin's AI won't write any of it for you. When you submit, your teacher reviews every comment before you see it.", systemImage: "hand.raised")
                    .font(.mFootnote).foregroundStyle(Palette.inkMuted).fixedSize(horizontal: false, vertical: true)
            }
            .padding(24)
        }
    }
}

/// A graphic organizer for planning before drafting. A visual-supports accommodation, useful for everyone.
struct EssayPlanner: View {
    var submissionID: UUID
    var startOpen: Bool
    var genre: EssayGenre
    @Environment(ClassroomStore.self) private var classroom
    @State private var open = false
    @State private var fields: [String] = []

    private var slots: [(String, String, Color)] {
        switch genre {
        case .argumentative:
            return [("My claim", "What do I think? One sentence.", Palette.forest),
                    ("Reason 1 + evidence", "Why? What fact, source or example shows it?", Palette.slate),
                    ("Reason 2 + evidence", "Another reason, with its evidence.", Palette.slate),
                    ("The other side", "What would someone who disagrees say? How do I answer?", Palette.terracotta),
                    ("So what?", "Why does this matter? How will I end?", Palette.ochre)]
        default:
            return [("My claim about the text", "What is the author doing, and why?", Palette.forest),
                    ("Quotation 1", "Copy the words exactly.", Palette.slate),
                    ("What it shows", "How does this quotation support my claim?", Palette.slate),
                    ("Quotation 2 (optional)", "Another moment from the text.", Palette.slate),
                    ("So what?", "What does it all add up to?", Palette.ochre)]
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button { withAnimation(.snappy) { open.toggle() } } label: {
                HStack {
                    Label("Plan it first", systemImage: "square.grid.3x1.below.line.grid.1x2").font(.mHeadline)
                    Spacer()
                    Image(systemName: open ? "chevron.up" : "chevron.down").font(.system(size: 12, weight: .bold)).foregroundStyle(Palette.inkMuted)
                }
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("essay-planner")
            if open {
                ForEach(Array(slots.enumerated()), id: \.offset) { i, slot in
                    HStack(alignment: .top, spacing: 10) {
                        RoundedRectangle(cornerRadius: 2).fill(slot.2).frame(width: 4)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(slot.0).font(.ui(13, .semibold)).foregroundStyle(slot.2)
                            TextField(slot.1, text: Binding(get: { fields[safe: i] ?? "" }, set: { v in
                                while fields.count < slots.count { fields.append("") }
                                fields[i] = v
                                classroom.mutate(submissionID) { $0.plan = fields }
                            }), axis: .vertical)
                            .font(.ui(14.5)).lineLimit(1...4)
                        }
                    }
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Palette.surface))
                }
                Text("Your plan stays with you. It isn't graded and AI never sees it.").font(.mCaption).foregroundStyle(Palette.inkMuted)
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 12).fill(Palette.slateSoft.opacity(0.5)))
        .onAppear {
            fields = classroom.submission(submissionID)?.plan ?? []
            if !open { open = startOpen || !(fields.allSatisfy(\.isEmpty)) }
        }
    }
}

// MARK: - Returned feedback (student)

struct StudentFeedbackView: View {
    var submissionID: UUID
    @Binding var path: [Route]
    @Environment(ClassroomStore.self) private var classroom
    @Environment(\.dismiss) private var dismiss
    @State private var selected: UUID?
    @State private var replying: FeedbackComment?
    @State private var showVersion: Int?

    var body: some View {
        if let sub = classroom.submission(submissionID), let a = classroom.assignment(sub.assignmentID), let f = sub.feedback, sub.status == .returned {
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 14) {
                        Button { dismiss() } label: { Image(systemName: "chevron.left").font(.system(size: 17, weight: .semibold)) }
                            .foregroundStyle(Palette.inkSoft).accessibilityLabel("Back")
                        VStack(alignment: .leading, spacing: 1) {
                            Text(a.title).font(.display(21, .semibold))
                            Text("Version \(sub.version) · returned \(f.releasedAt?.shortRelative ?? "")").font(.mCaption).foregroundStyle(Palette.inkSoft)
                        }
                        Spacer()
                        Button {
                            classroom.startRevision(submissionID)
                            path.removeLast()
                            path.append(.essay(submissionID))
                        } label: { Label("Revise & resubmit", systemImage: "arrow.uturn.backward") }
                            .buttonStyle(.primary(Palette.forest, compact: true))
                            .accessibilityIdentifier("revise")
                    }
                    .padding(.horizontal, 24).padding(.vertical, 12)
                    .background(Palette.surface)
                    Rule()
                    EssayTextView(text: sub.text, comments: f.approved, selectedID: selected, onTapComment: { selected = $0 })
                        .padding(.horizontal, 56).padding(.top, 20)
                        .frame(maxWidth: 820).frame(maxWidth: .infinity)
                        .background(Palette.surface.opacity(0.6))
                }
                Rectangle().fill(Palette.rule).frame(width: 1)
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            FeedbackSummaryCard(feedback: f, rubric: a.rubric, teacher: classroom.teacherName)
                            Button {
                                let script = (["Glow. " + f.glow, "Grow. " + f.grow] + f.approved.map { "\($0.kind.title). On the words: \($0.quote). \($0.text)" }).joined(separator: "\n")
                                Speech.shared.toggle(script, id: "feedback-\(sub.id)", rate: classroom.student(sub.studentID)?.prefs.speechRate ?? 0.46)
                            } label: {
                                Label(Speech.shared.speakingID == "feedback-\(sub.id)" ? "Stop" : "Listen to my feedback", systemImage: Speech.shared.speakingID == "feedback-\(sub.id)" ? "stop.fill" : "speaker.wave.2")
                            }
                            .buttonStyle(.secondary(compact: true))
                            .accessibilityIdentifier("listen-feedback")
                            Eyebrow("In the margin")
                            ForEach(f.approved) { c in
                                StudentCommentRow(comment: c, teacher: classroom.teacherName, selected: selected == c.id, onReply: { replying = c })
                                    .id(c.id)
                                    .onTapGesture { withAnimation(.snappy) { selected = c.id } }
                            }
                            Text("Feedback drafted with AI assistance and reviewed, edited and approved by \(classroom.teacherName).")
                                .font(.mFootnote).foregroundStyle(Palette.inkMuted).padding(.top, 6)
                        }
                        .padding(18)
                    }
                    .onChange(of: selected) { _, id in if let id { withAnimation { proxy.scrollTo(id, anchor: .center) } } }
                }
                .frame(width: 420)
                .background(Palette.paperDeep)
            }
            .background(PaperBackground())
            .toolbar(.hidden, for: .navigationBar)
            .onDisappear { Speech.shared.stop() }
            .sheet(item: $replying) { c in
                ReplySheet(comment: c) { classroom.studentReply(submissionID, comment: c.id, text: $0) }
            }
        } else {
            ContentUnavailableView("Feedback isn't ready yet", systemImage: "hourglass", description: Text("Your teacher is still reviewing it."))
        }
    }
}

struct FeedbackSummaryCard: View {
    var feedback: EssayFeedback
    var rubric: [RubricCriterion]
    var teacher: String
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                PersonAvatar(asset: "avatar-15", name: teacher, size: 34)
                VStack(alignment: .leading, spacing: 0) {
                    Text(teacher).font(.mHeadline)
                    Text("Your teacher").font(.mCaption).foregroundStyle(Palette.inkMuted)
                }
            }
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) { Circle().fill(Palette.forest).frame(width: 7, height: 7); Eyebrow("Glow", color: Palette.forest) }
                Text(feedback.glow).font(.custom(Typeface.serif, size: 17)).fixedSize(horizontal: false, vertical: true)
            }
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) { Circle().fill(Palette.ochre).frame(width: 7, height: 7); Eyebrow("Grow", color: Palette.ochre) }
                Text(feedback.grow).font(.custom(Typeface.serif, size: 17)).fixedSize(horizontal: false, vertical: true)
            }
            Rule()
            VStack(alignment: .leading, spacing: 10) {
                ForEach(rubric) { c in
                    let lvl = feedback.scores.first { $0.criterionID == c.id }?.confirmed
                    HStack(spacing: 10) {
                        Text(c.name).font(.mSubheadline).frame(width: 150, alignment: .leading)
                        HStack(spacing: 3) {
                            ForEach(0..<4, id: \.self) { i in
                                RoundedRectangle(cornerRadius: 2).fill(lvl.map { i <= $0 } == true ? Palette.forest : Palette.rule).frame(height: 8)
                            }
                        }
                        Text(lvl.map { RubricCriterion.levelNames[$0] } ?? "–").font(.mCaption).foregroundStyle(Palette.inkSoft).frame(width: 74, alignment: .trailing)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Palette.surface))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Palette.rule))
    }
}

struct StudentCommentRow: View {
    var comment: FeedbackComment
    var teacher: String
    var selected = false
    var onReply: (() -> Void)? = nil
    var body: some View {
        let color = EssayTextView.color(for: comment.kind)
        VStack(alignment: .leading, spacing: 8) {
            Tag(text: comment.kind.title, symbol: comment.kind.symbol, color: color)
            Text("\u{201C}\(comment.quote.prefix(90))\(comment.quote.count > 90 ? "…" : "")\u{201D}")
                .font(.custom(Typeface.serifItalic, size: 14)).foregroundStyle(Palette.inkSoft).lineLimit(2)
            Text(comment.text).font(.ui(15.5)).fixedSize(horizontal: false, vertical: true)
            if let r = comment.studentReply {
                Label(r, systemImage: "arrowshape.turn.up.left.fill").font(.mFootnote).foregroundStyle(Palette.slate)
            } else if let onReply {
                Button(action: onReply) { Label("Reply", systemImage: "arrowshape.turn.up.left") }.font(.ui(13, .semibold))
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Palette.surface))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(selected ? color : Palette.rule, lineWidth: selected ? 2 : 1))
    }
}

struct ReplySheet: View {
    var comment: FeedbackComment
    var onSend: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 14) {
                Text(comment.text).font(.mBody).foregroundStyle(Palette.inkSoft)
                TextField("What will you change, or what's your question?", text: $text, axis: .vertical)
                    .font(.ui(17)).lineLimit(3...8).padding(12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Palette.surface))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Palette.rule))
                Spacer()
            }
            .padding(24)
            .background(PaperBackground())
            .navigationTitle("Reply to your teacher").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Send") { onSend(text); dismiss() }.disabled(text.trimmingCharacters(in: .whitespaces).isEmpty) }
            }
        }
        .presentationDetents([.medium])
    }
}
