import Foundation

/// Rebuilding a name he hears from its letters, shuffled on screen. Two misses
/// in a row and the next letter is pointed out, so he is never stuck.
struct NameBuild: Equatable, Sendable {
    static let hintAfterMisses = 2

    /// A tile, not a character: Jeanne has two n and two e, and each brick has
    /// to be its own thing.
    struct Tile: Equatable, Hashable, Sendable, Identifiable {
        let id: Int
        let letter: Character
    }

    let name: String
    let tiles: [Tile]
    private(set) var placed: [Int] = []
    private(set) var misses = 0
    private(set) var totalMisses = 0

    init(name: String, random: inout SeededRandom) {
        self.name = name
        let ordered = Array(name).enumerated().map { Tile(id: $0.offset, letter: $0.element) }
        var shuffled = random.shuffled(ordered)
        // A name that lands already in order is not a puzzle.
        var tries = 0
        while ordered.count > 1, shuffled.map(\.letter) == ordered.map(\.letter), tries < 8 {
            shuffled = random.shuffled(ordered)
            tries += 1
        }
        tiles = shuffled
    }

    var letters: [Character] { Array(name) }
    var reached: Int { placed.count }
    var expected: Character? { reached < letters.count ? letters[reached] : nil }
    var isComplete: Bool { reached >= letters.count }
    var wasClean: Bool { totalMisses == 0 }
    var wantsHint: Bool { misses >= NameBuild.hintAfterMisses && !isComplete }

    func isPlaced(_ tile: Tile) -> Bool { placed.contains(tile.id) }

    /// The tile he should touch now, or with a doubled letter any of them.
    func isHinted(_ tile: Tile) -> Bool {
        wantsHint && !isPlaced(tile) && tile.letter == expected
    }

    /// The letter sitting in one slot of the model, once he has placed it.
    func letter(inSlot index: Int) -> Character? {
        index < reached ? letters[index] : nil
    }

    mutating func touch(_ tile: Tile) -> Bool {
        guard !isComplete, !isPlaced(tile), tile.letter == expected else {
            if !isComplete { misses += 1; totalMisses += 1 }
            return false
        }
        placed.append(tile.id)
        misses = 0
        return true
    }
}
