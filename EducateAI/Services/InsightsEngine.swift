import Foundation

struct SeededRandom: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed == 0 ? 0x9E3779B97F4A7C15 : seed }
    mutating func next() -> UInt64 {
        state ^= state << 13; state ^= state >> 7; state ^= state << 17; return state
    }
}

struct ClassInsights {
    struct ChapterStat: Identifiable { var id: Int { index }; var index: Int; var title: String; var masteryRate: Double; var avgHints: Double; var avgReasoning: Double; var remediationRate: Double }
    struct CountItem: Identifiable { var id: String { label }; var label: String; var count: Int?; var suppressed: Bool }
    var learnerCount: Int
    var chapters: [ChapterStat]
    var misconceptions: [CountItem]
    var concernThemes: [CountItem]
    var confidenceVsMastery: [(confidence: Double, mastery: Double)]
    var k: Int
    var epsilon: Double
    var includesThisDevice: Bool
}

/// Builds the educator view from a synthetic, de-identified cohort (demo data) plus this device's
/// own signals when the learner opted in. Every count goes through k-anonymity suppression and
/// Laplace noise before an educator sees it. No row-level data is ever displayed.
enum InsightsEngine {
    static func laplace(scale: Double, rng: inout SeededRandom) -> Double {
        let u = Double.random(in: -0.5..<0.5, using: &rng)
        return -scale * (u < 0 ? -1 : 1) * log(1 - 2 * abs(u))
    }

    static func privatize(_ raw: [String: Int], k: Int, epsilon: Double, rng: inout SeededRandom) -> [ClassInsights.CountItem] {
        raw.map { label, count in
            if count < k { return .init(label: label, count: nil, suppressed: true) }
            let noisy = max(k, Int((Double(count) + laplace(scale: 1 / epsilon, rng: &rng)).rounded()))
            return .init(label: label, count: noisy, suppressed: false)
        }
        .sorted { ($0.count ?? -1) > ($1.count ?? -1) }
    }

    static func build(course: Course, store: AppStore, k: Int = 5, epsilon: Double = 1.0) -> ClassInsights {
        let seed = UInt64(truncatingIfNeeded: course.id.uuidString.hashValue) ^ 0xA5A5
        var rng = SeededRandom(seed: seed)
        let learners = 28
        var chapterStats: [ClassInsights.ChapterStat] = []
        var misRaw: [String: Int] = [:]
        var points: [(Double, Double)] = []

        for ch in course.chapters {
            let difficulty = 0.12 * Double(ch.index) + Double.random(in: 0...0.08, using: &rng)
            var mastered = 0, hints = 0.0, reasoning = 0.0, remediated = 0
            let tags = ch.challenges.flatMap { ($0.misconceptions ?? [:]).values }
            for _ in 0..<learners {
                let ability = Double.random(in: 0.25...1.0, using: &rng)
                let m = ability - difficulty + Double.random(in: -0.1...0.1, using: &rng)
                if m > 0.5 { mastered += 1 } else { remediated += Double.random(in: 0...1, using: &rng) < 0.7 ? 1 : 0 }
                hints += max(0, (1 - m) * 3 + Double.random(in: -0.5...0.5, using: &rng))
                reasoning += min(1, max(0, m + Double.random(in: -0.15...0.15, using: &rng)))
                if m < 0.65, let tag = tags.randomElement(using: &rng) { misRaw[tag, default: 0] += 1 }
                if ch.index == 0 {
                    let conf = min(5, max(1, (ability * 5).rounded() + Double(Int.random(in: -1...1, using: &rng))))
                    points.append((conf, min(1, max(0, m))))
                }
            }
            // Blend in this learner's real data only if they opted in to sharing.
            var includeSelf = 0
            if store.settings.shareSignals {
                let p = store.chapterProgress(course, ch)
                if !p.attempts.isEmpty {
                    includeSelf = 1
                    if p.status == .mastered { mastered += 1 }
                    hints += Double(p.attempts.map(\.hintsUsed).max() ?? 0)
                    reasoning += p.attempts.map(\.reasoningScore).max() ?? 0
                    for a in p.attempts { if let m = a.misconception { misRaw[m, default: 0] += 1 } }
                }
            }
            let n = Double(learners + includeSelf)
            chapterStats.append(.init(index: ch.index, title: ch.title, masteryRate: Double(mastered) / n, avgHints: hints / n,
                                      avgReasoning: reasoning / n, remediationRate: Double(remediated) / n))
        }

        var themeRaw: [String: Int] = ["Stress & workload": 9, "Understanding the material": 12, "Belonging & confidence": 6,
                                       "Teaching & pace": 4, "Access & technology": 3]
        for c in store.concerns where c.visibility != .privateOnly && c.category != "Urgent wellbeing" {
            themeRaw[c.category, default: 0] += 1
        }

        return ClassInsights(learnerCount: learners + (store.settings.shareSignals ? 1 : 0), chapters: chapterStats,
                             misconceptions: privatize(misRaw, k: k, epsilon: epsilon, rng: &rng),
                             concernThemes: privatize(themeRaw, k: k, epsilon: epsilon, rng: &rng),
                             confidenceVsMastery: points.map { (confidence: $0.0, mastery: $0.1) },
                             k: k, epsilon: epsilon, includesThisDevice: store.settings.shareSignals)
    }

    struct GatewayItem: Codable, Identifiable { var id: String { kind + tag }; var kind: String; var tag: String; var count: Int?; var mean_value: Double?; var suppressed: Bool }
    struct GatewayInsights: Codable { var cohort: String; var k: Int; var epsilon: Double; var items: [GatewayItem]; var note: String? }

    static func fetchGateway(settings: AppSettings) async -> GatewayInsights? {
        guard settings.provider == .oci, var comps = URLComponents(string: settings.gatewayURL) else { return nil }
        comps.path = "/v1/insights"
        comps.queryItems = [.init(name: "cohort", value: settings.cohortCode), .init(name: "k", value: "5"), .init(name: "epsilon", value: "1.0")]
        guard let url = comps.url else { return nil }
        var req = URLRequest(url: url); req.timeoutInterval = 8
        if let t = Keychain.get("gatewayToken") { req.setValue("Bearer \(t)", forHTTPHeaderField: "Authorization") }
        guard let (data, _) = try? await URLSession.shared.data(for: req) else { return nil }
        return try? JSONDecoder().decode(GatewayInsights.self, from: data)
    }
}
