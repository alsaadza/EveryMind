import XCTest
@testable import EducateAI

/// Tests for teacher-approved essay feedback and the learning-differences formats.
final class ClassroomTests: XCTestCase {

    private let rubric = AssignmentStudio.rubric(for: .argumentative)

    // MARK: Essay feedback

    func testEveryDraftedCommentIsAnchoredToTheEssay() {
        for e in SeedEssays.lateStart + SeedEssays.poemResponses {
            let fb = EssayCoach.draft(essay: e.text, rubric: rubric, minWords: 300)
            XCTAssertFalse(fb.comments.isEmpty, e.studentName)
            for c in fb.comments {
                XCTAssertNotNil(e.text.range(of: c.quote), "\(e.studentName): unanchored quote \(c.quote)")
                XCTAssertEqual(c.state, .pending, "AI comments must start pending")
                XCTAssertEqual(c.origin, .ai)
            }
            XCTAssertEqual(fb.scores.count, rubric.count)
            XCTAssertFalse(fb.readyToRelease, "A fresh AI draft must never be releasable")
        }
    }

    func testFeedbackStaysEncouraging() {
        for e in SeedEssays.lateStart {
            let fb = EssayCoach.draft(essay: e.text, rubric: rubric, minWords: 300)
            XCTAssertGreaterThanOrEqual(fb.comments.filter { $0.kind == .strength }.count, 1, e.studentName)
            for c in fb.comments {
                XCTAssertFalse(EssayCoach.harsh.contains { c.draft.lowercased().contains($0) }, c.draft)
            }
        }
    }

    func testExemplaryScoresHigherThanStruggling() {
        func total(_ name: String) -> Int {
            let e = SeedEssays.lateStart.first { $0.studentName == name }!
            return EssayCoach.draft(essay: e.text, rubric: rubric).scores.reduce(0) { $0 + $1.suggested }
        }
        XCTAssertGreaterThan(total("Maya Okafor"), total("Mateo Alvarez"))
        XCTAssertGreaterThan(total("Maya Okafor"), total("Jonah Reyes"))
    }

    func testAnecdotesAndClockTimesAreNotSpecificEvidence() {
        let jonah = SeedEssays.lateStart.first { $0.studentName == "Jonah Reyes" }!
        let maya = SeedEssays.lateStart.first { $0.studentName == "Maya Okafor" }!
        let evidence = rubric[1].id
        let j = EssayCoach.draft(essay: jonah.text, rubric: rubric).scores.first { $0.criterionID == evidence }!.suggested
        let m = EssayCoach.draft(essay: maya.text, rubric: rubric).scores.first { $0.criterionID == evidence }!.suggested
        XCTAssertLessThanOrEqual(j, 1, "anecdotes and \"studies show\" are not specific evidence")
        XCTAssertEqual(m, 3)
    }

    func testEveryDraftIncludesANextStep() {
        for e in SeedEssays.lateStart + SeedEssays.poemResponses {
            let fb = EssayCoach.draft(essay: e.text, rubric: rubric)
            XCTAssertTrue(fb.comments.contains { $0.kind == .suggestion || $0.kind == .question }, e.studentName)
        }
    }

    func testCrowdedParagraphIsFlagged() {
        let kenji = SeedEssays.lateStart.first { $0.studentName == "Kenji Watanabe" }!
        let fb = EssayCoach.draft(essay: kenji.text, rubric: rubric)
        XCTAssertTrue(fb.comments.contains { $0.draft.contains("covers a lot of ground") })
    }

    func testOpposingPositionIsNotPenalised() {
        // Omar argues to keep 7:45. The claim must still be recognised as a clear position.
        let e = SeedEssays.lateStart.first { $0.profileHint.lowercased().contains("opposing") }!
        let claim = EssayCoach.draft(essay: e.text, rubric: rubric).scores.first { $0.criterionID == rubric[0].id }!
        XCTAssertGreaterThanOrEqual(claim.suggested, 2)
    }

    func testVagueOpeningIsQuestionedNotPraised() {
        let essay = "School start times are an important topic that should be talked about more.\n\nI am tired every morning. Our school should start at 9 because students would learn better."
        let fb = EssayCoach.draft(essay: essay, rubric: rubric)
        let first = fb.comments.first { $0.quote.hasPrefix("School start times") }
        XCTAssertEqual(first?.kind, .question)
    }

    func testSpellcheckFindsRealMisspellings() {
        let m = EssayCoach.misspellings("I was tird becuase we got up alot earlier.").map { $0.word.lowercased() }
        XCTAssertTrue(m.contains("becuase"))
        XCTAssertTrue(m.contains("alot"))
    }

    func testGuardDropsHallucinatedQuotesAndHarshTone() {
        let essay = "Our school should start later. Teens need more sleep to learn well."
        let comments = [
            FeedbackComment(quote: "Teens need more sleep", kind: .strength, draft: "Clear reason."),
            FeedbackComment(quote: "This sentence is not in the essay at all", kind: .suggestion, draft: "Fix this."),
            FeedbackComment(quote: "Our school should start later", kind: .suggestion, draft: "This is lazy writing."),
            FeedbackComment(quote: "teens need MORE sleep to learn", kind: .question, draft: "Which study?")
        ]
        let g = EssayCoach.guardComments(comments, essay: essay)
        XCTAssertEqual(g.kept.count, 2)
        XCTAssertTrue(g.kept.allSatisfy { essay.contains($0.quote) })
        XCTAssertTrue(g.notes.contains { $0.contains("quote did not appear") })
        XCTAssertTrue(g.notes.contains { $0.contains("tone check") })
    }

    func testReleaseRequiresEveryDecision() {
        var fb = EssayCoach.draft(essay: SeedEssays.lateStart[0].text, rubric: rubric)
        XCTAssertFalse(fb.readyToRelease)
        for i in fb.comments.indices { fb.comments[i].state = .approved }
        XCTAssertFalse(fb.readyToRelease, "scores not confirmed yet")
        for i in fb.scores.indices { fb.scores[i].confirmed = fb.scores[i].suggested }
        XCTAssertFalse(fb.readyToRelease, "summary not approved yet")
        fb.summaryApproved = true
        XCTAssertTrue(fb.readyToRelease)
        fb.comments[0].state = .rejected
        XCTAssertTrue(fb.readyToRelease, "rejected counts as a decision")
        XCTAssertFalse(fb.approved.contains { $0.id == fb.comments[0].id }, "rejected comments are never shown")
    }

    // MARK: Learning differences

    private var lessons: [[LessonSection]] {
        OfflineLibrary.curatedTopics.flatMap { t in
            OfflineLibrary.course(for: CourseRequest(topic: t, level: .beginner, stage: .k12, goals: "")).chapters.map(\.sections)
        }
    }

    func testChunkedFormatPreservesEverySentence() {
        for secs in lessons {
            let src = LessonAdapter.Source(sections: secs)
            for size in 1...4 {
                let r = LessonAdapter.fidelity(src, adaptedSentenceIDs: LessonAdapter.chunkOrder(LessonAdapter.chunks(src, size: size)))
                XCTAssertTrue(r.passed, r.summary)
            }
        }
    }

    func testVisualFormatPreservesEverySentence() {
        for secs in lessons {
            let src = LessonAdapter.Source(sections: secs)
            let r = LessonAdapter.fidelity(src, adaptedSentenceIDs: LessonAdapter.visualOrder(LessonAdapter.visual(src)))
            XCTAssertTrue(r.passed, r.summary)
        }
    }

    func testFidelityCatchesDroppedAndDuplicatedSentences() {
        let src = LessonAdapter.Source(sections: lessons[0])
        var ids = src.sentences.map(\.id)
        ids.removeLast()
        XCTAssertFalse(LessonAdapter.fidelity(src, adaptedSentenceIDs: ids).passed)
        XCTAssertFalse(LessonAdapter.fidelity(src, adaptedSentenceIDs: src.sentences.map(\.id) + [0]).passed)
    }

    func testInvalidAIPlanIsRejected() {
        let src = LessonAdapter.Source(sections: lessons[0])
        let n = src.sentences.count
        XCTAssertTrue(LessonAdapter.validPartition([Array(0..<n)], src))
        XCTAssertFalse(LessonAdapter.validPartition([Array(0..<(n - 1))], src), "missing a sentence")
        XCTAssertFalse(LessonAdapter.validPartition([Array(0..<n), [0]], src), "duplicate sentence")
        // A bad plan silently falls back to deterministic chunking.
        let chunks = LessonAdapter.chunks(src, size: 2, plan: .init(chunks: [[0]], labels: nil, steps: nil))
        XCTAssertEqual(LessonAdapter.chunkOrder(chunks).sorted(), Array(0..<n))
    }

    func testPresetsMatchProfiles() {
        XCTAssertEqual(ReadingPrefs.preset(.dyslexia).font, .lexend)
        XCTAssertGreaterThan(ReadingPrefs.preset(.dyslexia).letterSpacing, 0)
        XCTAssertEqual(ReadingProfile.focus.defaultFormat, .chunked)
        XCTAssertEqual(ReadingProfile.listen.defaultFormat, .listen)
    }

    // MARK: Accommodations

    func testAccommodationsApplyAutomatically() {
        let store = ClassroomStore()
        store.resetDemo()
        let a = store.assignments.first { $0.kind == .essay }!
        let extended = store.students.first { $0.accommodations.contains(.extendedTime) }!
        let standard = store.students.first { $0.accommodations.isEmpty }!
        XCTAssertGreaterThan(store.dueDate(a, for: extended), a.dueDate)
        XCTAssertEqual(store.dueDate(a, for: standard), a.dueDate)
        let reduced = store.students.first { $0.accommodations.contains(.reducedLength) }!
        XCTAssertLessThan(store.minWords(a, for: reduced), a.minWords)
    }

    func testSeededQueueAndReleaseFlow() {
        let store = ClassroomStore()
        store.resetDemo()
        XCTAssertGreaterThan(store.reviewQueue.count, 3)
        let sub = store.reviewQueue[0]
        XCTAssertFalse(store.release(sub.id), "cannot release an unreviewed draft")
        let f = sub.feedback!
        for c in f.comments { store.setComment(sub.id, c.id, state: .approved) }
        for s in f.scores { store.confirmScore(sub.id, criterion: s.criterionID, level: s.suggested) }
        store.setSummary(sub.id, glow: f.glow, grow: f.grow, approved: true)
        XCTAssertTrue(store.release(sub.id))
        XCTAssertEqual(store.submission(sub.id)?.status, .returned)
        XCTAssertFalse(store.reviewQueue.contains { $0.id == sub.id })
    }
}
