import Foundation

/// The alphabet exercise. The letters are shuffled on screen, so finding the
/// next one is real work rather than reading along a row.
struct AlphabetRun: Equatable, Sendable {
    let letters: [Character]
    let order: [Character]
    private(set) var reached = 0

    init(letters: [Character] = LetterPlan.frenchAlphabet, random: inout SeededRandom) {
        self.letters = letters
        order = random.shuffled(letters)
    }

    var expected: Character? { reached < letters.count ? letters[reached] : nil }
    var isComplete: Bool { reached >= letters.count }
    var advance: Double { letters.isEmpty ? 1 : Double(reached) / Double(letters.count) }

    func isDone(_ letter: Character) -> Bool {
        guard let position = letters.firstIndex(of: letter) else { return false }
        return position < reached
    }

    /// Returns whether that was the letter we were waiting for. A wrong tap
    /// costs nothing but the sound.
    mutating func touch(_ letter: Character) -> Bool {
        guard letter == expected else { return false }
        reached += 1
        return true
    }

    mutating func restart(random: inout SeededRandom) {
        self = AlphabetRun(letters: letters, random: &random)
    }
}
