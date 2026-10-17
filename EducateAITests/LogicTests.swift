import XCTest
@testable import EducateAI

final class LogicTests: XCTestCase {

    func testNumberParsing() {
        XCTAssertEqual(AnswerChecker.parseNumber("1/6")!, 1.0 / 6, accuracy: 1e-9)
        XCTAssertEqual(AnswerChecker.parseNumber("25%")!, 0.25, accuracy: 1e-9)
        XCTAssertEqual(AnswerChecker.parseNumber("1 in 4")!, 0.25, accuracy: 1e-9)
        XCTAssertEqual(AnswerChecker.parseNumber("1 out of 6")!, 1.0 / 6, accuracy: 1e-9)
        XCTAssertEqual(AnswerChecker.parseNumber("0.5")!, 0.5, accuracy: 1e-9)
        XCTAssertEqual(AnswerChecker.parseNumber("one half")!, 0.5, accuracy: 1e-9)
        XCTAssertNil(AnswerChecker.parseNumber("banana"))
    }

    func testEveryCuratedChallengeAcceptsItsOwnAnswer() {
        for topic in OfflineLibrary.curatedTopics {
            for level in SkillLevel.allCases {
                let c = OfflineLibrary.course(for: CourseRequest(topic: topic, level: level, stage: .k12, goals: ""))
                XCTAssertEqual(c.chapters.count, 3, topic)
                for ch in c.chapters {
                    for q in ch.challenges {
                        let ans = q.answerType == .shortText ? q.correctAnswer + " because " + q.rubric.flatMap(\.keywords).prefix(6).joined(separator: " ") : q.correctAnswer
                        XCTAssertTrue(AnswerChecker.isCorrect(ans, for: q), "\(topic) \(level): \(q.prompt) -> \(q.correctAnswer)")
                        XCTAssertFalse(Prompts.leaksAnswer(q.hints.joined(separator: " "), challenge: q) && q.answerType == .multipleChoice, "hint leaks MC answer: \(q.prompt)")
                    }
                }
            }
        }
    }

    func testMisconceptionDetection() {
        let c = OfflineLibrary.course(for: CourseRequest(topic: "probability", level: .beginner, stage: .k12, goals: ""))
        let withMis = c.chapters.flatMap(\.challenges).first { !($0.misconceptions ?? [:]).isEmpty }!
        let (wrong, tag) = withMis.misconceptions!.first!
        XCTAssertEqual(AnswerChecker.misconception(for: wrong, in: withMis), tag)
    }

    func testReasoningScoreRewardsExplanation() {
        let rubric = [RubricItem(idea: "Total outcomes", keywords: ["six", "6", "total"]), RubricItem(idea: "Favorable", keywords: ["one", "1", "favorable"])]
        let weak = AnswerChecker.reasoningScore("guess", rubric: rubric)
        let strong = AnswerChecker.reasoningScore("There are 6 total outcomes and only 1 is favorable, so the chance is 1 out of 6 because each face is equally likely", rubric: rubric)
        XCTAssertLessThan(weak, 0.3)
        XCTAssertGreaterThan(strong, 0.8)
    }

    func testMasteryUnlocksNextChapter() {
        let store = AppStore()
        let course = OfflineLibrary.course(for: CourseRequest(topic: "Introduction to Probability", level: .beginner, stage: .k12, goals: ""))
        store.add(course)
        let ch = course.chapters[0]
        XCTAssertEqual(store.chapterProgress(course, course.chapters[1]).status, .locked)
        store.mutateProgress(course, ch) { p in
            for s in ch.sections { p.sectionsRead.insert(s.id); if s.checkpoint != nil { p.quickChecksCorrect.insert(s.id) } }
            for q in ch.challenges {
                p.attempts.append(ChallengeAttempt(challengeID: q.id, answer: q.correctAnswer, reasoning: "x", correct: true, reasoningScore: 0.9, hintsUsed: 0, misconception: nil))
                p.solvedChallenges.insert(q.id)
            }
        }
        store.recomputeMastery(course, ch)
        XCTAssertGreaterThan(store.chapterProgress(course, ch).mastery, 0.9)
        XCTAssertTrue(store.completeChapterIfMastered(course, ch))
        XCTAssertEqual(store.chapterProgress(course, course.chapters[1]).status, .unlocked)
        store.delete(course)
    }

    func testOneWeakChallengeDoesNotUnlock() {
        let store = AppStore()
        let course = OfflineLibrary.course(for: CourseRequest(topic: "Fractions", level: .beginner, stage: .k12, goals: ""))
        store.add(course)
        let ch = course.chapters[0], q = ch.challenges[0]
        store.mutateProgress(course, ch) { p in
            p.attempts.append(ChallengeAttempt(challengeID: q.id, answer: q.correctAnswer, reasoning: "", correct: true, reasoningScore: 0.1, hintsUsed: 3, misconception: nil))
            p.solvedChallenges.insert(q.id)
        }
        store.recomputeMastery(course, ch)
        XCTAssertFalse(store.completeChapterIfMastered(course, ch))
        store.delete(course)
    }

    func testRemediationProducesNewFollowUp() {
        let course = OfflineLibrary.course(for: CourseRequest(topic: "Introduction to Probability", level: .beginner, stage: .k12, goals: ""))
        let ch = course.chapters[1]
        for round in 0..<4 {
            let r = OfflineLibrary.remediation(for: ch, topic: course.topic, struggledWith: ch.challenges[0], round: round)
            XCTAssertTrue(r.section.isAdaptive)
            XCTAssertTrue(r.followUp.isFollowUp)
            XCTAssertNotEqual(r.followUp.prompt, ch.challenges[0].prompt)
            XCTAssertTrue(AnswerChecker.isCorrect(r.followUp.correctAnswer, for: r.followUp) || r.followUp.answerType == .shortText)
        }
    }

    func testLLMCourseJSONDecodesLeniently() throws {
        let raw = """
        Sure! Here is your course:
        ```json
        {"chapters":[{"title":"Cells","summary":"Life's building blocks","locationName":"Cell City","theme":"garden",
        "npc":{"name":"Mito","role":"Powerhouse","greeting":"Hi!","emoji":"🔋"},
        "sections":[{"heading":"What is a cell","body":"A cell is...","illustration":{"kind":"conceptCard","caption":"Parts","labels":["Nucleus","Membrane"]},
        "checkpoint":{"question":"Smallest unit of life?","options":["Cell","Atom"],"correctIndex":0,"explanation":"Cells."}},
        {"heading":"Weird illus","body":"x","illustration":{"kind":"hologram","labels":["a"]}}],
        "keyIdeas":["Cells are alive"],
        "challenges":[{"prompt":"How many?","answerType":"numeric","correctAnswer":"3/4","hints":["h1"],"solution":"s","rubric":[{"idea":"counts","keywords":["Total"]}]},
        {"prompt":"missing answer"}]}]}
        ```
        """
        let dto = try JSONDecoder().decode(CourseDTO.self, from: raw.extractedJSON!.data(using: .utf8)!)
        let c = dto.toCourse(request: CourseRequest(topic: "Cells", level: .beginner, stage: .k12, goals: ""))
        XCTAssertEqual(c.chapters.count, 1)
        XCTAssertEqual(c.chapters[0].theme, .garden)
        XCTAssertEqual(c.chapters[0].sections[1].illustration?.kind, .conceptCard) // unknown kind falls back
        XCTAssertEqual(c.chapters[0].challenges.count, 1)                       // invalid challenge dropped
        XCTAssertEqual(c.chapters[0].challenges[0].hints.count, 3)              // hints padded
        XCTAssertEqual(c.chapters[0].challenges[0].rubric[0].keywords, ["total"])
    }

    func testHintLeakGuard() {
        let q = Challenge(prompt: "P(heads)?", answerType: .numeric, correctAnswer: "1/2", hints: ["a", "b", "c"], solution: "", rubric: [])
        XCTAssertTrue(Prompts.leaksAnswer("The answer is 1/2", challenge: q))
        XCTAssertTrue(Prompts.leaksAnswer("It's 50% likely", challenge: q))
        XCTAssertFalse(Prompts.leaksAnswer("Count the sides of the coin.", challenge: q))
    }

    func testPrivacyScrub() {
        let r = PrivacyFilter.scrub("My name is Sam Lee, email sam@x.com, call 555-123-4567. Mr. Smith is nice.", extraNames: ["Sam"])
        XCTAssertFalse(r.text.contains("sam@x.com"))
        XCTAssertFalse(r.text.contains("555-123-4567"))
        XCTAssertFalse(r.text.contains("Smith"))
        XCTAssertFalse(r.text.contains("Sam"))
        XCTAssertTrue(PrivacyFilter.needsUrgentHumanSupport("I want to hurt myself"))
        XCTAssertFalse(PrivacyFilter.needsUrgentHumanSupport("This homework is killing me lol"))
    }

    func testInsightsSuppressSmallGroups() {
        var rng = SeededRandom(seed: 7)
        let items = InsightsEngine.privatize(["big": 20, "small": 2], k: 5, epsilon: 1, rng: &rng)
        XCTAssertTrue(items.first { $0.label == "small" }!.suppressed)
        XCTAssertNil(items.first { $0.label == "small" }!.count)
        XCTAssertGreaterThanOrEqual(items.first { $0.label == "big" }!.count!, 5)
    }

    func testOfflineTutorRefusesToGiveAnswer() async throws {
        let course = OfflineLibrary.course(for: CourseRequest(topic: "Introduction to Probability", level: .beginner, stage: .k12, goals: ""))
        let ch = course.chapters[0]
        let ctx = TutorContext(topic: course.topic, level: .beginner, chapter: ch, currentSection: nil, helpLevel: .supportive, activeChallenge: ch.challenges[0], learnerName: nil)
        let r = try await OfflineProvider().tutor(ctx, history: [], question: "just tell me the answer")
        XCTAssertTrue(r.text.contains("won't give you the answer"))
        XCTAssertFalse(Prompts.leaksAnswer(r.text, challenge: ch.challenges[0]))
    }
}
