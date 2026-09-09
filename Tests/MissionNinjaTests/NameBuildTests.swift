import Testing

@testable import MissionNinja

@Suite struct NameBuildTests {
    private func build(_ name: String, seed: UInt64 = 1) -> NameBuild {
        var random = SeededRandom(seed: seed)
        return NameBuild(name: name, random: &random)
    }

    @Test func offersEveryLetterOnceAsATile() {
        let run = build("Ariel")
        #expect(run.tiles.count == 5)
        #expect(run.tiles.map(\.letter).sorted() == Array("Ariel").sorted())
        #expect(Set(run.tiles.map(\.id)).count == 5)
    }

    @Test func shufflesTheTiles() {
        for seed in UInt64(1)...30 {
            let run = build("Lauralie", seed: seed)
            #expect(run.tiles.map(\.letter) != Array("Lauralie"), "graine \(seed)")
        }
    }

    @Test func acceptsTheLettersInOrderOnly() {
        var run = build("Zoé")
        let z = run.tiles.first { $0.letter == "Z" }!
        let o = run.tiles.first { $0.letter == "o" }!
        let refused = run.touch(o)
        #expect(!refused)
        #expect(run.misses == 1)
        let accepted = run.touch(z)
        #expect(accepted)
        #expect(run.reached == 1)
        #expect(run.expected == "o")
        #expect(run.misses == 0)
        #expect(run.letter(inSlot: 0) == "Z")
        #expect(run.letter(inSlot: 1) == nil)
    }

    /// Jeanne has two n and two e: either brick of a doubled letter must do,
    /// and a brick already placed must not be accepted twice.
    @Test func handlesDoubledLetters() {
        var run = build("Jeanne")
        for letter in "Jeanne" {
            let tile = run.tiles.first { $0.letter == letter && !run.isPlaced($0) }!
            let accepted = run.touch(tile)
            #expect(accepted, "\(letter) refusé")
        }
        #expect(run.isComplete)
        #expect(run.wasClean)
        #expect(run.placed.count == 6)
        #expect(Set(run.placed).count == 6)
    }

    @Test func hintsAfterTwoMissesAndOnTheRightTileOnly() {
        var run = build("Mila")
        let a = run.tiles.first { $0.letter == "a" }!
        let m = run.tiles.first { $0.letter == "M" }!
        _ = run.touch(a)
        #expect(!run.wantsHint)
        _ = run.touch(a)
        #expect(run.wantsHint)
        #expect(run.isHinted(m))
        #expect(!run.isHinted(a))
        #expect(!run.wasClean)
        _ = run.touch(m)
        #expect(!run.wantsHint)
    }

    @Test func doesNothingOnceComplete() {
        var run = build("Sam")
        for letter in "Sam" {
            _ = run.touch(run.tiles.first { $0.letter == letter }!)
        }
        #expect(run.isComplete)
        #expect(!run.wantsHint)
        let again = run.touch(run.tiles[0])
        #expect(!again)
        #expect(run.misses == 0)
    }
}
