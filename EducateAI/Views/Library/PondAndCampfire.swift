import SwiftUI

struct ReflectionPondView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    var course: Course
    @State private var text = ""
    @State private var confidence = 3
    @State private var chapterIndex = 0

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Pause by the pond. Writing about your learning helps you remember it and notice what's still unclear.")
                            .foregroundStyle(Palette.inkSoft)
                        Picker("Chapter", selection: $chapterIndex) {
                            ForEach(course.chapters.indices, id: \.self) { i in Text(course.chapters[i].title).tag(i) }
                        }
                        Text(prompts[(chapterIndex + store.journal.count) % prompts.count]).font(.mHeadline).foregroundStyle(Theme.sky)
                        TextEditor(text: $text).frame(minHeight: 120)
                        HStack {
                            Text("Confidence")
                            ForEach(1...5, id: \.self) { i in
                                Image(systemName: i <= confidence ? "star.fill" : "star").foregroundStyle(Theme.sun).onTapGesture { confidence = i }
                                    .accessibilityLabel("\(i) stars").accessibilityAddTraits(.isButton)
                            }
                            Spacer()
                            Button("Save entry") {
                                store.journal.insert(.init(courseTopic: course.topic, chapterTitle: course.chapters[chapterIndex].title, text: text, confidence: confidence), at: 0)
                                store.addXP(course, 10)
                                store.award("reflector", "Deep Thinker", "Wrote your first reflection", "drop.fill")
                                text = ""
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(text.split { $0.isWhitespace }.count < 3)
                        }
                    }
                } header: { Text("New reflection") }
                Section("Your journal (private)") {
                    ForEach(store.journal.filter { $0.courseTopic == course.topic }) { e in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(e.chapterTitle).font(.mHeadline)
                                Spacer()
                                Text(String(repeating: "★", count: e.confidence)).foregroundStyle(Theme.sun)
                            }
                            Text(e.text)
                            Text(e.date, style: .date).font(.mCaption).foregroundStyle(Palette.inkSoft)
                        }
                    }
                    .onDelete { idx in
                        let items = store.journal.filter { $0.courseTopic == course.topic }
                        let ids = idx.map { items[$0].id }
                        store.journal.removeAll { ids.contains($0.id) }
                        store.save()
                    }
                }
            }
            .navigationTitle("Reflection Pond")
            .toolbar { Button("Done") { dismiss() } }
        }
    }

    private let prompts = [
        "What surprised you in this chapter?",
        "Explain the main idea as if to a younger student.",
        "Where did you get stuck, and what got you unstuck?",
        "Where might you use this outside of school?",
        "What question would you ask your teacher about this?"
    ]
}

struct ReviewCampfireView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    var course: Course
    @State private var index = 0
    @State private var flipped = false
    @State private var known: Set<Int> = []
    @State private var againQueue: [Int] = []

    struct Flash { var front: String; var back: String; var chapter: String }

    private var cards: [Flash] {
        var out: [Flash] = []
        for ch in course.chapters where store.chapterProgress(course, ch).status != .locked {
            for s in ch.sections { if let c = s.checkpoint { out.append(Flash(front: c.question, back: "\(c.options[c.correctIndex])\n\n\(c.explanation)", chapter: ch.title)) } }
            for (i, k) in ch.keyIdeas.enumerated() { out.append(Flash(front: "Key idea \(i + 1) of \"\(ch.title)\": can you recall it before flipping?", back: k, chapter: ch.title)) }
        }
        return out
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                let deck = cards
                if deck.isEmpty {
                    ContentUnavailableView("Nothing to review yet", systemImage: "flame", description: Text("Unlock a chapter to add its ideas to the campfire."))
                } else if known.count == deck.count {
                    VStack(spacing: 16) {
                        Image(systemName: "flame.fill").font(.system(size: 80)).foregroundStyle(Theme.sun.gradient)
                        Text("Review complete!").font(.mLargeTitle)
                        Text("Come back tomorrow. Spacing out reviews makes memories last.").foregroundStyle(Palette.inkSoft)
                        Button("Review again") { known = []; index = 0; flipped = false }.buttonStyle(.borderedProminent)
                    }
                } else {
                    let card = deck[index % deck.count]
                    Text("\(known.count) of \(deck.count) recalled").font(.mHeadline).foregroundStyle(Palette.inkSoft)
                    ProgressView(value: Double(known.count), total: Double(deck.count)).tint(Theme.sun).frame(maxWidth: 500)
                    ZStack {
                        RoundedRectangle(cornerRadius: 28).fill(flipped ? AnyShapeStyle(Theme.sun.opacity(0.18)) : AnyShapeStyle(Palette.surface))
                            .shadow(radius: 8)
                        VStack(spacing: 14) {
                            Text(card.chapter).font(.ui(12, .bold)).foregroundStyle(Palette.inkSoft)
                            Text(flipped ? card.back : card.front).font(.title2.weight(.semibold)).multilineTextAlignment(.center)
                                .padding(30)
                            if !flipped { Text("Tap to flip").font(.mCaption).foregroundStyle(Palette.inkSoft) }
                        }
                        .rotation3DEffect(.degrees(flipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
                    }
                    .rotation3DEffect(.degrees(flipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
                    .frame(maxWidth: 620, minHeight: 320, maxHeight: 360)
                    .onTapGesture { withAnimation(.spring) { flipped.toggle() } }
                    .accessibilityAddTraits(.isButton)
                    .accessibilityLabel(flipped ? card.back : card.front)
                    if flipped {
                        HStack(spacing: 20) {
                            Button { next(deck.count, knewIt: false) } label: { Label("Not yet", systemImage: "arrow.counterclockwise") }
                                .buttonStyle(PillButtonStyle(color: Theme.coral))
                            Button { next(deck.count, knewIt: true) } label: { Label("I knew it", systemImage: "checkmark") }
                                .buttonStyle(PillButtonStyle(color: Theme.mint))
                        }
                    }
                }
            }
            .padding(30)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Palette.paper)
            .navigationTitle("Review Campfire")
            .toolbar { Button("Done") { dismiss() } }
        }
    }

    private func next(_ count: Int, knewIt: Bool) {
        let current = index % count
        if knewIt { known.insert(current); store.addXP(course, 2) }
        flipped = false
        // Simple spaced repetition: unknown cards come back soon, known cards drop out.
        var n = (current + 1) % count
        var guardCount = 0
        while known.contains(n) && guardCount < count { n = (n + 1) % count; guardCount += 1 }
        index = n
        if known.count == count { store.award("campfire", "Campfire Keeper", "Completed a full review session", "flame.fill") }
    }
}
