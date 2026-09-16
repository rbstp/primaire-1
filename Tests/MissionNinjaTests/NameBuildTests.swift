import Foundation
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

    /// Same ration as the alphabet: missing on purpose buys one hint a minute.
    @Test func ratesTheHintToOnceAMinute() {
        let start = Date(timeIntervalSince1970: 30_000)
        var run = build("Mila")
        let a = run.tiles.first { $0.letter == "a" }!
        let m = run.tiles.first { $0.letter == "M" }!
        _ = run.touch(a, at: start)
        _ = run.touch(a, at: start)
        #expect(run.wantsHint)
        _ = run.touch(m, at: start)
        #expect(!run.wantsHint)

        let i = run.tiles.first { $0.letter == "i" }!
        _ = run.touch(a, at: start.addingTimeInterval(5))
        _ = run.touch(a, at: start.addingTimeInterval(6))
        #expect(!run.wantsHint)
        #expect(!run.isHinted(i))

        _ = run.touch(a, at: start.addingTimeInterval(61))
        #expect(run.wantsHint)
        #expect(run.isHinted(i))
    }

    /// The wait follows him to the next name of the run.
    @Test func carriesTheWaitToTheNextName() {
        let start = Date(timeIntervalSince1970: 40_000)
        var random = SeededRandom(seed: 21)
        var first = NameBuild(name: "Mila", random: &random)
        let a = first.tiles.first { $0.letter == "a" }!
        _ = first.touch(a, at: start)
        _ = first.touch(a, at: start)
        #expect(first.wantsHint)

        var second = NameBuild(name: "Nolan", random: &random, hint: first.hint)
        let n = second.tiles.last { $0.letter == "n" }!
        _ = second.touch(n, at: start.addingTimeInterval(3))
        _ = second.touch(n, at: start.addingTimeInterval(4))
        #expect(!second.wantsHint)
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
