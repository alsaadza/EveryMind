import SwiftUI

struct ChallengeView: View {
    @Environment(AppStore.self) private var store
    var course: Course
    var chapter: Chapter
    var openTutor: () -> Void
    var remediated: (LessonSection) -> Void
    var mastered: () -> Void

    @State private var answer = ""
    @State private var reasoning = ""
    @State private var hintsShown: [String] = []
    @State private var evaluation: Evaluation?
    @State private var busy = false
    @State private var showPad = false
    @State private var wrongAttempts = 0
    @State private var npcLine = ""
    @State private var showSolution = false
    @State private var teachBack = ""
    @State private var challengeID: UUID?

    static func current(store: AppStore, course: Course, chapter: Chapter) -> Challenge? {
        let p = store.chapterProgress(course, chapter)
        return chapter.challenges.first { !p.solvedChallenges.contains($0.id) && !p.revealedSolutions.contains($0.id) }
    }

    private var live: Chapter { store.course(course.id)?.chapters.first { $0.id == chapter.id } ?? chapter }
    private var liveCourse: Course { store.course(course.id) ?? course }

    var body: some View {
        let ch = Self.current(store: store, course: liveCourse, chapter: live)
        HStack(alignment: .top, spacing: 0) {
            npcPanel(ch).frame(width: 300)
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let ch {
                        workArea(ch)
                    } else {
                        allAttempted
                    }
                }
                .padding(32)
                .frame(maxWidth: 860)
                .frame(maxWidth: .infinity)
            }
        }
        .onAppear { resetIfNeeded(ch) }
        .onChange(of: ch?.id) { _, _ in resetIfNeeded(Self.current(store: store, course: liveCourse, chapter: live)) }
    }

    private func resetIfNeeded(_ ch: Challenge?) {
        guard ch?.id != challengeID else { return }
        challengeID = ch?.id
        answer = ""; reasoning = ""; hintsShown = []; evaluation = nil; wrongAttempts = 0; showSolution = false; teachBack = ""
        npcLine = ch.map { $0.isFollowUp ? "Let's try a fresh one, using what your new page showed you." : (live.challenges.first?.id == $0.id ? live.npc.greeting : "Nicely done. Here's the next one.") } ?? ""
    }

    // MARK: NPC panel

    private func npcPanel(_ ch: Challenge?) -> some View {
        let p = store.chapterProgress(liveCourse, live)
        return VStack(spacing: 18) {
            Text(live.npc.emoji).font(.system(size: 96))
                .padding(20)
                .background(Circle().fill(Theme.themeColor(live.theme).opacity(0.18)))
            VStack(spacing: 2) {
                Text(live.npc.name).font(.mTitle2)
                Text(live.npc.role).font(.mSubheadline).foregroundStyle(Palette.inkSoft)
            }
            if !npcLine.isEmpty {
                Text(npcLine)
                    .font(.mCallout)
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 18).fill(Palette.surface)).overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Palette.rule))
                    .overlay(alignment: .top) { Image(systemName: "triangle.fill").foregroundStyle(Palette.surface).offset(y: -12) }
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel("\(live.npc.name) says: \(npcLine)")
            }
            Spacer()
            VStack(alignment: .leading, spacing: 8) {
                Text("Challenges").font(.mHeadline)
                ForEach(Array(live.challenges.enumerated()), id: \.element.id) { i, c in
                    HStack {
                        Image(systemName: p.solvedChallenges.contains(c.id) ? "checkmark.circle.fill" : p.revealedSolutions.contains(c.id) ? "eye.circle.fill" : c.id == ch?.id ? "circle.inset.filled" : "circle")
                            .foregroundStyle(p.solvedChallenges.contains(c.id) ? Theme.mint : c.id == ch?.id ? Theme.accent : .secondary)
                        Text(c.isFollowUp ? "Follow-up \(i + 1)" : "Challenge \(i + 1)").font(.mSubheadline)
                        if c.isFollowUp { Image(systemName: "sparkles").font(.mCaption).foregroundStyle(Theme.accent) }
                    }
                }
                HStack {
                    Text("Mastery").font(.mSubheadline)
                    ProgressView(value: p.mastery).tint(Theme.mint)
                    Text("goal \(Int(store.settings.masteryThreshold * 100))%").font(.mCaption).foregroundStyle(Palette.inkSoft)
                }
                .padding(.top, 6)
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 16).fill(Palette.surface)).overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Palette.rule))
        }
        .padding(24)
    }

    // MARK: Work area

    @ViewBuilder
    private func workArea(_ ch: Challenge) -> some View {
        Text(ch.prompt).font(.display(27, .regular)).fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)

        // Answer
        VStack(alignment: .leading, spacing: 10) {
            Text("Your answer").font(.mHeadline)
            switch ch.answerType {
            case .multipleChoice:
                ForEach(ch.options ?? [], id: \.self) { opt in
                    Button { answer = opt } label: {
                        HStack {
                            Image(systemName: answer == opt ? "largecircle.fill.circle" : "circle")
                            Text(opt).multilineTextAlignment(.leading)
                            Spacer()
                        }
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 12).fill(answer == opt ? Theme.accent.opacity(0.15) : Palette.surface))
                    }
                    .buttonStyle(.plain)
                }
            case .numeric:
                TextField("e.g. 1/6, 0.25 or 25%", text: $answer)
                    .font(.title2.monospacedDigit())
                    .keyboardType(.numbersAndPunctuation)
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Palette.surface)).overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Palette.rule))
            case .shortText:
                TextField("Your answer in a sentence", text: $answer, axis: .vertical)
                    .lineLimit(2...4)
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Palette.surface)).overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Palette.rule))
            }
        }

        // Reasoning (required): this is what makes it learning rather than guessing.
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Explain your reasoning").font(.mHeadline)
                Text("required").font(.ui(12, .bold)).foregroundStyle(Theme.coral)
                Spacer()
                Text("\(wordCount(reasoning)) words").font(.mCaption).foregroundStyle(wordCount(reasoning) >= 6 ? Theme.mint : .secondary)
            }
            TextEditor(text: $reasoning)
                .frame(minHeight: 110)
                .scrollContentBackground(.hidden)
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 12).fill(Palette.surface)).overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Palette.rule))
                .overlay(alignment: .topLeading) {
                    if reasoning.isEmpty {
                        Text("How did you get your answer? Why does it make sense?").foregroundStyle(.tertiary).padding(18).allowsHitTesting(false)
                    }
                }
                .accessibilityLabel("Explain your reasoning")
        }

        if showPad {
            ScratchpadView(key: ch.id.uuidString).frame(height: 300)
                .transition(.opacity.combined(with: .move(edge: .top)))
        }

        // Hints
        if !hintsShown.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(hintsShown.enumerated()), id: \.offset) { i, h in
                    Label { Text(h).fixedSize(horizontal: false, vertical: true) } icon: {
                        Text("\(i + 1)").font(.ui(12, .bold)).frame(width: 22, height: 22).background(Circle().fill(Theme.sun)).foregroundStyle(.white)
                    }
                }
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 14).fill(Theme.sun.opacity(0.12)))
        }

        // Actions
        HStack(spacing: 12) {
            Button { Task { await nextHint(ch) } } label: {
                Label(hintsShown.count < ch.hints.count ? "Hint (\(ch.hints.count - hintsShown.count) left)" : "No hints left", systemImage: "lightbulb.fill")
            }
            .buttonStyle(.secondary(compact: true))
            .disabled(hintsShown.count >= ch.hints.count || busy)

            Button { withAnimation { showPad.toggle() } } label: { Label(showPad ? "Hide scratchpad" : "Scratchpad", systemImage: "pencil.tip.crop.circle") }
                .buttonStyle(.secondary(compact: true))

            if store.settings.aiEnabled {
                Button(action: openTutor) { Label("Ask tutor", systemImage: "bubble.left.fill") }.buttonStyle(.secondary(compact: true))
            }
            Spacer()
            Button { Task { await submit(ch) } } label: {
                if busy { ProgressView().tint(.white) } else { Label("Submit", systemImage: "paperplane.fill") }
            }
            .buttonStyle(PillButtonStyle())
            .disabled(busy || answer.trimmingCharacters(in: .whitespaces).isEmpty || wordCount(reasoning) < 4)
        }
        if wordCount(reasoning) < 4 && !answer.isEmpty {
            Text("Add a few words about how you got your answer. Your guide needs to see your thinking.").font(.mFootnote).foregroundStyle(Palette.inkSoft)
        }

        if let evaluation { feedbackCard(evaluation, ch) }

        if wrongAttempts >= 2 && evaluation?.correct != true {
            struggleCard(ch)
        }
    }

    private func feedbackCard(_ e: Evaluation, _ ch: Challenge) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: e.correct ? "checkmark.seal.fill" : "arrow.uturn.backward.circle.fill")
                    .font(.system(size: 32)).foregroundStyle(e.correct ? Palette.forest : Palette.ochre)
                VStack(alignment: .leading) {
                    Text(e.correct ? "Correct" : "Not yet").font(.mTitle2)
                    HStack(spacing: 8) {
                        Text("Reasoning").fixedSize()
                        Meter(value: e.reasoningScore, color: e.reasoningScore >= 0.6 ? Palette.forest : Palette.ochre, height: 5).frame(width: 110)
                        Text("\(Int(e.reasoningScore * 100))%").monospacedDigit().fixedSize()
                    }
                    .font(.mSubheadline)
                    .foregroundStyle(Palette.inkSoft)
                }
                Spacer()
                AIBadge(text: "How this was judged", detail: e.source)
            }
            Text(e.feedback).font(.mBody).fixedSize(horizontal: false, vertical: true)
            if !ch.rubric.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("A strong explanation…").font(.ui(14, .semibold))
                    ForEach(ch.rubric, id: \.idea) { r in
                        let met = e.rubricMet.contains(r.idea)
                        Label(r.idea, systemImage: met ? "checkmark.circle.fill" : "circle.dashed")
                            .foregroundStyle(met ? Palette.forest : Palette.inkMuted).font(.mSubheadline)
                    }
                }
            }
            if let probe = e.probe {
                Label(probe, systemImage: "questionmark.bubble").font(.custom(Typeface.serifItalic, size: 15)).foregroundStyle(Theme.accent)
            }
            if e.correct {
                HStack {
                    if e.reasoningScore < 0.6 {
                        Button("Improve my explanation") { evaluation = nil }.buttonStyle(.secondary(compact: true))
                    }
                    Spacer()
                    Button { advance(ch) } label: { Label("Continue", systemImage: "arrow.right") }.buttonStyle(PillButtonStyle(color: Theme.mint))
                }
            }
        }
        .padding(22)
        .background(RoundedRectangle(cornerRadius: 20).fill((e.correct ? Theme.mint : Theme.sun).opacity(0.1)))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke((e.correct ? Theme.mint : Theme.sun).opacity(0.4)))
        .accessibilityElement(children: .contain)
    }

    private func struggleCard(_ ch: Challenge) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Struggling is part of learning", systemImage: "figure.climbing").font(.mHeadline)
            Text("Your book can explain this idea a different way, then give you a fresh challenge on the same skill. That counts toward mastery just the same.")
                .fixedSize(horizontal: false, vertical: true)
            HStack {
                Button { Task { await remediate(ch) } } label: {
                    if busy { ProgressView() } else { Label("Show me another way", systemImage: "wand.and.stars") }
                }
                .buttonStyle(PillButtonStyle())
                .disabled(busy)
                Spacer()
                if hintsShown.count >= min(store.settings.hintsBeforeSolution, ch.hints.count) && wrongAttempts >= 3 {
                    Button("See the worked solution") { showSolution = true }.buttonStyle(.secondary(compact: true))
                } else {
                    Text("The worked solution unlocks after \(min(store.settings.hintsBeforeSolution, ch.hints.count)) hints and 3 attempts.")
                        .font(.mCaption).foregroundStyle(Palette.inkSoft)
                }
            }
            if showSolution {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Worked solution").font(.mHeadline)
                    Text(ch.solution).fixedSize(horizontal: false, vertical: true)
                    Text("Teach it back: in your own words, explain the key step.").font(.ui(14, .semibold)).padding(.top, 6)
                    TextField("The key step is…", text: $teachBack, axis: .vertical).lineLimit(2...4)
                        .padding(12).background(RoundedRectangle(cornerRadius: 10).fill(Palette.surface)).overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Palette.rule))
                    Button("Done, give me a similar challenge to prove it") {
                        store.mutateProgress(liveCourse, live) { $0.revealedSolutions.insert(ch.id); if !teachBack.isEmpty { $0.reflection += "\nTeach-back: \(teachBack)" } }
                        Task { await remediate(ch) }
                    }
                    .buttonStyle(.primary(Palette.forest, compact: true))
                    .disabled(wordCount(teachBack) < 4 || busy)
                }
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 14).fill(Palette.surfaceSunk))
            }
        }
        .padding(22)
        .background(RoundedRectangle(cornerRadius: 20).fill(Theme.accent.opacity(0.08)))
    }

    private var allAttempted: some View {
        let p = store.chapterProgress(liveCourse, live)
        return VStack(spacing: 18) {
            Image(systemName: "mountain.2.fill").font(.system(size: 60)).foregroundStyle(Theme.accent)
            Text("Almost there").font(.mLargeTitle)
            Text("Your mastery is \(Int(p.mastery * 100))%. The goal is \(Int(store.settings.masteryThreshold * 100))%. One more explanation and challenge will get you there.")
                .multilineTextAlignment(.center).font(.ui(19, .medium))
            Button { Task { await remediate(live.challenges.last ?? live.challenges[0]) } } label: {
                if busy { ProgressView() } else { Label("Show me another way", systemImage: "wand.and.stars") }
            }
            .buttonStyle(PillButtonStyle())
        }
        .frame(maxWidth: .infinity).padding(.top, 60)
    }

    // MARK: Actions

    private var tutorContext: TutorContext {
        TutorContext(topic: liveCourse.topic, level: liveCourse.level, chapter: live, currentSection: nil, helpLevel: store.effectiveHelpLevel,
                     activeChallenge: Self.current(store: store, course: liveCourse, chapter: live), learnerName: nil)
    }

    private func nextHint(_ ch: Challenge) async {
        busy = true; defer { busy = false }
        let level = hintsShown.count
        let ctx = tutorContext
        let h: String
        if store.settings.aiEnabled {
            h = await store.ai { try await $0.hint(challenge: ch, level: level, answer: answer, reasoning: reasoning, context: ctx) } ?? ch.hints[min(level, ch.hints.count - 1)]
        } else {
            h = ch.hints[min(level, ch.hints.count - 1)]
        }
        withAnimation { hintsShown.append(h) }
        npcLine = ["Here's a nudge. Take your time.", "Let's think about strategy.", "You're close. One more step."][min(level, 2)]
        store.emitSignal(course: liveCourse, chapter: live, kind: "hint", tag: "level-\(level + 1)", value: 1)
    }

    private func submit(_ ch: Challenge) async {
        busy = true; defer { busy = false }
        let attemptNo = store.chapterProgress(liveCourse, live).attempts.filter { $0.challengeID == ch.id }.count + 1
        let ctx = tutorContext
        let a = answer, r = reasoning
        var e: Evaluation?
        if store.settings.aiEnabled {
            e = await store.ai { try await $0.evaluate(challenge: ch, answer: a, reasoning: r, attempt: attemptNo, context: ctx) }
        }
        if e == nil { e = try? await OfflineProvider().evaluate(challenge: ch, answer: a, reasoning: r, attempt: attemptNo, context: ctx) }
        guard let e else { return }
        let attempt = ChallengeAttempt(challengeID: ch.id, answer: a, reasoning: r, correct: e.correct, reasoningScore: e.reasoningScore, hintsUsed: hintsShown.count, misconception: e.misconception)
        store.mutateProgress(liveCourse, live) { p in
            p.attempts.append(attempt)
            if e.correct { p.solvedChallenges.insert(ch.id) }
        }
        store.emitSignal(course: liveCourse, chapter: live, kind: "challenge_attempt", tag: e.correct ? "correct" : (e.misconception ?? "incorrect"), value: e.reasoningScore)
        withAnimation(.spring) { evaluation = e }
        if e.correct {
            npcLine = e.reasoningScore >= 0.6 ? "Brilliant! You didn't just get it right. You showed why." : "Right answer! Can you strengthen your explanation?"
            store.addXP(liveCourse, 30 + (e.reasoningScore >= 0.7 ? 10 : 0) + (hintsShown.isEmpty ? 10 : 0))
            if hintsShown.isEmpty { store.award("independent", "Independent Solver", "Solved a challenge without hints", "brain.head.profile") }
            if e.reasoningScore >= 0.8 { store.award("clear-thinker", "Clear Thinker", "Wrote an excellent explanation", "text.bubble.fill") }
            if ch.isFollowUp { store.award("persistence", "Persistence", "Solved a challenge after a new explanation", "figure.climbing") }
            store.recomputeMastery(liveCourse, live)
        } else {
            wrongAttempts += 1
            npcLine = wrongAttempts >= 2 ? "This one's tricky. Want me to show you another way to think about it?" : "Good try. Mistakes show us where to look. Check your reasoning."
        }
    }

    private func advance(_ ch: Challenge) {
        store.recomputeMastery(liveCourse, live)
        if store.completeChapterIfMastered(liveCourse, live) {
            store.emitSignal(course: liveCourse, chapter: live, kind: "mastery", tag: "mastered", value: store.chapterProgress(liveCourse, live).mastery)
            mastered()
        } else {
            challengeID = nil
            resetIfNeeded(Self.current(store: store, course: liveCourse, chapter: live))
        }
    }

    private func remediate(_ ch: Challenge) async {
        busy = true; defer { busy = false }
        let p = store.chapterProgress(liveCourse, live)
        let atts = p.attempts.filter { $0.challengeID == ch.id }
        let c = liveCourse, chap = live
        var remOpt = await store.ai({ try await $0.remediate(chapter: chap, topic: c.topic, level: c.level, struggledWith: ch, attempts: atts, round: p.remediations) })
        if remOpt == nil { remOpt = try? await OfflineProvider().remediate(chapter: chap, topic: c.topic, level: c.level, struggledWith: ch, attempts: atts, round: p.remediations) }
        guard let rem = remOpt else { return }
        var course = liveCourse
        guard let ci = course.chapters.firstIndex(where: { $0.id == chap.id }) else { return }
        var section = rem.section
        section.isAdaptive = true
        if section.heading.isEmpty { section.heading = rem.approach }
        var follow = rem.followUp
        follow.isFollowUp = true
        course.chapters[ci].sections.append(section)
        course.chapters[ci].challenges.append(follow)
        store.update(course)
        store.mutateProgress(course, course.chapters[ci]) { $0.remediations += 1 }
        store.emitSignal(course: course, chapter: course.chapters[ci], kind: "remediation", tag: ch.misconceptions?.values.first ?? "general", value: 1)
        remediated(section)
    }

    private func wordCount(_ s: String) -> Int { s.split { $0.isWhitespace }.count }
}
