import SwiftUI

/// The private, trusted channel: ask anything, or share a concern and choose exactly who sees it.
struct LibraryView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    var course: Course?
    @State private var tab = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Mode", selection: $tab) {
                    Text("Ask privately").tag(0)
                    Text("Share a concern").tag(1)
                    Text("My notes").tag(2)
                }
                .pickerStyle(.segmented)
                .padding()
                switch tab {
                case 0: PrivateAskView(course: course ?? store.courses.first)
                case 1: ConcernView()
                default: MyConcernsView()
                }
            }
            .background(Palette.paper)
            .navigationTitle("The Library")
            .toolbar { Button("Done") { dismiss() } }
        }
    }
}

struct PrivateAskView: View {
    @Environment(AppStore.self) private var store
    var course: Course?
    @State private var chapterIndex = 0

    var body: some View {
        if let course, !course.chapters.isEmpty {
            VStack(spacing: 0) {
                HStack {
                    Label("Questions here are never shown to your educator.", systemImage: "lock.fill").font(.mFootnote).foregroundStyle(Palette.inkSoft)
                    Spacer()
                    Picker("Chapter", selection: $chapterIndex) {
                        ForEach(course.chapters.indices, id: \.self) { i in Text("Ch. \(i + 1): \(course.chapters[i].title)").tag(i) }
                    }
                }
                .padding(.horizontal)
                TutorPanel(course: course, chapter: course.chapters[min(chapterIndex, course.chapters.count - 1)], section: nil, activeChallenge: nil) {}
            }
        } else {
            ContentUnavailableView("No course yet", systemImage: "books.vertical", description: Text("Create a course to ask the tutor questions. You can still share a concern."))
        }
    }
}

struct ConcernView: View {
    @Environment(AppStore.self) private var store
    @State private var text = ""
    @State private var visibility: ConcernVisibility = .privateOnly
    @State private var busy = false
    @State private var reply: ConcernTriage?
    @State private var preview: PrivacyFilter.Result?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Is something getting in the way of your learning? Stress, confusion, pace, access, feeling left out: anything. You decide who sees it.")
                    .font(.ui(19, .medium))
                TextEditor(text: $text)
                    .frame(minHeight: 140)
                    .scrollContentBackground(.hidden)
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Palette.surface))
                    .onChange(of: text) { _, t in preview = PrivacyFilter.scrub(t, extraNames: [store.settings.learnerName]) }
                    .accessibilityLabel("Your concern")

                Text("Who can see this?").font(.mHeadline)
                ForEach(ConcernVisibility.allCases) { v in
                    Button { visibility = v } label: {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: visibility == v ? "largecircle.fill.circle" : "circle").font(.ui(19, .medium))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(v.rawValue).font(.mHeadline)
                                Text(v.detail).font(.mSubheadline).foregroundStyle(Palette.inkSoft).multilineTextAlignment(.leading)
                            }
                            Spacer()
                        }
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 14).fill(visibility == v ? Palette.forestSoft : Palette.surface))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(visibility == v ? .isSelected : [])
                }

                if visibility == .anonymous, let preview, preview.redactions > 0 {
                    VStack(alignment: .leading, spacing: 6) {
                        Label("\(preview.redactions) identifying detail\(preview.redactions == 1 ? "" : "s") will be removed before sharing", systemImage: "eye.slash.fill").font(.ui(14, .semibold)).foregroundStyle(Theme.mint)
                        Text(preview.text).font(.mCallout).foregroundStyle(Palette.inkSoft)
                    }
                    .padding(14).background(RoundedRectangle(cornerRadius: 12).fill(Theme.mint.opacity(0.1)))
                }

                Button { Task { await submit() } } label: {
                    if busy { ProgressView().tint(.white) } else { Label(visibility == .privateOnly ? "Save privately" : "Share", systemImage: "paperplane.fill") }
                }
                .buttonStyle(PillButtonStyle())
                .disabled(text.trimmingCharacters(in: .whitespaces).count < 3 || busy)

                if let reply {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Label(reply.urgent ? "Please talk to someone today" : "A note back", systemImage: reply.urgent ? "heart.circle.fill" : "sparkles")
                                .font(.mHeadline).foregroundStyle(reply.urgent ? Theme.coral : Theme.accent)
                            Spacer()
                            AIBadge(detail: "Written by \(store.lastAIStatus.isEmpty ? store.primaryProvider.displayName : store.lastAIStatus). Messages about safety always get the same human-reviewed guidance, never AI improvisation. This AI is not a counselor.")
                        }
                        Text(reply.reply).fixedSize(horizontal: false, vertical: true)
                        Text("Category: \(reply.category)").font(.mCaption).foregroundStyle(Palette.inkSoft)
                    }
                    .padding(18)
                    .background(RoundedRectangle(cornerRadius: 16).fill(reply.urgent ? Theme.coral.opacity(0.12) : Palette.surface))
                }
            }
            .padding(24)
            .frame(maxWidth: 820)
            .frame(maxWidth: .infinity)
        }
    }

    private func submit() async {
        busy = true; defer { busy = false }
        let scrubbed = PrivacyFilter.scrub(text, extraNames: visibility == .named ? [] : [store.settings.learnerName]).text
        let sendText = scrubbed
        let triage: ConcernTriage
        if PrivacyFilter.needsUrgentHumanSupport(text) {
            triage = ConcernTriage(category: "Urgent wellbeing", reply: PrivacyFilter.urgentSupportMessage, urgent: true)
        } else if store.settings.aiEnabled, let t = await store.ai({ try await $0.triageConcern(sendText) }) {
            triage = t
        } else {
            triage = (try? await OfflineProvider().triageConcern(sendText)) ?? ConcernTriage(category: "General", reply: "Thanks for sharing.", urgent: false)
        }
        let stored = visibility == .privateOnly ? text : (visibility == .named ? text : scrubbed)
        store.concerns.insert(Concern(text: stored, category: triage.category, visibility: visibility, supportiveReply: triage.reply), at: 0)
        store.save()
        if visibility != .privateOnly, let course = store.courses.first, let ch = course.chapters.first {
            store.emitSignal(course: course, chapter: ch, kind: "concern_theme", tag: triage.category, value: 1)
        }
        withAnimation { reply = triage }
        text = ""
    }
}

struct MyConcernsView: View {
    @Environment(AppStore.self) private var store
    var body: some View {
        List {
            if store.concerns.isEmpty {
                Text("Nothing here yet. Anything you save or share appears here, and you can delete it at any time.").foregroundStyle(Palette.inkSoft)
            }
            ForEach(store.concerns) { c in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Label(c.visibility.rawValue, systemImage: c.visibility == .privateOnly ? "lock.fill" : c.visibility == .anonymous ? "person.fill.questionmark" : "person.fill")
                            .font(.ui(12, .bold)).foregroundStyle(Theme.accent)
                        Spacer()
                        Text(c.date, style: .date).font(.mCaption).foregroundStyle(Palette.inkSoft)
                    }
                    Text(c.text)
                    Text(c.supportiveReply).font(.mCallout).foregroundStyle(Palette.inkSoft)
                }
                .padding(.vertical, 4)
            }
            .onDelete { idx in store.concerns.remove(atOffsets: idx); store.save() }
        }
    }
}
