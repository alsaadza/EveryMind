import AVFoundation
import Observation

@Observable
final class Speech: NSObject, AVSpeechSynthesizerDelegate {
    static let shared = Speech()
    private let synth = AVSpeechSynthesizer()
    var speakingID: String?

    override init() { super.init(); synth.delegate = self }

    func toggle(_ text: String, id: String, rate: Double) {
        if speakingID == id { stop(); return }
        stop()
        let u = AVSpeechUtterance(string: text.replacingOccurrences(of: "**", with: ""))
        u.rate = Float(rate)
        u.voice = AVSpeechSynthesisVoice(language: Locale.current.language.languageCode?.identifier ?? "en")
        speakingID = id
        synth.speak(u)
    }

    func stop() {
        synth.stopSpeaking(at: .immediate)
        speakingID = nil
    }

    func speechSynthesizer(_ s: AVSpeechSynthesizer, didFinish u: AVSpeechUtterance) {
        DispatchQueue.main.async { self.speakingID = nil }
    }
}
