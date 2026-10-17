import SwiftUI

struct SettingsView: View {
    var embedded = false
    @Environment(AppStore.self) private var store
    @Environment(ClassroomStore.self) private var classroom
    @Environment(\.dismiss) private var dismiss
    @State private var token = Keychain.get("gatewayToken") ?? ""
    @State private var testResult: String?
    @State private var testing = false
    @State private var confirmDelete = false
    @State private var exportURL: URL?

    var body: some View {
        if embedded { content } else { NavigationStack { content } }
    }

    private var content: some View {
        @Bindable var store = store
        return Group {
            Form {
                Section {
                    Picker("Engine", selection: $store.settings.provider) {
                        ForEach(ProviderKind.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    if store.settings.provider == .oci {
                        TextField("Gateway URL", text: $store.settings.gatewayURL).textInputAutocapitalization(.never).keyboardType(.URL).autocorrectionDisabled()
                        SecureField("Gateway token (optional, stored in Keychain)", text: $token)
                            .onChange(of: token) { _, t in t.isEmpty ? Keychain.delete("gatewayToken") : Keychain.set("gatewayToken", t) }
                        TextField("Model label", text: $store.settings.modelLabel).textInputAutocapitalization(.never).autocorrectionDisabled()
                        HStack {
                            Button(testing ? "Testing…" : "Test connection") { Task { await test() } }.disabled(testing)
                            if let testResult { Text(testResult).font(.mFootnote).foregroundStyle(Palette.inkSoft) }
                        }
                    }
                    Toggle("AI assistance", isOn: $store.settings.aiEnabled)
                } header: { Text("AI provider") } footer: {
                    Text(store.settings.provider == .offline
                         ? "Everything runs on this iPad. No network needed."
                         : "Requests go through the Margin privacy gateway to Oracle Cloud Infrastructure Generative AI. The gateway holds the OCI credentials, removes personal details, and logs no content. If it can't be reached, the app falls back to the on-device engine.")
                    + Text(store.settings.aiEnabled ? "" : "\nWith AI off, the tutor is hidden and challenges use the authored hints and on-device checking.")
                }

                Section {
                    Picker("Tutor help level", selection: $store.settings.helpLevel) {
                        ForEach(HelpLevel.allCases) { Text($0.rawValue).tag($0) }
                    }
                    Text(store.effectiveHelpLevel.detail).font(.mFootnote).foregroundStyle(Palette.inkSoft)
                    if store.settings.maxHelpLevel != .supportive {
                        Label("Your educator limits help to \(store.settings.maxHelpLevel.rawValue)", systemImage: "person.badge.shield.checkmark").font(.mFootnote)
                    }
                } header: { Text("Learning") }

                Section("Accessibility") {
                    VStack(alignment: .leading) {
                        Text("Reading text size: \(Int(store.settings.textScale * 100))%")
                        Slider(value: $store.settings.textScale, in: 0.8...1.8, step: 0.1)
                    }
                    Toggle("Dyslexia-friendly text in quests (Lexend, extra spacing)", isOn: $store.settings.dyslexiaFriendly)
                    Toggle("High contrast reading", isOn: $store.settings.highContrast)
                    Toggle("Reduce motion", isOn: $store.settings.reduceMotion)
                    VStack(alignment: .leading) {
                        Text("Read-aloud speed")
                        Slider(value: $store.settings.readAloudRate, in: 0.3...0.6)
                    }
                    ReadingText(text: "Preview: **Probability** tells us how likely something is to happen.", size: 17)
                }

                Section {
                    Toggle("Share anonymous learning signals with my class", isOn: $store.settings.shareSignals)
                    if store.settings.shareSignals {
                        TextField("Class code", text: $store.settings.cohortCode).textInputAutocapitalization(.never)
                    }
                    NavigationLink("What is shared, exactly?") { PrivacyExplainer() }
                    Button("Export my data") { exportURL = store.exportData() }
                    if let exportURL { ShareLink(item: exportURL) { Label("Share export file", systemImage: "square.and.arrow.up") } }
                    Button("Delete all my data", role: .destructive) { confirmDelete = true }
                } header: { Text("Privacy center") } footer: {
                    Text("Off by default. When on, only counts like \"chapter 2, hint used\" or a misconception tag are sent, with no name, ID or written answers. Educators see groups of 5 or more learners, with statistical noise added.")
                }

                Section {
                    Button("Reset demo classroom") { classroom.resetDemo() }
                } header: { Text("Demo") } footer: {
                    Text("Restores the sample classes, students, essays and assignments.")
                }

                Section("Transparency") {
                    NavigationLink("See the instructions the AI follows") { PromptAudit() }
                    LabeledContent("Last AI used", value: store.lastAIStatus.isEmpty ? "–" : store.lastAIStatus)
                }
            }
            .scrollContentBackground(.hidden)
            .background(PaperBackground())
            .navigationTitle("Settings")
            .toolbar { if !embedded { Button("Done") { dismiss() } } }
            .confirmationDialog("Delete everything?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Delete all courses, progress, notes and settings", role: .destructive) { store.deleteAllData(); dismiss() }
            } message: { Text("This cannot be undone.") }
        }
    }

    private func test() async {
        testing = true; defer { testing = false }
        guard let url = URL(string: store.settings.gatewayURL) else { testResult = "Invalid URL"; return }
        do { testResult = try await GatewayProvider(baseURL: url, token: token, modelLabel: store.settings.modelLabel).health() }
        catch { testResult = "Not reachable: \(error.localizedDescription)" }
    }
}

struct PrivacyExplainer: View {
    var body: some View {
        List {
            Section("Never leaves this iPad") {
                Label("Your name and avatar", systemImage: "person.fill")
                Label("Your written answers and explanations", systemImage: "text.bubble")
                Label("Private questions to the tutor (on-device mode)", systemImage: "lock.fill")
                Label("Journal entries and private notes", systemImage: "book.closed")
            }
            Section("Sent only if you opt in") {
                Label("Event counts: \"chapter 1 · hint · level 2\"", systemImage: "number")
                Label("Misconception tags, e.g. \"forgot-without-replacement\"", systemImage: "tag")
                Label("Themes of concerns you chose to share", systemImage: "bubble.left.and.exclamationmark.bubble.right")
            }
            Section("How educators see it") {
                Label("Only groups of 5 or more learners (k-anonymity)", systemImage: "person.3.fill")
                Label("Counts include random noise (differential privacy)", systemImage: "waveform")
                Label("No individual timelines or rankings", systemImage: "eye.slash")
            }
            Section("When using OCI Generative AI") {
                Label("Text is scrubbed of emails, phones, addresses and names before sending", systemImage: "eye.slash.fill")
                Label("The gateway logs counts only, never content", systemImage: "doc.text.magnifyingglass")
                Label("Credentials stay on the server, not this iPad", systemImage: "key.fill")
            }
        }
        .navigationTitle("What is shared")
    }
}

struct PromptAudit: View {
    var body: some View {
        List {
            Section("Core principles (sent with every request)") { Text(Prompts.principles).font(.mCallout.monospaced()) }
            Section("Tutor guardrail") { Text("The tutor is told the active challenge's answer only so it can avoid revealing it. Hints are checked on device, and any hint containing the answer is replaced with an authored hint.").font(.mCallout) }
            Section("Grading") { Text("Correctness is checked by code on this iPad, never by AI. AI only gives feedback on your explanation, using a rubric your educator can see and edit.").font(.mCallout) }
            Section("Concern replies") { Text(Prompts.concernSystem).font(.mCallout.monospaced()) }
            Section("Educator insights") { Text(Prompts.insightsSystem).font(.mCallout.monospaced()) }
        }
        .navigationTitle("AI instructions")
    }
}
