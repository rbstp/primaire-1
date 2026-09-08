import AVFoundation
import Foundation

/// The app's voice. He cannot read yet, so every instruction is spoken.
///
/// Deliberate choices, each one a trap avoided: a fresh AVSpeechUtterance every
/// time because requeueing the same object raises an exception, no delegate
/// because the protocol is Sendable while AVSpeechUtterance is not, and never a
/// nil voice because the system would then read French with an English one.
@MainActor
@Observable
final class Speaker {
    static let rate: Float = 0.42
    static let gapBetweenUtterances: TimeInterval = 0.12

    private let synthesizer = AVSpeechSynthesizer()
    private let voiceWatch = NotificationToken()

    private(set) var voice: AVSpeechSynthesisVoice?
    var isMuted = false

    init(configuresSession: Bool = true) {
        if configuresSession { Speaker.configureSession() }

        voice = Speaker.bestFrenchVoice()
        warmUp()
        voiceWatch.token = NotificationCenter.default.addObserver(
            forName: AVSpeechSynthesizer.availableVoicesDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.voice = Speaker.bestFrenchVoice() }
        }
    }

    var canSpeak: Bool { voice != nil && !isMuted }

    /// What the parent screen shows, so a missing Canadian voice is visible
    /// rather than a mystery.
    var voiceDescription: String {
        guard let voice else { return "Aucune voix française installée" }
        return "\(voice.name), \(voice.language), \(Speaker.qualityName(voice.quality))"
    }

    var usesCanadianFrench: Bool { voice?.language == "fr-CA" }

    func say(_ utterance: Utterance) {
        say([utterance])
    }

    /// Queues the whole instruction at once: the synthesiser sequences it
    /// itself, which is why no delegate is needed.
    func say(_ utterances: [Utterance]) {
        guard canSpeak else { return }
        stop()
        for item in utterances {
            synthesizer.speak(spokenForm(of: item))
        }
    }

    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }

    // MARK: Building an utterance

    private func spokenForm(of item: Utterance) -> AVSpeechUtterance {
        let utterance = Speaker.attributed(item) ?? AVSpeechUtterance(string: item.text)
        utterance.voice = voice
        utterance.rate = Speaker.rate
        utterance.prefersAssistiveTechnologySettings = false
        utterance.postUtteranceDelay = Speaker.gapBetweenUtterances
        return utterance
    }

    /// The phonetic attribute is documented for a single word, so a phrase
    /// falls back to plain text rather than risking a mangled reading.
    private static func attributed(_ item: Utterance) -> AVSpeechUtterance? {
        guard let ipa = item.ipa, !item.text.contains(" ") else { return nil }
        let text = NSMutableAttributedString(string: item.text)
        text.addAttribute(
            NSAttributedString.Key(rawValue: AVSpeechSynthesisIPANotationAttribute),
            value: ipa,
            range: NSRange(location: 0, length: (item.text as NSString).length)
        )
        return AVSpeechUtterance(attributedString: text)
    }

    /// Silent, so the first real instruction does not pay the voice loading
    /// cost while he is waiting.
    private func warmUp() {
        guard voice != nil else { return }
        let primer = AVSpeechUtterance(string: " ")
        primer.voice = voice
        primer.volume = 0
        synthesizer.speak(primer)
    }

    // MARK: Picking a voice

    /// voiceWithLanguage never reaches a premium voice, so the list is walked
    /// by hand: Canadian French first and the best quality within it.
    static func bestFrenchVoice() -> AVSpeechSynthesisVoice? {
        let french = AVSpeechSynthesisVoice.speechVoices().filter { $0.language.hasPrefix("fr") }
        guard !french.isEmpty else { return nil }
        return french.max { left, right in
            rank(left) < rank(right)
        }
    }

    private static func rank(_ voice: AVSpeechSynthesisVoice) -> (Int, Int) {
        let region = voice.language == "fr-CA" ? 2 : (voice.language == "fr-FR" ? 1 : 0)
        return (region, voice.quality.rawValue)
    }

    static func qualityName(_ quality: AVSpeechSynthesisVoiceQuality) -> String {
        switch quality {
        case .premium: "qualité supérieure"
        case .enhanced: "qualité améliorée"
        default: "qualité standard"
        }
    }

    /// Playback so the silent switch cannot mute a lesson about vowel sounds,
    /// and without mixing so another app's music cannot bury it.
    ///
    /// Off the main thread: setActive blocks, and on the main thread it shows
    /// up as a hang risk at launch.
    static func configureSession() {
        Task.detached(priority: .userInitiated) {
            let session = AVAudioSession.sharedInstance()
            try? session.setCategory(.playback, mode: .default, options: [])
            try? session.setActive(true)
        }
    }
}

/// A deinit on a @MainActor class is nonisolated and so cannot touch the
/// class's own stored properties. Holding the token out here lets it be
/// unregistered when the owner goes away.
private final class NotificationToken: @unchecked Sendable {
    var token: NSObjectProtocol?

    deinit {
        if let token { NotificationCenter.default.removeObserver(token) }
    }
}
