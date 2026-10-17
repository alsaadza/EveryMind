import SwiftUI

enum Theme {
    static let ink = Palette.ink
    static let paper = Palette.paper
    static let accent = Palette.forest
    static let mint = Color(light: 0x3F7D5F, dark: 0x86C2A3)
    static let sun = Palette.ochre
    static let coral = Palette.terracotta
    static let sky = Palette.slate
    static let avatarColors: [Color] = [Palette.forest, Palette.terracotta, Palette.ochre, Palette.slate, Palette.plum, Color(light: 0x3F7D5F, dark: 0x86C2A3), Color(light: 0x8C6A4F, dark: 0xC9A88C), Color(light: 0x5E6E7E, dark: 0xA6B4C2)]

    static func themeColor(_ t: LocationTheme) -> Color {
        switch t {
        case .grove: return mint
        case .tower: return sky
        case .castle: return accent
        case .harbor: return Palette.slate
        case .observatory: return Palette.plum
        case .garden: return mint
        case .workshop: return Palette.ochre
        case .library: return coral
        }
    }

    static let heroGradient = LinearGradient(colors: [Palette.forest, Palette.forest.opacity(0.85)], startPoint: .topLeading, endPoint: .bottomTrailing)
}

/// Reading text that honours the learner's accessibility preferences.
struct ReadingText: View {
    @Environment(AppStore.self) private var store
    var text: String
    var size: CGFloat = 19

    var body: some View {
        let s = store.settings
        Text(Self.attributed(text))
            .font(s.dyslexiaFriendly ? .system(size: size * s.textScale, weight: .regular, design: .rounded) : .system(size: size * s.textScale, design: .serif))
            .tracking(s.dyslexiaFriendly ? 0.8 : 0)
            .lineSpacing(s.dyslexiaFriendly ? 10 : 6)
            .foregroundStyle(s.highContrast ? Color.primary : Theme.ink.opacity(0.92))
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
    }

    static func attributed(_ s: String) -> AttributedString {
        (try? AttributedString(markdown: s, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(s)
    }
}

struct Card<Content: View>: View {
    var padding: CGFloat = 20
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(padding)
            .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Palette.surface))
            .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
    }
}

/// Clear disclosure whenever AI produced or shaped what the learner sees.
struct AIBadge: View {
    var text = "AI-assisted"
    var detail: String
    @State private var show = false
    var body: some View {
        Button { show.toggle() } label: {
            HStack(spacing: 4) {
                Image(systemName: "sparkle").font(.system(size: 9.5, weight: .bold))
                Text(text).font(.ui(12, .semibold))
                Image(systemName: "info.circle").font(.system(size: 10, weight: .semibold)).opacity(0.7)
            }
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(Capsule().fill(Palette.plumSoft))
            .foregroundStyle(Palette.plum)
        }
        .buttonStyle(.plain)
        .accessibilityHint("Shows what informed this AI output")
        .popover(isPresented: $show) {
            VStack(alignment: .leading, spacing: 10) {
                Label("What informed this", systemImage: "info.circle").font(.mHeadline)
                Text(detail).font(.mCallout).fixedSize(horizontal: false, vertical: true)
                Divider()
                Text("You stay in charge: you can ask for another explanation, change the help level, or turn AI off in Settings.")
                    .font(.mFootnote).foregroundStyle(Palette.inkSoft).fixedSize(horizontal: false, vertical: true)
            }
            .padding(20).frame(width: 340)
        }
    }
}

struct MasteryRing: View {
    var value: Double
    var size: CGFloat = 54
    var color: Color = Theme.mint
    var body: some View {
        ZStack {
            Circle().stroke(color.opacity(0.18), lineWidth: size * 0.12)
            Circle().trim(from: 0, to: value).stroke(color, style: StrokeStyle(lineWidth: size * 0.12, lineCap: .round)).rotationEffect(.degrees(-90))
            Text("\(Int(value * 100))%").font(.ui(size * 0.26, .bold)).monospacedDigit()
        }
        .frame(width: size, height: size)
        .animation(.spring, value: value)
        .accessibilityElement().accessibilityLabel("Mastery \(Int(value * 100)) percent")
    }
}

struct PillButtonStyle: ButtonStyle {
    var color: Color = Theme.accent
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.ui(16, .semibold))
            .padding(.horizontal, 20).padding(.vertical, 13)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(color))
            .foregroundStyle(Palette.onAccent)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct AvatarView: View {
    var emoji: String
    var colorIndex: Int
    var size: CGFloat = 56
    var body: some View {
        Text(emoji)
            .font(.system(size: size * 0.58))
            .frame(width: size, height: size)
            .background(Circle().fill(Theme.avatarColors[colorIndex % Theme.avatarColors.count].gradient))
            .overlay(Circle().stroke(.white, lineWidth: size * 0.06))
            .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
    }
}

extension View {
    func toast(_ text: Binding<String?>) -> some View {
        overlay(alignment: .top) {
            if let t = text.wrappedValue {
                Text(t)
                    .font(.mHeadline)
                    .padding(.horizontal, 20).padding(.vertical, 12)
                    .background(.regularMaterial, in: Capsule())
                    .shadow(radius: 8)
                    .padding(.top, 20)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .task(id: t) {
                        try? await Task.sleep(nanoseconds: 2_600_000_000)
                        withAnimation { text.wrappedValue = nil }
                    }
            }
        }
        .animation(.spring, value: text.wrappedValue)
    }
}

extension View {
    /// Big, page-sized sheets on iPad (iOS 18+); standard large sheets on iOS 17.
    @ViewBuilder func pageSheet() -> some View {
        if #available(iOS 18.0, *) { self.presentationSizing(.page) } else { self.presentationDetents([.large]) }
    }
}
