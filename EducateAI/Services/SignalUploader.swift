import Foundation

/// Sends opt-in, de-identified learning signals to the gateway. Events carry no learner ID,
/// name, device ID or free text: only topic, chapter number, event kind, a tag and a number.
final class SignalUploader {
    static let shared = SignalUploader()
    struct Event: Codable { var topic: String; var chapter_index: Int; var kind: String; var tag: String; var value: Double }
    private var queue: [Event] = []
    private let lock = NSLock()

    func enqueue(_ e: Event, cohort: String, settings: AppSettings) {
        guard settings.provider == .oci, let base = URL(string: settings.gatewayURL) else { return }
        lock.lock(); queue.append(e); let batch = queue.count >= 3 ? queue : []; if !batch.isEmpty { queue.removeAll() }; lock.unlock()
        guard !batch.isEmpty else { return }
        Task.detached {
            var req = URLRequest(url: base.appendingPathComponent("v1/signals"))
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            if let t = Keychain.get("gatewayToken") { req.setValue("Bearer \(t)", forHTTPHeaderField: "Authorization") }
            struct Body: Codable { var cohort: String; var events: [Event] }
            req.httpBody = try? JSONEncoder().encode(Body(cohort: cohort, events: batch))
            _ = try? await URLSession.shared.data(for: req)
        }
    }
}
