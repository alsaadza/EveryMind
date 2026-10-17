import SwiftUI

// MARK: - Venn

struct VennView: View {
    var labels: [String]
    var a: Double, b: Double, both: Double, neither: Double
    enum Region: String { case onlyA, onlyB, both, union }
    @State private var selected: Region?

    var body: some View {
        let total = a + b + both + neither
        HStack(spacing: 28) {
            ZStack {
                RoundedRectangle(cornerRadius: 16).stroke(Color.secondary.opacity(0.4)).frame(width: 330, height: 220)
                Text("Neither: \(Int(neither))").font(.mCaption).foregroundStyle(Palette.inkSoft).offset(x: 110, y: 92)
                Circle().fill(Theme.coral.opacity(highlight(.onlyA) ? 0.6 : 0.3)).frame(width: 170).offset(x: -50)
                Circle().fill(Theme.sky.opacity(highlight(.onlyB) ? 0.6 : 0.3)).frame(width: 170).offset(x: 50)
                Text("\(Int(a))").font(.mTitle).offset(x: -95)
                Text("\(Int(b))").font(.mTitle).offset(x: 95)
                Text("\(Int(both))").font(.mTitle).padding(8).background(Circle().fill(highlight(.both) ? Theme.accent.opacity(0.5) : .clear)).offset(x: 0)
                Text(labels[0]).font(.mHeadline).offset(x: -80, y: -98)
                Text(labels[1]).font(.mHeadline).offset(x: 80, y: -98)
            }
            .frame(width: 340, height: 230)
            .accessibilityElement().accessibilityLabel("Venn diagram. Only \(labels[0]): \(Int(a)). Only \(labels[1]): \(Int(b)). Both: \(Int(both)). Neither: \(Int(neither)).")
            VStack(alignment: .leading, spacing: 10) {
                Text("Tap to explore").font(.ui(14, .semibold))
                row(.onlyA, "P(\(labels[0]))", a + both, total)
                row(.onlyB, "P(\(labels[1]))", b + both, total)
                row(.both, "P(\(labels[0]) and \(labels[1]))", both, total)
                row(.union, "P(\(labels[0]) or \(labels[1]))", a + b + both, total)
                if selected == .union {
                    Text("Addition rule: \(Int(a + both))/\(Int(total)) + \(Int(b + both))/\(Int(total)) − \(Int(both))/\(Int(total)). Subtract the overlap so it isn't counted twice.")
                        .font(.mFootnote).foregroundStyle(Palette.inkSoft).fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func highlight(_ r: Region) -> Bool {
        guard let s = selected else { return false }
        if s == .union { return true }
        if s == .both { return r == .both }
        return s == r
    }

    private func row(_ r: Region, _ title: String, _ n: Double, _ total: Double) -> some View {
        Button { withAnimation { selected = selected == r ? nil : r } } label: {
            HStack {
                Text(title).font(.mCallout)
                Spacer()
                Text("\(Int(n))/\(Int(total))").font(.callout.monospacedDigit().bold())
            }
            .padding(10).frame(width: 300)
            .background(RoundedRectangle(cornerRadius: 10).fill(selected == r ? Theme.accent.opacity(0.15) : Palette.surfaceSunk))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Probability tree

struct ProbabilityTreeView: View {
    var labels: [String]
    @State var p: Double
    @State private var path: (Int, Int)?

    init(labels: [String], p: Double) { self.labels = labels; _p = State(initialValue: p) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            GeometryReader { g in
                let w = g.size.width, h = g.size.height
                let root = CGPoint(x: 30, y: h / 2)
                let mids = [CGPoint(x: w * 0.38, y: h * 0.25), CGPoint(x: w * 0.38, y: h * 0.75)]
                let leaves = [CGPoint(x: w * 0.74, y: h * 0.1), CGPoint(x: w * 0.74, y: h * 0.38), CGPoint(x: w * 0.74, y: h * 0.62), CGPoint(x: w * 0.74, y: h * 0.9)]
                let probs = [p, 1 - p]
                ZStack {
                    ForEach(0..<2, id: \.self) { i in
                        line(root, mids[i], on: path?.0 == i)
                        Text(String(format: "%.2f", probs[i])).font(.ui(12, .bold)).position(x: (root.x + mids[i].x) / 2 - 8, y: (root.y + mids[i].y) / 2 - 12)
                        ForEach(0..<2, id: \.self) { j in
                            line(mids[i], leaves[i * 2 + j], on: path?.0 == i && path?.1 == j)
                            Text(String(format: "%.2f", probs[j])).font(.ui(12, .bold)).position(x: (mids[i].x + leaves[i * 2 + j].x) / 2, y: (mids[i].y + leaves[i * 2 + j].y) / 2 - 10)
                            Button { withAnimation { path = (i, j) } } label: {
                                Text("\(labels[i].prefix(1))\(labels[j].prefix(1))  = \(String(format: "%.3f", probs[i] * probs[j]))")
                                    .font(.callout.monospacedDigit().bold())
                                    .padding(.horizontal, 10).padding(.vertical, 6)
                                    .background(Capsule().fill(path?.0 == i && path?.1 == j ? Theme.accent : Palette.surfaceSunk))
                                    .foregroundStyle(path?.0 == i && path?.1 == j ? .white : .primary)
                            }
                            .buttonStyle(.plain)
                            .position(x: leaves[i * 2 + j].x + 70, y: leaves[i * 2 + j].y)
                            .accessibilityLabel("\(labels[i]) then \(labels[j]), probability \(String(format: "%.3f", probs[i] * probs[j]))")
                        }
                        Text(labels[i]).font(.ui(14, .semibold)).padding(6).background(Capsule().fill(Theme.sun.opacity(0.3))).position(mids[i])
                    }
                    Circle().fill(Theme.ink).frame(width: 14).position(root)
                }
            }
            .frame(height: 240)
            if let path {
                Text("\(labels[path.0]) then \(labels[path.1]): multiply along the branches, \(String(format: "%.2f", path.0 == 0 ? p : 1 - p)) × \(String(format: "%.2f", path.1 == 0 ? p : 1 - p)) = \(String(format: "%.3f", (path.0 == 0 ? p : 1 - p) * (path.1 == 0 ? p : 1 - p)))")
                    .font(.callout.bold())
            } else {
                Text("Tap an outcome on the right to follow its path.").font(.mCallout).foregroundStyle(Palette.inkSoft)
            }
            HStack {
                Text("P(\(labels[0])) = \(String(format: "%.2f", p))").monospacedDigit()
                Slider(value: $p, in: 0.05...0.95, step: 0.05)
            }
            Text("All four outcomes always add up to 1. Try moving the slider.").font(.mFootnote).foregroundStyle(Palette.inkSoft)
        }
    }

    private func line(_ a: CGPoint, _ b: CGPoint, on: Bool) -> some View {
        Path { $0.move(to: a); $0.addLine(to: b) }.stroke(on ? Theme.accent : Color.secondary.opacity(0.5), lineWidth: on ? 4 : 2)
    }
}

// MARK: - Number line

struct NumberLineView: View {
    var value: Double
    var label: String
    @State private var guess = 0.5
    @State private var revealed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(label.isEmpty ? "Drag the marker to your estimate, then reveal." : "Where does “\(label)” go? Drag your marker, then reveal.").font(.ui(14, .semibold))
            GeometryReader { g in
                let w = g.size.width
                ZStack(alignment: .leading) {
                    Capsule().fill(LinearGradient(colors: [Palette.terracotta, Palette.ochre, Palette.forest], startPoint: .leading, endPoint: .trailing)).frame(height: 14).offset(y: 0)
                    ForEach(0..<5) { i in
                        VStack(spacing: 4) {
                            Rectangle().fill(Theme.ink).frame(width: 2, height: 20)
                            Text(["0\nimpossible", "¼\nunlikely", "½\neven", "¾\nlikely", "1\ncertain"][i]).font(.ui(11)).multilineTextAlignment(.center).fixedSize()
                        }
                        .position(x: w * CGFloat(i) / 4, y: 34)
                    }
                    Image(systemName: "person.fill").font(.mTitle2).foregroundStyle(Theme.accent)
                        .padding(6).background(Circle().fill(.white).shadow(radius: 2))
                        .position(x: w * guess, y: -22)
                        .gesture(DragGesture().onChanged { v in guess = min(1, max(0, v.location.x / w)); revealed = false })
                        .accessibilityLabel("Your estimate").accessibilityValue("\(Int(guess * 100)) percent")
                        .accessibilityAdjustableAction { dir in guess = min(1, max(0, guess + (dir == .increment ? 0.05 : -0.05))) }
                    if revealed {
                        Image(systemName: "star.fill").font(.mTitle2).foregroundStyle(Theme.sun)
                            .padding(6).background(Circle().fill(Theme.ink))
                            .position(x: w * value, y: -22)
                            .transition(.scale)
                    }
                }
            }
            .frame(height: 70)
            .padding(.top, 34).padding(.horizontal, 20)
            HStack {
                Button(revealed ? "Hide" : "Reveal") { withAnimation(.spring) { revealed.toggle() } }.buttonStyle(.borderedProminent)
                if revealed {
                    Text("Your estimate: \(Int(guess * 100))%. Book value: \(Int(value * 100))%. \(abs(guess - value) < 0.1 ? "Great estimate!" : "What made you place it there?")")
                        .font(.mCallout)
                }
            }
        }
    }
}

// MARK: - Fraction bar

struct FractionBarView: View {
    @State var numerator: Int
    @State var denominator: Int
    init(numerator: Int, denominator: Int) { _numerator = State(initialValue: numerator); _denominator = State(initialValue: max(1, denominator)) }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 3) {
                ForEach(0..<denominator, id: \.self) { i in
                    Button { numerator = i < numerator ? i : i + 1 } label: {
                        RoundedRectangle(cornerRadius: 6).fill(i < numerator ? Theme.accent : Palette.surfaceSunk)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.accent.opacity(0.5), lineWidth: 1.5))
                            .frame(height: 64)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Part \(i + 1) of \(denominator), \(i < numerator ? "shaded" : "not shaded")")
                }
            }
            .animation(.spring, value: numerator)
            .animation(.spring, value: denominator)
            HStack(spacing: 22) {
                VStack(spacing: 0) {
                    Text("\(numerator)").font(.mTitle)
                    Rectangle().frame(width: 36, height: 3)
                    Text("\(denominator)").font(.mTitle)
                }
                VStack(alignment: .leading) {
                    Text("Decimal: \(String(format: "%.3f", Double(numerator) / Double(denominator)))").monospacedDigit()
                    Text("Percent: \(String(format: "%.1f", Double(numerator) / Double(denominator) * 100))%").monospacedDigit()
                    let g = gcd(numerator, denominator)
                    if g > 1 && numerator > 0 { Text("Simplest form: \(numerator / g)/\(denominator / g)").foregroundStyle(Theme.mint).bold() }
                }
                Spacer()
                Stepper("Parts: \(denominator)", value: $denominator, in: 1...16).frame(width: 200)
                    .onChange(of: denominator) { _, d in numerator = min(numerator, d) }
            }
            Text("Tap the parts to shade them. Change the number of parts and look for equal fractions.").font(.mFootnote).foregroundStyle(Palette.inkSoft)
        }
    }

    private func gcd(_ a: Int, _ b: Int) -> Int { b == 0 ? max(1, abs(a)) : gcd(b, a % b) }
}

// MARK: - Concept card

struct ConceptCardView: View {
    var points: [String]
    @State private var revealed = 1
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(points.enumerated()), id: \.offset) { i, pt in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(i + 1)").font(.mHeadline).foregroundStyle(.white).frame(width: 32, height: 32).background(Circle().fill(Theme.accent))
                    Text(pt).font(.ui(19, .medium)).fixedSize(horizontal: false, vertical: true)
                    Spacer()
                }
                .opacity(i < revealed ? 1 : 0.12)
                .blur(radius: i < revealed ? 0 : 3)
                .accessibilityHidden(i >= revealed)
            }
            if revealed < points.count {
                Button { withAnimation(.spring) { revealed += 1 } } label: { Label("Predict the next idea, then reveal", systemImage: "eye") }
                    .buttonStyle(.bordered)
            }
        }
    }
}

// MARK: - Water cycle

struct WaterCycleView: View {
    @State private var stage = 0
    private let stages: [(String, String, String)] = [
        ("Evaporation", "The sun heats water in oceans, lakes and puddles. It turns into invisible water vapor and rises.", "sun.max.fill"),
        ("Condensation", "High up, the air is cooler. The vapor cools into tiny droplets that gather around dust and form clouds.", "cloud.fill"),
        ("Precipitation", "Droplets join and grow heavy. They fall as rain, snow, sleet or hail.", "cloud.rain.fill"),
        ("Collection", "Water gathers in rivers, lakes, oceans and underground. Then the cycle starts again.", "water.waves")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            TimelineView(.animation) { ctx in
                let t = ctx.date.timeIntervalSinceReferenceDate
                Canvas { g, size in
                    let w = size.width, h = size.height
                    let ink = Palette.ink
                    g.fill(Path(CGRect(x: 0, y: 0, width: w, height: h)), with: .color(Palette.surface))
                    // Ocean: slate wash with engraved lines
                    let sea = Path(CGRect(x: 0, y: h * 0.72, width: w * 0.55, height: h * 0.28))
                    g.fill(sea, with: .color(Palette.slateSoft))
                    for k in 0..<4 {
                        var l = Path(); let y = h * 0.76 + CGFloat(k) * 12
                        l.move(to: CGPoint(x: 8, y: y)); l.addLine(to: CGPoint(x: w * 0.5 - CGFloat(k) * 14, y: y))
                        g.stroke(l, with: .color(Palette.slate.opacity(0.5)), lineWidth: 1)
                    }
                    var shore = Path(); shore.move(to: CGPoint(x: 0, y: h * 0.72)); shore.addLine(to: CGPoint(x: w * 0.55, y: h * 0.72))
                    g.stroke(shore, with: .color(ink.opacity(0.8)), lineWidth: 1.4)
                    // Hill with hatching
                    var hill = Path(); hill.move(to: CGPoint(x: w * 0.5, y: h)); hill.addQuadCurve(to: CGPoint(x: w, y: h * 0.45), control: CGPoint(x: w * 0.75, y: h * 0.3)); hill.addLine(to: CGPoint(x: w, y: h)); hill.closeSubpath()
                    g.fill(hill, with: .color(Palette.forestSoft))
                    g.stroke(hill, with: .color(ink.opacity(0.8)), lineWidth: 1.4)
                    for k in 0..<10 {
                        var hl = Path(); let x = w * 0.7 + CGFloat(k) * w * 0.03
                        hl.move(to: CGPoint(x: x, y: h * 0.62 + CGFloat(k % 3) * 6)); hl.addLine(to: CGPoint(x: x - 6, y: h * 0.62 + 14 + CGFloat(k % 3) * 6))
                        g.stroke(hl, with: .color(ink.opacity(0.3)), lineWidth: 1)
                    }
                    // Sun with inked rays
                    let sc = CGPoint(x: 60, y: 50)
                    g.fill(Path(ellipseIn: CGRect(x: sc.x - 24, y: sc.y - 24, width: 48, height: 48)), with: .color(Palette.ochre.opacity(stage == 0 ? 1 : 0.55)))
                    g.stroke(Path(ellipseIn: CGRect(x: sc.x - 24, y: sc.y - 24, width: 48, height: 48)), with: .color(ink.opacity(0.8)), lineWidth: 1.3)
                    for r in 0..<12 {
                        let a = Double(r) / 12 * 2 * .pi
                        var ray = Path(); ray.move(to: CGPoint(x: sc.x + cos(a) * 30, y: sc.y + sin(a) * 30)); ray.addLine(to: CGPoint(x: sc.x + cos(a) * 40, y: sc.y + sin(a) * 40))
                        g.stroke(ray, with: .color(ink.opacity(0.6)), lineWidth: 1.2)
                    }
                    // vapor rising
                    for i in 0..<6 {
                        let phase = (t * 0.4 + Double(i) / 6).truncatingRemainder(dividingBy: 1)
                        let y = h * 0.72 - CGFloat(phase) * h * 0.5
                        var curl = Path(); curl.move(to: CGPoint(x: w * 0.12 + CGFloat(i) * 40, y: y + 10)); curl.addQuadCurve(to: CGPoint(x: w * 0.12 + CGFloat(i) * 40, y: y - 10), control: CGPoint(x: w * 0.12 + CGFloat(i) * 40 + 8, y: y))
                        g.stroke(curl, with: .color(Palette.slate.opacity((stage == 0 ? 0.9 : 0.35) * (1 - phase))), lineWidth: 1.5)
                    }
                    // cloud
                    let cx = w * 0.58
                    for (dx, dy, r) in [(0.0, 0.0, 40.0), (40, -12, 46), (85, 0, 38), (40, 12, 40)] {
                        g.stroke(Path(ellipseIn: CGRect(x: cx + dx - r, y: h * 0.2 + dy - r * 0.6, width: r * 2, height: r * 1.3)), with: .color(Palette.ink.opacity(0.75)), lineWidth: 1.3)
                    }
                    for (dx, dy, r) in [(0.0, 0.0, 40.0), (40, -12, 46), (85, 0, 38), (40, 12, 40)] {
                        g.fill(Path(ellipseIn: CGRect(x: cx + dx - r + 1, y: h * 0.2 + dy - r * 0.6 + 1, width: r * 2 - 2, height: r * 1.3 - 2)), with: .color(stage == 1 ? Palette.slateSoft : Palette.surfaceSunk))
                    }
                    // rain
                    if stage >= 2 {
                        for i in 0..<14 {
                            let phase = (t * 1.5 + Double(i) / 14).truncatingRemainder(dividingBy: 1)
                            let x = cx - 30 + CGFloat(i) * 11
                            let y = h * 0.3 + CGFloat(phase) * h * 0.4
                            g.stroke(Path { $0.move(to: CGPoint(x: x, y: y)); $0.addLine(to: CGPoint(x: x - 3, y: y + 12)) }, with: .color(Palette.slate), lineWidth: 1.6)
                        }
                    }
                    // runoff
                    if stage == 3 {
                        var river = Path(); river.move(to: CGPoint(x: w * 0.92, y: h * 0.5)); river.addCurve(to: CGPoint(x: w * 0.52, y: h * 0.8), control1: CGPoint(x: w * 0.8, y: h * 0.75), control2: CGPoint(x: w * 0.7, y: h * 0.6))
                        g.stroke(river, with: .color(Palette.ink.opacity(0.7)), style: StrokeStyle(lineWidth: 9, lineCap: .round))
                        g.stroke(river, with: .color(Palette.slateSoft), style: StrokeStyle(lineWidth: 7, lineCap: .round))
                        g.stroke(river, with: .color(Palette.slate), style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [6, 8], dashPhase: CGFloat(-t * 30)))
                    }
                }
            }
            .frame(height: 230)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Palette.ink.opacity(0.6), lineWidth: 1.2))
            .accessibilityLabel("Animated water cycle showing \(stages[stage].0)")
            HStack {
                ForEach(stages.indices, id: \.self) { i in
                    Button { withAnimation { stage = i } } label: {
                        Label(stages[i].0, systemImage: stages[i].2).font(.ui(14, .semibold))
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .background(Capsule().fill(stage == i ? Palette.ink : Palette.surfaceSunk))
                            .foregroundStyle(stage == i ? Palette.onAccent : Palette.ink)
                    }
                    .buttonStyle(.plain)
                }
            }
            Text(stages[stage].1).font(.mCallout)
        }
    }
}
