import SwiftUI

struct ChapterCompleteView: View {
    @Environment(AppStore.self) private var store
    var course: Course
    var chapter: Chapter
    var backToMap: () -> Void
    @State private var reflection = ""
    @State private var confidence = 3
    @State private var saved = false
    @State private var burst = false

    var body: some View {
        let p = store.chapterProgress(course, chapter)
        let next = course.chapters.first { $0.index == chapter.index + 1 }
        ScrollView {
            VStack(spacing: 26) {
                ZStack {
                    if burst { ConfettiView().frame(width: 300, height: 300) }
                    MasteryRing(value: p.mastery, size: 150, color: Theme.themeColor(chapter.theme))
                }
                Text("\(chapter.locationName) mastered!").font(.display(40, .semibold))
                if let next {
                    Label("\(next.locationName) is now unlocked on your map", systemImage: "lock.open.fill")
                        .font(.mTitle3).foregroundStyle(Theme.mint)
                } else {
                    Label("You've completed every chapter of \(course.topic)!", systemImage: "trophy.fill").font(.mTitle3).foregroundStyle(Theme.sun)
                }
                stats(p)

                Card {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Reflect", systemImage: "drop.fill").font(.mHeadline).foregroundStyle(Theme.sky)
                        Text("In your own words, what's the most important thing you learned? What still feels fuzzy?")
                        TextEditor(text: $reflection).frame(minHeight: 100).scrollContentBackground(.hidden)
                            .padding(8).background(RoundedRectangle(cornerRadius: 12).fill(Palette.surfaceSunk))
                        Text("How confident do you feel?").font(.ui(14, .semibold))
                        HStack {
                            ForEach(1...5, id: \.self) { i in
                                Button { confidence = i } label: {
                                    Image(systemName: i <= confidence ? "star.fill" : "star").font(.mTitle).foregroundStyle(Theme.sun)
                                }
                                .accessibilityLabel("\(i) stars")
                            }
                            Spacer()
                            Button(saved ? "Saved to Reflection Pond" : "Save reflection") {
                                store.journal.insert(.init(courseTopic: course.topic, chapterTitle: chapter.title, text: reflection, confidence: confidence), at: 0)
                                store.mutateProgress(course, chapter) { $0.reflection = reflection; $0.confidence = confidence }
                                store.addXP(course, 15)
                                store.award("reflector", "Deep Thinker", "Wrote your first reflection", "drop.fill")
                                saved = true
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(saved || reflection.split { $0.isWhitespace }.count < 3)
                        }
                    }
                }

                Card {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Talk it through with someone", systemImage: "person.2.fill").font(.mHeadline).foregroundStyle(Theme.coral)
                        Text("Explaining to another person is one of the best ways to learn. Try one of these with a classmate, teacher or family member:")
                            .foregroundStyle(Palette.inkSoft)
                        ForEach(chapter.discussionPrompts, id: \.self) { q in
                            Label(q, systemImage: "bubble.left.and.bubble.right").fixedSize(horizontal: false, vertical: true)
                        }
                        ShareLink(item: "Let's discuss \(chapter.title):\n" + chapter.discussionPrompts.map { "• \($0)" }.joined(separator: "\n")) {
                            Label("Share prompts", systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(.bordered)
                    }
                }

                Button(action: backToMap) { Label("Back to the map", systemImage: "map.fill") }
                    .buttonStyle(PillButtonStyle(color: Theme.mint))
            }
            .padding(36)
            .frame(maxWidth: 820)
            .frame(maxWidth: .infinity)
        }
        .onAppear { reflection = p.reflection; confidence = p.confidence ?? 3; withAnimation { burst = true } }
    }

    private func stats(_ p: ChapterProgress) -> some View {
        let attempts = p.attempts
        let avgReason = attempts.filter(\.correct).map(\.reasoningScore).reduce(0, +) / Double(max(1, attempts.filter(\.correct).count))
        return HStack(spacing: 16) {
            stat("\(p.solvedChallenges.count)", "challenges solved", "flag.checkered", Theme.accent)
            stat("\(Int(avgReason * 100))%", "reasoning quality", "text.bubble.fill", Theme.mint)
            stat("\(attempts.map(\.hintsUsed).reduce(0, +))", "hints used", "lightbulb.fill", Theme.sun)
            stat("\(p.remediations)", "new explanations", "wand.and.stars", Theme.sky)
        }
    }

    private func stat(_ v: String, _ l: String, _ icon: String, _ c: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon).foregroundStyle(c).font(.mTitle2)
            Text(v).font(.title.bold().monospacedDigit())
            Text(l).font(.mCaption).foregroundStyle(Palette.inkSoft)
        }
        .frame(maxWidth: .infinity).padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(Palette.surface))
        .accessibilityElement(children: .combine)
    }
}
