import Foundation

/// Fully on-device engine. Uses curated content, retrieval over the textbook, rubric scoring
/// and Socratic templates. No network and no learner data leaves the iPad.
struct OfflineProvider: AIProvider {
    var displayName: String { "On-device engine" }
    var runsOnDevice: Bool { true }

    func generateCourse(_ request: CourseRequest) async throws -> Course {
        try await Task.sleep(nanoseconds: 1_400_000_000) // let the "writing your book" moment breathe
        return OfflineLibrary.course(for: request)
    }

    // MARK: Tutor

    func tutor(_ context: TutorContext, history: [ChatMessage], question: String) async throws -> TutorReply {
        try await Task.sleep(nanoseconds: 450_000_000)
        let q = question.lowercased()

        if PrivacyFilter.needsUrgentHumanSupport(question) {
            return TutorReply(text: PrivacyFilter.urgentSupportMessage, sources: ["Safety guidance"])
        }

        // Guardrail: do not hand over challenge answers.
        let answerSeeking = ["what's the answer", "what is the answer", "just tell me", "give me the answer", "solve it", "solve this", "answer to the", "do it for me"]
        if let ch = context.activeChallenge, answerSeeking.contains(where: { q.contains($0) }) {
            let hint = ch.hints.first ?? "Start by listing every possible outcome."
            return TutorReply(text: "I won't give you the answer, because working it out is how it sticks. Let's take one step together. \(hint)\n\nWhat do you think the first step is?",
                              sources: ["Challenge hint ladder", "Help level: \(context.helpLevel.rawValue)"])
        }

        // Common quick-prompt intents, answered from the page the learner is on.
        if let intent = Self.intentReply(q, context: context) { return intent }

        // Retrieve the most relevant passages from the chapter.
        let terms = Set(AnswerChecker.normalize(q).split(separator: " ").map(String.init).filter { $0.count > 2 && !Self.stop.contains($0) })
        var scored: [(LessonSection, String, Int)] = []
        for section in context.chapter.sections {
            for para in section.body.components(separatedBy: "\n\n") {
                let words = Set(AnswerChecker.normalize(para).split(separator: " ").map(String.init))
                var score = terms.intersection(words).count * 2
                if let cur = context.currentSection, cur.id == section.id { score += 1 }
                for t in terms where AnswerChecker.normalize(section.heading).contains(t) { score += 2 }
                scored.append((section, para, score))
            }
        }
        scored.sort { $0.2 > $1.2 }
        let best = scored.first(where: { $0.2 > 1 })

        let wantsExample = q.contains("example") || q.contains("real life") || q.contains("real world")
        let confused = q.contains("confus") || q.contains("don't get") || q.contains("dont get") || q.contains("don't understand") || q.contains("lost")

        var text = ""
        var sources: [String] = []
        if let best {
            let excerpt = Self.clean(best.1)
            sources.append("Chapter \(context.chapter.index + 1), \"\(best.0.heading)\"")
            switch context.helpLevel {
            case .socratic:
                text = "Here's the part of your book that helps:\n\n“\(excerpt)”\n\n\(Self.probe(for: terms, chapter: context.chapter))"
            case .balanced:
                text = "Good question. Your book puts it this way:\n\n“\(excerpt)”\n\nIn other words, \(Self.restate(excerpt))\n\n\(Self.probe(for: terms, chapter: context.chapter))"
            case .supportive:
                text = "Let me explain. \(excerpt)\n\nIn other words, \(Self.restate(excerpt))"
                if let idea = context.chapter.keyIdeas.first { text += "\n\nThe big idea to hold on to: \(idea)" }
                text += "\n\nWant me to walk through an example step by step?"
            }
        } else if confused, let section = context.currentSection ?? context.chapter.sections.first {
            sources.append("Chapter \(context.chapter.index + 1), \"\(section.heading)\"")
            text = "That's okay. Confusion usually means you're close to something new. Let's slow down. In one sentence, what do you think \"\(section.heading)\" is about? I'll build from what you already know."
        } else {
            sources.append("Chapter \(context.chapter.index + 1) key ideas")
            let ideas = context.chapter.keyIdeas.prefix(3).map { "• \($0)" }.joined(separator: "\n")
            text = "I couldn't find that exact idea in this chapter, so here are its key ideas:\n\(ideas)\n\nWhich of these is closest to your question? You can also try rephrasing it, or ask your teacher. Connecting OCI Generative AI gives the tutor wider knowledge."
        }
        if wantsExample, context.helpLevel != .socratic {
            text += "\n\nTry this example: picture doing it with real objects, like coins, dice or slices of something, and count the ways each outcome can happen."
        }
        sources.append("On-device retrieval (no data sent)")
        return TutorReply(text: text, sources: sources)
    }

    static func intentReply(_ q: String, context: TutorContext) -> TutorReply? {
        let section = context.currentSection ?? context.chapter.sections.first
        let src = ["Chapter \(context.chapter.index + 1), \"\(section?.heading ?? context.chapter.title)\"", "On-device engine (no data sent)"]
        let paras = (section?.body ?? "").replacingOccurrences(of: "**", with: "").components(separatedBy: "\n\n").filter { !$0.isEmpty }
        let sentences = paras.joined(separator: " ").components(separatedBy: ". ").filter { $0.count > 20 }
        let idea = context.chapter.keyIdeas.first { k in
            let words = Set(AnswerChecker.normalize(k).split(separator: " ").map(String.init).filter { $0.count > 4 })
            return !words.isDisjoint(with: Set(AnswerChecker.normalize(paras.joined(separator: " ")).split(separator: " ").map(String.init)))
        } ?? context.chapter.keyIdeas.first ?? context.chapter.summary

        if context.activeChallenge != nil && (q.contains("stuck") || q.contains("where do i start") || q.contains("start")) {
            let ch = context.activeChallenge!
            return TutorReply(text: "Let's break it into steps.\n\n1. What is the question really asking for?\n2. List every possible outcome. How many are there?\n3. Which of those count as a \"win\" for this question?\n\nStart with step 1 and tell me what you think. \(ch.hints.first.map { "A nudge: \($0)" } ?? "")", sources: ["Challenge hint ladder"] + src.suffix(1))
        }
        if context.activeChallenge != nil && (q.contains("question mean") || q.contains("what does this")) {
            return TutorReply(text: "Let's put the question in your own words. Which part tells you what can happen (all the outcomes)? Which part tells you what you're hoping for (the favorable outcomes)? Try rewriting the question as: \"Out of all the ways it could go, how many ways give me ___?\"", sources: src)
        }
        if context.activeChallenge != nil && q.contains("check my thinking") {
            return TutorReply(text: "Happy to. Type your reasoning in the explanation box and tap Submit. Your guide checks it against the rubric and tells you which ideas you've covered, without giving away the answer. Or tell me your first step here and I'll ask you a question about it.", sources: src)
        }
        if q.contains("different way") || q.contains("explain this") || q.contains("simpler") {
            let core = sentences.first ?? context.chapter.summary
            let help = context.helpLevel
            var t = "Here's another way to see it.\n\n**The big idea:** \(idea)\n\n**Picture it:** imagine a bag of identical marbles. Each marble is one possible outcome. Probability asks: if I reach in without looking, what share of the marbles are the kind I want?\n\n**Back to your page:** \(core)."
            t += help == .socratic ? "\n\nCan you match each part of the marble picture to something on your page?" : "\n\nWhich part of that clicks for you, and which part still feels fuzzy?"
            return TutorReply(text: t, sources: src)
        }
        if q.contains("example") || q.contains("real life") || q.contains("real-life") {
            return TutorReply(text: "Real-life example: a weather app says \"70% chance of rain.\" On 100 days like today, it would rain on about 70. That's the same idea as your page: \(idea)\n\nNow you try: where else do you see chances in everyday life? Games, sports, traffic lights?", sources: src)
        }
        if q.contains("why does this work") || q.hasPrefix("why") {
            return TutorReply(text: "Good instinct to ask why. \(sentences.dropFirst().first ?? sentences.first ?? idea).\n\nThe reason it works: when every outcome is equally likely, each one gets an equal share of the total chance, which is 1. So the chance of your event is just the number of shares it owns.\n\nCan you explain that back in one sentence?", sources: src)
        }
        if q.contains("quiz") || q.contains("test me") {
            if let c = section?.checkpoint {
                return TutorReply(text: "Quick quiz from this page:\n\n**\(c.question)**\n" + c.options.enumerated().map { "\(["A","B","C","D","E"][min($0.offset, 4)]). \($0.element)" }.joined(separator: "\n") + "\n\nReply with a letter and your reason.", sources: src)
            }
            return TutorReply(text: "Quick quiz: in your own words, explain this key idea and give one example.\n\n**\(idea)**", sources: src)
        }
        if let letter = ["a", "b", "c", "d"].firstIndex(of: q.trimmingCharacters(in: .whitespaces).prefix(1).lowercased()), q.count < 80,
           let c = section?.checkpoint, (q.count == 1 || q.dropFirst().first == " " || q.dropFirst().first == "." || q.dropFirst().first == ","), letter < c.options.count {
            return TutorReply(text: letter == c.correctIndex ? "Yes! \(c.explanation)" : "Not quite. Look again at what the page says about \"\(section?.heading ?? "this")\". What makes the other options different?", sources: src)
        }
        return nil
    }

    private static let stop: Set<String> = ["what", "why", "how", "the", "and", "does", "that", "this", "with", "for", "are", "you", "can", "mean", "means", "explain", "about", "tell", "when", "which", "there", "have", "from", "into", "not"]

    private static func clean(_ s: String) -> String {
        let plain = s.replacingOccurrences(of: "**", with: "")
        return plain.count > 420 ? String(plain.prefix(420)) + "…" : plain
    }

    private static func restate(_ excerpt: String) -> String {
        let first = excerpt.split(separator: ".").first.map(String.init) ?? excerpt
        return "the key move is this: \(first.prefix(1).lowercased() + first.dropFirst()). Try saying it back in your own words."
    }

    private static func probe(for terms: Set<String>, chapter: Chapter) -> String {
        let probes = [
            "Can you explain why that works, in your own words?",
            "What would change if there were more possible outcomes?",
            "Can you think of an example from your own life where this shows up?",
            "How would you check whether your idea is right?"
        ]
        return probes[abs(terms.sorted().joined().hashValue) % probes.count]
    }

    // MARK: Challenges

    func evaluate(challenge: Challenge, answer: String, reasoning: String, attempt: Int, context: TutorContext) async throws -> Evaluation {
        try await Task.sleep(nanoseconds: 500_000_000)
        let correct = AnswerChecker.isCorrect(answer, for: challenge)
        let coverage = AnswerChecker.rubricCoverage(reasoning + " " + answer, rubric: challenge.rubric)
        let score = AnswerChecker.reasoningScore(reasoning + " " + answer, rubric: challenge.rubric)
        let mis = correct ? nil : AnswerChecker.misconception(for: answer, in: challenge)

        var feedback: String
        var probe: String?
        if correct && score >= 0.6 {
            feedback = "Exactly right, and your reasoning holds together. You explained \(coverage.met.first.map { $0.idea.lowercased() } ?? "your steps") clearly."
            probe = "Quick stretch: how would the answer change if one part of the problem changed? You don't have to answer to move on."
        } else if correct {
            feedback = "Your answer is correct. Your explanation is missing something though: \(coverage.missing.first?.idea ?? "say why each step works"). Strong reasoning is what makes this stick. Can you add that?"
        } else if let mis {
            feedback = Self.misconceptionFeedback(mis)
        } else if score >= 0.5 {
            feedback = "Your thinking is on a good track, but the final number isn't right yet. Check your arithmetic, or recount the outcomes."
        } else {
            feedback = "Not quite yet. Try writing out every possible outcome before you calculate."
        }
        return Evaluation(correct: correct, reasoningScore: score, feedback: feedback,
                          rubricMet: coverage.met.map(\.idea), rubricMissing: coverage.missing.map(\.idea),
                          misconception: mis, probe: probe,
                          source: "Answer checked exactly on device. Reasoning compared with the educator-visible rubric.")
    }

    static func misconceptionFeedback(_ tag: String) -> String {
        let known: [String: String] = [
            "equally-likely-fallacy": "It's tempting to think every outcome has the same chance. Do these outcomes really happen in the same number of ways?",
            "added-instead-of-multiplied": "You added the probabilities. When both events must happen, does adding make sense? Picture how the possibilities branch.",
            "multiplied-instead-of-added": "You multiplied, but this asks for either one OR the other. Does \"or\" make the chance bigger or smaller?",
            "forgot-without-replacement": "Remember that the first card isn't put back. How many cards are left for the second draw?",
            "gamblers-fallacy": "Past flips don't change the coin. Does a coin remember what happened before?",
            "counted-outcomes-wrong": "Check your count of possible outcomes. Try listing them all in a grid.",
            "inverted-fraction": "Your fraction looks upside down. Which goes on top: the outcomes you want, or all outcomes?",
            "forgot-complement": "Is it easier to find the chance it does NOT happen and subtract from 1?",
            "added-denominators": "When adding fractions, can you add the bottoms? Think about what the bottom number means."
        ]
        return known[tag] ?? "There's a common mix-up here (\(tag.replacingOccurrences(of: "-", with: " "))). Look at your steps again. Which one are you least sure about?"
    }

    func hint(challenge: Challenge, level: Int, answer: String, reasoning: String, context: TutorContext) async throws -> String {
        try await Task.sleep(nanoseconds: 250_000_000)
        let idx = min(max(level, 0), max(challenge.hints.count - 1, 0))
        var h = challenge.hints.isEmpty ? "List all possible outcomes first." : challenge.hints[idx]
        if let mis = AnswerChecker.misconception(for: answer, in: challenge), level > 0 {
            h = Self.misconceptionFeedback(mis) + "\n\n" + h
        }
        return h
    }

    func remediate(chapter: Chapter, topic: String, level: SkillLevel, struggledWith: Challenge, attempts: [ChallengeAttempt], round: Int) async throws -> Remediation {
        try await Task.sleep(nanoseconds: 900_000_000)
        return OfflineLibrary.remediation(for: chapter, topic: topic, struggledWith: struggledWith, round: round)
    }

    func triageConcern(_ text: String) async throws -> ConcernTriage {
        try await Task.sleep(nanoseconds: 300_000_000)
        if PrivacyFilter.needsUrgentHumanSupport(text) {
            return ConcernTriage(category: "Urgent wellbeing", reply: PrivacyFilter.urgentSupportMessage, urgent: true)
        }
        let t = text.lowercased()
        let categories: [(String, [String], String)] = [
            ("Stress & workload", ["stress", "overwhelm", "too much", "workload", "deadline", "tired", "anxious", "anxiety", "pressure"],
             "That sounds like a lot to carry. It can help to break work into one small next step, and to tell your teacher early, before deadlines. Would a short study plan help?"),
            ("Understanding the material", ["confus", "don't understand", "dont understand", "lost", "hard", "difficult", "behind", "stuck"],
             "Feeling stuck is a normal part of learning, not a sign you can't do it. Your book can re-explain any section in a new way. Asking in class helps too, because others likely have the same question."),
            ("Belonging & confidence", ["alone", "left out", "stupid", "dumb", "not smart", "don't belong", "embarrass", "afraid to ask", "shy"],
             "Thank you for sharing that. Many learners feel this way, and it doesn't reflect your ability. Asking questions is a strength. Would it help to practice a question here first?"),
            ("Access & technology", ["internet", "wifi", "device", "laptop", "computer", "access", "can't see", "hearing", "reading"],
             "Access matters. This app works offline, and Settings has text-size, read-aloud and contrast options. Your educator can also arrange other supports."),
            ("Teaching & pace", ["too fast", "too slow", "pace", "lecture", "teacher explains", "boring"],
             "That's useful feedback. Sharing it anonymously helps your educator adjust the pace for everyone.")
        ]
        for (cat, keys, reply) in categories where keys.contains(where: { t.contains($0) }) {
            return ConcernTriage(category: cat, reply: reply, urgent: false)
        }
        return ConcernTriage(category: "General", reply: "Thanks for sharing. You decide who sees this. If you'd like your educator to know, you can share it anonymously or with your name.", urgent: false)
    }

    func summarizeInsights(_ input: InsightSummaryInput) async throws -> String {
        try await Task.sleep(nanoseconds: 400_000_000)
        var lines: [String] = []
        if let hardest = input.chapterStats.min(by: { $0.masteryRate < $1.masteryRate }) {
            lines.append("**Where learners struggle most:** \"\(hardest.title)\" has the lowest mastery rate, at \(Int(hardest.masteryRate * 100))%, with \(String(format: "%.1f", hardest.avgHints)) hints per challenge on average.")
        }
        if let top = input.topMisconceptions.first {
            lines.append("**Most common misconception:** \(top.tag.replacingOccurrences(of: "-", with: " ")). It may help to model a counter-example in class, then have pairs explain it to each other.")
        }
        if let theme = input.concernThemes.first {
            lines.append("**Wellbeing signal:** the most frequent anonymous theme is \"\(theme.theme)\". Consider a brief check-in or adjusting the pace.")
        }
        lines.append("**Suggested next step:** start the next session with a 5-minute discussion of the hardest challenge before introducing new material.")
        return lines.joined(separator: "\n\n")
    }

    // MARK: Classroom

    func draftEssayFeedback(essay: String, prompt: String, rubric: [RubricCriterion], gradeBand: String, minWords: Int) async throws -> EssayFeedback {
        EssayCoach.draft(essay: essay, rubric: rubric, minWords: minWords)
    }

    func draftAssignment(_ request: AssignmentRequest) async throws -> AssignmentDraft {
        AssignmentStudio.draft(request)
    }

    /// The on-device engine uses deterministic paragraph-aware chunking, so it returns an empty plan.
    func planLessonStructure(_ sentences: [String], chunkSize: Int) async throws -> LessonAdapter.StructurePlan {
        LessonAdapter.StructurePlan()
    }
}
