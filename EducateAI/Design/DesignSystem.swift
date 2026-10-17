import SwiftUI
import UIKit

// MARK: - Brand

enum Brand {
    static let name = "Margin"
    static let tagline = "Room for every learner."
}

// MARK: - Palette
// Warm paper and ink. Every colour adapts to dark mode.

extension Color {
    init(light: UInt32, dark: UInt32) {
        self.init(UIColor { t in UIColor(hex: t.userInterfaceStyle == .dark ? dark : light) })
    }
}

extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255, blue: CGFloat(hex & 0xFF) / 255, alpha: alpha)
    }
}

enum Palette {
    static let paper = Color(light: 0xF6F1E7, dark: 0x16171B)
    static let paperDeep = Color(light: 0xEDE6D8, dark: 0x111216)
    static let surface = Color(light: 0xFFFDF8, dark: 0x1F2127)
    static let surfaceSunk = Color(light: 0xF1EBDF, dark: 0x1A1C21)
    static let ink = Color(light: 0x1D2230, dark: 0xEDE7DB)
    static let inkSoft = Color(light: 0x4A4F5C, dark: 0xBDB7AB)
    static let inkMuted = Color(light: 0x8A8476, dark: 0x8A867E)
    static let rule = Color(light: 0xE2D9C8, dark: 0x2E3038)
    static let ruleStrong = Color(light: 0xCFC4AF, dark: 0x3C3F48)

    static let forest = Color(light: 0x2E5E4E, dark: 0x7FB8A2)
    static let forestSoft = Color(light: 0xDCE8DF, dark: 0x22362F)
    static let terracotta = Color(light: 0xC2603F, dark: 0xE08A6B)
    static let terracottaSoft = Color(light: 0xF6E1D6, dark: 0x3A2620)
    static let ochre = Color(light: 0xC98F22, dark: 0xE2B354)
    static let ochreSoft = Color(light: 0xF6EAC9, dark: 0x382F1C)
    static let slate = Color(light: 0x4C6A92, dark: 0x8FAAD0)
    static let slateSoft = Color(light: 0xDFE6EF, dark: 0x222B38)
    static let plum = Color(light: 0x6E5A8A, dark: 0xB5A1D3)
    static let plumSoft = Color(light: 0xE9E3F1, dark: 0x2B2536)

    /// Ink on a coloured fill (buttons). Cream in light mode, near-black in dark mode.
    static let onAccent = Color(light: 0xFFFDF8, dark: 0x111216)

    static func tint(_ t: PageTint) -> Color {
        switch t {
        case .paper: return surface
        case .cream: return Color(light: 0xFBF3DC, dark: 0x24221B)
        case .peach: return Color(light: 0xFCE9DE, dark: 0x2A211D)
        case .mint: return Color(light: 0xE6F2EA, dark: 0x1C2621)
        case .sky: return Color(light: 0xE5EEF7, dark: 0x1C232C)
        case .night: return Color(light: 0x22252D, dark: 0x0E0F12)
        }
    }
    static func tintInk(_ t: PageTint) -> Color { t == .night ? Color(light: 0xE8E2D4, dark: 0xE8E2D4) : ink }

    static let avatarTints: [Color] = [forestSoft, terracottaSoft, ochreSoft, slateSoft, plumSoft]
}

// MARK: - Typography

enum Typeface {
    static let display = "Fraunces-Regular"
    static let displaySemibold = "Fraunces-SemiBold"
    static let displayBold = "Fraunces-Bold"
    static let displayItalic = "Fraunces-Italic"
    static let serif = "SourceSerif4-Regular"
    static let serifSemibold = "SourceSerif4-SemiBold"
    static let serifItalic = "SourceSerif4-Italic"
    static let ui = "Figtree-Regular"
    static let uiMedium = "Figtree-Medium"
    static let uiSemibold = "Figtree-SemiBold"
    static let uiBold = "Figtree-Bold"
    static let lexend = "Lexend-Regular"
    static let lexendMedium = "Lexend-Medium"
    static let lexendSemibold = "Lexend-SemiBold"
    static let atkinson = "AtkinsonHyperlegible-Regular"
    static let atkinsonBold = "AtkinsonHyperlegible-Bold"
    static let openDyslexic = "OpenDyslexic-Regular"
    static let openDyslexicBold = "OpenDyslexic-Bold"

    static func reading(_ f: ReadingFont, bold: Bool = false) -> String {
        switch f {
        case .serif: return bold ? serifSemibold : serif
        case .lexend: return bold ? lexendSemibold : lexend
        case .openDyslexic: return bold ? openDyslexicBold : openDyslexic
        case .atkinson: return bold ? atkinsonBold : atkinson
        }
    }
}

extension Font {
    /// Editorial display face (Fraunces). Scales with Dynamic Type.
    static func display(_ size: CGFloat, _ weight: Font.Weight = .regular, relativeTo style: Font.TextStyle = .title) -> Font {
        let name = weight == .bold || weight == .heavy || weight == .black ? Typeface.displayBold : weight == .semibold || weight == .medium ? Typeface.displaySemibold : Typeface.display
        return .custom(name, size: size, relativeTo: style)
    }
    static func displayItalic(_ size: CGFloat, relativeTo style: Font.TextStyle = .title) -> Font { .custom(Typeface.displayItalic, size: size, relativeTo: style) }

    /// Interface face (Figtree).
    static func ui(_ size: CGFloat, _ weight: Font.Weight = .regular, relativeTo style: Font.TextStyle = .body) -> Font {
        let name: String
        switch weight {
        case .bold, .heavy, .black: name = Typeface.uiBold
        case .semibold: name = Typeface.uiSemibold
        case .medium: name = Typeface.uiMedium
        default: name = Typeface.ui
        }
        return .custom(name, size: size, relativeTo: style)
    }

    static func reading(_ f: ReadingFont, _ size: CGFloat, bold: Bool = false) -> Font { .custom(Typeface.reading(f, bold: bold), size: size, relativeTo: .body) }

    // Semantic shorthands
    static let mLargeTitle = Font.display(44, .regular, relativeTo: .largeTitle)
    static let mTitle = Font.display(32, .regular, relativeTo: .title)
    static let mTitle2 = Font.display(25, .regular, relativeTo: .title2)
    static let mTitle3 = Font.display(20, .semibold, relativeTo: .title3)
    static let mHeadline = Font.ui(16, .semibold, relativeTo: .headline)
    static let mBody = Font.ui(16, .regular, relativeTo: .body)
    static let mCallout = Font.ui(15, .regular, relativeTo: .callout)
    static let mSubheadline = Font.ui(14, .regular, relativeTo: .subheadline)
    static let mFootnote = Font.ui(13, .regular, relativeTo: .footnote)
    static let mCaption = Font.ui(12, .medium, relativeTo: .caption)
}

// MARK: - Surfaces

struct PaperBackground: View {
    var color: Color = Palette.paper
    var body: some View {
        color
            .overlay(Image("paper-grain").resizable(resizingMode: .tile).opacity(0.55).blendMode(.multiply).allowsHitTesting(false))
            .ignoresSafeArea()
    }
}

struct Surface<Content: View>: View {
    var padding: CGFloat = 20
    var radius: CGFloat = 16
    var fill: Color = Palette.surface
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: radius, style: .continuous).fill(fill))
            .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).strokeBorder(Palette.rule, lineWidth: 1))
            .shadow(color: Color.black.opacity(0.035), radius: 12, y: 6)
    }
}

struct Eyebrow: View {
    var text: String
    var color: Color = Palette.inkMuted
    init(_ text: String, color: Color = Palette.inkMuted) { self.text = text; self.color = color }
    var body: some View {
        Text(text.uppercased())
            .font(.ui(11.5, .semibold, relativeTo: .caption))
            .tracking(1.4)
            .foregroundStyle(color)
    }
}

struct Rule: View {
    var color: Color = Palette.rule
    var body: some View { Rectangle().fill(color).frame(height: 1) }
}

struct Tag: View {
    var text: String
    var symbol: String? = nil
    var color: Color = Palette.inkSoft
    var fill: Color? = nil
    var body: some View {
        HStack(spacing: 5) {
            if let symbol { Image(systemName: symbol).font(.system(size: 10.5, weight: .semibold)) }
            Text(text).font(.ui(12, .semibold, relativeTo: .caption))
        }
        .padding(.horizontal, 9).padding(.vertical, 4.5)
        .foregroundStyle(color)
        .background(Capsule().fill(fill ?? color.opacity(0.1)))
    }
}

/// The one consistent mark for anything AI drafted.
struct AIMark: View {
    var text = "AI draft"
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "sparkle").font(.system(size: 9.5, weight: .bold))
            Text(text).font(.ui(11.5, .semibold, relativeTo: .caption))
        }
        .padding(.horizontal, 8).padding(.vertical, 3.5)
        .foregroundStyle(Palette.plum)
        .background(Capsule().fill(Palette.plumSoft))
        .accessibilityLabel(text)
    }
}

struct SectionHeader<Trailing: View>: View {
    var eyebrow: String? = nil
    var title: String
    var subtitle: String? = nil
    @ViewBuilder var trailing: Trailing
    var body: some View {
        HStack(alignment: .lastTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                if let eyebrow { Eyebrow(eyebrow) }
                Text(title).font(.mTitle2).foregroundStyle(Palette.ink)
                if let subtitle { Text(subtitle).font(.mSubheadline).foregroundStyle(Palette.inkSoft) }
            }
            Spacer(minLength: 12)
            trailing
        }
    }
}
extension SectionHeader where Trailing == EmptyView {
    init(eyebrow: String? = nil, title: String, subtitle: String? = nil) { self.init(eyebrow: eyebrow, title: title, subtitle: subtitle) { EmptyView() } }
}

struct StatBlock: View {
    var value: String
    var label: String
    var note: String? = nil
    var color: Color = Palette.ink
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Eyebrow(label)
            Text(value).font(.display(40, .regular, relativeTo: .largeTitle)).foregroundStyle(color).monospacedDigit()
                .minimumScaleFactor(0.6).lineLimit(1)
            if let note { Text(note).font(.mFootnote).foregroundStyle(Palette.inkSoft).fixedSize(horizontal: false, vertical: true) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

struct Meter: View {
    var value: Double
    var color: Color = Palette.forest
    var height: CGFloat = 6
    var body: some View {
        GeometryReader { g in
            ZStack(alignment: .leading) {
                Capsule().fill(Palette.rule)
                Capsule().fill(color).frame(width: max(height, g.size.width * min(1, max(0, value))))
                    .opacity(value <= 0 ? 0 : 1)
            }
        }
        .frame(height: height)
        .accessibilityElement().accessibilityValue("\(Int(value * 100)) percent")
    }
}

// MARK: - Buttons

struct PrimaryButtonStyle: ButtonStyle {
    var color: Color = Palette.forest
    var compact = false
    @Environment(\.isEnabled) private var enabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.ui(compact ? 14.5 : 16, .semibold, relativeTo: .headline))
            .padding(.horizontal, compact ? 14 : 20).padding(.vertical, compact ? 9 : 13)
            .foregroundStyle(Palette.onAccent)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(color.opacity(enabled ? 1 : 0.35)))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    var color: Color = Palette.ink
    var compact = false
    @Environment(\.isEnabled) private var enabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.ui(compact ? 14.5 : 16, .semibold, relativeTo: .headline))
            .padding(.horizontal, compact ? 14 : 20).padding(.vertical, compact ? 9 : 13)
            .foregroundStyle(color.opacity(enabled ? 1 : 0.4))
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(configuration.isPressed ? Palette.surfaceSunk : Palette.surface))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Palette.ruleStrong, lineWidth: 1))
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
    static func primary(_ color: Color, compact: Bool = false) -> PrimaryButtonStyle { PrimaryButtonStyle(color: color, compact: compact) }
}
extension ButtonStyle where Self == SecondaryButtonStyle {
    static var secondary: SecondaryButtonStyle { SecondaryButtonStyle() }
    static func secondary(compact: Bool) -> SecondaryButtonStyle { SecondaryButtonStyle(compact: compact) }
}

// MARK: - Art & people

/// Public-domain artwork used as a cover, with optional bottom scrim for overlaid text.
struct ArtCover: View {
    var asset: String
    var height: CGFloat? = 180
    var radius: CGFloat = 14
    var scrim = false
    var body: some View {
        Color.clear
            .frame(height: height)
            .frame(maxWidth: .infinity)
            .overlay(Image(asset).resizable().scaledToFill())
            .overlay {
                if scrim { LinearGradient(colors: [.clear, .black.opacity(0.55)], startPoint: .center, endPoint: .bottom) }
            }
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .accessibilityHidden(true)
    }
}

struct ArtCredit: View {
    var asset: String
    var body: some View {
        let p = ArtCatalog.piece(asset)
        Text("\(p.title), \(p.artist), \(p.date). \(p.source)")
            .font(.ui(11, .regular, relativeTo: .caption2))
            .italic()
            .foregroundStyle(Palette.inkMuted)
            .lineLimit(1)
    }
}

struct PersonAvatar: View {
    var asset: String
    var name: String
    var size: CGFloat = 40
    var body: some View {
        let stable = name.unicodeScalars.reduce(0) { $0 + Int($1.value) } % Palette.avatarTints.count
        return ZStack {
            Circle().fill(Palette.avatarTints[stable])
            if UIImage(named: asset) != nil {
                Image(asset).resizable().scaledToFit().padding(size * 0.04).clipShape(Circle())
            } else {
                Text(name.split(separator: " ").compactMap(\.first).prefix(2).map(String.init).joined())
                    .font(.ui(size * 0.38, .semibold)).foregroundStyle(Palette.ink)
            }
        }
        .frame(width: size, height: size)
        .overlay(Circle().strokeBorder(Palette.surface, lineWidth: max(1.5, size * 0.04)))
        .accessibilityLabel(name)
    }
}

// MARK: - Helpers

extension Date {
    var dueLabel: String {
        let cal = Calendar.current
        if cal.isDateInToday(self) { return "Due today" }
        if cal.isDateInTomorrow(self) { return "Due tomorrow" }
        let days = cal.dateComponents([.day], from: cal.startOfDay(for: Date()), to: cal.startOfDay(for: self)).day ?? 0
        if days < 0 { return "Was due \(formatted(.dateTime.month(.abbreviated).day()))" }
        if days < 7 { return "Due \(formatted(.dateTime.weekday(.wide)))" }
        return "Due \(formatted(.dateTime.month(.abbreviated).day()))"
    }
    var shortRelative: String { formatted(.relative(presentation: .named, unitsStyle: .abbreviated)) }
}

extension View {
    func paperNavigation() -> some View {
        self.toolbarBackground(Palette.paper, for: .navigationBar)
    }
}
