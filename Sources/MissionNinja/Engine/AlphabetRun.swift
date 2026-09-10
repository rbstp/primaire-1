import Foundation

/// The alphabet exercise. The letters are shuffled on screen, so finding the
/// next one is real work rather than reading along a row.
struct AlphabetRun: Equatable, Sendable {
    /// Two misses in a row and the row holding the letter lights up: a hint
    /// that narrows the search without handing over the answer.
    static let hintAfterMisses = 2

    /// What a tap did. A letter already in the dragon is idle: he is playing
    /// with what he built, not guessing.
    enum Touch: Equatable, Sendable {
        case found(Character, pays: Bool)
        case missed(Character)
        case idle
    }

    let letters: [Character]
    let order: [Character]
    private(set) var reached = 0
    private(set) var misses = 0
    /// Letters that have already paid a star since the screen opened. A
    /// restart reshuffles but keeps them: without that, finding the a and
    /// restarting pays a star every second tap.
    private(set) var rewarded: Set<Character> = []

    init(letters: [Character] = LetterPlan.frenchAlphabet, random: inout SeededRandom) {
        self.letters = letters
        order = random.shuffled(letters)
    }

    var expected: Character? { reached < letters.count ? letters[reached] : nil }
    var isComplete: Bool { reached >= letters.count }
    var advance: Double { letters.isEmpty ? 1 : Double(reached) / Double(letters.count) }
    var wantsHint: Bool { misses >= AlphabetRun.hintAfterMisses && !isComplete }

    func isDone(_ letter: Character) -> Bool {
        guard let position = letters.firstIndex(of: letter) else { return false }
        return position < reached
    }

    /// A wrong tap costs nothing but the sound. The outcome carries the letter
    /// so the screen can file a star, or file the miss against the letter he
    /// was looking for rather than the one he hit.
    mutating func touch(_ letter: Character) -> Touch {
        guard let expected else { return .idle }
        guard letter == expected else {
            if isDone(letter) { return .idle }
            misses += 1
            return .missed(expected)
        }
        // Marked whether it pays or not, so a letter found after a miss
        // cannot come back and pay on the next shuffle.
        let pays = rewarded.insert(letter).inserted && misses == 0
        reached += 1
        misses = 0
        return .found(letter, pays: pays)
    }

    mutating func restart(random: inout SeededRandom) {
        let paid = rewarded
        self = AlphabetRun(letters: letters, random: &random)
        rewarded = paid
    }
}
