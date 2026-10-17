import AVFoundation
import Observation

/// Read-aloud with word-level highlighting. Speaks one sentence per utterance so the
/// reader always knows which sentence and which word is being spoken.
@Observable
final class SpeechReader: NSObject, AVSpeechSynthesizerDelegate {
    private let synth = AVSpeechSynthesizer()
    private(set) var sentences: [String] = []
    var current: Int? = nil              // sentence index
    var wordRange: NSRange? = nil        // range within the current sentence
    var isPlaying = false
    var rate: Double = 0.46
    private var stopping = false

    override init() {
        super.init()
        synth.delegate = self
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
    }

    func load(_ s: [String]) {
        stop()
        sentences = s
    }

    func play(from index: Int? = nil) {
        let i = index ?? current ?? 0
        guard sentences.indices.contains(i) else { return }
        stopping = true
        synth.stopSpeaking(at: .immediate)
        stopping = false
        current = i
        wordRange = nil
        isPlaying = true
        speak(i)
    }

    private func speak(_ i: Int) {
        let u = AVSpeechUtterance(string: sentences[i])
        u.rate = Float(rate)
        u.postUtteranceDelay = 0.12
        u.voice = AVSpeechSynthesisVoice(language: "en-US")
        synth.speak(u)
    }

    func pause() {
        isPlaying = false
        stopping = true
        synth.stopSpeaking(at: .word)
        stopping = false
    }

    func toggle() { isPlaying ? pause() : play() }

    func stop() {
        stopping = true
        synth.stopSpeaking(at: .immediate)
        stopping = false
        isPlaying = false
        wordRange = nil
    }

    func next() { if let c = current, c + 1 < sentences.count { play(from: c + 1) } }
    func previous() { if let c = current, c > 0 { play(from: c - 1) } }

    func speechSynthesizer(_ s: AVSpeechSynthesizer, willSpeakRangeOfSpeechString r: NSRange, utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { self.wordRange = r }
    }

    func speechSynthesizer(_ s: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            guard !self.stopping, self.isPlaying, let c = self.current else { return }
            if c + 1 < self.sentences.count {
                self.current = c + 1; self.wordRange = nil
                self.speak(c + 1)
            } else {
                self.isPlaying = false; self.wordRange = nil
            }
        }
    }
}
