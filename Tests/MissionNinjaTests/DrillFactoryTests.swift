import Testing

@testable import MissionNinja

private func week(
    vowels: GlyphList = ["a", "e", "i", "o", "u", "y"],
    digitsTo: Int = 9,
    counting: Bool = true
) -> Week {
    Week(
        schema: 1,
        id: "2026-09-07",
        title: "Semaine",
        grade: "1re année",
        teacher: "Mme Catherine",
        days: [],
        letters: LetterPlan(vowels: vowels, alphabet: true),
        numbers: NumberPlan(from: 0, to: digitsTo, counting: counting),
        tracing: [],
        tasks: []
    )
}

@Suite struct DrillFactoryTests {
    @Test func buildsAFullLetterSession() {
        var random = SeededRandom(seed: 1)
        let drills = DrillFactory.session(mode: .letters, week: week(), progress: Progress(), random: &random)
        #expect(drills.count == DrillFactory.drillsPerSession)
        #expect(drills.allSatisfy { $0.kind == .hearLetter })
        #expect(drills.map(\.id) == Array(0..<DrillFactory.drillsPerSession))
    }

    @Test func everyDrillHoldsItsOwnAnswer() {
        var random = SeededRandom(seed: 2)
        for mode in [DrillFactory.Mode.letters, .numbers] {
            let drills = DrillFactory.session(mode: mode, week: week(), progress: Progress(), random: &random)
            for drill in drills {
                #expect(drill.choices.indices.contains(drill.answerIndex))
                #expect(drill.choices.filter { $0 == drill.answer }.count == 1)
                #expect(drill.isCorrect(drill.answer))
            }
        }
    }

    @Test func distractorsStayInsideTheWeek() {
        var random = SeededRandom(seed: 3)
        let plan = week(vowels: ["a", "e", "i"])
        let allowed = Set(plan.letters.vowels.characters.map(DrillChoice.letter))
        let drills = DrillFactory.session(mode: .letters, week: plan, progress: Progress(), random: &random)
        for drill in drills {
            #expect(Set(drill.choices).isSubset(of: allowed))
        }
    }

    @Test func startsWithThreeChoicesAndWidensOnceMastered() {
        #expect(DrillFactory.choiceWidth(for: .hearLetter, progress: Progress(), poolSize: 6) == 3)

        var mastered = Progress()
        for _ in 0..<25 {
            mastered.apply(.answered(key: "a", drill: .hearLetter, firstTry: true, correct: true))
        }
        #expect(DrillFactory.choiceWidth(for: .hearLetter, progress: mastered, poolSize: 6) == 4)
    }

    @Test func neverAsksForMoreChoicesThanTheWeekHas() {
        var random = SeededRandom(seed: 4)
        let plan = week(vowels: ["a", "e"])
        let drills = DrillFactory.session(mode: .letters, week: plan, progress: Progress(), random: &random)
        #expect(drills.allSatisfy { $0.choices.count == 2 })
    }

    @Test func neverRepeatsTheSameTargetBackToBack() {
        for seed in UInt64(1)...20 {
            var random = SeededRandom(seed: seed)
            let drills = DrillFactory.session(mode: .letters, week: week(), progress: Progress(), random: &random)
            for pair in zip(drills, drills.dropFirst()) {
                #expect(pair.0.answer != pair.1.answer)
            }
        }
    }

    @Test func mixesCountingIntoTheNumberSession() {
        var random = SeededRandom(seed: 5)
        let drills = DrillFactory.session(mode: .numbers, week: week(), progress: Progress(), random: &random)
        #expect(drills.contains { $0.kind == .countObjects })
        #expect(drills.contains { $0.kind == .hearNumber })
    }

    @Test func countingNeverShowsAnEmptyPile() {
        for seed in UInt64(1)...20 {
            var random = SeededRandom(seed: seed)
            let drills = DrillFactory.session(mode: .numbers, week: week(), progress: Progress(), random: &random)
            for drill in drills where drill.kind == .countObjects {
                guard case let .bricks(count) = drill.prompt else {
                    Issue.record("a counting drill must show bricks")
                    continue
                }
                #expect((1...9).contains(count))
                #expect(drill.answer == .number(count))
            }
        }
    }

    /// Neighbouring numbers force him to count instead of judging the pile size.
    @Test func countingDistractorsSitNextToTheAnswer() {
        var random = SeededRandom(seed: 6)
        let drills = DrillFactory.session(mode: .numbers, week: week(), progress: Progress(), random: &random)
        for drill in drills where drill.kind == .countObjects {
            guard case let .bricks(count) = drill.prompt else { continue }
            let spread = drill.choices.compactMap { choice -> Int? in
                guard case let .number(value) = choice else { return nil }
                return abs(value - count)
            }
            #expect(spread.max() ?? 0 <= 3)
        }
    }

    @Test func skipsCountingWhenTheWeekDoesNotAskForIt() {
        var random = SeededRandom(seed: 7)
        let drills = DrillFactory.session(mode: .numbers, week: week(counting: false), progress: Progress(), random: &random)
        #expect(drills.allSatisfy { $0.kind == .hearNumber })
    }

    @Test func favoursWhatHeGetsWrong() {
        var progress = Progress()
        for _ in 0..<20 {
            progress.apply(.answered(key: "a", drill: .hearLetter, firstTry: true, correct: true))
            progress.apply(.answered(key: "e", drill: .hearLetter, firstTry: true, correct: true))
            progress.apply(.answered(key: "i", drill: .hearLetter, firstTry: true, correct: true))
            progress.apply(.answered(key: "o", drill: .hearLetter, firstTry: true, correct: true))
            progress.apply(.answered(key: "u", drill: .hearLetter, firstTry: false, correct: false))
        }

        var strong = 0
        var weak = 0
        for seed in UInt64(1)...60 {
            var random = SeededRandom(seed: seed)
            let drills = DrillFactory.session(
                mode: .letters,
                week: week(vowels: ["a", "e", "i", "o", "u"]),
                progress: progress,
                random: &random
            )
            for drill in drills {
                if drill.answer == .letter("u") { weak += 1 } else { strong += 1 }
            }
        }
        #expect(weak > strong / 4)
    }

    @Test func isDeterministicForAGivenSeed() {
        var left = SeededRandom(seed: 99)
        var right = SeededRandom(seed: 99)
        let a = DrillFactory.session(mode: .numbers, week: week(), progress: Progress(), random: &left)
        let b = DrillFactory.session(mode: .numbers, week: week(), progress: Progress(), random: &right)
        #expect(a == b)
    }

    @Test func returnsNothingForAnEmptyWeek() {
        var random = SeededRandom(seed: 8)
        #expect(DrillFactory.session(mode: .letters, week: week(vowels: []), progress: Progress(), random: &random).isEmpty)
    }
}
