import SwiftUI

struct WelcomeView: View {
    @Environment(ClassroomStore.self) private var classroom
    @State private var showPIN = false
    @State private var appeared = false

    var body: some View {
        GeometryReader { g in
            let wide = g.size.width > g.size.height
            HStack(spacing: 0) {
                if wide {
                    artPanel.frame(width: g.size.width * 0.46)
                }
                ZStack {
                    PaperBackground()
                    ScrollView {
                        VStack(alignment: .leading, spacing: 34) {
                            if !wide { ArtCover(asset: "art-hero-student", height: 220, radius: 18) }
                            brand
                            VStack(spacing: 14) {
                                choice(title: "I'm a student", detail: "Sign in with your class. Your reading settings and assignments follow you to any iPad.",
                                       symbol: "backpack", color: Palette.forest, id: "Student") {
                                    withAnimation { classroom.role = .student }
                                }
                                choice(title: "I'm a teacher", detail: "Review AI-drafted feedback, send assignments and set each student's reading supports.",
                                       symbol: "text.book.closed", color: Palette.terracotta, id: "Teacher") {
                                    showPIN = true
                                }
                            }
                            promises
                        }
                        .padding(.horizontal, wide ? 64 : 32)
                        .padding(.vertical, 56)
                        .frame(maxWidth: 620, alignment: .leading)
                        .frame(maxWidth: .infinity, minHeight: g.size.height)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 12)
                    }
                    .scrollBounceBehavior(.basedOnSize)
                }
            }
        }
        .ignoresSafeArea(edges: .vertical)
        .onAppear { withAnimation(.easeOut(duration: 0.6).delay(0.1)) { appeared = true } }
        .sheet(isPresented: $showPIN) { TeacherPINView { withAnimation { classroom.becomeTeacher() } } }
    }

    private var artPanel: some View {
        ZStack(alignment: .bottomLeading) {
            Color.clear.overlay(Image("art-hero-student").resizable().scaledToFill()).clipped()
            LinearGradient(colors: [.clear, .black.opacity(0.6)], startPoint: .center, endPoint: .bottom)
            VStack(alignment: .leading, spacing: 10) {
                Text("\u{201C}The mind is not a vessel to be filled, but a fire to be kindled.\u{201D}")
                    .font(.displayItalic(26)).foregroundStyle(.white).fixedSize(horizontal: false, vertical: true)
                Text("Plutarch").font(.ui(14, .semibold)).foregroundStyle(.white.opacity(0.8))
                Text("A Sunday on La Grande Jatte, Georges Seurat, 1884. Art Institute of Chicago, CC0.")
                    .font(.ui(11)).italic().foregroundStyle(.white.opacity(0.6)).padding(.top, 14)
            }
            .padding(40)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    private var brand: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image("brand-mark").resizable().frame(width: 44, height: 44).clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                Text(Brand.name).font(.display(30, .semibold))
            }
            Text("Every learner reads the same lesson, in the way that works for them. Every comment a student sees, their teacher approved.")
                .font(.display(34, .regular, relativeTo: .largeTitle))
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func choice(title: String, detail: String, symbol: String, color: Color, id: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 18) {
                Image(systemName: symbol)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(color)
                    .frame(width: 52, height: 52)
                    .background(Circle().fill(color.opacity(0.12)))
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.display(22, .semibold))
                    Text(detail).font(.mSubheadline).foregroundStyle(Palette.inkSoft).multilineTextAlignment(.leading).fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                Image(systemName: "arrow.right").font(.system(size: 16, weight: .semibold)).foregroundStyle(Palette.inkMuted)
            }
            .padding(20)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Palette.surface))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Palette.rule))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("role-\(id)")
    }

    private var promises: some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow("Built on three promises")
            promise("checkmark.seal", "Teachers stay in charge", "AI drafts. A teacher approves every comment before a student sees it.")
            promise("text.magnifyingglass", "Same content, every format", "Chunked, read-aloud and visual versions are checked word for word against the original.")
            promise("lock", "Private by default", "Runs on this iPad. Names and support notes never go to an AI model.")
        }
        .padding(.top, 6)
    }

    private func promise(_ symbol: String, _ title: String, _ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: symbol).foregroundStyle(Palette.forest).frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.mHeadline)
                Text(text).font(.mSubheadline).foregroundStyle(Palette.inkSoft).fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct TeacherPINView: View {
    var onSuccess: () -> Void
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var pin = ""
    @State private var shake = false

    var body: some View {
        VStack(spacing: 26) {
            VStack(spacing: 8) {
                Image(systemName: "lock").font(.system(size: 26)).foregroundStyle(Palette.terracotta)
                Text("Teacher sign-in").font(.mTitle2)
                Text("Enter your 4-digit PIN. Demo PIN: \(store.settings.educatorPIN)").font(.mSubheadline).foregroundStyle(Palette.inkSoft)
            }
            HStack(spacing: 16) {
                ForEach(0..<4, id: \.self) { i in
                    Circle()
                        .strokeBorder(Palette.ruleStrong, lineWidth: 1.5)
                        .background(Circle().fill(i < pin.count ? Palette.ink : .clear))
                        .frame(width: 16, height: 16)
                }
            }
            .offset(x: shake ? 10 : 0)
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(76), spacing: 16), count: 3), spacing: 14) {
                ForEach(["1", "2", "3", "4", "5", "6", "7", "8", "9", "", "0", "⌫"], id: \.self) { k in
                    if k.isEmpty { Color.clear.frame(height: 64) } else {
                        Button { tap(k) } label: {
                            Text(k == "⌫" ? "" : k).font(.display(28))
                                .overlay { if k == "⌫" { Image(systemName: "delete.left").font(.system(size: 20)) } }
                                .frame(width: 76, height: 64)
                                .background(RoundedRectangle(cornerRadius: 14).fill(Palette.surface))
                                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Palette.rule))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(k == "⌫" ? "Delete" : k)
                        .accessibilityIdentifier("pin-\(k)")
                    }
                }
            }
            Button("Cancel") { dismiss() }.font(.mHeadline).foregroundStyle(Palette.inkSoft)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PaperBackground())
        .presentationDetents([.large])
    }

    private func tap(_ k: String) {
        if k == "⌫" { if !pin.isEmpty { pin.removeLast() }; return }
        guard pin.count < 4 else { return }
        pin += k
        if pin.count == 4 {
            if pin == store.settings.educatorPIN { dismiss(); onSuccess() } else {
                withAnimation(.spring(response: 0.15, dampingFraction: 0.2)) { shake = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { shake = false; pin = "" }
            }
        }
    }
}

struct StudentSignInView: View {
    @Environment(ClassroomStore.self) private var classroom
    @State private var classID: UUID?

    var body: some View {
        let cls = classroom.classes.first { $0.id == (classID ?? classroom.classes.first?.id) }
        ZStack {
            PaperBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    HStack {
                        Button { withAnimation { classroom.role = nil } } label: { Label("Back", systemImage: "chevron.left") }
                            .font(.mHeadline).foregroundStyle(Palette.inkSoft)
                        Spacer()
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Eyebrow("Shared iPad")
                        Text("Who's learning today?").font(.mLargeTitle)
                        Text("Tap your name. Your reading settings and assignments will load.").font(.mBody).foregroundStyle(Palette.inkSoft)
                    }
                    Picker("Class", selection: Binding(get: { classID ?? classroom.classes.first?.id }, set: { classID = $0 })) {
                        ForEach(classroom.classes) { c in Text("\(c.name) · \(c.period)").tag(Optional(c.id)) }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 640)
                    if let cls {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 18)], spacing: 18) {
                            ForEach(classroom.roster(cls)) { s in
                                Button { withAnimation { classroom.signIn(s) } } label: {
                                    VStack(spacing: 12) {
                                        PersonAvatar(asset: s.avatar, name: s.name, size: 84)
                                        Text(s.name).font(.mHeadline).multilineTextAlignment(.center).lineLimit(2)
                                    }
                                    .frame(maxWidth: .infinity).padding(.vertical, 22)
                                    .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Palette.surface))
                                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Palette.rule))
                                }
                                .buttonStyle(.plain)
                                .accessibilityIdentifier("student-\(s.firstName)")
                            }
                        }
                    }
                    Text("Support plans and reading profiles are never shown on this screen.")
                        .font(.mFootnote).foregroundStyle(Palette.inkMuted)
                }
                .padding(48)
            }
        }
    }
}
