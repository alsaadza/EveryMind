import SwiftUI

struct TutorPanel: View {
    @Environment(AppStore.self) private var store
    var course: Course
    var chapter: Chapter
    var section: LessonSection?
    var activeChallenge: Challenge?
    var close: () -> Void
    @State private var input = ""
    @State private var busy = false

    private var log: [ChatMessage] { store.progress[course.id]?.tutorLog[chapter.id] ?? [] }

    private var suggestions: [String] {
        activeChallenge != nil
        ? ["I'm stuck. Where do I start?", "What does this question mean?", "Can you check my thinking?"]
        : ["Explain this a different way", "Give me a real-life example", "Why does this work?", "Quiz me on this page"]
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("AI Tutor").font(.mHeadline)
                    Text("\(store.effectiveHelpLevel.rawValue) mode · \(store.primaryProvider.runsOnDevice ? "on-device" : "OCI Generative AI")")
                        .font(.mCaption).foregroundStyle(Palette.inkSoft)
                }
                Spacer()
                Menu {
                    Picker("Help level", selection: Binding(get: { store.settings.helpLevel }, set: { store.settings.helpLevel = $0 })) {
                        ForEach(HelpLevel.allCases) { Text($0.rawValue).tag($0) }
                    }
                    if store.settings.maxHelpLevel != .supportive {
                        Text("Your educator set the maximum to \(store.settings.maxHelpLevel.rawValue)")
                    }
                    Button("Clear this conversation", role: .destructive) {
                        store.progress[course.id]?.tutorLog[chapter.id] = []
                        store.save()
                    }
                } label: { Image(systemName: "slider.horizontal.3").font(.ui(19, .medium)) }
                .accessibilityLabel("Tutor options")
                Button(action: close) { Image(systemName: "xmark.circle.fill").font(.mTitle2).foregroundStyle(Palette.inkSoft) }
                    .accessibilityLabel("Close tutor")
            }
            .padding(16)
            Divider()
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        Text(store.effectiveHelpLevel.detail + " Your questions stay private on this device.")
                            .font(.mFootnote).foregroundStyle(Palette.inkSoft)
                            .padding(12).background(RoundedRectangle(cornerRadius: 12).fill(Palette.surfaceSunk))
                        ForEach(log) { m in bubble(m).id(m.id) }
                        if busy {
                            HStack { ProgressView(); Text("Thinking…").foregroundStyle(Palette.inkSoft) }.id("busy")
                        }
                    }
                    .padding(16)
                }
                .onChange(of: log.count) { _, _ in withAnimation { proxy.scrollTo(log.last?.id, anchor: .bottom) } }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(suggestions, id: \.self) { s in
                        Button(s) { Task { await send(s) } }
                            .font(.mSubheadline).buttonStyle(.bordered).disabled(busy)
                    }
                }
                .padding(.horizontal, 16)
            }
            HStack {
                TextField("Ask anything about this chapter…", text: $input, axis: .vertical)
                    .lineLimit(1...4)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Palette.surfaceSunk))
                    .onSubmit { Task { await send(input) } }
                Button { Task { await send(input) } } label: { Image(systemName: "arrow.up.circle.fill").font(.system(size: 34)) }
                    .disabled(input.trimmingCharacters(in: .whitespaces).isEmpty || busy)
                    .accessibilityLabel("Send")
            }
            .padding(16)
        }
        .background(Palette.surface)
    }

    private func bubble(_ m: ChatMessage) -> some View {
        VStack(alignment: m.role == .learner ? .trailing : .leading, spacing: 6) {
            Text(ReadingText.attributed(m.text))
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 16).fill(m.role == .learner ? Theme.accent : Palette.surfaceSunk))
                .foregroundStyle(m.role == .learner ? .white : .primary)
                .fixedSize(horizontal: false, vertical: true)
                .textSelection(.enabled)
            if m.role == .tutor {
                HStack(spacing: 8) {
                    if let src = m.sources, !src.isEmpty {
                        AIBadge(text: "Sources", detail: "This answer drew on:\n" + src.map { "• \($0)" }.joined(separator: "\n") + "\n\nAI can make mistakes. Check important ideas with your book or your teacher.")
                    }
                    Button { Speech.shared.toggle(m.text, id: m.id.uuidString, rate: store.settings.readAloudRate) } label: {
                        Image(systemName: Speech.shared.speakingID == m.id.uuidString ? "stop.fill" : "speaker.wave.2")
                    }
                    .buttonStyle(.borderless).accessibilityLabel("Read aloud")
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: m.role == .learner ? .trailing : .leading)
    }

    private func append(_ m: ChatMessage) {
        var p = store.progress[course.id] ?? CourseProgress(courseID: course.id)
        p.tutorLog[chapter.id, default: []].append(m)
        store.progress[course.id] = p
        store.save()
    }

    private func send(_ raw: String) async {
        let q = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty, !busy else { return }
        input = ""
        let history = log
        append(ChatMessage(role: .learner, text: q))
        busy = true; defer { busy = false }
        let ctx = TutorContext(topic: course.topic, level: course.level, chapter: chapter, currentSection: section,
                               helpLevel: store.effectiveHelpLevel, activeChallenge: activeChallenge, learnerName: nil)
        if let r = await store.ai({ try await $0.tutor(ctx, history: history, question: q) }) {
            append(ChatMessage(role: .tutor, text: r.text, sources: r.sources))
        } else {
            append(ChatMessage(role: .tutor, text: "I couldn't answer just now. Try again, or check your connection in Settings.", sources: []))
        }
        store.emitSignal(course: course, chapter: chapter, kind: "tutor_question", tag: section.map { _ in "lesson" } ?? "challenge", value: 1)
    }
}
