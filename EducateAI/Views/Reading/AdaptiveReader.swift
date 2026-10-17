import SwiftUI

struct ReaderEvent { var progress: Double; var format: LessonFormat }

/// One lesson, five ways. Every format renders the *original sentences*; the fidelity check proves it.
struct AdaptiveReader: View {
    var sections: [LessonSection]
    var keyTerms: [String]
    @State var prefs: ReadingPrefs
    var initialFormat: LessonFormat
    var title: String
    var onProgress: (ReaderEvent) -> Void
    var onPrefsChange: ((ReadingPrefs) -> Void)? = nil
    var allowAIStructure = false

    @Environment(AppStore.self) private var app
    @State private var chosenFormat: LessonFormat?
    private var format: LessonFormat { chosenFormat ?? initialFormat }
    @State private var showSettings = false
    @State private var showFidelity = false
    @State private var plan: LessonAdapter.StructurePlan?
    @State private var planSource = ""
    @State private var seen: Set<Int> = []        // sentence ids seen

    var body: some View {
        let src = LessonAdapter.Source(sections: sections, extraTerms: keyTerms)
        let chunks = LessonAdapter.chunks(src, size: prefs.chunkSentences, plan: plan)
        let visual = LessonAdapter.visual(src, plan: plan)
        let order: [Int] = {
            switch format {
            case .original, .listen: return src.sentences.map(\.id)
            case .chunked: return LessonAdapter.chunkOrder(chunks)
            case .visual: return LessonAdapter.visualOrder(visual)
            }
        }()
        let report = LessonAdapter.fidelity(src, adaptedSentenceIDs: order, aiLabels: format == .chunked ? (chunks.compactMap(\.label).count) : 0)

        VStack(spacing: 0) {
            toolbar(report)
            Rule()
            ZStack {
                Palette.tint(prefs.tint).ignoresSafeArea()
                switch format {
                case .original: OriginalFormat(src: src, prefs: prefs, onSeen: markSeen)
                case .chunked: ChunkedFormat(src: src, chunks: chunks, prefs: prefs, onSeen: markSeen)
                case .listen: ListenFormat(src: src, prefs: $prefs, onSeen: markSeen)
                case .visual: VisualFormat(src: src, sections: visual, prefs: prefs, onSeen: markSeen)
                }
            }
            .environment(\.colorScheme, prefs.tint == .night ? .dark : (prefs.tint == .paper ? (UITraitCollection.current.userInterfaceStyle == .dark ? .dark : .light) : .light))
        }
        .onChange(of: chosenFormat) { _, _ in emit(src) }
        .onChange(of: prefs) { _, p in onPrefsChange?(p) }
        .task(id: allowAIStructure) {
            guard allowAIStructure, plan == nil, !app.primaryProvider.runsOnDevice else { return }
            let sentences = src.sentences.map(\.plain)
            if let p = await app.ai({ try await $0.planLessonStructure(sentences, chunkSize: prefs.chunkSentences) }),
               let groups = p.chunks, LessonAdapter.validPartition(groups, src) {
                plan = p; planSource = app.lastAIStatus
            }
        }
    }

    private func markSeen(_ ids: [Int]) {
        let before = seen.count
        seen.formUnion(ids)
        if seen.count != before { emit(LessonAdapter.Source(sections: sections, extraTerms: keyTerms)) }
    }

    private func emit(_ src: LessonAdapter.Source) {
        let p = src.sentences.isEmpty ? 1 : Double(seen.count) / Double(src.sentences.count)
        onProgress(ReaderEvent(progress: p, format: format))
    }

    private func toolbar(_ report: LessonAdapter.FidelityReport) -> some View {
        HStack(spacing: 14) {
            HStack(spacing: 4) {
                ForEach(LessonFormat.allCases) { f in
                    Button { withAnimation(.snappy) { chosenFormat = f } } label: {
                        Label(f.title, systemImage: f.symbol)
                            .font(.ui(14, .semibold))
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .foregroundStyle(format == f ? Palette.onAccent : Palette.inkSoft)
                            .background(Capsule().fill(format == f ? Palette.ink : .clear))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("format-\(f.rawValue)")
                    .accessibilityAddTraits(format == f ? .isSelected : [])
                }
            }
            .padding(4)
            .background(Capsule().fill(Palette.surfaceSunk))
            Spacer()
            Button { showFidelity = true } label: {
                Label(report.passed ? "Same content" : "Check failed", systemImage: report.passed ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                    .font(.ui(13, .semibold))
                    .foregroundStyle(report.passed ? Palette.forest : Palette.terracotta)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(Capsule().fill(report.passed ? Palette.forestSoft : Palette.terracottaSoft))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("fidelity-badge")
            .popover(isPresented: $showFidelity) { FidelityPopover(report: report, format: format, planSource: plan == nil ? nil : planSource) }
            Button { showSettings = true } label: {
                Image(systemName: "textformat.size").font(.system(size: 17, weight: .medium))
                    .frame(width: 38, height: 34)
                    .background(RoundedRectangle(cornerRadius: 9).fill(Palette.surfaceSunk))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Reading settings")
            .accessibilityIdentifier("reading-settings")
            .popover(isPresented: $showSettings) { ReadingSettingsPanel(prefs: $prefs).frame(width: 380) }
        }
        .padding(.horizontal, 20).padding(.vertical, 10)
        .background(Palette.surface)
    }
}

struct FidelityPopover: View {
    var report: LessonAdapter.FidelityReport
    var format: LessonFormat
    var planSource: String?
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Same-content check", systemImage: "checkmark.seal").font(.mHeadline).foregroundStyle(Palette.forest)
            Text(report.summary).font(.mSubheadline).fixedSize(horizontal: false, vertical: true)
            VStack(alignment: .leading, spacing: 8) {
                row("Sentences", report.sentencesPresent, report.sentencesTotal)
                row("Numbers and figures", report.numbersPresent, report.numbersTotal)
                row("Key terms", report.termsPresent, report.termsTotal)
                HStack { Text("Repeated sentences").font(.mSubheadline); Spacer(); Text("\(report.duplicated)").font(.ui(14, .semibold)).monospacedDigit() }
            }
            Rule()
            Text(format == .original ? "This is the lesson as written." :
                 "The \(format.title.lowercased()) format only regroups, highlights or reads the original sentences. Nothing is rewritten or summarised.")
                .font(.mFootnote).foregroundStyle(Palette.inkSoft).fixedSize(horizontal: false, vertical: true)
            if let planSource {
                Text("Chunk boundaries and \(report.aiLabels) signpost labels suggested by \(planSource). The AI returned sentence numbers only, and the result was verified above.")
                    .font(.mFootnote).foregroundStyle(Palette.plum).fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(20).frame(width: 360)
    }
    private func row(_ t: String, _ a: Int, _ b: Int) -> some View {
        HStack {
            Text(t).font(.mSubheadline)
            Spacer()
            Text("\(a) / \(b)").font(.ui(14, .semibold)).monospacedDigit()
            Image(systemName: a == b ? "checkmark.circle.fill" : "xmark.circle.fill").foregroundStyle(a == b ? Palette.forest : Palette.terracotta)
        }
    }
}

// MARK: - Typography

struct ReadingStyle {
    var prefs: ReadingPrefs
    var size: CGFloat = 20
    var font: Font { .reading(prefs.font, size) }
    var ink: Color { Palette.tintInk(prefs.tint) }

    /// Applies word spacing and key-term emphasis without changing any words.
    func attributed(_ text: String, terms: [String], highlightWords: NSRange? = nil) -> AttributedString {
        var s = (try? AttributedString(markdown: text, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(text)
        if !prefs.boldKeyTerms {
            // Remove bold emphasis when the learner turns it off.
            for run in s.runs where run.inlinePresentationIntent?.contains(.stronglyEmphasized) == true {
                s[run.range].inlinePresentationIntent = nil
            }
        } else {
            for t in terms {
                var searchStart = s.startIndex
                while let r = s[searchStart...].range(of: t, options: .caseInsensitive) {
                    s[r].inlinePresentationIntent = .stronglyEmphasized
                    searchStart = r.upperBound
                }
            }
        }
        for run in s.runs where run.inlinePresentationIntent?.contains(.stronglyEmphasized) == true {
            s[run.range].font = .reading(prefs.font, size, bold: true)
            if prefs.profile == .focus || prefs.profile == .dyslexia { s[run.range].backgroundColor = Palette.ochre.opacity(0.18) }
        }
        if let w = highlightWords, let r = Range(w, in: s.description.isEmpty ? "" : String(s.characters)) {
            let plain = String(s.characters)
            let lower = plain.distance(from: plain.startIndex, to: r.lowerBound)
            let len = plain.distance(from: r.lowerBound, to: r.upperBound)
            let a = s.index(s.startIndex, offsetByCharacters: lower)
            let b = s.index(a, offsetByCharacters: len)
            s[a..<b].backgroundColor = Palette.ochre.opacity(0.55)
        }
        if prefs.wordSpacing > 0 {
            // Widen word gaps by adding thin spaces after each regular space (presentation only).
            let extra = String(repeating: "\u{200A}", count: Int(prefs.wordSpacing.rounded()) * 2)
            var out = AttributedString()
            for run in s.runs {
                let piece = String(s[run.range].characters).replacingOccurrences(of: " ", with: " " + extra)
                var a = AttributedString(piece); a.mergeAttributes(run.attributes)
                out += a
            }
            s = out
        }
        return s
    }
}

struct ReadingParagraph: View {
    var text: String
    var prefs: ReadingPrefs
    var terms: [String]
    var size: CGFloat = 20
    var body: some View {
        let style = ReadingStyle(prefs: prefs, size: size)
        Text(style.attributed(text, terms: terms))
            .font(style.font)
            .tracking(prefs.letterSpacing)
            .lineSpacing(prefs.lineSpacing)
            .foregroundStyle(style.ink)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Original

struct OriginalFormat: View {
    var src: LessonAdapter.Source
    var prefs: ReadingPrefs
    var onSeen: ([Int]) -> Void
    @State private var rulerY: CGFloat = 220

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                ForEach(Array(src.sections.enumerated()), id: \.offset) { i, sec in
                    Eyebrow("Part \(i + 1) of \(src.sections.count)", color: Palette.tintInk(prefs.tint).opacity(0.55))
                        .padding(.top, i == 0 ? 0 : 30)
                    Text(sec.heading).font(prefs.font == .serif ? .display(32) : .reading(prefs.font, 30, bold: true)).foregroundStyle(Palette.tintInk(prefs.tint))
                    let paras = Dictionary(grouping: src.sentences.filter { $0.section == i }, by: \.paragraph)
                    ForEach(paras.keys.sorted(), id: \.self) { p in
                        ReadingParagraph(text: paras[p]!.map(\.text).joined(separator: " "), prefs: prefs, terms: src.keyTerms)
                            .onAppear { onSeen(paras[p]!.map(\.id)) }
                    }
                    if let ill = sec.illustration { IllustrationView(illustration: ill) }
                    if let c = sec.checkpoint { ReaderCheck(check: c, prefs: prefs) }
                }
            }
            .padding(.horizontal, 48).padding(.vertical, 40)
            .frame(maxWidth: prefs.profile == .dyslexia ? 700 : 760)
            .frame(maxWidth: .infinity)
        }
        .overlay(alignment: .topLeading) {
            if prefs.ruler { ReadingRuler(y: $rulerY, tint: prefs.tint) }
        }
    }
}

/// A draggable band that dims everything except the line being read.
struct ReadingRuler: View {
    @Binding var y: CGFloat
    var tint: PageTint
    var body: some View {
        GeometryReader { g in
            let h: CGFloat = 64
            ZStack(alignment: .topLeading) {
                Color.black.opacity(tint == .night ? 0.45 : 0.18).frame(height: max(0, y - h / 2)).allowsHitTesting(false)
                Color.black.opacity(tint == .night ? 0.45 : 0.18).frame(height: max(0, g.size.height - y - h / 2)).offset(y: y + h / 2).allowsHitTesting(false)
                RoundedRectangle(cornerRadius: 6).strokeBorder(Palette.ochre, lineWidth: 2)
                    .frame(height: h).offset(y: y - h / 2).allowsHitTesting(false)
                HStack {
                    Spacer()
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 14, weight: .bold)).foregroundStyle(Palette.onAccent)
                        .frame(width: 34, height: 34).background(Circle().fill(Palette.ochre))
                        .gesture(DragGesture().onChanged { v in y = min(max(40, v.location.y), g.size.height - 40) })
                        .accessibilityLabel("Reading ruler. Drag to move.")
                }
                .padding(.trailing, 10).offset(y: y - 17)
            }
        }
    }
}

struct ReaderCheck: View {
    var check: QuickCheck
    var prefs: ReadingPrefs
    @State private var picked: Int?
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Check your understanding", systemImage: "checkmark.circle").font(.ui(13, .semibold)).foregroundStyle(Palette.forest)
            Text(check.question).font(.reading(prefs.font, 19, bold: true)).foregroundStyle(Palette.ink).fixedSize(horizontal: false, vertical: true)
            ForEach(Array(check.options.enumerated()), id: \.offset) { i, o in
                Button { withAnimation { picked = i } } label: {
                    HStack {
                        Text(o).font(.reading(prefs.font, 17)).multilineTextAlignment(.leading)
                        Spacer()
                        if picked == i { Image(systemName: i == check.correctIndex ? "checkmark.circle.fill" : "xmark.circle.fill") }
                    }
                    .padding(12)
                    .foregroundStyle(Palette.ink)
                    .background(RoundedRectangle(cornerRadius: 10).fill(picked == i ? (i == check.correctIndex ? Palette.forestSoft : Palette.terracottaSoft) : Palette.surfaceSunk))
                }
                .buttonStyle(.plain)
            }
            if let p = picked {
                Text(p == check.correctIndex ? check.explanation : "Not quite. Look back at the paragraph above and try again.")
                    .font(.reading(prefs.font, 16)).foregroundStyle(Palette.inkSoft).fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 14).fill(Palette.surface))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Palette.rule))
        .environment(\.colorScheme, .light)
    }
}

// MARK: - Chunked (Focus)

struct ChunkedFormat: View {
    var src: LessonAdapter.Source
    var chunks: [LessonAdapter.Chunk]
    var prefs: ReadingPrefs
    var onSeen: ([Int]) -> Void
    @State private var index = 0
    @State private var extra: Extra? = nil      // illustration/check shown after a section's last chunk
    @State private var timerEnd: Date?
    @State private var breakDue = false
    @FocusState private var focused: Bool

    enum Extra: Hashable { case illustration(Int), check(Int) }

    var body: some View {
        VStack(spacing: 0) {
            trail
            Spacer(minLength: 20)
            Group {
                if let extra { extraView(extra) } else if let c = chunks[safe: index] { chunkCard(c) }
            }
            .frame(maxWidth: 720)
            .padding(.horizontal, 40)
            .id("\(index)-\(String(describing: extra))")
            .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
            Spacer(minLength: 20)
            controls
        }
        .focusable().focused($focused).focusEffectDisabled()
        .onKeyPress(.rightArrow) { next(); return .handled }
        .onKeyPress(.space) { next(); return .handled }
        .onKeyPress(.leftArrow) { back(); return .handled }
        .onAppear {
            focused = true
            if let c = chunks.first { onSeen(c.sentenceIDs) }
            if prefs.focusMinutes > 0, timerEnd == nil { timerEnd = Date().addingTimeInterval(Double(prefs.focusMinutes) * 60) }
        }
        .alert("Time for a short break", isPresented: $breakDue) {
            Button("Keep going") { timerEnd = Date().addingTimeInterval(Double(max(1, prefs.focusMinutes)) * 60) }
        } message: { Text("You've focused for \(prefs.focusMinutes) minutes. Stand up, stretch, get some water, then pick up right where you left off.") }
    }

    private var trail: some View {
        HStack(spacing: 14) {
            HStack(spacing: 4) {
                ForEach(chunks) { c in
                    Capsule().fill(c.id < index ? Palette.forest : c.id == index ? Palette.ochre : Palette.ruleStrong)
                        .frame(height: 6)
                        .padding(.trailing, c.isLastInSection ? 6 : 0)
                }
            }
            Text("\(min(index + 1, chunks.count)) of \(chunks.count)").font(.ui(13, .semibold)).monospacedDigit().foregroundStyle(Palette.inkSoft)
            if let end = timerEnd {
                TimelineView(.periodic(from: .now, by: 1)) { ctx in
                    let left = max(0, end.timeIntervalSince(ctx.date))
                    Label(String(format: "%d:%02d", Int(left) / 60, Int(left) % 60), systemImage: "timer")
                        .font(.ui(13, .semibold)).monospacedDigit()
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Capsule().fill(Palette.surfaceSunk))
                        .onChange(of: left == 0) { _, done in if done { breakDue = true } }
                }
            }
        }
        .padding(.horizontal, 28).padding(.top, 18)
    }

    private func chunkCard(_ c: LessonAdapter.Chunk) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 10) {
                Eyebrow(c.heading, color: Palette.tintInk(prefs.tint).opacity(0.6))
                if let l = c.label { Tag(text: l, symbol: "sparkle", color: Palette.plum) }
            }
            ReadingParagraph(text: c.sentenceIDs.map { src.sentences[$0].text }.joined(separator: " "), prefs: prefs, terms: src.keyTerms, size: 25)
        }
        .padding(36)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Palette.tint(prefs.tint)))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(Palette.rule))
        .shadow(color: .black.opacity(0.06), radius: 20, y: 10)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder private func extraView(_ e: Extra) -> some View {
        switch e {
        case .illustration(let s): if let ill = src.sections[s].illustration { IllustrationView(illustration: ill) }
        case .check(let s): if let c = src.sections[s].checkpoint { ReaderCheck(check: c, prefs: prefs) }
        }
    }

    private var controls: some View {
        HStack(spacing: 16) {
            Button(action: back) { Label("Back", systemImage: "arrow.left") }
                .buttonStyle(.secondary).disabled(index == 0 && extra == nil)
            Spacer()
            Text("Space or → for next").font(.mCaption).foregroundStyle(Palette.inkMuted)
            Spacer()
            Button(action: next) {
                Label(index >= chunks.count - 1 && extra == nil && nextExtra(after: chunks.last) == nil ? "Done" : "Next", systemImage: "arrow.right")
            }
            .buttonStyle(.primary)
            .accessibilityIdentifier("chunk-next")
        }
        .padding(.horizontal, 28).padding(.bottom, 22)
    }

    private func nextExtra(after c: LessonAdapter.Chunk?) -> Extra? {
        guard let c, c.isLastInSection else { return nil }
        if extra == nil, src.sections[c.section].illustration != nil { return .illustration(c.section) }
        if extra == nil || extra == .illustration(c.section), src.sections[c.section].checkpoint != nil { return .check(c.section) }
        return nil
    }

    private func next() {
        withAnimation(.snappy) {
            if let c = chunks[safe: index], let e = nextExtra(after: c) { extra = e; return }
            extra = nil
            if index + 1 < chunks.count { index += 1; onSeen(chunks[index].sentenceIDs) }
        }
    }

    private func back() {
        withAnimation(.snappy) {
            if extra != nil { extra = nil; return }
            if index > 0 { index -= 1 }
        }
    }
}

// MARK: - Listen

struct ListenFormat: View {
    var src: LessonAdapter.Source
    @Binding var prefs: ReadingPrefs
    var onSeen: ([Int]) -> Void
    @State private var reader = SpeechReader()

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 30) {
                        ForEach(Array(src.sections.enumerated()), id: \.offset) { i, sec in
                            VStack(alignment: .leading, spacing: 14) {
                                Text(sec.heading).font(.reading(prefs.font, 28, bold: true)).foregroundStyle(Palette.tintInk(prefs.tint))
                                ForEach(src.sentences.filter { $0.section == i }) { s in sentence(s).id(s.id) }
                            }
                        }
                    }
                    .padding(.horizontal, 48).padding(.vertical, 36)
                    .frame(maxWidth: 760).frame(maxWidth: .infinity)
                }
                .onChange(of: reader.current) { _, c in
                    if let c { withAnimation { proxy.scrollTo(c, anchor: .center) }; onSeen([c]) }
                }
            }
            player
        }
        .onAppear { reader.load(src.sentences.map(\.plain)); reader.rate = prefs.speechRate }
        .onDisappear { reader.stop() }
    }

    private func sentence(_ s: LessonAdapter.SourceSentence) -> some View {
        let active = reader.current == s.id
        let style = ReadingStyle(prefs: prefs, size: 21)
        return Button { reader.play(from: s.id) } label: {
            Text(style.attributed(s.text, terms: src.keyTerms, highlightWords: active ? reader.wordRange : nil))
                .font(style.font)
                .tracking(prefs.letterSpacing)
                .lineSpacing(prefs.lineSpacing)
                .foregroundStyle(active ? Palette.tintInk(prefs.tint) : Palette.tintInk(prefs.tint).opacity(reader.current == nil ? 1 : 0.55))
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 6).padding(.horizontal, 10)
                .background(RoundedRectangle(cornerRadius: 10).fill(active ? Palette.ochre.opacity(0.12) : .clear))
        }
        .buttonStyle(.plain)
        .accessibilityHint("Starts reading aloud from this sentence")
    }

    private var player: some View {
        HStack(spacing: 20) {
            Button { reader.previous() } label: { Image(systemName: "backward.fill") }.accessibilityLabel("Previous sentence")
            Button { reader.toggle() } label: {
                Image(systemName: reader.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 22)).foregroundStyle(Palette.onAccent)
                    .frame(width: 58, height: 58).background(Circle().fill(Palette.forest))
            }
            .accessibilityLabel(reader.isPlaying ? "Pause" : "Play")
            .accessibilityIdentifier("listen-play")
            Button { reader.next() } label: { Image(systemName: "forward.fill") }.accessibilityLabel("Next sentence")
            VStack(alignment: .leading, spacing: 2) {
                Text(reader.current.map { "Sentence \($0 + 1) of \(src.sentences.count)" } ?? "Tap play, or tap any sentence").font(.mHeadline)
                Text("Each word lights up as it's read.").font(.mCaption).foregroundStyle(Palette.inkMuted)
            }
            Spacer()
            Image(systemName: "tortoise").foregroundStyle(Palette.inkMuted)
            Slider(value: Binding(get: { prefs.speechRate }, set: { prefs.speechRate = $0; reader.rate = $0 }), in: 0.3...0.6).frame(width: 180)
                .accessibilityLabel("Reading speed")
            Image(systemName: "hare").foregroundStyle(Palette.inkMuted)
        }
        .font(.system(size: 18))
        .foregroundStyle(Palette.ink)
        .padding(.horizontal, 28).padding(.vertical, 14)
        .background(Palette.surface.shadow(.drop(color: .black.opacity(0.06), radius: 10, y: -4)))
    }
}

// MARK: - Visual

struct VisualFormat: View {
    var src: LessonAdapter.Source
    var sections: [LessonAdapter.VisualSection]
    var prefs: ReadingPrefs
    var onSeen: ([Int]) -> Void

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 48) {
                ForEach(sections) { sec in
                    VStack(alignment: .leading, spacing: 18) {
                        HStack(spacing: 14) {
                            Image(systemName: sec.symbol).font(.system(size: 22, weight: .medium)).foregroundStyle(Palette.forest)
                                .frame(width: 50, height: 50).background(Circle().fill(Palette.forestSoft))
                            Text(sec.heading).font(.reading(prefs.font, 28, bold: true))
                        }
                        blocks(sec)
                        if let ill = sec.illustration { IllustrationView(illustration: ill) }
                    }
                    .onAppear { onSeen(sec.blocks.flatMap(\.sentenceIDs)) }
                }
            }
            .padding(.horizontal, 44).padding(.vertical, 36)
            .frame(maxWidth: 980).frame(maxWidth: .infinity)
        }
        .foregroundStyle(Palette.tintInk(prefs.tint))
    }

    @ViewBuilder private func blocks(_ sec: LessonAdapter.VisualSection) -> some View {
        // Group consecutive cards of the same kind into rows so the layout reads like a diagram.
        let groups = group(sec.blocks)
        ForEach(Array(groups.enumerated()), id: \.offset) { _, g in
            switch g.first {
            case .term?, .fact?:
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 260), spacing: 14)], spacing: 14) {
                    ForEach(g) { b in card(b) }
                }
            case .steps(let title, let ids)?:
                stepsView(title, ids)
            default:
                VStack(alignment: .leading, spacing: 12) { ForEach(g) { b in card(b) } }
            }
        }
    }

    private func group(_ blocks: [LessonAdapter.VisualBlock]) -> [[LessonAdapter.VisualBlock]] {
        func kind(_ b: LessonAdapter.VisualBlock) -> Int {
            switch b { case .term, .fact: return 0; case .steps: return 1; case .idea: return 2 }
        }
        var out: [[LessonAdapter.VisualBlock]] = []
        for b in blocks {
            if kind(b) != 1, let last = out.last?.last, kind(last) == kind(b) { out[out.count - 1].append(b) } else { out.append([b]) }
        }
        return out
    }

    @ViewBuilder private func card(_ b: LessonAdapter.VisualBlock) -> some View {
        switch b {
        case .term(let term, let s, let symbol):
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: symbol).foregroundStyle(Palette.slate)
                    Eyebrow("Key term", color: Palette.slate)
                }
                Text(term).font(prefs.font == .serif ? .display(24, .semibold) : .reading(prefs.font, 22, bold: true))
                ReadingParagraph(text: src.sentences[s].text, prefs: prefs, terms: src.keyTerms, size: 16)
            }
            .padding(18).frame(maxWidth: .infinity, alignment: .topLeading)
            .background(RoundedRectangle(cornerRadius: 14).fill(Palette.slateSoft.opacity(0.7)))
        case .fact(let fig, let s):
            VStack(alignment: .leading, spacing: 8) {
                Text(fig).font(.display(40, .semibold)).foregroundStyle(Palette.terracotta).minimumScaleFactor(0.5).lineLimit(1)
                ReadingParagraph(text: src.sentences[s].text, prefs: prefs, terms: src.keyTerms, size: 16)
            }
            .padding(18).frame(maxWidth: .infinity, alignment: .topLeading)
            .background(RoundedRectangle(cornerRadius: 14).fill(Palette.terracottaSoft.opacity(0.7)))
        case .idea(let s, let symbol):
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: symbol).font(.system(size: 16)).foregroundStyle(Palette.forest)
                    .frame(width: 34, height: 34).background(Circle().fill(Palette.forestSoft))
                ReadingParagraph(text: src.sentences[s].text, prefs: prefs, terms: src.keyTerms, size: 18)
            }
        case .steps(let t, let ids):
            stepsView(t, ids)
        }
    }

    private func stepsView(_ title: String, _ ids: [Int]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow(title, color: Palette.ochre)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 0) {
                    ForEach(Array(ids.enumerated()), id: \.offset) { i, s in
                        HStack(alignment: .top, spacing: 0) {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("\(i + 1)").font(.display(22, .semibold)).foregroundStyle(Palette.onAccent)
                                    .frame(width: 40, height: 40).background(Circle().fill(Palette.ochre))
                                ReadingParagraph(text: src.sentences[s].text, prefs: prefs, terms: src.keyTerms, size: 16)
                            }
                            .padding(16).frame(width: 240, alignment: .topLeading)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Palette.ochreSoft.opacity(0.75)))
                            if i < ids.count - 1 {
                                Image(systemName: "arrow.right").font(.system(size: 18, weight: .semibold)).foregroundStyle(Palette.ochre)
                                    .padding(.horizontal, 8).padding(.top, 24)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Settings panel

struct ReadingSettingsPanel: View {
    @Binding var prefs: ReadingPrefs
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Reading settings").font(.mTitle3)
                VStack(alignment: .leading, spacing: 8) {
                    Eyebrow("Profile presets")
                    FlowRow(spacing: 6) {
                        ForEach(ReadingProfile.allCases) { p in
                            Button { prefs = .preset(p) } label: { Label(p.title, systemImage: p.symbol) }
                                .buttonStyle(.bordered).tint(prefs.profile == p ? Palette.forest : Palette.inkSoft).font(.ui(13, .semibold))
                        }
                    }
                }
                VStack(alignment: .leading, spacing: 8) {
                    Eyebrow("Typeface")
                    ForEach(ReadingFont.allCases) { f in
                        Button { prefs.font = f } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(f.title).font(.reading(f, 18))
                                    Text(f.note).font(.mCaption).foregroundStyle(Palette.inkMuted)
                                }
                                Spacer()
                                if prefs.font == f { Image(systemName: "checkmark").foregroundStyle(Palette.forest) }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("font-\(f.rawValue)")
                    }
                }
                slider("Letter spacing", $prefs.letterSpacing, 0...3)
                slider("Line spacing", $prefs.lineSpacing, 4...24)
                slider("Word spacing", $prefs.wordSpacing, 0...2, step: 1)
                VStack(alignment: .leading, spacing: 8) {
                    Eyebrow("Page tint")
                    HStack(spacing: 10) {
                        ForEach(PageTint.allCases) { t in
                            Button { prefs.tint = t } label: {
                                Circle().fill(Palette.tint(t)).frame(width: 34, height: 34)
                                    .overlay(Circle().strokeBorder(prefs.tint == t ? Palette.forest : Palette.ruleStrong, lineWidth: prefs.tint == t ? 3 : 1))
                            }
                            .buttonStyle(.plain).accessibilityLabel("\(t.title) page")
                        }
                    }
                }
                Toggle("Reading ruler", isOn: $prefs.ruler).tint(Palette.forest)
                Toggle("Emphasise key terms", isOn: $prefs.boldKeyTerms).tint(Palette.forest)
                Stepper("Chunk size: \(prefs.chunkSentences) sentence\(prefs.chunkSentences == 1 ? "" : "s")", value: $prefs.chunkSentences, in: 1...4)
                Stepper("Focus timer: \(prefs.focusMinutes == 0 ? "off" : "\(prefs.focusMinutes) min")", value: $prefs.focusMinutes, in: 0...25, step: 5)
                Text("These settings change how the lesson looks and sounds, never what it says.").font(.mFootnote).foregroundStyle(Palette.inkMuted)
            }
            .font(.mBody)
            .padding(22)
        }
        .frame(maxHeight: 640)
    }

    private func slider(_ t: String, _ v: Binding<Double>, _ r: ClosedRange<Double>, step: Double? = nil) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Eyebrow(t)
            if let step { Slider(value: v, in: r, step: step).tint(Palette.forest) } else { Slider(value: v, in: r).tint(Palette.forest) }
        }
    }
}
