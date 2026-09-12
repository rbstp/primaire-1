import Testing

@testable import MissionNinja

private func week(
    vowels: GlyphList = ["a", "e", "i", "o", "u", "y"],
    digitsTo: Int = 9,
    counting: Bool = true,
    focus: NumberSpan? = nil,
    words: WordPlan = WordPlan(),
    names: [String] = []
) -> Week {
    Week(
        schema: 1,
        id: "2026-09-07",
        title: "Semaine",
        grade: "1re année",
        teacher: "Mme Catherine",
        days: [],
        letters: LetterPlan(vowels: vowels, alphabet: true),
        numbers: NumberPlan(from: 0, to: digitsTo, counting: counting, focus: focus),
        tracing: [],
        words: words,
        names: names,
        tasks: []
    )
}

private extension WeekProgress {
    mutating func apply(_ event: ProgressEvent) {
        var progress = Progress()
        progress.weeks["w"] = self
        progress.apply(event, in: "w")
        self = progress.week("w")
    }
}

private let classNames = ["Ariel", "Arthur", "Séréna", "Hayden", "Mme Sylvie", "Loïc", "Mila", "Charlie", "Nolan", "Olivia"]

private func answered(_ drill: Drill) -> Int? {
    guard case let .number(value) = drill.answer else { return nil }
    return value
}

private let classWords = WordPlan(sight: ["un", "une"], decode: ["je", "le", "la", "joli"])

@Suite struct DrillFactoryTests {
    @Test func buildsAFullWordSession() {
        var random = SeededRandom(seed: 11)
        let drills = DrillFactory.session(mode: .words, week: week(words: classWords), progress: WeekProgress(), random: &random)
        #expect(drills.count == DrillFactory.drillsPerSession)
        #expect(drills.allSatisfy { $0.kind == .hearWord })
        for drill in drills {
            #expect(drill.choices.count >= 3)
            #expect(Set(drill.choices).count == drill.choices.count)
            #expect(drill.isCorrect(drill.answer))
            guard case let .word(word) = drill.answer else { Issue.record("not a word"); return }
            #expect(classWords.all.contains(word))
            #expect(drill.prompt == .spokenWord(word))
        }
    }

    /// Two words on the table is a coin toss, not a game.
    @Test func skipsTheWordGameWithoutEnoughWords() {
        var random = SeededRandom(seed: 12)
        for thin in [WordPlan(sight: ["un"]), WordPlan(sight: ["un", "une"])] {
            let drills = DrillFactory.session(mode: .words, week: week(words: thin), progress: WeekProgress(), random: &random)
            #expect(drills.isEmpty)
            #expect(!DrillFactory.modes(for: week(words: thin)).contains(.words))
        }
    }

    /// A French unit offers no number game and a maths one no letter game.
    @Test func onlyOffersTheModesTheWeekHasMaterialFor() {
        #expect(DrillFactory.modes(for: week(words: classWords)) == [.letters, .numbers, .words])
        let french = week(digitsTo: -1, words: classWords)
        #expect(DrillFactory.modes(for: french) == [.letters, .words])
        let maths = week(vowels: [], digitsTo: 99)
        #expect(DrillFactory.modes(for: maths) == [.numbers])
        #expect(DrillFactory.modes(for: week(names: classNames)) == [.letters, .numbers, .names])
    }

    @Test func buildsAFullLetterSession() {
        var random = SeededRandom(seed: 1)
        let drills = DrillFactory.session(mode: .letters, week: week(), progress: WeekProgress(), random: &random)
        #expect(drills.count == DrillFactory.drillsPerSession)
        #expect(drills.allSatisfy { $0.kind == .hearLetter })
        #expect(drills.map(\.id) == Array(0..<DrillFactory.drillsPerSession))
    }

    @Test func everyDrillHoldsItsOwnAnswer() {
        var random = SeededRandom(seed: 2)
        for mode in [DrillFactory.Mode.letters, .numbers] {
            let drills = DrillFactory.session(mode: mode, week: week(), progress: WeekProgress(), random: &random)
            for drill in drills {
                #expect(drill.choices.indices.contains(drill.answerIndex))
                #expect(drill.choices.filter { $0 == drill.answer }.count == 1)
                #expect(drill.isCorrect(drill.answer))
            }
        }
    }

    @Test func buildsAFullVowelPictureSession() {
        var random = SeededRandom(seed: 21)
        let drills = DrillFactory.session(mode: .vowels, week: week(), progress: WeekProgress(), random: &random)
        #expect(drills.count == DrillFactory.drillsPerSession)
        #expect(drills.allSatisfy { $0.kind == .pictureLetter })
    }

    /// The answer is the letter the object's own name starts with, accent
    /// included, and the decoys are letters of the week.
    @Test func aPictureIsAnsweredByTheLetterItsWordStartsWith() {
        var random = SeededRandom(seed: 22)
        let plan = week()
        let allowed = Set(plan.letters.vowelsAndAccents.map(DrillChoice.letter))
        let drills = DrillFactory.session(mode: .vowels, week: plan, progress: WeekProgress(), random: &random)
        for drill in drills {
            guard case let .object(word) = drill.prompt else {
                Issue.record("\(drill.id) n'a pas d'objet")
                continue
            }
            let picture = PictureLibrary.word(word)
            #expect(picture != nil, "\(word)")
            #expect(drill.answer == .letter(picture?.letter ?? " "))
            #expect(Set(drill.choices).isSubset(of: allowed))
        }
    }

    /// The accents are offered even though no object starts with è: telling
    /// it from é is the exercise.
    @Test func offersTheAccentsOfTheWeeksVowels() {
        var random = SeededRandom(seed: 23)
        let drills = DrillFactory.session(mode: .vowels, week: week(), progress: WeekProgress(), random: &random)
        let offered = Set(drills.flatMap(\.choices))
        #expect(offered.contains(.letter("é")) || offered.contains(.letter("è")))
    }

    /// The dojo asks the same question before it shows the tile, so a week
    /// without the material never opens on a run that is already over.
    @Test func hasNoVowelSessionWithoutTheMaterial() {
        var random = SeededRandom(seed: 24)
        for vowels in [GlyphList(["z", "w"]), GlyphList(["a"])] {
            let plan = week(vowels: vowels)
            #expect(!DrillFactory.hasVowelGame(plan))
            let drills = DrillFactory.session(mode: .vowels, week: plan, progress: WeekProgress(), random: &random)
            #expect(drills.isEmpty)
        }
        #expect(DrillFactory.hasVowelGame(week()))
    }

    @Test func distractorsStayInsideTheWeek() {
        var random = SeededRandom(seed: 3)
        let plan = week(vowels: ["a", "e", "i"])
        let allowed = Set(plan.letters.vowels.characters.map(DrillChoice.letter))
        let drills = DrillFactory.session(mode: .letters, week: plan, progress: WeekProgress(), random: &random)
        for drill in drills {
            #expect(Set(drill.choices).isSubset(of: allowed))
        }
    }

    @Test func startsWithThreeChoicesAndWidensOnceMastered() {
        #expect(DrillFactory.choiceWidth(for: .hearLetter, progress: WeekProgress(), poolSize: 6) == 3)

        var mastered = WeekProgress()
        for _ in 0..<25 {
            mastered.apply(.answered(key: "a", drill: .hearLetter, firstTry: true, correct: true))
        }
        #expect(DrillFactory.choiceWidth(for: .hearLetter, progress: mastered, poolSize: 6) == 4)
    }

    @Test func neverAsksForMoreChoicesThanTheWeekHas() {
        var random = SeededRandom(seed: 4)
        let plan = week(vowels: ["a", "e"])
        let drills = DrillFactory.session(mode: .letters, week: plan, progress: WeekProgress(), random: &random)
        #expect(drills.allSatisfy { $0.choices.count == 2 })
    }

    @Test func neverRepeatsTheSameTargetBackToBack() {
        for seed in UInt64(1)...20 {
            var random = SeededRandom(seed: seed)
            let drills = DrillFactory.session(mode: .letters, week: week(), progress: WeekProgress(), random: &random)
            for pair in zip(drills, drills.dropFirst()) {
                #expect(pair.0.answer != pair.1.answer)
            }
        }
    }

    @Test func mixesCountingIntoTheNumberSession() {
        var random = SeededRandom(seed: 5)
        let drills = DrillFactory.session(mode: .numbers, week: week(), progress: WeekProgress(), random: &random)
        #expect(drills.contains { $0.kind == .countObjects })
        #expect(drills.contains { $0.kind == .hearNumber })
    }

    @Test func countingNeverShowsAnEmptyPile() {
        for seed in UInt64(1)...20 {
            var random = SeededRandom(seed: seed)
            let drills = DrillFactory.session(mode: .numbers, week: week(), progress: WeekProgress(), random: &random)
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
        let drills = DrillFactory.session(mode: .numbers, week: week(), progress: WeekProgress(), random: &random)
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
        let drills = DrillFactory.session(mode: .numbers, week: week(counting: false), progress: WeekProgress(), random: &random)
        #expect(drills.allSatisfy { $0.kind == .hearNumber })
    }

    @Test func favoursWhatHeGetsWrong() {
        var progress = WeekProgress()
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

    /// "Presque exclusivement de 10 à 20": most drills stay in the focus, and
    /// a drill never mixes the two slices, or a lone two digit number among
    /// single digits would give itself away.
    @Test func dwellsOnTheFocusRange() {
        var inFocus = 0
        var total = 0
        for seed in UInt64(1)...40 {
            var random = SeededRandom(seed: seed)
            let plan = week(digitsTo: 20, focus: NumberSpan(from: 10, to: 20))
            let drills = DrillFactory.session(mode: .numbers, week: plan, progress: WeekProgress(), random: &random)
            for drill in drills {
                total += 1
                guard let value = answered(drill) else { continue }
                if value >= 10 { inFocus += 1 }
                let choices = drill.choices.compactMap { choice -> Int? in
                    guard case let .number(number) = choice else { return nil }
                    return number
                }
                #expect(choices.allSatisfy { ($0 >= 10) == (value >= 10) }, "les deux blocs se mélangent dans \(choices)")
            }
        }
        #expect(Double(inFocus) / Double(total) > 0.8)
        #expect(inFocus < total, "le reste de la semaine doit encore revenir")
    }

    @Test func aFocusOutsideTheWeekIsIgnored() {
        var random = SeededRandom(seed: 3)
        let plan = week(digitsTo: 9, focus: NumberSpan(from: 30, to: 40))
        let drills = DrillFactory.session(mode: .numbers, week: plan, progress: WeekProgress(), random: &random)
        #expect(drills.count == DrillFactory.drillsPerSession)
        #expect(drills.compactMap(answered).allSatisfy { (0...9).contains($0) })
    }

    @Test func countsUpToTwentyBricks() {
        var seen: Set<Int> = []
        for seed in UInt64(1)...60 {
            var random = SeededRandom(seed: seed)
            let plan = week(digitsTo: 20, focus: NumberSpan(from: 10, to: 20))
            let drills = DrillFactory.session(mode: .numbers, week: plan, progress: WeekProgress(), random: &random)
            for drill in drills where drill.kind == .countObjects {
                guard case let .bricks(count) = drill.prompt else { continue }
                #expect((1...DrillFactory.countingLimit).contains(count))
                seen.insert(count)
            }
        }
        #expect(seen.contains { $0 > 10 })
    }

    // MARK: Names

    @Test func asksNamesAmongFiveChoices() {
        var random = SeededRandom(seed: 9)
        let drills = DrillFactory.session(mode: .names, week: week(names: classNames), progress: WeekProgress(), random: &random)
        #expect(drills.count == DrillFactory.drillsPerSession)
        for drill in drills {
            #expect(drill.kind == .hearName)
            #expect(drill.choices.count == DrillFactory.nameChoices)
            #expect(Set(drill.choices).count == DrillFactory.nameChoices)
            #expect(drill.isCorrect(drill.answer))
            guard case let .spokenName(name) = drill.prompt else {
                Issue.record("a name drill must speak a name")
                continue
            }
            #expect(drill.answer == .name(name))
            #expect(classNames.contains(name))
        }
    }

    @Test func aSmallClassGetsFewerNameChoices() {
        var random = SeededRandom(seed: 10)
        let drills = DrillFactory.session(mode: .names, week: week(names: ["Ariel", "Zoé", "Sam"]), progress: WeekProgress(), random: &random)
        #expect(drills.allSatisfy { $0.choices.count == 3 })
    }

    @Test func namesNeedAtLeastTwoToBeAsked() {
        var random = SeededRandom(seed: 11)
        #expect(DrillFactory.session(mode: .names, week: week(names: ["Ariel"]), progress: WeekProgress(), random: &random).isEmpty)
        #expect(DrillFactory.session(mode: .names, week: week(), progress: WeekProgress(), random: &random).isEmpty)
    }

    @Test func neverAsksTheSameNameBackToBack() {
        for seed in UInt64(1)...20 {
            var random = SeededRandom(seed: seed)
            let drills = DrillFactory.session(mode: .names, week: week(names: classNames), progress: WeekProgress(), random: &random)
            for pair in zip(drills, drills.dropFirst()) {
                #expect(pair.0.answer != pair.1.answer)
            }
        }
    }

    @Test func isDeterministicForAGivenSeed() {
        var left = SeededRandom(seed: 99)
        var right = SeededRandom(seed: 99)
        let a = DrillFactory.session(mode: .numbers, week: week(), progress: WeekProgress(), random: &left)
        let b = DrillFactory.session(mode: .numbers, week: week(), progress: WeekProgress(), random: &right)
        #expect(a == b)
    }

    @Test func returnsNothingForAnEmptyWeek() {
        var random = SeededRandom(seed: 8)
        #expect(DrillFactory.session(mode: .letters, week: week(vowels: []), progress: WeekProgress(), random: &random).isEmpty)
    }
}
