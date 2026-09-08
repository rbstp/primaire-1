import Testing

@testable import MissionNinja

@Suite struct AlphabetRunTests {
    @Test func showsEveryLetterExactlyOnce() {
        var random = SeededRandom(seed: 1)
        let run = AlphabetRun(random: &random)
        #expect(run.order.count == 26)
        #expect(Set(run.order) == Set(LetterPlan.frenchAlphabet))
    }

    /// Reading along a row is not the exercise, so the tiles must be shuffled.
    @Test func shufflesTheTiles() {
        var random = SeededRandom(seed: 1)
        let run = AlphabetRun(random: &random)
        #expect(run.order != LetterPlan.frenchAlphabet)
    }

    @Test func opensOnADifferentOrderEachTime() {
        var first = SeededRandom(seed: 7)
        var second = SeededRandom(seed: 8)
        let one = AlphabetRun(random: &first).order
        let two = AlphabetRun(random: &second).order
        #expect(one != two)
    }

    @Test func asksForTheLettersInAlphabeticalOrder() {
        var random = SeededRandom(seed: 2)
        var run = AlphabetRun(random: &random)
        #expect(run.expected == "a")
        let accepted = run.touch("a")
        #expect(accepted)
        #expect(run.expected == "b")
    }

    @Test func aWrongLetterCostsNothing() {
        var random = SeededRandom(seed: 3)
        var run = AlphabetRun(random: &random)
        let accepted = run.touch("m")
        #expect(!accepted)
        #expect(run.reached == 0)
        #expect(run.expected == "a")
    }

    @Test func marksWhatIsAlreadyFound() {
        var random = SeededRandom(seed: 4)
        var run = AlphabetRun(random: &random)
        _ = run.touch("a")
        _ = run.touch("b")
        #expect(run.isDone("a"))
        #expect(run.isDone("b"))
        #expect(!run.isDone("c"))
        #expect(run.expected == "c")
    }

    @Test func finishesOnZ() {
        var random = SeededRandom(seed: 5)
        var run = AlphabetRun(random: &random)
        for letter in LetterPlan.frenchAlphabet {
            let accepted = run.touch(letter)
            #expect(accepted, "\(letter) refusé")
        }
        #expect(run.isComplete)
        #expect(run.expected == nil)
        #expect(run.advance == 1)
        let afterEnd = run.touch("a")
        #expect(!afterEnd)
    }

    @Test func restartingReshufflesAndClearsProgress() {
        var random = SeededRandom(seed: 6)
        var run = AlphabetRun(random: &random)
        let before = run.order
        _ = run.touch("a")
        run.restart(random: &random)
        #expect(run.reached == 0)
        #expect(run.order != before)
    }

    @Test func handlesAShortAlphabet() {
        var random = SeededRandom(seed: 9)
        var run = AlphabetRun(letters: ["a", "b"], random: &random)
        #expect(run.order.count == 2)
        _ = run.touch("a")
        _ = run.touch("b")
        #expect(run.isComplete)
    }
}

@Suite struct SeededRandomTests {
    @Test func aSeedAlwaysGivesTheSameShuffle() {
        var left = SeededRandom(seed: 42)
        var right = SeededRandom(seed: 42)
        let one = left.shuffled(Array(0..<20))
        let two = right.shuffled(Array(0..<20))
        #expect(one == two)
    }

    @Test func shufflingKeepsEveryElement() {
        var random = SeededRandom(seed: 11)
        let shuffled = random.shuffled(Array(0..<30))
        #expect(Set(shuffled) == Set(0..<30))
        #expect(shuffled != Array(0..<30))
    }

    @Test func leavesShortListsAlone() {
        var random = SeededRandom(seed: 12)
        let single = random.shuffled([1])
        let none = random.shuffled([Int]())
        #expect(single == [1])
        #expect(none.isEmpty)
    }

    @Test func freshSeedsDiffer() {
        var first = SeededRandom.fresh()
        var second = SeededRandom.fresh()
        let a = first.next()
        let b = second.next()
        #expect(a != b)
    }
}
