import Foundation

enum EssayGenre: String, Codable, CaseIterable, Identifiable {
    case argumentative, literary, informative, narrative
    var id: String { rawValue }
    var title: String {
        switch self {
        case .argumentative: return "Argument"
        case .literary: return "Literary analysis"
        case .informative: return "Explanatory"
        case .narrative: return "Narrative"
        }
    }
}

struct AssignmentRequest: Hashable {
    var kind: AssignmentKind
    var topic: String
    var gradeBand: String
    var genre: EssayGenre = .argumentative
    var level: SkillLevel = .beginner
    var minWords: Int = 300
    var notes: String = ""
}

struct AssignmentDraft {
    var title: String
    var instructions: String
    var prompt: String = ""
    var rubric: [RubricCriterion] = []
    var sections: [LessonSection] = []
    var keyTerms: [String] = []
    var standards: [String] = []
    var minWords: Int = 300
    var generatedBy: String
}

/// Offline assignment drafting: research-based templates the teacher then edits.
enum AssignmentStudio {

    static func draft(_ r: AssignmentRequest) -> AssignmentDraft {
        switch r.kind {
        case .essay: return essay(r)
        case .reading: return reading(r)
        case .quest:
            return AssignmentDraft(title: r.topic, instructions: "Explore all three chapters of the \(r.topic) world. Read each chapter, try the checkpoints and explain your reasoning in every challenge. You'll unlock the next location once you've shown you understand.",
                                   standards: [], generatedBy: "On-device course engine")
        }
    }

    static func essay(_ r: AssignmentRequest) -> AssignmentDraft {
        let topic = r.topic.trimmingCharacters(in: .whitespacesAndNewlines)
        let isQuestion = topic.hasSuffix("?")
        let prompt: String
        let title: String
        switch r.genre {
        case .argumentative:
            title = isQuestion ? topic : "Argument: \(topic)"
            prompt = isQuestion
                ? "\(topic) Take a clear position and support it with at least two pieces of evidence and your own reasoning. Address at least one counterargument and explain why your position still holds."
                : "Take a position on \(topic.lowercased()). State your claim clearly in your introduction, support it with at least two pieces of evidence and your own reasoning, and address at least one counterargument."
        case .literary:
            title = "Analysis: \(topic)"
            prompt = "Analyze \(topic). Make a claim about how the author creates meaning, and support it with at least two quotations from the text. Explain how each quotation supports your claim."
        case .informative:
            title = "Explain: \(topic)"
            prompt = "Explain \(topic.lowercased()) to a reader who knows nothing about it. Define key terms, organize your explanation logically, and use at least two facts or examples from reliable sources."
        case .narrative:
            title = "Story: \(topic)"
            prompt = "Write a narrative about \(topic.lowercased()). Use vivid details, dialogue and a clear sequence of events, and end with a reflection on what the experience meant."
        }
        return AssignmentDraft(
            title: title,
            instructions: "Write \(r.minWords)–\(r.minWords + 200) words. Plan first, draft, then read your work aloud before submitting. The rubric below shows exactly what your teacher is looking for. AI will not write this for you, and your teacher reviews all feedback personally.",
            prompt: prompt,
            rubric: rubric(for: r.genre),
            standards: standards(for: r.genre, grade: r.gradeBand),
            minWords: r.minWords,
            generatedBy: "On-device assignment templates")
    }

    static func rubric(for g: EssayGenre) -> [RubricCriterion] {
        switch g {
        case .argumentative:
            return [
                .init(name: "Claim", detail: "States a clear, arguable position early.", levels: ["Position is missing or unclear.", "Position is stated but vague or appears late.", "Clear position stated in the introduction.", "Precise, arguable claim that previews the reasons."]),
                .init(name: "Evidence", detail: "Supports the claim with relevant, specific evidence.", levels: ["Little or no evidence.", "Mostly personal opinion or vague references.", "Relevant evidence with some specific sources or data.", "Specific, well-chosen evidence from credible, named sources."]),
                .init(name: "Reasoning & counterargument", detail: "Explains how evidence supports the claim and answers the other side.", levels: ["Evidence is not explained.", "Some explanation; the other side is ignored.", "Explains evidence; acknowledges a counterargument.", "Insightful reasoning; counterargument is raised and convincingly answered."]),
                .init(name: "Organization", detail: "Logical paragraphs, transitions and a conclusion.", levels: ["Hard to follow.", "Some structure; paragraphs blend ideas.", "Clear paragraphs and transitions; has a conclusion.", "Purposeful structure that builds to a strong conclusion."]),
                .init(name: "Conventions", detail: "Spelling, punctuation, sentence clarity.", levels: ["Errors make it hard to read.", "Frequent errors that distract.", "Few errors; sentences are clear.", "Polished, varied and precise sentences."])
            ]
        case .literary:
            return [
                .init(name: "Claim", detail: "Interpretive claim about the text.", levels: ["Summary only.", "Claim is general.", "Clear interpretive claim.", "Insightful, specific claim."]),
                .init(name: "Evidence", detail: "Quotations that fit the claim.", levels: ["No quotations.", "Quotations loosely related.", "Relevant quotations, integrated.", "Well-chosen, smoothly integrated quotations."]),
                .init(name: "Analysis", detail: "Explains how language creates meaning.", levels: ["No analysis.", "Restates the quotation.", "Explains meaning of evidence.", "Analyzes word choice and effect in depth."]),
                .init(name: "Organization", detail: "Logical flow.", levels: ["Hard to follow.", "Some structure.", "Clear structure.", "Purposeful, cohesive structure."]),
                .init(name: "Conventions", detail: "Spelling, punctuation, clarity.", levels: ["Errors impede meaning.", "Distracting errors.", "Few errors.", "Polished."])
            ]
        case .informative:
            return [
                .init(name: "Main idea", detail: "Focus and purpose.", levels: ["Unfocused.", "Topic is named.", "Clear focus.", "Sharp focus that frames the whole piece."]),
                .init(name: "Evidence", detail: "Facts, definitions, examples.", levels: ["Few facts.", "Some facts, loosely sourced.", "Relevant facts and examples.", "Precise facts from credible, named sources."]),
                .init(name: "Explanation", detail: "Makes ideas clear to a reader.", levels: ["Confusing.", "Partly clear.", "Clear explanations of key terms.", "Illuminating explanations and connections."]),
                .init(name: "Organization", detail: "Logical sequence.", levels: ["Hard to follow.", "Some order.", "Logical order with transitions.", "Seamless progression."]),
                .init(name: "Conventions", detail: "Spelling, punctuation, clarity.", levels: ["Errors impede meaning.", "Distracting errors.", "Few errors.", "Polished."])
            ]
        case .narrative:
            return [
                .init(name: "Narrative idea", detail: "Engaging situation and point of view.", levels: ["Unclear situation.", "Basic situation.", "Engaging situation.", "Compelling, original situation."]),
                .init(name: "Detail & description", detail: "Vivid details and dialogue.", levels: ["Few details.", "Some details.", "Vivid details and dialogue.", "Rich, purposeful detail."]),
                .init(name: "Reflection", detail: "What the experience meant.", levels: ["None.", "Brief.", "Clear reflection.", "Insightful reflection."]),
                .init(name: "Organization", detail: "Clear sequence of events.", levels: ["Hard to follow.", "Some order.", "Clear sequence.", "Masterful pacing."]),
                .init(name: "Conventions", detail: "Spelling, punctuation, clarity.", levels: ["Errors impede meaning.", "Distracting errors.", "Few errors.", "Polished."])
            ]
        }
    }

    static func standards(for g: EssayGenre, grade: String) -> [String] {
        let band = grade.contains("11") || grade.contains("12") ? "11-12" : grade.contains("9") || grade.contains("10") ? "9-10" : grade.contains("6") || grade.contains("7") || grade.contains("8") ? "8" : "9-10"
        switch g {
        case .argumentative: return ["CCSS.ELA-LITERACY.W.\(band).1", "CCSS.ELA-LITERACY.W.\(band).4"]
        case .literary: return ["CCSS.ELA-LITERACY.RL.\(band).1", "CCSS.ELA-LITERACY.W.\(band).9"]
        case .informative: return ["CCSS.ELA-LITERACY.W.\(band).2"]
        case .narrative: return ["CCSS.ELA-LITERACY.W.\(band).3"]
        }
    }

    /// Reading lessons reuse the curated textbook content when available, so the facts are reviewed.
    static func reading(_ r: AssignmentRequest) -> AssignmentDraft {
        let course = OfflineLibrary.course(for: CourseRequest(topic: r.topic, level: r.level, stage: .k12, goals: r.notes))
        let ch = course.chapters.first
        let sections = (ch?.sections ?? []).filter { !$0.isAdaptive }
        let terms = LessonAdapter.Source(sections: sections).keyTerms
        return AssignmentDraft(
            title: ch.map { "\(r.topic): \($0.title)" } ?? r.topic,
            instructions: "Read the lesson in whichever format works best for you: original, chunked, read aloud or visual. Every format has exactly the same content. Answer the checkpoints as you go.",
            sections: sections, keyTerms: terms, standards: ["CCSS.ELA-LITERACY.RI.\(r.gradeBand.contains("9") || r.gradeBand.contains("10") ? "9-10" : "8").4"],
            generatedBy: course.generatedBy)
    }
}
