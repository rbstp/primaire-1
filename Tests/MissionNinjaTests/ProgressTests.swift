import Foundation
import Testing

@testable import MissionNinja

private let calendar = Calendar(identifier: .gregorian)

private func tick(_ day: Int, task: String = "deux-lignes") -> TaskTick {
    TaskTick(week: "2026-09-07", task: task, day: DayKey(year: 2026, month: 9, day: day))
}

@Suite struct ProgressTests {
    @Test func aFirstTryAnswerEarnsOneStar() {
        var progress = Progress()
        progress.apply(.answered(key: "a", drill: .hearLetter, firstTry: true, correct: true))
        #expect(progress.stars == 1)
        #expect(progress.record(for: "a").firstTries == 1)
        #expect(progress.record(for: .hearLetter).solvedFirstTry == 1)
    }

    @Test func aSecondTryAnswerEarnsNothing() {
        var progress = Progress()
        progress.apply(.answered(key: "a", drill: .hearLetter, firstTry: false, correct: true))
        #expect(progress.stars == 0)
        #expect(progress.record(for: "a").successes == 1)
        #expect(progress.record(for: "a").firstTries == 0)
    }

    @Test func aMissIsRecordedWithoutPunishment() {
        var progress = Progress()
        progress.apply(.answered(key: "e", drill: .hearLetter, firstTry: true, correct: false))
        #expect(progress.stars == 0)
        #expect(progress.record(for: "e").attempts == 1)
        #expect(progress.record(for: "e").successes == 0)
    }

    @Test func aTaskPaysAStarOnlyOnce() {
        var progress = Progress()
        progress.apply(.tickedTask(tick(8)))
        #expect(progress.stars == 1)
        progress.apply(.untickedTask(tick(8)))
        progress.apply(.tickedTask(tick(8)))
        #expect(progress.stars == 1)
        #expect(progress.isTicked(tick(8)))
    }

    @Test func untickingNeverTakesAStarBack() {
        var progress = Progress()
        progress.apply(.tickedTask(tick(8)))
        progress.apply(.untickedTask(tick(8)))
        #expect(progress.stars == 1)
        #expect(!progress.isTicked(tick(8)))
    }

    @Test func theSameTaskOnAnotherDayPaysAgain() {
        var progress = Progress()
        progress.apply(.tickedTask(tick(8)))
        progress.apply(.tickedTask(tick(9)))
        #expect(progress.stars == 2)
    }

    @Test func countsConsecutivePracticeDays() {
        var progress = Progress()
        for day in 7...10 { progress.apply(.practised(DayKey(year: 2026, month: 9, day: day))) }
        #expect(progress.streak(on: DayKey(year: 2026, month: 9, day: 10), calendar: calendar) == 4)
    }

    @Test func aStreakStaysAliveUntilTheNextDayIsMissed() {
        var progress = Progress()
        for day in 7...9 { progress.apply(.practised(DayKey(year: 2026, month: 9, day: day))) }
        #expect(progress.streak(on: DayKey(year: 2026, month: 9, day: 10), calendar: calendar) == 3)
        #expect(progress.streak(on: DayKey(year: 2026, month: 9, day: 11), calendar: calendar) == 0)
    }

    @Test func aGapBreaksTheStreak() {
        var progress = Progress()
        for day in [5, 6, 9, 10] { progress.apply(.practised(DayKey(year: 2026, month: 9, day: day))) }
        #expect(progress.streak(on: DayKey(year: 2026, month: 9, day: 10), calendar: calendar) == 2)
    }

    /// Weakness drives which characters come back, so a never seen one has to
    /// rank above a mastered one.
    @Test func weaknessRanksNeverSeenAboveMastered() {
        var progress = Progress()
        for _ in 0..<5 {
            progress.apply(.answered(key: "a", drill: .hearLetter, firstTry: true, correct: true))
        }
        progress.apply(.answered(key: "e", drill: .hearLetter, firstTry: true, correct: false))
        #expect(progress.record(for: "i").weakness == 1)
        #expect(progress.record(for: "e").weakness == 1)
        #expect(progress.record(for: "a").weakness == 0)
    }

    @Test func historyIsBounded() {
        var progress = Progress()
        var day = DayKey(year: 2024, month: 1, day: 1)
        for _ in 0..<(Progress.dayHistoryLimit + 50) {
            progress.apply(.practised(day))
            day = day.adding(days: 1, in: calendar) ?? day
        }
        #expect(progress.practiceDays.count == Progress.dayHistoryLimit)
        #expect(progress.practiceDays.min() ?? DayKey(year: 0, month: 1, day: 1) > DayKey(year: 2024, month: 1, day: 1))
    }

    @Test func decodesADocumentMissingNewerFields() throws {
        let older = Data(#"{"schema":1,"stars":7}"#.utf8)
        let decoded = try JSONDecoder().decode(Progress.self, from: older)
        #expect(decoded.stars == 7)
        #expect(decoded.characters.isEmpty)
        #expect(decoded.practiceDays.isEmpty)
    }

    @Test func survivesARoundTrip() throws {
        var progress = Progress()
        progress.apply(.answered(key: "o", drill: .countObjects, firstTry: true, correct: true))
        progress.apply(.tracedGlyph("4", clean: false))
        progress.apply(.tickedTask(tick(8)))
        progress.apply(.practised(DayKey(year: 2026, month: 9, day: 8)))
        let data = try JSONEncoder().encode(progress)
        #expect(try JSONDecoder().decode(Progress.self, from: data) == progress)
    }

    @Test func tracingAGlyphEarnsAStar() {
        var progress = Progress()
        progress.apply(.tracedGlyph("7", clean: true))
        #expect(progress.stars == 1)
        #expect(progress.timesTraced("7") == 1)
        #expect(progress.timesTracedCleanly("7") == 1)
        #expect(progress.record(for: .trace).solvedFirstTry == 1)
    }

    /// Writing a letter well says nothing about hearing it, so tracing must not
    /// make a letter look mastered and stop it being asked.
    @Test func tracingDoesNotCountAsListening() {
        var progress = Progress()
        for _ in 0..<10 { progress.apply(.tracedGlyph("a", clean: true)) }
        #expect(progress.record(for: "a") == CharacterRecord())
        #expect(progress.record(for: "a").weakness == 1)
        #expect(progress.timesTraced("a") == 10)
    }

    /// Scribbling until the checkpoints happen to be hit still finishes the
    /// glyph, but the parent screen can tell it apart.
    @Test func aScribbledTraceIsCountedSeparately() {
        var progress = Progress()
        progress.apply(.tracedGlyph("a", clean: true))
        progress.apply(.tracedGlyph("a", clean: false))
        #expect(progress.timesTraced("a") == 2)
        #expect(progress.timesTracedCleanly("a") == 1)
        #expect(progress.stars == 2)
    }

    /// A week reaching 10 used to trap: a two digit number has no single
    /// character form.
    @Test func handlesATwoDigitNumber() {
        var progress = Progress()
        progress.apply(.answered(key: "10", drill: .hearNumber, firstTry: true, correct: true))
        #expect(progress.stars == 1)
        #expect(progress.record(for: "10").firstTries == 1)
    }
}
