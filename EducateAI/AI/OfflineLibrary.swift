import Foundation

/// Curated, on-device course content used when no cloud model is connected (or as a fallback).
/// Content was authored for the demo and checked against standard curricula. No learner data is used.
enum OfflineLibrary {
    static let curatedTopics: [String] = ["Introduction to Probability", "Fractions", "The Water Cycle"]

    static let engineName = "Margin on-device engine"
    static let curatedProvenance = "Curated lesson content authored for this demo and reviewed against standard curricula (Common Core, NGSS and introductory college syllabi). No learner data was used to create it."

    enum CuratedTopic { case probability, fractions, waterCycle }

    static func match(_ topic: String) -> CuratedTopic? {
        let t = topic.lowercased()
        if t.contains("prob") || t.contains("chance") || t.contains("odds") || t.contains("likelihood") { return .probability }
        if t.contains("fraction") || t.contains("numerator") || t.contains("denominator") { return .fractions }
        if t.contains("water cycle") || t.contains("water-cycle") || t.contains("hydrolog") || t.contains("evaporation") || t.contains("precipitation") || (t.contains("water") && t.contains("cycle")) { return .waterCycle }
        return nil
    }

    static func course(for request: CourseRequest) -> Course {
        let chapters: [Chapter]
        let title: String
        var provenance = curatedProvenance
        switch match(request.topic) {
        case .probability?:
            chapters = probabilityChapters(level: request.level)
            title = "Introduction to Probability"
        case .fractions?:
            chapters = fractionsChapters(level: request.level)
            title = "Fractions"
        case .waterCycle?:
            chapters = waterCycleChapters(level: request.level)
            title = "The Water Cycle"
        case nil:
            let clean = request.topic.trimmingCharacters(in: .whitespacesAndNewlines)
            title = clean.isEmpty ? "Your Topic" : clean
            chapters = genericChapters(topic: title, level: request.level)
            provenance = "Offline scaffold generated on this iPad from a general learning-science template (no topic-specific facts and no learner data). Connect OCI Generative AI in Settings to generate topic-specific content."
        }
        return Course(topic: title, level: request.level, stage: request.stage, chapters: chapters,
                      reviewStatus: .pendingReview, generatedBy: engineName, provenance: provenance,
                      goals: request.goals.isEmpty ? nil : request.goals)
    }

    static func remediation(for chapter: Chapter, topic: String, struggledWith challenge: Challenge, round: Int) -> Remediation {
        let variants: [Remediation]
        switch match(topic) {
        case .probability?: variants = probabilityRemediations(chapter: chapter.index, round: round)
        case .fractions?: variants = fractionsRemediations(chapter: chapter.index, round: round)
        case .waterCycle?: variants = waterCycleRemediations(chapter: chapter.index, round: round)
        case nil: variants = [genericRemediation(chapter: chapter, topic: topic, round: round)]
        }
        guard !variants.isEmpty else { return genericRemediation(chapter: chapter, topic: topic, round: round) }
        // Pick by round, skipping any variant whose follow-up repeats the challenge the learner struggled with.
        for offset in 0..<variants.count {
            var r = variants[(round + offset) % variants.count]
            if r.followUp.prompt != challenge.prompt {
                r.section.id = UUID()
                r.followUp.id = UUID()
                return r
            }
        }
        return genericRemediation(chapter: chapter, topic: topic, round: round)
    }

    // MARK: - Builders

    static func sec(_ heading: String, _ body: String, _ illustration: Illustration? = nil, _ check: QuickCheck? = nil, adaptive: Bool = false) -> LessonSection {
        LessonSection(heading: heading, body: body, illustration: illustration, checkpoint: check, isAdaptive: adaptive)
    }

    static func rub(_ idea: String, _ keywords: [String]) -> RubricItem {
        RubricItem(idea: idea, keywords: keywords)
    }

    static func numeric(_ prompt: String, answer: String, hints: [String], solution: String,
                        rubric: [RubricItem], misconceptions: [String: String] = [:], followUp: Bool = false) -> Challenge {
        Challenge(prompt: prompt, answerType: .numeric, options: nil, correctAnswer: answer, tolerance: 0.01,
                  hints: hints, solution: solution, rubric: rubric,
                  misconceptions: misconceptions.isEmpty ? nil : misconceptions, isFollowUp: followUp)
    }

    static func choice(_ prompt: String, options: [String], answer: String, hints: [String], solution: String,
                       rubric: [RubricItem], misconceptions: [String: String] = [:], followUp: Bool = false) -> Challenge {
        Challenge(prompt: prompt, answerType: .multipleChoice, options: options, correctAnswer: answer, tolerance: nil,
                  hints: hints, solution: solution, rubric: rubric,
                  misconceptions: misconceptions.isEmpty ? nil : misconceptions, isFollowUp: followUp)
    }

    static func short(_ prompt: String, answer: String, hints: [String], solution: String,
                      rubric: [RubricItem], misconceptions: [String: String] = [:], followUp: Bool = false) -> Challenge {
        Challenge(prompt: prompt, answerType: .shortText, options: nil, correctAnswer: answer, tolerance: nil,
                  hints: hints, solution: solution, rubric: rubric,
                  misconceptions: misconceptions.isEmpty ? nil : misconceptions, isFollowUp: followUp)
    }

    static func check(_ q: String, _ options: [String], _ correct: Int, _ why: String) -> QuickCheck {
        QuickCheck(question: q, options: options, correctIndex: correct, explanation: why)
    }

    static func gcd(_ a: Int, _ b: Int) -> Int { b == 0 ? abs(a) : gcd(b, a % b) }
    static func frac(_ n: Int, _ d: Int) -> String {
        let g = max(gcd(n, d), 1)
        let nn = n / g, dd = d / g
        return dd == 1 ? "\(nn)" : "\(nn)/\(dd)"
    }

    // MARK: - Generic scaffold

    static func topicKeywords(_ topic: String) -> [String] {
        let stop: Set<String> = ["the", "of", "and", "to", "a", "an", "in", "for", "on", "with", "introduction", "intro", "basics", "into"]
        let words = topic.lowercased().components(separatedBy: CharacterSet.alphanumerics.inverted)
        return words.filter { $0.count > 2 && !stop.contains($0) }
    }

    static func genericChapters(topic: String, level: SkillLevel) -> [Chapter] {
        let kw = topicKeywords(topic)
        let topicKW = kw.isEmpty ? [topic.lowercased()] : kw
        let depth: String
        switch level {
        case .beginner: depth = "Start with everyday examples before any technical vocabulary."
        case .intermediate: depth = "Connect each new term to something you already know, then test it on a slightly harder case."
        case .advanced: depth = "Look for the edge cases where the simple version of an idea stops working."
        }
        let note = "**About this offline scaffold:** this course is running in offline generic mode. It gives you a proven learning structure for \(topic), but it does not contain topic-specific facts. Connect OCI Generative AI in Settings to generate full, topic-specific lessons."

        var chapters: [Chapter] = []

        // Chapter 1
        var s1: [LessonSection] = []
        s1.append(sec("Map what you already know",
            "\(note)\n\nEvery new subject is easier when you anchor it to what you already know. Before reading anything about \(topic), take two minutes and list every word, example or question that comes to mind. Researchers call this **activating prior knowledge**, and it measurably improves how much you remember.\n\n\(depth)",
            Illustration(kind: .conceptCard, caption: "A starting routine for any new topic", labels: ["List what you already know", "Write three questions you want answered", "Find one real-world example", "Predict what will be hardest"]),
            check("Why list what you already know before studying \(topic)?", ["It wastes time", "It gives new ideas something to attach to", "It replaces reading the material"], 1, "New knowledge sticks better when it connects to existing knowledge.")))
        s1.append(sec("Find the key vocabulary",
            "Most subjects have a small core of words that unlock everything else. As you read about \(topic), keep a running list of terms that keep showing up. For each one, write a definition **in your own words** and one example.\n\nIf you cannot explain a term without repeating the definition you read, that is a signal to slow down and look at another example.",
            Illustration(kind: .conceptCard, caption: "The three-column vocabulary method", labels: ["Term", "My own definition", "An example I made up"])))
        s1.append(sec("Ask good questions",
            "Strong learners ask **why** and **how**, not only **what**. A \"what\" question has a single fact for an answer. A \"why\" question forces you to connect ideas, which is where understanding happens.\n\nTry turning each heading you read about \(topic) into a why-question, and answer it before moving on.",
            nil,
            check("Which question builds the deepest understanding?", ["What is the definition?", "Why does this idea work the way it does?", "How many pages is the chapter?"], 1, "Why-questions force you to link ideas together.")))
        let c1a = short("In your own words, explain what \(topic) is about and why someone might want to learn it. Give one example.",
            answer: "\(topic) is about ... For example ... It matters because ...",
            hints: ["Start with one sentence that a younger student could understand.", "Add a concrete example from daily life, school or work.", "Finish with a 'because' sentence explaining why it matters."],
            solution: "A strong answer names the main idea of \(topic) in plain words, gives a specific example, and explains why it is useful.",
            rubric: [rub("You described the topic in your own words", topicKW + ["about", "means", "is when", "study of"]),
                     rub("You gave a concrete example", ["example", "for instance", "such as", "like when", "e.g"]),
                     rub("You explained why it matters", ["because", "useful", "helps", "important", "matters", "so that"])])
        let c1b = choice("Which study strategy is most effective for long-term memory?",
            options: ["Re-reading notes many times", "Testing yourself without looking", "Highlighting everything"],
            answer: "Testing yourself without looking",
            hints: ["Think about which strategy makes your brain do the most work.", "Which one forces you to recall instead of recognize?", "Re-reading feels productive but is mostly recognition."],
            solution: "Retrieval practice (testing yourself) strengthens memory far more than re-reading or highlighting, because recalling information rebuilds the memory each time.",
            rubric: [rub("You mentioned recalling or retrieving information", ["recall", "retriev", "remember", "memory", "test"]),
                     rub("You compared it with passive strategies", ["re-read", "reread", "highlight", "passive", "recogni"])],
            misconceptions: ["Re-reading notes many times": "fluency-illusion", "Highlighting everything": "passive-study"])
        let c1c = short("Write two 'why' questions about \(topic) that you want this course to answer.",
            answer: "Why does ...? Why is ...?",
            hints: ["Start each question with the word 'why'.", "Pick something that surprised or confused you.", "Make sure the answer would need an explanation, not a single fact."],
            solution: "Good questions start with why or how and point to a cause, mechanism or reason within \(topic).",
            rubric: [rub("You wrote why or how questions", ["why", "how"]),
                     rub("Your questions are about the topic", topicKW)])
        chapters.append(Chapter(index: 0, title: "Foundations of \(topic)", summary: "Activate what you know, build vocabulary and learn to ask powerful questions.",
            locationName: "Lantern Library", theme: .library,
            npc: NPC(name: "Archivist Ada", role: "Keeper of Questions", greeting: "Welcome! Before we learn anything new, tell me what you already know.", emoji: "📚"),
            sections: s1, keyIdeas: ["Connect new ideas to what you already know", "Define terms in your own words", "Why-questions build deeper understanding", "Examples make abstract ideas concrete"],
            challenges: [c1a, c1b, c1c],
            discussionPrompts: ["What do you already know about \(topic), and where did you learn it?", "Which word about \(topic) is still confusing?", "Who in your life uses \(topic) and how?"]))

        // Chapter 2
        var s2: [LessonSection] = []
        s2.append(sec("Big ideas, not just facts",
            "Experts organize knowledge around a few **big ideas**. Beginners store a pile of separate facts. As you study \(topic), keep asking: which idea explains the most other things?\n\nDraw a simple map with the big idea in the middle and connected details around it. Seeing the structure makes it easier to remember and apply.",
            Illustration(kind: .conceptCard, caption: "Build a concept map", labels: ["Big idea in the center", "Supporting ideas around it", "Arrows that say how they connect", "An example on each branch"])))
        s2.append(sec("Explain it to someone else",
            "The **protégé effect** says we learn more when we prepare to teach. Explaining \(topic) to a friend, family member or even an imaginary student reveals gaps you did not know you had.\n\nWhen you get stuck mid-explanation, mark that spot. That is exactly what to study next.",
            nil,
            check("You get stuck while explaining an idea out loud. What does that tell you?", ["You should stop studying", "You have found a gap to study next", "Explaining never helps"], 1, "Getting stuck is useful information about what you have not yet understood.")))
        s2.append(sec("Spacing and mixing",
            "Cramming feels efficient but fades fast. Spreading practice over several days (**spacing**) and mixing different kinds of problems (**interleaving**) is harder in the moment and much better for long-term learning.\n\nPlan short sessions on \(topic) across the week instead of one long one.",
            Illustration(kind: .numberLine, caption: "How much you remember a week later (illustrative)", params: ["value": 0.75], labels: ["Spaced practice"])))
        let c2a = short("Pick one big idea in \(topic) and explain how two smaller facts connect to it.",
            answer: "The big idea is ... Fact one connects because ... Fact two connects because ...",
            hints: ["Name the idea that seems to explain the most.", "Choose two details you have learned.", "Use 'because' to show each connection."],
            solution: "A strong answer names one central idea and shows, with a reason, how each of two details depends on or follows from it.",
            rubric: [rub("You named a central idea", topicKW + ["big idea", "main idea", "central", "key"]),
                     rub("You explained connections", ["because", "so", "connect", "leads to", "depends", "causes"])])
        let c2b = choice("A friend wants to learn \(topic) for a test in one week. Which plan is best?",
            options: ["One 5-hour session the night before", "Five 1-hour sessions spread over the week", "Reading the textbook once on day one"],
            answer: "Five 1-hour sessions spread over the week",
            hints: ["Think about forgetting over time.", "Which plan revisits the material most often?", "Spacing beats cramming for remembering."],
            solution: "Spaced sessions let you revisit and retrieve material repeatedly, which beats cramming for retention.",
            rubric: [rub("You mentioned spacing or repetition over time", ["spac", "spread", "repeat", "revisit", "over time", "days"]),
                     rub("You explained why cramming is weaker", ["cram", "forget", "fade", "one session"])],
            misconceptions: ["One 5-hour session the night before": "cramming-illusion"])
        let c2c = short("Explain one idea from \(topic) as if teaching a 10-year-old.",
            answer: "Imagine ... It's like ... because ...",
            hints: ["Use simple words and short sentences.", "Use an analogy: 'it's like...'.", "End with why it matters."],
            solution: "A good explanation uses simple language, an analogy and an example.",
            rubric: [rub("You used an analogy or example", ["like", "imagine", "example", "pretend", "similar"]),
                     rub("You explained the reason", ["because", "so", "that's why", "which means"]),
                     rub("You stayed on topic", topicKW)])
        chapters.append(Chapter(index: 1, title: "Core ideas of \(topic)", summary: "Organize knowledge around big ideas and learn by teaching.",
            locationName: "Tinker Workshop", theme: .workshop,
            npc: NPC(name: "Mechanic Milo", role: "Builder of Ideas", greeting: "Ideas are like gears. Show me how yours connect!", emoji: "🛠️"),
            sections: s2, keyIdeas: ["Organize facts around big ideas", "Teaching reveals gaps", "Space out practice", "Mix problem types"],
            challenges: [c2a, c2b, c2c],
            discussionPrompts: ["Teach someone one idea about \(topic). Where did you get stuck?", "What is the biggest idea in \(topic) so far?", "How will you space your study this week?"]))

        // Chapter 3
        var s3: [LessonSection] = []
        s3.append(sec("Transfer: use it somewhere new",
            "Real understanding shows up when you can use an idea in a situation you have never seen. This is called **transfer**. For \(topic), try applying what you learned to a problem from a different class, a hobby, or your job.\n\nIf the idea does not fit perfectly, explain what is different. That reasoning is a sign of deep understanding.",
            Illustration(kind: .conceptCard, caption: "Transfer checklist", labels: ["Pick a new situation", "Identify what is the same", "Identify what is different", "Adapt the idea"])))
        s3.append(sec("Check your confidence",
            "Good learners are **calibrated**: their confidence matches their actual performance. After each problem about \(topic), rate your confidence from 1 to 5, then check. Over time you will learn when to trust yourself and when to double-check.",
            Illustration(kind: .numberLine, caption: "Rate your confidence before checking", params: ["value": 0.6], labels: ["My confidence"]),
            check("You felt 5/5 confident but got the problem wrong. What should you do?", ["Ignore it", "Look closely at why, since your confidence was miscalibrated", "Stop trying problems"], 1, "Mismatches between confidence and results show exactly where to look.")))
        s3.append(sec("Reflect and plan",
            "End every study session with a short reflection: What did I learn about \(topic)? What is still fuzzy? What will I do next time? Writing this down turns one session into a learning plan you control.",
            nil))
        let c3a = short("Describe a real situation outside this course where you could apply \(topic). What would you do?",
            answer: "In ..., I could use ... by ...",
            hints: ["Think about school, work, home or a hobby.", "Describe the specific problem in that situation.", "Explain step by step how the idea helps."],
            solution: "A strong answer names a specific situation, the idea being applied, and how it helps.",
            rubric: [rub("You described a specific situation", ["when", "at work", "at home", "school", "situation", "example", "if"]),
                     rub("You explained how the idea applies", ["because", "by", "use", "apply", "help"]),
                     rub("You connected it to the topic", topicKW)])
        let c3b = choice("Which reflection is most useful at the end of a study session?",
            options: ["\"I studied.\"", "\"I understand the main idea, but I'm unsure how it applies to new cases, so next time I'll try two new examples.\"", "\"That was boring.\""],
            answer: "\"I understand the main idea, but I'm unsure how it applies to new cases, so next time I'll try two new examples.\"",
            hints: ["Which reflection leads to an action?", "Look for one that names what is still unclear.", "Specific plans beat vague feelings."],
            solution: "Useful reflections name what you know, what is unclear, and a concrete next step.",
            rubric: [rub("You valued specific next steps", ["next", "plan", "specific", "action", "step"]),
                     rub("You valued naming what is unclear", ["unsure", "unclear", "gap", "confus", "don't know"])])
        let c3c = short("What is one thing about \(topic) you still find confusing, and what is your plan to fix it?",
            answer: "I'm still unsure about ... My plan is ...",
            hints: ["Be honest. Every learner has gaps.", "Make the confusing part as specific as possible.", "Name one concrete action and when you'll do it."],
            solution: "A strong reflection names a specific gap and a concrete, time-bound plan.",
            rubric: [rub("You named a specific confusion", ["confus", "unsure", "don't understand", "unclear", "hard", "stuck"]),
                     rub("You made a plan", ["plan", "will", "next", "ask", "practice", "review", "tomorrow"])])
        chapters.append(Chapter(index: 2, title: "Applying \(topic)", summary: "Transfer ideas to new situations and reflect on your learning.",
            locationName: "Starlight Observatory", theme: .observatory,
            npc: NPC(name: "Astronomer Orion", role: "Guide to New Horizons", greeting: "Knowledge is only half the journey. Where else could this idea take you?", emoji: "🔭"),
            sections: s3, keyIdeas: ["Transfer means using ideas in new situations", "Calibrate your confidence", "Reflection turns study into a plan", "Explaining differences shows deep understanding"],
            challenges: [c3a, c3b, c3c],
            discussionPrompts: ["Where could you use \(topic) this month?", "When was your confidence wrong?", "What is your plan for the next week of learning?"]))
        return chapters
    }

    static func genericRemediation(chapter: Chapter, topic: String, round: Int) -> Remediation {
        let kw = topicKeywords(topic)
        let approaches = ["Slow it down", "Real-world story", "Teach-back"]
        let approach = approaches[round % approaches.count]
        let body: String
        switch round % approaches.count {
        case 0:
            body = "Let's slow down. Re-read the key ideas of \"\(chapter.title)\" one at a time. After each one, close your eyes and say it back in your own words. If you can't, re-read just that idea.\n\nThis is not a sign you're behind. Retrieving ideas slowly is how memory gets built."
        case 1:
            body = "Think of a time in your own life that connects to \(topic), even loosely. Write a two-sentence story about it. Then point to the moment in the story where one of this chapter's key ideas shows up.\n\nStories give abstract ideas a place to live in memory."
        default:
            body = "Imagine a classmate missed this lesson. What three things would you tell them first? Write them as short sentences, each with a 'because'.\n\nTeaching forces you to organize what you know, and the gaps become obvious."
        }
        let section = sec("Another way in: \(approach.lowercased())", body,
            Illustration(kind: .conceptCard, caption: "Key ideas to revisit", labels: Array(chapter.keyIdeas.prefix(4))), nil, adaptive: true)
        let follow = short("Using the \(approach.lowercased()) approach, explain one key idea from \"\(chapter.title)\" in your own words with an example.",
            answer: "One key idea is ... For example ... because ...",
            hints: ["Choose the key idea that feels clearest.", "Add an example you made up yourself.", "Connect them with 'because'."],
            solution: "A good answer restates a key idea in your own words, adds an original example, and explains the connection.",
            rubric: [rub("You restated a key idea", kw + ["idea", "means", "is"]),
                     rub("You gave an example", ["example", "for instance", "like", "such as"]),
                     rub("You explained why", ["because", "so", "which means"])],
            followUp: true)
        return Remediation(approach: approach, section: section, followUp: follow)
    }
}
