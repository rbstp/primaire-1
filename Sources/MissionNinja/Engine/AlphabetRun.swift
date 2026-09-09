import Foundation

/// The alphabet exercise. The letters are shuffled on screen, so finding the
/// next one is real work rather than reading along a row.
struct AlphabetRun: Equatable, Sendable {
    /// Two misses in a row and the row holding the letter lights up: a hint
    /// that narrows the search without handing over the answer.
    static let hintAfterMisses = 2

    let letters: [Character]
    let order: [Character]
    private(set) var reached = 0
    private(set) var misses = 0

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

    /// Returns whether that was the letter we were waiting for. A wrong tap
    /// costs nothing but the sound.
    mutating func touch(_ letter: Character) -> Bool {
        guard letter == expected else {
            // A letter already in the dragon is a tap, not a wrong guess.
            if !isComplete, !isDone(letter) { misses += 1 }
            return false
        }
        reached += 1
        misses = 0
        return true
    }

    mutating func restart(random: inout SeededRandom) {
        self = AlphabetRun(letters: letters, random: &random)
    }
}
