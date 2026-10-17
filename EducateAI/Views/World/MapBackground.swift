import SwiftUI

/// A hand-inked map on warm paper, drawn procedurally. Deterministic, so the map is the same each visit.
struct MapBackground: View {
    var chapterSpots: [CGPoint]
    var extraSpots: [CGPoint]
    var animate: Bool = true
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 12, paused: !animate)) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate
            Canvas { g, size in draw(&g, size: size, t: t) }
        }
        .overlay(Image("paper-grain").resizable(resizingMode: .tile).opacity(0.9).blendMode(.multiply).allowsHitTesting(false))
        .accessibilityHidden(true)
    }

    private func p(_ n: CGPoint, _ s: CGSize) -> CGPoint { CGPoint(x: n.x * s.width, y: n.y * s.height) }

    private var colors: (paper: Color, land: Color, sea: Color, ink: Color, forest: Color, road: Color, contour: Color) {
        scheme == .dark
        ? (Color(red: 0.12, green: 0.12, blue: 0.13), Color(red: 0.17, green: 0.19, blue: 0.16), Color(red: 0.13, green: 0.17, blue: 0.21),
           Color(red: 0.85, green: 0.80, blue: 0.70), Color(red: 0.38, green: 0.55, blue: 0.45), Color(red: 0.80, green: 0.62, blue: 0.40), Color(red: 0.70, green: 0.58, blue: 0.35))
        : (Color(red: 0.94, green: 0.90, blue: 0.81), Color(red: 0.90, green: 0.89, blue: 0.79), Color(red: 0.80, green: 0.86, blue: 0.87),
           Color(red: 0.23, green: 0.22, blue: 0.20), Color(red: 0.29, green: 0.42, blue: 0.33), Color(red: 0.55, green: 0.36, blue: 0.22), Color(red: 0.72, green: 0.58, blue: 0.33))
    }

    /// Wobbly closed blob around a centre: the island's coastline.
    private func blob(center: CGPoint, rx: CGFloat, ry: CGFloat, seed: UInt64, points n: Int = 48, wobble: CGFloat = 0.10) -> Path {
        var rng = SeededRandom(seed: seed)
        let offsets = (0..<n).map { _ in CGFloat.random(in: -wobble...wobble, using: &rng) }
        var pts: [CGPoint] = []
        for i in 0..<n {
            let a = Double(i) / Double(n) * 2 * .pi
            let k = 1 + offsets[i] + 0.5 * offsets[(i + 3) % n]
            pts.append(CGPoint(x: center.x + cos(a) * rx * k, y: center.y + sin(a) * ry * k))
        }
        var path = Path()
        path.move(to: CGPoint(x: (pts[0].x + pts[n - 1].x) / 2, y: (pts[0].y + pts[n - 1].y) / 2))
        for i in 0..<n {
            let a = pts[i], b = pts[(i + 1) % n]
            path.addQuadCurve(to: CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2), control: a)
        }
        path.closeSubpath()
        return path
    }

    private func draw(_ g: inout GraphicsContext, size: CGSize, t: Double) {
        let c = colors
        let W = size.width, H = size.height
        g.fill(Path(CGRect(origin: .zero, size: size)), with: .color(c.sea))

        // Sea hatching: short horizontal strokes that drift slowly.
        var rng = SeededRandom(seed: 7)
        let drift = CGFloat(sin(t * 0.6)) * 3
        for _ in 0..<420 {
            let x = CGFloat.random(in: 0...W, using: &rng), y = CGFloat.random(in: 0...H, using: &rng)
            var s = Path(); s.move(to: CGPoint(x: x + drift, y: y)); s.addLine(to: CGPoint(x: x + drift + CGFloat.random(in: 8...18, using: &rng), y: y))
            g.stroke(s, with: .color(c.ink.opacity(0.13)), lineWidth: 1)
        }

        // Island with coastline echo lines (classic engraved-map look).
        let island = blob(center: CGPoint(x: W * 0.5, y: H * 0.52), rx: W * 0.47, ry: H * 0.46, seed: 3, wobble: 0.07)
        for i in (1...3).reversed() {
            g.stroke(island, with: .color(c.ink.opacity(0.10)), style: StrokeStyle(lineWidth: 1, dash: i == 3 ? [2, 4] : []))
            g.transform = CGAffineTransform(translationX: W * 0.5, y: H * 0.52).scaledBy(x: 1 + CGFloat(i) * 0.018, y: 1 + CGFloat(i) * 0.022).translatedBy(x: -W * 0.5, y: -H * 0.52)
            g.stroke(island, with: .color(c.ink.opacity(0.12)), lineWidth: 1)
            g.transform = .identity
        }
        g.fill(island, with: .color(c.land))
        g.stroke(island, with: .color(c.ink.opacity(0.85)), lineWidth: 1.6)

        g.clip(to: island)

        // Contour lines around two hills.
        for (hc, seed) in [(CGPoint(x: W * 0.33, y: H * 0.20), UInt64(11)), (CGPoint(x: W * 0.80, y: H * 0.80), UInt64(12))] {
            for r in stride(from: 40.0, through: 160.0, by: 24.0) {
                g.stroke(blob(center: hc, rx: CGFloat(r) * 1.4, ry: CGFloat(r), seed: seed, points: 28, wobble: 0.12), with: .color(c.contour.opacity(0.35)), lineWidth: 1)
            }
        }

        // River with ink banks.
        var river = Path()
        river.move(to: CGPoint(x: W * 0.66, y: 0))
        river.addCurve(to: CGPoint(x: W * 0.70, y: H * 0.45), control1: CGPoint(x: W * 0.60, y: H * 0.15), control2: CGPoint(x: W * 0.76, y: H * 0.30))
        river.addCurve(to: CGPoint(x: W * 0.98, y: H), control1: CGPoint(x: W * 0.64, y: H * 0.62), control2: CGPoint(x: W * 0.92, y: H * 0.80))
        g.stroke(river, with: .color(c.ink.opacity(0.75)), style: StrokeStyle(lineWidth: 30, lineCap: .round))
        g.stroke(river, with: .color(c.sea), style: StrokeStyle(lineWidth: 27, lineCap: .round))
        g.stroke(river, with: .color(c.ink.opacity(0.18)), style: StrokeStyle(lineWidth: 1, lineCap: .round, dash: [6, 10], dashPhase: CGFloat(t * 12)))

        // Trail: start -> chapters, plus spurs to extras. Dotted ink like a treasure map.
        let start = p(CGPoint(x: 0.36, y: 0.9), size)
        var nodes = [start] + chapterSpots.map { p($0, size) }
        if nodes.count < 2 { nodes.append(p(CGPoint(x: 0.5, y: 0.5), size)) }
        var road = Path()
        road.move(to: nodes[0])
        for i in 1..<nodes.count {
            let a = nodes[i - 1], b = nodes[i]
            road.addQuadCurve(to: b, control: CGPoint(x: (a.x + b.x) / 2 + (i % 2 == 0 ? 60 : -60), y: (a.y + b.y) / 2))
        }
        for e in extraSpots {
            let target = p(e, size)
            let from = nodes.min { hypot($0.x - target.x, $0.y - target.y) < hypot($1.x - target.x, $1.y - target.y) } ?? start
            road.move(to: from)
            road.addQuadCurve(to: target, control: CGPoint(x: (from.x + target.x) / 2, y: (from.y + target.y) / 2 - 40))
        }
        g.stroke(road, with: .color(c.paper.opacity(0.9)), style: StrokeStyle(lineWidth: 16, lineCap: .round, lineJoin: .round))
        g.stroke(road, with: .color(c.road), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round, dash: [1, 9]))

        // Pond
        if let pond = extraSpots.first(where: { $0.y > 0.7 }) {
            let pc = p(pond, size)
            let shape = blob(center: CGPoint(x: pc.x, y: pc.y + 18), rx: 120, ry: 44, seed: 21, points: 24, wobble: 0.08)
            g.fill(shape, with: .color(c.sea))
            g.stroke(shape, with: .color(c.ink.opacity(0.8)), lineWidth: 1.4)
            for k in 0..<3 {
                var l = Path(); let y = pc.y + 6 + CGFloat(k) * 12
                l.move(to: CGPoint(x: pc.x - 50 + CGFloat(k) * 10, y: y)); l.addLine(to: CGPoint(x: pc.x + 30 - CGFloat(k) * 6, y: y))
                g.stroke(l, with: .color(c.ink.opacity(0.25)), lineWidth: 1)
            }
        }

        let avoid = (chapterSpots + extraSpots).map { p($0, size) } + [start]
        func free(_ pt: CGPoint, _ r: CGFloat) -> Bool {
            !avoid.contains(where: { hypot($0.x - pt.x, $0.y - pt.y) < r }) && !road.contains(pt)
                && abs(pt.x - W * 0.68 - (pt.y / H - 0.45) * W * 0.2) > 46
        }

        // Mountains: inked peaks with hatching on the shaded side.
        var mrng = SeededRandom(seed: 99)
        for _ in 0..<26 {
            let x = CGFloat.random(in: W * 0.18...W * 0.56, using: &mrng), y = CGFloat.random(in: H * 0.08...H * 0.26, using: &mrng)
            let pt = CGPoint(x: x, y: y)
            guard free(pt, 110) else { continue }
            let h = CGFloat.random(in: 22...40, using: &mrng), w = h * 1.3
            var m = Path()
            m.move(to: CGPoint(x: x - w / 2, y: y)); m.addLine(to: CGPoint(x: x, y: y - h)); m.addLine(to: CGPoint(x: x + w / 2, y: y))
            g.fill(m, with: .color(c.land))
            g.stroke(m, with: .color(c.ink.opacity(0.85)), style: StrokeStyle(lineWidth: 1.3, lineJoin: .round))
            for k in 1..<5 {
                var hl = Path(); let f = CGFloat(k) / 5
                hl.move(to: CGPoint(x: x + w / 2 * f * 0.9, y: y - h * (1 - f) + 2)); hl.addLine(to: CGPoint(x: x + w / 2 * f * 0.9 - 4, y: y))
                g.stroke(hl, with: .color(c.ink.opacity(0.35)), lineWidth: 0.8)
            }
        }

        // Forests: clusters of small inked trees.
        var trng = SeededRandom(seed: 42)
        let clusters = [CGPoint(x: 0.10, y: 0.55), CGPoint(x: 0.30, y: 0.48), CGPoint(x: 0.88, y: 0.42), CGPoint(x: 0.42, y: 0.66), CGPoint(x: 0.75, y: 0.90), CGPoint(x: 0.92, y: 0.70), CGPoint(x: 0.20, y: 0.86), CGPoint(x: 0.56, y: 0.50)]
        for cl in clusters {
            let cc = p(cl, size)
            for _ in 0..<16 {
                let x = cc.x + CGFloat.random(in: -70...70, using: &trng), y = cc.y + CGFloat.random(in: -45...45, using: &trng)
                let pt = CGPoint(x: x, y: y)
                guard free(pt, 100) else { continue }
                let r = CGFloat.random(in: 7...11, using: &trng)
                var stem = Path(); stem.move(to: CGPoint(x: x, y: y)); stem.addLine(to: CGPoint(x: x, y: y + r * 1.1))
                g.stroke(stem, with: .color(c.ink.opacity(0.8)), lineWidth: 1.2)
                let crown = Path(ellipseIn: CGRect(x: x - r, y: y - r * 1.7, width: r * 2, height: r * 2))
                g.fill(crown, with: .color(c.forest.opacity(0.45)))
                g.stroke(crown, with: .color(c.ink.opacity(0.85)), lineWidth: 1.2)
            }
        }

        // Start marker
        var x = Path(); x.move(to: CGPoint(x: start.x - 8, y: start.y - 8)); x.addLine(to: CGPoint(x: start.x + 8, y: start.y + 8))
        x.move(to: CGPoint(x: start.x + 8, y: start.y - 8)); x.addLine(to: CGPoint(x: start.x - 8, y: start.y + 8))
        g.stroke(x, with: .color(Palette.terracotta), lineWidth: 2.5)

        g.clip(to: Path(CGRect(origin: .zero, size: size)))
        compass(&g, at: CGPoint(x: W - 90, y: H - 150), ink: c.ink)

        // Vignette
        g.fill(Path(CGRect(origin: .zero, size: size)), with: .radialGradient(Gradient(colors: [.clear, .black.opacity(scheme == .dark ? 0.35 : 0.12)]),
                                                                              center: CGPoint(x: W / 2, y: H / 2), startRadius: min(W, H) * 0.45, endRadius: max(W, H) * 0.75))
    }

    private func compass(_ g: inout GraphicsContext, at c: CGPoint, ink: Color) {
        let r: CGFloat = 38
        g.stroke(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)), with: .color(ink.opacity(0.7)), lineWidth: 1)
        g.stroke(Path(ellipseIn: CGRect(x: c.x - r + 5, y: c.y - r + 5, width: r * 2 - 10, height: r * 2 - 10)), with: .color(ink.opacity(0.4)), lineWidth: 0.8)
        for (i, a) in stride(from: -Double.pi / 2, to: Double.pi * 1.5, by: Double.pi / 2).enumerated() {
            var star = Path()
            let tip = CGPoint(x: c.x + cos(a) * r * 1.15, y: c.y + sin(a) * r * 1.15)
            let l = CGPoint(x: c.x + cos(a - .pi / 2) * 6, y: c.y + sin(a - .pi / 2) * 6)
            let rr = CGPoint(x: c.x + cos(a + .pi / 2) * 6, y: c.y + sin(a + .pi / 2) * 6)
            star.move(to: l); star.addLine(to: tip); star.addLine(to: rr); star.addLine(to: c); star.closeSubpath()
            g.fill(star, with: .color(i == 0 ? Palette.terracotta : ink.opacity(0.75)))
        }
        g.draw(Text("N").font(.display(15, .semibold)).foregroundColor(ink), at: CGPoint(x: c.x, y: c.y - r * 1.15 - 12))
    }
}
