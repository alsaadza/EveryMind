import SwiftUI

struct CreateCourseView: View {
    @Environment(AppStore.self) private var store
    @Binding var path: [Route]
    @State private var topic = "Introduction to Probability"
    @State private var level: SkillLevel = .beginner
    @State private var stage: LearnerStage = .k12
    @State private var goals = ""
    @State private var generating = false
    @State private var generated: Course?
    @State private var errorText: String?

    private let suggestions = ["Introduction to Probability", "Fractions", "The Water Cycle", "Photosynthesis", "Personal Finance Basics", "Intro to Python"]

    var body: some View {
        ZStack {
            PaperBackground()
            if let course = generated {
                CoursePreview(course: course) {
                    let id = course.id
                    path.removeAll { $0 == .create }
                    path.append(.world(id))
                } regenerate: {
                    store.delete(course); generated = nil
                }
            } else if generating {
                GeneratingView(topic: topic, provider: store.primaryProvider.displayName)
            } else {
                form
            }
        }
        .navigationTitle(generated == nil ? "New course" : "Your textbook")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var form: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                HStack(alignment: .bottom, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Eyebrow("New quest", color: Palette.forest)
                        Text("What do you want to learn?").font(.mLargeTitle)
                        Text("AI writes you a three-chapter book. Then it becomes a map to explore, with a guide at every stop.").font(.mBody).foregroundStyle(Palette.inkSoft)
                    }
                    Spacer()
                    ArtCover(asset: ArtCatalog.cover(for: topic).asset, height: 120, radius: 12).frame(width: 180)
                        .animation(.easeInOut, value: ArtCatalog.cover(for: topic).asset)
                }

                Card {
                    VStack(alignment: .leading, spacing: 14) {
                        TextField("Any topic, e.g. Introduction to Probability", text: $topic)
                            .font(.display(26))
                            .textInputAutocapitalization(.words)
                            .submitLabel(.done)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(suggestions, id: \.self) { s in
                                    Button { topic = s } label: {
                                        HStack(spacing: 4) {
                                            if OfflineLibrary.curatedTopics.contains(s) { Image(systemName: "checkmark.seal.fill").font(.mCaption) }
                                            Text(s)
                                        }
                                        .padding(.horizontal, 14).padding(.vertical, 8)
                                        .font(.ui(14, .semibold))
                                        .background(Capsule().fill(topic == s ? Palette.ink : Palette.surfaceSunk))
                                        .foregroundStyle(topic == s ? Palette.onAccent : Palette.inkSoft)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        if store.settings.provider == .offline && !OfflineLibrary.curatedTopics.contains(where: { $0.localizedCaseInsensitiveContains(topic) || topic.localizedCaseInsensitiveContains($0) }) && !topic.isEmpty {
                            Label("On-device mode has full curated packs for the topics with a seal. Other topics get a study scaffold. Connect OCI Generative AI in Settings for a fully written book on any topic.", systemImage: "info.circle")
                                .font(.mFootnote).foregroundStyle(Palette.inkSoft)
                        }
                    }
                }

                Text("Your skill level").font(.mTitle3)
                HStack(spacing: 14) {
                    ForEach(SkillLevel.allCases) { l in
                        Button { level = l } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Image(systemName: l == .beginner ? "leaf.fill" : l == .intermediate ? "flame.fill" : "bolt.fill")
                                    Text(l.label).font(.mHeadline)
                                }
                                Text(l.blurb).font(.mSubheadline).foregroundStyle(level == l ? Palette.onAccent.opacity(0.85) : Palette.inkSoft).multilineTextAlignment(.leading)
                            }
                            .frame(maxWidth: .infinity, minHeight: 90, alignment: .topLeading)
                            .padding(16)
                            .background(RoundedRectangle(cornerRadius: 14).fill(level == l ? Palette.forest : Palette.surface))
                            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(level == l ? .clear : Palette.rule))
                            .foregroundStyle(level == l ? Palette.onAccent : Palette.ink)
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(level == l ? .isSelected : [])
                    }
                }

                Text("Where are you learning?").font(.mTitle3)
                Picker("Learner stage", selection: $stage) {
                    ForEach(LearnerStage.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)

                Text("Any goals? (optional)").font(.mTitle3)
                TextField("e.g. I have a quiz next week, or I want to understand games of chance", text: $goals, axis: .vertical)
                    .lineLimit(2...4)
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Palette.surface))
                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Palette.rule))

                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: store.primaryProvider.runsOnDevice ? "lock.iphone" : "cloud").font(.system(size: 22)).foregroundStyle(Palette.plum)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Written by \(store.primaryProvider.displayName)").font(.mHeadline)
                        Text("Only your topic, level, stage and goals are used. Your name and progress are never sent. Educators can review and edit the book.")
                            .font(.mSubheadline).foregroundStyle(Palette.inkSoft)
                    }
                }
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 16).fill(Palette.plumSoft.opacity(0.5)))

                if let errorText { Text(errorText).foregroundStyle(Theme.coral) }

                Button {
                    Task { await generate() }
                } label: {
                    Label("Write my textbook", systemImage: "wand.and.stars").frame(maxWidth: .infinity)
                }
                .buttonStyle(.primary)
                .disabled(topic.trimmingCharacters(in: .whitespaces).count < 2)
            }
            .padding(32)
            .frame(maxWidth: 900)
            .frame(maxWidth: .infinity)
        }
    }

    private func generate() async {
        errorText = nil
        withAnimation { generating = true }
        let req = CourseRequest(topic: topic.trimmingCharacters(in: .whitespaces), level: level, stage: stage, goals: PrivacyFilter.scrub(goals, extraNames: [store.settings.learnerName]).text)
        let course = await store.ai { try await $0.generateCourse(req) }
        withAnimation(.spring) {
            generating = false
            if var c = course {
                if c.chapters.isEmpty { errorText = "The AI returned an empty book. Please try again."; return }
                c.chapters = c.chapters.enumerated().map { i, ch in var ch = ch; ch.index = i; return ch }
                store.add(c)
                generated = c
            } else {
                errorText = "Couldn't create the course. Check Settings > AI Provider and try again."
            }
        }
    }
}

struct GeneratingView: View {
    var topic: String
    var provider: String
    @State private var step = 0
    private let steps = ["Outlining three chapters", "Writing lessons for your level", "Designing interactive illustrations", "Inventing guides and challenges", "Inking your world map"]

    var body: some View {
        VStack(spacing: 34) {
            ZStack {
                ForEach(0..<3) { i in
                    RoundedRectangle(cornerRadius: 6).fill(Palette.surface)
                        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Palette.rule))
                        .overlay(alignment: .topLeading) {
                            VStack(alignment: .leading, spacing: 7) {
                                ForEach(0..<7) { k in Capsule().fill(Palette.rule).frame(width: k == 0 ? 70 : CGFloat(90 + (k * 13) % 30), height: k == 0 ? 7 : 4) }
                            }.padding(18)
                        }
                        .frame(width: 160, height: 210)
                        .shadow(color: .black.opacity(0.08), radius: 10, y: 6)
                        .rotationEffect(.degrees(Double(i - 1) * 8 + (step % 2 == 0 ? 1.5 : -1.5)))
                        .offset(x: CGFloat(i - 1) * 34)
                }
                Image(systemName: "sparkle").font(.system(size: 34, weight: .medium)).foregroundStyle(Palette.plum).symbolEffect(.pulse).offset(x: 70, y: -100)
            }
            .animation(.easeInOut(duration: 0.8), value: step)
            VStack(spacing: 6) {
                Eyebrow("Writing your book")
                Text(topic).font(.mTitle).multilineTextAlignment(.center)
            }
            VStack(alignment: .leading, spacing: 12) {
                ForEach(steps.indices, id: \.self) { i in
                    HStack(spacing: 12) {
                        Image(systemName: i < step ? "checkmark.circle.fill" : i == step ? "circle.dotted" : "circle")
                            .foregroundStyle(i <= step ? Palette.forest : Palette.inkMuted)
                        Text(steps[i]).foregroundStyle(i <= step ? Palette.ink : Palette.inkMuted)
                    }
                }
            }
            .font(.ui(18, .medium))
            AIMark(text: provider)
        }
        .task {
            while step < steps.count - 1 {
                try? await Task.sleep(nanoseconds: 700_000_000)
                step += 1
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Generating your textbook")
    }
}

struct CoursePreview: View {
    var course: Course
    var enter: () -> Void
    var regenerate: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ZStack(alignment: .bottomLeading) {
                    ArtCover(asset: ArtCatalog.cover(for: course.topic).asset, height: 220, radius: 18, scrim: true)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(course.topic).font(.display(40, .semibold)).foregroundStyle(.white)
                        Text("\(course.level.label) · \(course.stage.rawValue) · \(course.chapters.count) chapters").font(.mHeadline).foregroundStyle(.white.opacity(0.85))
                    }
                    .padding(24)
                }
                HStack {
                    ArtCredit(asset: ArtCatalog.cover(for: course.topic).asset)
                    Spacer()
                    AIBadge(text: "AI-generated", detail: "\(course.provenance)\n\nEngine: \(course.generatedBy)\nStatus: \(course.reviewStatus.label)")
                }
                VStack(spacing: 0) {
                    ForEach(course.chapters) { ch in
                        HStack(alignment: .top, spacing: 20) {
                            Text("\(ch.index + 1)").font(.display(44)).foregroundStyle(Theme.themeColor(ch.theme)).frame(width: 44)
                            VStack(alignment: .leading, spacing: 6) {
                                Eyebrow("\(ch.locationName)", color: Theme.themeColor(ch.theme))
                                Text(ch.title).font(.mTitle2)
                                Text(ch.summary).font(.mCallout).foregroundStyle(Palette.inkSoft).fixedSize(horizontal: false, vertical: true)
                                Text("\(ch.sections.count) pages · \(ch.challenges.count) challenges · guide \(ch.npc.emoji) \(ch.npc.name)")
                                    .font(.mFootnote).foregroundStyle(Palette.inkMuted)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 18)
                        if ch.id != course.chapters.last?.id { Rule() }
                    }
                }
                .padding(.horizontal, 22)
                .background(RoundedRectangle(cornerRadius: 16).fill(Palette.surface))
                .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Palette.rule))
                Text("Next, your book becomes a map. Each chapter is a place to explore, and mastering one unlocks the next.")
                    .font(.mCallout).foregroundStyle(Palette.inkSoft)
                HStack {
                    Button("Write a different version", action: regenerate).buttonStyle(.secondary)
                    Spacer()
                    Button(action: enter) { Label("Enter the learning world", systemImage: "map") }
                        .buttonStyle(.primary)
                }
            }
            .padding(32)
            .frame(maxWidth: 900)
            .frame(maxWidth: .infinity)
        }
    }
}
