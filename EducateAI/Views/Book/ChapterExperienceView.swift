import SwiftUI

struct ChapterExperienceView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    var courseID: UUID
    var chapterID: UUID

    enum Stage { case book, challenge, complete }
    @State private var stage: Stage = .book
    @State private var sectionIndex = 0
    @State private var showTutor = false
    @State private var toast: String?

    var body: some View {
        if let course = store.course(courseID), let chapter = course.chapters.first(where: { $0.id == chapterID }) {
            VStack(spacing: 0) {
                topBar(course, chapter)
                HStack(spacing: 0) {
                    Group {
                        switch stage {
                        case .book:
                            BookView(course: course, chapter: chapter, index: $sectionIndex) { withAnimation(.spring) { stage = .challenge } }
                        case .challenge:
                            ChallengeView(course: course, chapter: chapter, openTutor: { showTutor = true }) { section in
                                // The book adapts: jump to the new page written for this learner.
                                if let i = store.course(courseID)?.chapters.first(where: { $0.id == chapterID })?.sections.firstIndex(where: { $0.id == section.id }) {
                                    sectionIndex = i
                                }
                                toast = "📖 Your book wrote a new page for you"
                                withAnimation(.spring) { stage = .book }
                            } mastered: {
                                withAnimation(.spring) { stage = .complete }
                            }
                        case .complete:
                            ChapterCompleteView(course: course, chapter: chapter) { dismiss() }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    if showTutor && stage != .complete {
                        Divider()
                        TutorPanel(course: course, chapter: chapter,
                                   section: stage == .book && chapter.sections.indices.contains(sectionIndex) ? chapter.sections[sectionIndex] : nil,
                                   activeChallenge: stage == .challenge ? ChallengeView.current(store: store, course: course, chapter: chapter) : nil) { showTutor = false }
                            .frame(width: 400)
                            .transition(.move(edge: .trailing))
                    }
                }
            }
            .background(Palette.paper)
            .animation(.spring, value: showTutor)
            .toast($toast)
            .onAppear { if ProcessInfo.processInfo.arguments.contains("-openChallenge") { stage = .challenge } }
            .onDisappear { Speech.shared.stop() }
        }
    }

    private func topBar(_ course: Course, _ chapter: Chapter) -> some View {
        HStack(spacing: 16) {
            Button { dismiss() } label: { Label("Map", systemImage: "map") }
                .buttonStyle(.secondary(compact: true))
            VStack(alignment: .leading, spacing: 2) {
                Eyebrow("Chapter \(chapter.index + 1) · \(chapter.locationName)", color: Theme.themeColor(chapter.theme))
                Text(chapter.title).font(.display(21, .semibold)).lineLimit(1)
            }
            Spacer()
            Picker("Stage", selection: $stage) {
                Text("Book").tag(Stage.book)
                Text("Challenge").tag(Stage.challenge)
                if store.chapterProgress(course, chapter).status == .mastered { Text("Summary").tag(Stage.complete) }
            }
            .pickerStyle(.segmented)
            .frame(width: 280)
            MasteryRing(value: store.chapterProgress(course, chapter).mastery, size: 44, color: Theme.themeColor(chapter.theme))
            Button { showTutor.toggle() } label: {
                Label("Tutor", systemImage: showTutor ? "bubble.left.and.text.bubble.right.fill" : "bubble.left.and.text.bubble.right")
            }
            .buttonStyle(.primary(Palette.plum, compact: true))
            .disabled(!store.settings.aiEnabled || stage == .complete)
            .accessibilityHint(store.settings.aiEnabled ? "Opens the AI tutor" : "AI is turned off in Settings")
        }
        .padding(.horizontal, 24).padding(.vertical, 12)
        .background(Palette.surface)
        .overlay(alignment: .bottom) { Rule() }
    }
}

// MARK: - Book

struct BookView: View {
    @Environment(AppStore.self) private var store
    @Environment(ClassroomStore.self) private var classroom
    var course: Course
    var chapter: Chapter
    @Binding var index: Int
    var startChallenge: () -> Void
    @State private var format: LessonFormat?
    @State private var showCheck = false
    @State private var showSettings = false
    @State private var showFidelity = false

    private var prefs: ReadingPrefs {
        if let s = classroom.currentStudent { return s.prefs }
        return store.settings.dyslexiaFriendly ? .preset(.dyslexia) : ReadingPrefs()
    }

    var body: some View {
        HStack(spacing: 0) {
            toc.frame(width: 260)
            Rectangle().fill(Palette.rule).frame(width: 1)
            if chapter.sections.indices.contains(index) {
                page(chapter.sections[index])
                    .id(chapter.sections[index].id)
                    .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: index)
        .onAppear { if format == nil { format = prefs.profile.defaultFormat } }
    }

    private var toc: some View {
        let p = store.chapterProgress(course, chapter)
        return ScrollView {
            VStack(alignment: .leading, spacing: 6) {
                Eyebrow("Contents").padding(.bottom, 6)
                ForEach(Array(chapter.sections.enumerated()), id: \.element.id) { i, s in
                    Button { index = i } label: {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: p.sectionsRead.contains(s.id) ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(p.sectionsRead.contains(s.id) ? Palette.forest : Palette.inkMuted)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(s.heading).font(.ui(14.5, i == index ? .semibold : .regular)).multilineTextAlignment(.leading)
                                if s.isAdaptive { Label("New page for you", systemImage: "sparkle").font(.ui(11, .semibold)).foregroundStyle(Palette.plum) }
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 10).fill(i == index ? Palette.surfaceSunk : .clear))
                    }
                    .buttonStyle(.plain)
                }
                Rule().padding(.vertical, 12)
                Eyebrow("Key ideas")
                ForEach(chapter.keyIdeas, id: \.self) { k in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Circle().fill(Palette.ochre).frame(width: 6, height: 6)
                        Text(k).font(.mFootnote).foregroundStyle(Palette.inkSoft)
                    }
                    .padding(.top, 4)
                }
                Rule().padding(.vertical, 12)
                AIBadge(text: "AI-generated book", detail: "\(course.provenance)\n\nEngine: \(course.generatedBy)\nReview: \(course.reviewStatus.label)\(course.educatorNote.map { "\nEducator note: \($0)" } ?? "")")
            }
            .padding(18)
        }
        .background(Palette.paperDeep)
    }

    private func adapted(_ s: LessonSection) -> LessonSection {
        var x = s; x.checkpoint = nil; return x
    }

    private func page(_ s: LessonSection) -> some View {
        let f = format ?? .original
        let src = LessonAdapter.Source(sections: [adapted(s)])
        let report: LessonAdapter.FidelityReport = {
            switch f {
            case .chunked: return LessonAdapter.fidelity(src, adaptedSentenceIDs: LessonAdapter.chunkOrder(LessonAdapter.chunks(src, size: prefs.chunkSentences)))
            case .visual: return LessonAdapter.fidelity(src, adaptedSentenceIDs: LessonAdapter.visualOrder(LessonAdapter.visual(src)))
            default: return LessonAdapter.fidelity(src, adaptedSentenceIDs: src.sentences.map(\.id))
            }
        }()
        return VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Eyebrow("Page \(index + 1) of \(chapter.sections.count)")
                    Text(s.heading).font(prefs.font == .serif ? .display(30, .semibold) : .reading(prefs.font, 27, bold: true)).lineLimit(2)
                }
                Spacer()
                formatPicker
                Button { showFidelity = true } label: {
                    Image(systemName: report.passed ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(report.passed ? Palette.forest : Palette.terracotta)
                }
                .accessibilityLabel("Same-content check")
                .popover(isPresented: $showFidelity) { FidelityPopover(report: report, format: f, planSource: nil) }
                Button { showSettings = true } label: { Image(systemName: "textformat.size") }
                    .accessibilityLabel("Reading settings")
                    .popover(isPresented: $showSettings) {
                        ReadingSettingsPanel(prefs: Binding(get: { prefs }, set: { p in
                            if classroom.currentStudent != nil { classroom.updatePrefs(p) } else { store.settings.dyslexiaFriendly = p.profile == .dyslexia }
                        })).frame(width: 380)
                    }
            }
            .font(.system(size: 17, weight: .medium))
            .padding(.horizontal, 36).padding(.top, 20).padding(.bottom, 12)
            if s.isAdaptive {
                Label("This page was written just for you, using a different approach. Read it, then try the follow-up challenge.", systemImage: "wand.and.stars")
                    .font(.ui(14.5, .medium)).foregroundStyle(Palette.plum).padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Palette.plumSoft))
                    .padding(.horizontal, 36).padding(.bottom, 8)
            }
            Rule()
            ZStack {
                Palette.tint(prefs.tint)
                switch f {
                case .original: originalPage(s)
                case .chunked: ChunkedFormat(src: src, chunks: LessonAdapter.chunks(src, size: prefs.chunkSentences), prefs: prefs, onSeen: { _ in })
                case .listen: ListenFormat(src: src, prefs: .constant(prefs), onSeen: { _ in })
                case .visual: VisualFormat(src: src, sections: LessonAdapter.visual(src), prefs: prefs, onSeen: { _ in })
                }
            }
            if f != .original {
                Rule()
                HStack {
                    if s.checkpoint != nil {
                        Button { showCheck = true } label: { Label("Checkpoint", systemImage: "checkmark.circle") }.buttonStyle(.secondary(compact: true))
                    }
                    navButtons
                }
                .padding(.horizontal, 28).padding(.vertical, 12)
                .background(Palette.surface)
            }
        }
        .onAppear { markRead(s) }
        .sheet(isPresented: $showCheck) {
            if let c = s.checkpoint {
                ScrollView { QuickCheckView(check: c, sectionID: s.id, course: course, chapter: chapter).padding(28) }
                    .presentationDetents([.medium, .large])
            }
        }
    }

    private var formatPicker: some View {
        HStack(spacing: 2) {
            ForEach(LessonFormat.allCases) { f in
                Button { withAnimation(.snappy) { format = f } } label: {
                    Image(systemName: f.symbol).font(.system(size: 15, weight: .medium))
                        .frame(width: 40, height: 32)
                        .foregroundStyle((format ?? .original) == f ? Palette.onAccent : Palette.inkSoft)
                        .background(Capsule().fill((format ?? .original) == f ? Palette.ink : .clear))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(f.title) format")
                .accessibilityIdentifier("book-format-\(f.rawValue)")
            }
        }
        .padding(3)
        .background(Capsule().fill(Palette.surfaceSunk))
    }

    private func originalPage(_ s: LessonSection) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                ForEach(Array(s.body.components(separatedBy: "\n\n").enumerated()), id: \.offset) { _, para in
                    ReadingParagraph(text: para.trimmingCharacters(in: .whitespacesAndNewlines), prefs: prefs, terms: [], size: 20 * store.settings.textScale)
                }
                if let ill = s.illustration {
                    IllustrationView(illustration: ill)
                }
                if let check = s.checkpoint {
                    QuickCheckView(check: check, sectionID: s.id, course: course, chapter: chapter)
                }
                navButtons
            }
            .padding(.horizontal, 48).padding(.vertical, 28)
            .frame(maxWidth: 820)
            .frame(maxWidth: .infinity)
        }
    }

    private var navButtons: some View {
        HStack {
            if index > 0 {
                Button { index -= 1 } label: { Label("Previous", systemImage: "chevron.left") }.buttonStyle(.secondary)
            }
            Spacer()
            if index < chapter.sections.count - 1 {
                Button { index += 1 } label: { Label("Next page", systemImage: "chevron.right") }.buttonStyle(.primary)
            } else {
                Button(action: startChallenge) {
                    Label("Meet \(chapter.npc.emoji) \(chapter.npc.name) for the challenge", systemImage: "flag.checkered")
                }
                .buttonStyle(.primary(Theme.themeColor(chapter.theme)))
            }
        }
        .padding(.top, 10)
    }

    private func markRead(_ s: LessonSection) {
        guard !store.chapterProgress(course, chapter).sectionsRead.contains(s.id) else { return }
        store.mutateProgress(course, chapter) { $0.sectionsRead.insert(s.id) }
        store.addXP(course, 5)
        store.recomputeMastery(course, chapter)
    }
}

struct QuickCheckView: View {
    @Environment(AppStore.self) private var store
    var check: QuickCheck
    var sectionID: UUID
    var course: Course
    var chapter: Chapter
    @State private var picked: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Eyebrow("Checkpoint", color: Palette.forest)
            Text(check.question).font(.display(21, .semibold)).fixedSize(horizontal: false, vertical: true)
            ForEach(check.options.indices, id: \.self) { i in
                Button {
                    guard picked == nil || picked != check.correctIndex else { return }
                    picked = i
                    if i == check.correctIndex {
                        store.mutateProgress(course, chapter) { $0.quickChecksCorrect.insert(sectionID) }
                        store.addXP(course, 10)
                        store.recomputeMastery(course, chapter)
                    }
                } label: {
                    HStack {
                        Text(check.options[i]).multilineTextAlignment(.leading)
                        Spacer()
                        if picked == i { Image(systemName: i == check.correctIndex ? "checkmark.circle.fill" : "xmark.circle.fill") }
                    }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(color(for: i)))
                }
                .buttonStyle(.plain)
            }
            if let picked {
                Text(picked == check.correctIndex ? check.explanation : "Not quite. Think again, and try another option.")
                    .font(.mCallout).foregroundStyle(Palette.inkSoft).fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 16).fill(Palette.surface))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Palette.rule))
        .onAppear { if store.chapterProgress(course, chapter).quickChecksCorrect.contains(sectionID) { picked = check.correctIndex } }
    }

    private func color(for i: Int) -> Color {
        guard let picked, picked == i else { return Palette.surfaceSunk }
        return i == check.correctIndex ? Palette.forestSoft : Palette.terracottaSoft
    }
}
