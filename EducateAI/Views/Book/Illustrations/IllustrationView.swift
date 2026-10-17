import SwiftUI
import Charts

struct IllustrationView: View {
    var illustration: Illustration

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) { Image(systemName: "hand.tap").font(.system(size: 11, weight: .semibold)); Eyebrow("Try it", color: Palette.forest) }
                    .foregroundStyle(Palette.forest)
                Spacer()
            }
            content
            if !illustration.caption.isEmpty {
                Text(illustration.caption).font(.custom(Typeface.serifItalic, size: 15)).foregroundStyle(Palette.inkSoft).fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(22)
        .background(RoundedRectangle(cornerRadius: 16).fill(Palette.surface))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Palette.rule))
        .environment(\.colorScheme, .light)
    }

    @ViewBuilder private var content: some View {
        let p = illustration.params ?? [:]
        let l = illustration.labels ?? []
        switch illustration.kind {
        case .coinFlip: CoinFlipSim(bias: p["bias"] ?? 0.5)
        case .diceRoll: DiceSim(dice: Int(p["dice"] ?? 1))
        case .spinner: SpinnerSim(labels: l.isEmpty ? ["Red", "Blue", "Green", "Yellow"] : l)
        case .cardDraw: CardDrawSim()
        case .venn: VennView(labels: l.count >= 2 ? l : ["A", "B"], a: p["a"] ?? 3, b: p["b"] ?? 12, both: p["both"] ?? 1, neither: p["neither"] ?? 36)
        case .probabilityTree: ProbabilityTreeView(labels: l.count >= 2 ? l : ["Heads", "Tails"], p: p["p"] ?? 0.5)
        case .numberLine: NumberLineView(value: p["value"] ?? 0.5, label: l.first ?? "")
        case .fractionBar: FractionBarView(numerator: Int(p["numerator"] ?? 1), denominator: Int(p["denominator"] ?? 4))
        case .conceptCard: ConceptCardView(points: l)
        case .waterCycle: WaterCycleView()
        }
    }
}

// MARK: - Coin

struct CoinFlipSim: View {
    var bias: Double
    @State private var flips: [Bool] = []
    @State private var spin = 0.0
    @State private var face = true
    @Environment(AppStore.self) private var store

    var body: some View {
        HStack(alignment: .top, spacing: 24) {
            VStack(spacing: 14) {
                ZStack {
                    Circle().fill(Palette.ochreSoft)
                    Circle().strokeBorder(Palette.ink.opacity(0.8), lineWidth: 1.6)
                    Circle().strokeBorder(Palette.ochre, lineWidth: 5).padding(7)
                    Circle().strokeBorder(Palette.ink.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [2, 3])).padding(14)
                    Text(face ? "H" : "T").font(.display(48, .semibold)).foregroundStyle(Palette.ink)
                }
                .frame(width: 120, height: 120)
                .rotation3DEffect(.degrees(spin), axis: (x: 1, y: 0, z: 0))
                .accessibilityLabel("Coin showing \(face ? "heads" : "tails")")
                HStack {
                    Button("Flip") { flip(1) }.buttonStyle(.borderedProminent)
                    Button("×10") { flip(10) }.buttonStyle(.bordered)
                    Button("×100") { flip(100) }.buttonStyle(.bordered)
                }
                Button("Reset") { flips = [] }.font(.mCaption)
                let h = flips.filter { $0 }.count
                Text("\(h) heads · \(flips.count - h) tails").font(.headline.monospacedDigit())
                if !flips.isEmpty { Text("Heads: \(String(format: "%.1f", Double(h) / Double(flips.count) * 100))%").font(.subheadline.monospacedDigit()).foregroundStyle(Palette.inkSoft) }
            }
            .frame(width: 220)
            VStack(alignment: .leading) {
                Text("Share of heads as you flip more").font(.ui(14, .semibold))
                Chart {
                    RuleMark(y: .value("Theory", bias)).foregroundStyle(Theme.coral).lineStyle(StrokeStyle(lineWidth: 2, dash: [6]))
                        .annotation(position: .top, alignment: .trailing) { Text("theory \(Int(bias * 100))%").font(.ui(11)).foregroundStyle(Theme.coral) }
                    ForEach(running, id: \.0) { n, share in
                        LineMark(x: .value("Flips", n), y: .value("Share of heads", share)).foregroundStyle(Theme.accent)
                    }
                }
                .chartYScale(domain: 0...1)
                .chartXAxisLabel("Number of flips")
                .frame(height: 220)
                Text(flips.count < 20 ? "Flip a lot. Watch what happens to the line." : "Notice the line settles near \(Int(bias * 100))%. That's the law of large numbers.")
                    .font(.mFootnote).foregroundStyle(Palette.inkSoft)
            }
        }
    }

    private var running: [(Int, Double)] {
        var out: [(Int, Double)] = []; var h = 0
        let step = max(1, flips.count / 200)
        for (i, f) in flips.enumerated() { if f { h += 1 }; if i % step == 0 || i == flips.count - 1 { out.append((i + 1, Double(h) / Double(i + 1))) } }
        return out
    }

    private func flip(_ n: Int) {
        let results = (0..<n).map { _ in Double.random(in: 0..<1) < bias }
        if store.settings.reduceMotion { face = results.last ?? true; flips += results; return }
        withAnimation(.easeInOut(duration: 0.6)) { spin += 720 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { face = results.last ?? true; flips += results }
    }
}

// MARK: - Dice

struct DiceSim: View {
    var dice: Int
    @State private var counts: [Int: Int] = [:]
    @State private var last: [Int] = [1, 1]
    @State private var wobble = 0.0
    var body: some View {
        let range = dice == 2 ? Array(2...12) : Array(1...6)
        let total = counts.values.reduce(0, +)
        HStack(alignment: .top, spacing: 24) {
            VStack(spacing: 14) {
                HStack(spacing: 14) {
                    ForEach(0..<max(1, min(2, dice)), id: \.self) { i in DieFace(value: last[i]).rotationEffect(.degrees(wobble * (i == 0 ? 1 : -1))) }
                }
                if dice == 2 { Text("Sum: \(last[0] + last[1])").font(.mHeadline) }
                HStack {
                    Button("Roll") { roll(1) }.buttonStyle(.borderedProminent)
                    Button("×10") { roll(10) }.buttonStyle(.bordered)
                    Button("×100") { roll(100) }.buttonStyle(.bordered)
                }
                Button("Reset") { counts = [:] }.font(.mCaption)
                Text("\(total) rolls").font(.subheadline.monospacedDigit()).foregroundStyle(Palette.inkSoft)
            }
            .frame(width: 220)
            VStack(alignment: .leading) {
                Text(dice == 2 ? "How often each sum appears" : "How often each face appears").font(.ui(14, .semibold))
                Chart {
                    ForEach(range, id: \.self) { v in
                        BarMark(x: .value("Outcome", "\(v)"), y: .value("Share", total == 0 ? 0 : Double(counts[v] ?? 0) / Double(total)))
                            .foregroundStyle(Palette.slate)
                        PointMark(x: .value("Outcome", "\(v)"), y: .value("Theory", theory(v)))
                            .foregroundStyle(Theme.coral).symbolSize(50)
                    }
                }
                .chartYAxisLabel("Share of rolls")
                .frame(height: 220)
                Text("Bars are your rolls. Red dots are the theoretical probability\(dice == 2 ? " (ways to make the sum ÷ 36)" : " (1/6 each)").")
                    .font(.mFootnote).foregroundStyle(Palette.inkSoft)
            }
        }
    }

    private func theory(_ v: Int) -> Double {
        dice == 2 ? Double(6 - abs(7 - v)) / 36 : 1.0 / 6
    }

    private func roll(_ n: Int) {
        var lastRoll = [1, 1]
        for _ in 0..<n {
            lastRoll = [Int.random(in: 1...6), Int.random(in: 1...6)]
            let key = dice == 2 ? lastRoll[0] + lastRoll[1] : lastRoll[0]
            counts[key, default: 0] += 1
        }
        last = lastRoll
        withAnimation(.interpolatingSpring(stiffness: 300, damping: 6)) { wobble = wobble == 0 ? 12 : 0 }
    }
}

struct DieFace: View {
    var value: Int
    var body: some View {
        let pips: [Int: [(CGFloat, CGFloat)]] = [
            1: [(0.5, 0.5)], 2: [(0.25, 0.25), (0.75, 0.75)], 3: [(0.25, 0.25), (0.5, 0.5), (0.75, 0.75)],
            4: [(0.25, 0.25), (0.75, 0.25), (0.25, 0.75), (0.75, 0.75)],
            5: [(0.25, 0.25), (0.75, 0.25), (0.5, 0.5), (0.25, 0.75), (0.75, 0.75)],
            6: [(0.25, 0.22), (0.75, 0.22), (0.25, 0.5), (0.75, 0.5), (0.25, 0.78), (0.75, 0.78)]
        ]
        return GeometryReader { g in
            ZStack {
                RoundedRectangle(cornerRadius: 16).fill(.white).shadow(radius: 3)
                RoundedRectangle(cornerRadius: 16).stroke(Color.black.opacity(0.15), lineWidth: 2)
                ForEach(Array((pips[value] ?? []).enumerated()), id: \.offset) { _, p in
                    Circle().fill(Theme.ink).frame(width: g.size.width * 0.18).position(x: p.0 * g.size.width, y: p.1 * g.size.height)
                }
            }
        }
        .frame(width: 80, height: 80)
        .accessibilityLabel("Die showing \(value)")
    }
}

// MARK: - Spinner

struct SpinnerSim: View {
    var labels: [String]
    @State private var angle = 0.0
    @State private var tally: [String: Int] = [:]
    @State private var result: String?
    private let colors: [Color] = [Palette.terracotta, Palette.slate, Palette.forest, Palette.ochre, Palette.plum, Color(light: 0x8C6A4F, dark: 0xC9A88C), Color(light: 0x5E8A86, dark: 0x9CC7C2), Color(light: 0xB0704A, dark: 0xD9A07E)]

    var body: some View {
        let unique = Array(NSOrderedSet(array: labels)) as? [String] ?? labels
        HStack(alignment: .top, spacing: 28) {
            VStack(spacing: 12) {
                ZStack {
                    Canvas { g, size in
                        let c = CGPoint(x: size.width / 2, y: size.height / 2), r = min(size.width, size.height) / 2
                        let n = labels.count
                        for i in 0..<n {
                            let a0 = Angle.degrees(Double(i) / Double(n) * 360 - 90), a1 = Angle.degrees(Double(i + 1) / Double(n) * 360 - 90)
                            var p = Path(); p.move(to: c); p.addArc(center: c, radius: r, startAngle: a0, endAngle: a1, clockwise: false); p.closeSubpath()
                            let ci = unique.firstIndex(of: labels[i]) ?? i
                            g.fill(p, with: .color(colors[ci % colors.count]))
                            g.stroke(p, with: .color(.white), lineWidth: 2)
                            let mid = (a0.radians + a1.radians) / 2
                            let tp = CGPoint(x: c.x + cos(mid) * r * 0.62, y: c.y + sin(mid) * r * 0.62)
                            g.draw(Text(labels[i]).font(.ui(12, .bold)).foregroundStyle(.white), at: tp)
                        }
                    }
                    .rotationEffect(.degrees(angle))
                    Image(systemName: "arrowtriangle.down.fill").font(.mTitle).foregroundStyle(Theme.ink).offset(y: -112)
                }
                .frame(width: 210, height: 210)
                .accessibilityLabel("Spinner with sections: \(labels.joined(separator: ", "))")
                HStack {
                    Button("Spin") { spin(1) }.buttonStyle(.borderedProminent)
                    Button("×20") { spin(20) }.buttonStyle(.bordered)
                    Button("Reset") { tally = [:]; result = nil }.buttonStyle(.bordered)
                }
                if let result { Text("Landed on \(result)").font(.mHeadline) }
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("Theory vs. your spins").font(.ui(14, .semibold))
                let total = tally.values.reduce(0, +)
                ForEach(unique, id: \.self) { u in
                    let share = Double(labels.filter { $0 == u }.count) / Double(labels.count)
                    HStack {
                        Circle().fill(colors[(unique.firstIndex(of: u) ?? 0) % colors.count]).frame(width: 14)
                        Text(u).frame(width: 100, alignment: .leading)
                        Text("P = \(labels.filter { $0 == u }.count)/\(labels.count)").monospacedDigit().frame(width: 80, alignment: .leading)
                        ProgressView(value: total == 0 ? 0 : Double(tally[u] ?? 0) / Double(total)).frame(width: 120)
                        Text(total == 0 ? "–" : "\(tally[u] ?? 0)").monospacedDigit()
                    }
                    .font(.mCallout)
                    .accessibilityElement(children: .combine)
                    .accessibilityValue("theoretical \(Int(share * 100)) percent")
                }
            }
        }
    }

    private func spin(_ n: Int) {
        var lastIdx = 0
        for _ in 0..<n {
            lastIdx = Int.random(in: 0..<labels.count)
            tally[labels[lastIdx], default: 0] += 1
        }
        // The pointer sits at the top, so rotate so the middle of the chosen sector lands under it.
        let sector = 360.0 / Double(labels.count)
        let targetMod = 360 - (Double(lastIdx) + 0.5) * sector
        let base = angle - angle.truncatingRemainder(dividingBy: 360) + 1080
        withAnimation(.easeOut(duration: n == 1 ? 1.6 : 0.8)) { angle = base + targetMod }
        DispatchQueue.main.asyncAfter(deadline: .now() + (n == 1 ? 1.6 : 0.8)) { result = labels[lastIdx] }
    }
}

// MARK: - Cards

struct CardDrawSim: View {
    struct PlayingCard: Hashable { var rank: String; var suit: String; var red: Bool { suit == "♥" || suit == "♦" } }
    static let fullDeck: [PlayingCard] = ["♠", "♥", "♦", "♣"].flatMap { s in ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"].map { PlayingCard(rank: $0, suit: s) } }
    @State private var deck = CardDrawSim.fullDeck.shuffled()
    @State private var drawn: [PlayingCard] = []
    @State private var replace = false

    var body: some View {
        let hearts = deck.filter { $0.suit == "♥" }.count
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 18) {
                ZStack {
                    ForEach(0..<min(5, deck.count), id: \.self) { i in
                        RoundedRectangle(cornerRadius: 10).fill(Palette.forest).frame(width: 80, height: 112).overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Palette.onAccent.opacity(0.6), lineWidth: 1).padding(6))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(.white, lineWidth: 3)).offset(x: CGFloat(i) * 2, y: CGFloat(-i) * 2)
                    }
                }
                .accessibilityLabel("Deck with \(deck.count) cards")
                if let c = drawn.last {
                    VStack {
                        Text(c.rank).font(.mTitle)
                        Text(c.suit).font(.mLargeTitle)
                    }
                    .foregroundStyle(c.red ? Palette.terracotta : Palette.ink)
                    .frame(width: 80, height: 112)
                    .background(RoundedRectangle(cornerRadius: 10).fill(.white).shadow(radius: 3))
                    .transition(.scale.combined(with: .opacity))
                    .id(drawn.count)
                    .accessibilityLabel("Drew \(c.rank) of \(c.suit)")
                }
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Put cards back (with replacement)", isOn: $replace).frame(width: 330)
                    HStack {
                        Button("Draw a card") { draw() }.buttonStyle(.borderedProminent).disabled(deck.isEmpty)
                        Button("Reshuffle") { withAnimation { deck = Self.fullDeck.shuffled(); drawn = [] } }.buttonStyle(.bordered)
                    }
                }
            }
            HStack(spacing: 24) {
                stat("Cards left", "\(deck.count)")
                stat("Hearts left", "\(hearts)")
                stat("P(next is ♥)", deck.isEmpty ? "–" : "\(hearts)/\(deck.count) ≈ \(String(format: "%.3f", Double(hearts) / Double(deck.count)))")
            }
            if !drawn.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack { ForEach(Array(drawn.enumerated()), id: \.offset) { _, c in Text("\(c.rank)\(c.suit)").foregroundStyle(c.red ? Palette.terracotta : Palette.ink).padding(6).background(RoundedRectangle(cornerRadius: 6).fill(Palette.surfaceSunk)) } }
                }
            }
            Text(replace ? "With replacement, the deck resets each time, so the chance never changes." : "Without replacement, every draw changes what's left. Watch P(next is ♥) move.")
                .font(.mFootnote).foregroundStyle(Palette.inkSoft)
        }
    }

    private func stat(_ l: String, _ v: String) -> some View {
        VStack(alignment: .leading) { Text(l).font(.mCaption).foregroundStyle(Palette.inkSoft); Text(v).font(.headline.monospacedDigit()) }
            .accessibilityElement(children: .combine)
    }

    private func draw() {
        guard !deck.isEmpty else { return }
        withAnimation(.spring) {
            let c = deck.removeFirst()
            drawn.append(c)
            if replace { deck.append(c); deck.shuffle() }
        }
    }
}
