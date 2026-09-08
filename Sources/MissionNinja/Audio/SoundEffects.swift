import AVFoundation
import Foundation

/// A small pool of player nodes with every buffer rendered once at launch.
/// Rebuilt on a media services reset, without which the app would go silent
/// for good.
@MainActor
@Observable
final class SoundEffects {
    private static let sampleRate = 22050.0
    private static let voices = 6

    private let engine = AVAudioEngine()
    private let format = AVAudioFormat(standardFormatWithSampleRate: SoundEffects.sampleRate, channels: 1)!
    private var players: [AVAudioPlayerNode] = []
    private var buffers: [Sfx: AVAudioPCMBuffer] = [:]
    private var nextPlayer = 0
    private let watches = NotificationTokens()

    var isMuted = false

    init() {
        for sfx in Sfx.allCases {
            buffers[sfx] = SoundEffects.buffer(ToneSynth.render(sfx.recipe), format: format)
        }
        attachPlayers()
        engine.prepare()
        watch()
    }

    func play(_ sfx: Sfx) {
        guard !isMuted, let buffer = buffers[sfx], start() else { return }
        let player = players[nextPlayer]
        nextPlayer = (nextPlayer + 1) % players.count
        if player.isPlaying { player.stop() }
        player.scheduleBuffer(buffer, at: nil, options: .interrupts)
        player.play()
    }

    private func attachPlayers() {
        // The engine owns attached nodes, so they have to be detached rather
        // than just dropped from the array, or a rebuild grows the graph.
        for node in players { engine.detach(node) }
        players.removeAll()
        for _ in 0..<SoundEffects.voices {
            let node = AVAudioPlayerNode()
            engine.attach(node)
            engine.connect(node, to: engine.mainMixerNode, format: format)
            players.append(node)
        }
    }

    private func start() -> Bool {
        guard !engine.isRunning else { return true }
        do {
            try engine.start()
            return true
        } catch {
            return false
        }
    }

    private func watch() {
        watches.tokens.append(NotificationCenter.default.addObserver(
            forName: .AVAudioEngineConfigurationChange,
            object: engine,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.rebuild() }
        })
        watches.tokens.append(NotificationCenter.default.addObserver(
            forName: AVAudioSession.mediaServicesWereResetNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.rebuild() }
        })
    }

    private func rebuild() {
        engine.stop()
        attachPlayers()
        engine.prepare()
    }

    private static func buffer(_ samples: [Float], format: AVAudioFormat) -> AVAudioPCMBuffer? {
        guard !samples.isEmpty,
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count)),
              let channel = buffer.floatChannelData?[0]
        else { return nil }
        buffer.frameLength = AVAudioFrameCount(samples.count)
        samples.withUnsafeBufferPointer { source in
            channel.update(from: source.baseAddress!, count: samples.count)
        }
        return buffer
    }
}

/// See NotificationToken in Speaker.swift: a nonisolated deinit cannot reach
/// the stored properties of a @MainActor class.
private final class NotificationTokens: @unchecked Sendable {
    var tokens: [NSObjectProtocol] = []

    deinit {
        for token in tokens { NotificationCenter.default.removeObserver(token) }
    }
}
