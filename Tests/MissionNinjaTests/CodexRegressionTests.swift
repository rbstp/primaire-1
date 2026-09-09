import Foundation
import Testing

@testable import MissionNinja

/// Regressions for defects an adversarial review turned up. Each one was
/// reachable in the shipped build.
@Suite struct TracingRegressionTests {
    /// The dot used the stray radius, which was wide enough to reach the top of
    /// the stem right below it, so tapping the already drawn stem completed the
    /// dot without ever touching it.
    @Test func theDotOnAnICannotBeCompletedFromTheStem() throws {
        let glyph = try #require(GlyphLibrary.glyph(for: "i"))
        let stem = glyph.strokes[0]
        let dot = glyph.strokes[1]

        var validator = TraceValidator(stroke: dot, canvasSide: 360)
        #expect(validator.isDot)
        #expect(validator.began(at: stem.first) == .ignored)
        #expect(!validator.isComplete)

        #expect(validator.began(at: dot.first) == .finished)
    }

    @Test func theDotSitsClearOfTheStem() throws {
        let glyph = try #require(GlyphLibrary.glyph(for: "i"))
        let gap = glyph.strokes[0].first.distance(to: glyph.strokes[1].first)
        let capture = TraceValidator.Tolerance.forCanvas(side: 360).capture
        #expect(gap > capture * 1.5, "le point est à \(gap) de la tige")
    }

    /// The widened tolerance was unreachable: the counter lived in a method
    /// nobody called, and wiping the glyph rebuilt the engine from zero.
    @MainActor
    @Test func wipingTwiceWidensTheTarget() throws {
        let glyph = try #require(GlyphLibrary.glyph(for: "a"))
        let first = TracingEngine(glyph: glyph, side: 360, attempt: 0)
        let third = TracingEngine(glyph: glyph, side: 360, attempt: TracingEngine.easedAfterAttempts)

        #expect(!first.isEased)
        #expect(third.isEased)
        #expect(third.tracer.validator.tolerance.capture > first.tracer.validator.tolerance.capture)
    }

    /// Resampling dropped the authored endpoint whenever it landed close to the
    /// last regular sample, quietly shortening the stroke.
    @Test func resamplingAlwaysKeepsTheEndpoint() {
        let line = Polyline(points: [UnitPoint2(x: 0, y: 0), UnitPoint2(x: 1, y: 0)])
        for step in [0.24, 0.1, 0.07, 0.02, 0.333] {
            let even = line.resampled(step: step)
            #expect(even.last == line.last, "pas de \(step)")
            #expect(abs(even.length - 1) < 1e-9, "pas de \(step)")
        }
    }
}

@Suite struct TwoDigitNumberTests {
    /// A week reaching 10 is valid content, and every answer used to trap on
    /// Character(String(10)).
    @Test func aTwoDigitChoiceHasAUsableStatsKey() {
        #expect(DrillChoice.number(10).statKey == "10")
        #expect(DrillChoice.number(7).statKey == "7")
        #expect(DrillChoice.letter("é").statKey == "é")
    }

    @Test func aSessionReachingTenAnswersWithoutTrapping() {
        let week = Week(
            schema: 1,
            id: "2026-10-05",
            title: "Semaine",
            grade: "1re année",
            teacher: "Mme Catherine",
            days: [],
            letters: LetterPlan(vowels: ["a"], alphabet: true),
            numbers: NumberPlan(from: 0, to: 10, counting: true),
            tracing: [],
            names: [],
            tasks: []
        )
        var random = SeededRandom(seed: 1)
        var session = DrillSession(
            drills: DrillFactory.session(mode: .numbers, week: week, progress: WeekProgress(), random: &random)
        )
        var progress = Progress()
        while let drill = session.current {
            guard let answer = session.answer(drill.answer) else { break }
            for event in answer.events { progress.apply(event, in: "2026-10-05") }
        }
        #expect(session.isFinished)
        #expect(progress.stars == DrillFactory.drillsPerSession)
    }

    /// Counting is its own skill: its choice count must follow its own history,
    /// not how well he recognises a spoken number.
    @Test func countingWidensOnItsOwnHistory() {
        var progress = Progress()
        for _ in 0..<25 {
            progress.apply(.answered(key: "3", drill: .hearNumber, firstTry: true, correct: true), in: "2026-09-07")
        }
        let listening = progress.week("2026-09-07")
        #expect(DrillFactory.choiceWidth(for: .hearNumber, progress: listening, poolSize: 10) == 4)
        #expect(DrillFactory.choiceWidth(for: .countObjects, progress: listening, poolSize: 10) == 3)
    }
}

@Suite struct SalvagedDocumentTests {
    /// The unreadable document was kept aside but nothing ever surfaced it, so
    /// the parent saw zero stars with no explanation.
    @MainActor
    @Test func theParentScreenCanSeeThatADocumentWasLost() {
        let defaults = UserDefaults(suiteName: "test-\(UUID().uuidString)")!
        defaults.set(Data("pas du json".utf8), forKey: UserDefaultsProgress.key)
        let persistence = UserDefaultsProgress(defaults: defaults)
        let store = ProgressStore(persistence: persistence)

        #expect(store.stars == 0)
        #expect(store.lostAPreviousDocument)
    }

    @MainActor
    @Test func nothingIsFlaggedOnAHealthyStore() {
        #expect(!ProgressStore(persistence: InMemoryProgress()).lostAPreviousDocument)
    }
}
