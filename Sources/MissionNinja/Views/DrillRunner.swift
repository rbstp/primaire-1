import Foundation

/// Drives one training run: holds the session, speaks the instruction, plays
/// the sounds and files the progress. The rules themselves stay in
/// DrillSession, which is a plain value and fully tested.
@MainActor
@Observable
final class DrillRunner {
    static let feedbackPause = Duration.milliseconds(1100)

    let mode: DrillFactory.Mode

    private let week: Week
    private let store: ProgressStore
    private let speaker: Speaker
    private let effects: SoundEffects
    private var random: SeededRandom

    private(set) var session: DrillSession
    private(set) var shown: Drill?
    private(set) var picked: DrillChoice?
    private(set) var wasRight = false
    private(set) var starBursts = 0
    private var settle: Task<Void, Never>?
    private var praiseIndex = 0

    init(
        mode: DrillFactory.Mode,
        week: Week,
        store: ProgressStore,
        speaker: Speaker,
        effects: SoundEffects,
        random: SeededRandom = .fresh()
    ) {
        self.mode = mode
        self.week = week
        self.store = store
        self.speaker = speaker
        self.effects = effects
        self.random = random
        session = DrillSession(drills: [])
    }

    var isFinished: Bool { session.isFinished && shown == nil }
    var isWaiting: Bool { picked != nil }
    var advance: Double { session.advance }
    var settled: Int { session.settled }
    var total: Int { session.total }
    var stars: Int { session.stars }

    func begin() {
        session = DrillSession(
            drills: DrillFactory.session(mode: mode, week: week, progress: store.thisWeek, random: &random)
        )
        shown = session.current
        store.markPractised()
        speakPrompt()
    }

    func speakPrompt() {
        guard let prompt = shown?.prompt else { return }
        speaker.say(Pronunciation.script(for: prompt))
    }

    func choose(_ choice: DrillChoice) {
        guard !isWaiting, let answer = session.answer(choice) else { return }
        picked = choice
        wasRight = answer.correct
        store.apply(answer.events)

        if answer.correct {
            effects.play(.right)
            if answer.firstTry {
                starBursts += 1
                effects.play(.star)
            }
            praiseIndex += 1
            speaker.say(Pronunciation.praise(praiseIndex))
        } else {
            effects.play(.wrong)
            speaker.say(Pronunciation.correction(answer.expected))
        }

        settle?.cancel()
        settle = Task { [weak self] in
            try? await Task.sleep(for: DrillRunner.feedbackPause)
            guard !Task.isCancelled else { return }
            self?.next()
        }
    }

    /// State for one tile: green on the right answer, red only on the tile he
    /// actually picked.
    func state(of choice: DrillChoice) -> BigChoiceButton.State {
        guard let picked, let shown else { return .idle }
        if choice == shown.answer { return wasRight ? .correct : .revealed }
        return choice == picked ? .wrong : .idle
    }

    func stop() {
        settle?.cancel()
        settle = nil
        speaker.stop()
        store.flush()
    }

    private func next() {
        picked = nil
        shown = session.current
        guard shown != nil else { return }
        speakPrompt()
    }
}
