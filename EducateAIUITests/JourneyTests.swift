import XCTest

/// End-to-end journeys for Margin: teacher feedback review, AI assignments reaching students,
/// accessible reading formats, essay submission, and the five-step quest. Saves screenshots.
final class JourneyTests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-resetState", "-uiTesting"]
    }

    func shot(_ name: String) {
        let a = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        a.name = name; a.lifetime = .keepAlways; add(a)
        if let dir = ProcessInfo.processInfo.environment["SHOT_DIR"] {
            try? XCUIScreen.main.screenshot().pngRepresentation.write(to: URL(fileURLWithPath: dir).appendingPathComponent("\(name).png"))
        }
    }

    func button(_ id: String) -> XCUIElement { app.buttons[id].firstMatch }
    func tapWhenReady(_ e: XCUIElement, timeout: Double = 6, file: StaticString = #file, line: UInt = #line) {
        XCTAssertTrue(e.waitForExistence(timeout: timeout), "missing \(e)", file: file, line: line)
        e.tap()
    }

    func signInAsTeacher() {
        tapWhenReady(button("role-Teacher"))
        for d in ["2", "4", "6", "8"] { tapWhenReady(button("pin-\(d)")) }
        XCTAssertTrue(button("nav-today").waitForExistence(timeout: 6))
    }

    func switchToStudent(_ first: String) {
        tapWhenReady(button("teacher-account"))
        tapWhenReady(app.buttons["Switch to student sign-in"])
        tapWhenReady(button("student-\(first)"))
    }

    // MARK: 1. Teacher reviews AI-drafted feedback; the student only sees what was approved.

    func testTeacherApprovesFeedbackBeforeStudentSeesIt() throws {
        app.launch()
        XCTAssertTrue(app.staticTexts["Margin"].waitForExistence(timeout: 6))
        shot("t01-welcome")
        signInAsTeacher()
        sleep(1); shot("t02-today")

        tapWhenReady(button("nav-feedback"))
        sleep(1); shot("t03-queue")
        tapWhenReady(button("start-reviewing"))
        XCTAssertTrue(button("release").waitForExistence(timeout: 6))
        XCTAssertFalse(button("release").isEnabled, "release must be locked until everything is reviewed")
        sleep(1); shot("t04-review")

        // Edit one comment, reject one, approve the rest.
        tapWhenReady(app.buttons["Edit"].firstMatch)
        let editor = app.textViews["comment-editor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 4))
        editor.tap(); editor.typeText(" Nice work.")
        shot("t05-edit")
        tapWhenReady(button("save-comment"))
        sleep(1)
        tapWhenReady(button("reject-comment"))
        var guardCount = 0
        while button("approve-comment").exists && guardCount < 20 {
            button("approve-comment").tap(); guardCount += 1; usleep(300_000)
        }
        shot("t06-comments-decided")

        // Confirm rubric scores.
        tapWhenReady(app.buttons["Rubric"])
        sleep(1)
        let scoreButtons = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'score-' AND identifier ENDSWITH '-2'"))
        for i in 0..<scoreButtons.count { scoreButtons.element(boundBy: i).tap() }
        shot("t07-rubric")

        // Approve the summary.
        tapWhenReady(app.buttons["Summary"])
        let toggle = app.switches["approve-summary"].firstMatch
        XCTAssertTrue(toggle.waitForExistence(timeout: 4))
        toggle.tap()
        sleep(1); shot("t08-summary")

        XCTAssertTrue(button("release").isEnabled)
        button("release").tap()
        XCTAssertTrue(button("confirm-release").waitForExistence(timeout: 4))
        sleep(1); shot("t09-student-preview")
        button("confirm-release").tap()
        sleep(2); shot("t10-next-in-queue")
    }

    // MARK: 2. AI drafts an assignment, the teacher sends it, a student receives it in their format.

    func testAssignmentBuilderToStudentInbox() throws {
        app.launch()
        signInAsTeacher()
        tapWhenReady(button("today-new-assignment"))
        tapWhenReady(button("kind-reading"))
        let topic = app.textFields["builder-topic"]
        tapWhenReady(topic); topic.typeText("The Water Cycle")
        tapWhenReady(button("draft-with-ai"))
        XCTAssertTrue(app.textFields["draft-title"].waitForExistence(timeout: 15))
        sleep(1); shot("a01-builder-draft")
        app.swipeUp(); sleep(1)
        shot("a02-same-content-check")
        tapWhenReady(button("preview-dyslexia"))
        sleep(2); shot("a03-preview-dyslexia")
        tapWhenReady(app.buttons["Done"])
        app.swipeUp(); sleep(1)
        shot("a04-send-panel")
        tapWhenReady(button("send-assignment"))
        sleep(2); shot("a05-assignment-detail")

        // Supports: set a student's profile.
        tapWhenReady(button("nav-supports"))
        sleep(1); shot("a06-supports")
        tapWhenReady(button("support-Lucas"))
        sleep(1); shot("a07-student-supports")

        switchToStudent("Lucas")
        sleep(1); shot("a08-student-home")
        let card = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'todo-The Water Cycle'")).firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 5), "the new assignment reached the student")
        card.tap()
        XCTAssertTrue(button("listen-play").waitForExistence(timeout: 6), "listen profile opens read-aloud")
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS '· 0% read'")).firstMatch.exists, "opening a reading must not count as reading it")
        sleep(1); shot("a09-listen")
        tapWhenReady(button("format-chunked"))
        sleep(1); shot("a10-chunked")
        tapWhenReady(button("chunk-next")); sleep(1)
        tapWhenReady(button("format-visual"))
        sleep(1); shot("a11-visual")
        tapWhenReady(button("fidelity-badge"))
        sleep(1); shot("a12-fidelity")
    }

    // MARK: 3. A student with dyslexia writes and submits an essay; AI drafts feedback for the teacher only.

    func testStudentWritesAndSubmitsEssay() throws {
        app.launch()
        tapWhenReady(button("role-Student"))
        sleep(1); shot("s01-sign-in")
        tapWhenReady(button("student-Theo"))
        sleep(1); shot("s02-home")
        tapWhenReady(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'todo-How Water'")).firstMatch)
        sleep(2); shot("s03-reading-dyslexia")
        tapWhenReady(button("reading-settings"))
        sleep(1); shot("s04-reading-settings")
        tapWhenReady(button("font-openDyslexic"))
        app.tap()
        sleep(1); shot("s05-opendyslexic")
        app.buttons["Back"].firstMatch.tap()

        tapWhenReady(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'todo-Later Start'")).firstMatch)
        let editor = app.textViews["essay-editor"]
        tapWhenReady(editor)
        editor.typeText("Our school should start at 9:00 because teenagers need more sleep to learn well. The American Academy of Pediatrics recommends that high schools start no earlier than 8:30 a.m.\n\nSome people argue that a later start would make sports run late. However, students who sleep more do better in class and on the field.")
        sleep(1); shot("s06-writing")
        tapWhenReady(button("submit-essay"))
        tapWhenReady(app.buttons.matching(NSPredicate(format: "label == 'Submit' AND identifier != 'submit-essay'")).firstMatch)
        sleep(2); shot("s07-submitted")
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'is with Ms. Ellis'")).firstMatch.waitForExistence(timeout: 6))

        // The returned example (Maya) shows approved comments only.
        tapWhenReady(button("student-account"))
        tapWhenReady(app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Not Theo'")).firstMatch)
        tapWhenReady(button("student-Maya"))
        tapWhenReady(button("feedback-banner"))
        XCTAssertTrue(button("revise").waitForExistence(timeout: 5))
        sleep(1); shot("s08-student-feedback")
    }

    // MARK: 4. The five-step quest: create, world, book, challenge, adapt.

    func testQuestJourney() throws {
        app.launch()
        tapWhenReady(button("role-Student"))
        tapWhenReady(button("student-Maya"))
        tapWhenReady(button("create-quest"))
        XCTAssertTrue(app.staticTexts["What do you want to learn?"].waitForExistence(timeout: 5))
        shot("q01-create")
        app.buttons["Write my textbook"].tap()
        sleep(1); shot("q02-generating")
        XCTAssertTrue(app.buttons["Enter the learning world"].waitForExistence(timeout: 20))
        shot("q03-preview")
        app.buttons["Enter the learning world"].tap()

        sleep(2); shot("q04-world")
        app.buttons["Quick travel list"].tap()
        XCTAssertTrue(app.navigationBars["Quick travel"].waitForExistence(timeout: 5))
        app.collectionViews.firstMatch.buttons.matching(NSPredicate(format: "label CONTAINS 'Coin Grove'")).firstMatch.tap()

        XCTAssertTrue(app.buttons["Tutor"].waitForExistence(timeout: 8))
        sleep(1); shot("q05-book")
        tapWhenReady(button("book-format-visual"))
        sleep(1); shot("q06-book-visual")
        tapWhenReady(button("book-format-original"))
        app.buttons["Tutor"].tap()
        if app.buttons["Explain this a different way"].waitForExistence(timeout: 3) {
            app.buttons["Explain this a different way"].tap()
            sleep(2); shot("q07-tutor")
        }
        for _ in 0..<6 {
            if app.buttons["Next page"].exists { app.buttons["Next page"].tap(); sleep(1) } else { break }
        }
        let meet = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Meet'")).firstMatch
        tapWhenReady(meet)
        sleep(1); shot("q08-challenge")
        let answer = app.textFields["e.g. 1/6, 0.25 or 25%"]
        if answer.exists {
            answer.tap(); answer.typeText("7/8")
            let reasoning = app.textViews["Explain your reasoning"]
            reasoning.tap(); reasoning.typeText("I guessed because it seemed likely to me")
            app.buttons["Submit"].tap(); sleep(2)
            shot("q09-feedback-wrong")
            app.buttons["Submit"].tap(); sleep(2)
            let another = app.buttons["Show me another way"]
            if another.waitForExistence(timeout: 3) {
                another.tap(); sleep(3)
                shot("q10-adaptive-page")
            }
        }
    }
}
