import Foundation
import Testing

@testable import MissionNinja

private let calendar = Calendar(identifier: .gregorian)
private let thisWeek = "2026-09-07"
private let nextWeek = "2026-09-14"

private func tick(_ day: Int, task: String = "deux-lignes") -> TaskTick {
    TaskTick(week: thisWeek, task: task, day: DayKey(year: 2026, month: 9, day: day))
}

@Suite struct ProgressTests {
    @Test func aFirstTryAnswerEarnsOneStar() {
        var progress = Progress()
        progress.apply(.answered(key: "a", drill: .hearLetter, firstTry: true, correct: true), in: thisWeek)
        #expect(progress.stars == 1)
        #expect(progress.week(thisWeek).stars == 1)
        #expect(progress.week(thisWeek).record(for: "a").firstTries == 1)
        #expect(progress.week(thisWeek).record(for: .hearLetter).solvedFirstTry == 1)
    }

    @Test func aSecondTryAnswerEarnsNothing() {
        var progress = Progress()
        progress.apply(.answered(key: "a", drill: .hearLetter, firstTry: false, correct: true), in: thisWeek)
        #expect(progress.stars == 0)
        #expect(progress.week(thisWeek).record(for: "a").successes == 1)
        #expect(progress.week(thisWeek).record(for: "a").firstTries == 0)
    }

    @Test func aMissIsRecordedWithoutPunishment() {
        var progress = Progress()
        progress.apply(.answered(key: "e", drill: .hearLetter, firstTry: true, correct: false), in: thisWeek)
        #expect(progress.stars == 0)
        #expect(progress.week(thisWeek).record(for: "e").attempts == 1)
        #expect(progress.week(thisWeek).record(for: "e").successes == 0)
    }

    /// The belt reads the week, so a new Monday starts back at white while
    /// the lifetime count keeps climbing.
    @Test func eachWeekStartsBackAtWhite() {
        var progress = Progress()
        for _ in 0..<30 {
            progress.apply(.answered(key: "a", drill: .hearLetter, firstTry: true, correct: true), in: thisWeek)
        }
        #expect(progress.week(thisWeek).belt == .orange)
        progress.apply(.answered(key: "a", drill: .hearLetter, firstTry: true, correct: true), in: nextWeek)
        #expect(progress.week(nextWeek).belt == .white)
        #expect(progress.week(nextWeek).stars == 1)
        #expect(progress.week(thisWeek).stars == 30)
        #expect(progress.stars == 31)
        #expect(progress.weekKeys == [nextWeek, thisWeek])
    }

    /// A week's stats are its own: what he got wrong last week does not
    /// make a letter come back this week.
    @Test func statsDoNotLeakAcrossWeeks() {
        var progress = Progress()
        progress.apply(.answered(key: "u", drill: .hearLetter, firstTry: true, correct: false), in: thisWeek)
        #expect(progress.week(nextWeek).record(for: "u") == CharacterRecord())
        #expect(progress.week(nextWeek).record(for: .hearLetter) == DrillRecord())
    }

    @Test func aTaskPaysAStarOnlyOnce() {
        var progress = Progress()
        progress.apply(.tickedTask(tick(8)), in: thisWeek)
        #expect(progress.stars == 1)
        progress.apply(.untickedTask(tick(8)), in: thisWeek)
        progress.apply(.tickedTask(tick(8)), in: thisWeek)
        #expect(progress.stars == 1)
        #expect(progress.week(thisWeek).stars == 1)
        #expect(progress.isTicked(tick(8)))
    }

    @Test func untickingNeverTakesAStarBack() {
        var progress = Progress()
        progress.apply(.tickedTask(tick(8)), in: thisWeek)
        progress.apply(.untickedTask(tick(8)), in: thisWeek)
        #expect(progress.stars == 1)
        #expect(!progress.isTicked(tick(8)))
    }

    @Test func theSameTaskOnAnotherDayPaysAgain() {
        var progress = Progress()
        progress.apply(.tickedTask(tick(8)), in: thisWeek)
        progress.apply(.tickedTask(tick(9)), in: thisWeek)
        #expect(progress.stars == 2)
    }

    @Test func timeAddsUpWithinTheWeek() {
        var progress = Progress()
        progress.apply(.timeSpent(seconds: 90), in: thisWeek)
        progress.apply(.timeSpent(seconds: 30), in: thisWeek)
        progress.apply(.timeSpent(seconds: -5), in: thisWeek)
        progress.apply(.timeSpent(seconds: 10), in: nextWeek)
        #expect(progress.week(thisWeek).seconds == 120)
        #expect(progress.week(nextWeek).seconds == 10)
        #expect(progress.stars == 0)
    }

    /// Finishing a name pays a star whatever the misses; the misses only show
    /// in the first try count the parent sees.
    @Test func buildingANameEarnsAStar() {
        var progress = Progress()
        progress.apply(.builtName(clean: true), in: thisWeek)
        progress.apply(.builtName(clean: false), in: thisWeek)
        #expect(progress.stars == 2)
        #expect(progress.week(thisWeek).record(for: .buildName) == DrillRecord(asked: 2, solvedFirstTry: 1))
    }

    @Test func countsConsecutivePracticeDays() {
        var progress = Progress()
        for day in 7...10 { progress.apply(.practised(DayKey(year: 2026, month: 9, day: day)), in: thisWeek) }
        #expect(progress.streak(on: DayKey(year: 2026, month: 9, day: 10), calendar: calendar) == 4)
    }

    @Test func aStreakStaysAliveUntilTheNextDayIsMissed() {
        var progress = Progress()
        for day in 7...9 { progress.apply(.practised(DayKey(year: 2026, month: 9, day: day)), in: thisWeek) }
        #expect(progress.streak(on: DayKey(year: 2026, month: 9, day: 10), calendar: calendar) == 3)
        #expect(progress.streak(on: DayKey(year: 2026, month: 9, day: 11), calendar: calendar) == 0)
    }

    @Test func aGapBreaksTheStreak() {
        var progress = Progress()
        for day in [5, 6, 9, 10] { progress.apply(.practised(DayKey(year: 2026, month: 9, day: day)), in: thisWeek) }
        #expect(progress.streak(on: DayKey(year: 2026, month: 9, day: 10), calendar: calendar) == 2)
    }

    /// Practising alone leaves no week record behind, so the summary does not
    /// list an empty week.
    @Test func practisingAloneCreatesNoWeekRecord() {
        var progress = Progress()
        progress.apply(.practised(DayKey(year: 2026, month: 9, day: 8)), in: thisWeek)
        #expect(progress.weeks.isEmpty)
    }

    /// Weakness drives which characters come back, so a never seen one has to
    /// rank above a mastered one.
    @Test func weaknessRanksNeverSeenAboveMastered() {
        var progress = Progress()
        for _ in 0..<5 {
            progress.apply(.answered(key: "a", drill: .hearLetter, firstTry: true, correct: true), in: thisWeek)
        }
        progress.apply(.answered(key: "e", drill: .hearLetter, firstTry: true, correct: false), in: thisWeek)
        let week = progress.week(thisWeek)
        #expect(week.record(for: "i").weakness == 1)
        #expect(week.record(for: "e").weakness == 1)
        #expect(week.record(for: "a").weakness == 0)
    }

    @Test func historyIsBounded() {
        var progress = Progress()
        var day = DayKey(year: 2024, month: 1, day: 1)
        for _ in 0..<(Progress.dayHistoryLimit + 50) {
            progress.apply(.practised(day), in: thisWeek)
            day = day.adding(days: 1, in: calendar) ?? day
        }
        #expect(progress.practiceDays.count == Progress.dayHistoryLimit)
        #expect(progress.practiceDays.min() ?? DayKey(year: 0, month: 1, day: 1) > DayKey(year: 2024, month: 1, day: 1))
    }

    /// A schema 1 document kept its stats at the top level. They cannot be
    /// filed under a week after the fact, so only the total survives.
    @Test func decodesAnOlderDocumentKeepingTheTotal() throws {
        let older = Data(#"{"schema":1,"stars":7,"characters":{"a":{"attempts":3,"successes":3,"firstTries":3}},"practiceDays":[{"year":2026,"month":9,"day":8}]}"#.utf8)
        let decoded = try JSONDecoder().decode(Progress.self, from: older)
        #expect(decoded.stars == 7)
        #expect(decoded.weeks.isEmpty)
        #expect(decoded.practiceDays.count == 1)
        #expect(decoded.schema == Progress.currentSchema)
    }

    @Test func refusesADocumentFromANewerApp() {
        let newer = Data(#"{"schema":3,"stars":7}"#.utf8)
        #expect(throws: DecodingError.self) { try JSONDecoder().decode(Progress.self, from: newer) }
    }

    @Test func survivesARoundTrip() throws {
        var progress = Progress()
        progress.apply(.answered(key: "o", drill: .countObjects, firstTry: true, correct: true), in: thisWeek)
        progress.apply(.tracedGlyph("4", clean: false), in: thisWeek)
        progress.apply(.builtName(clean: true), in: thisWeek)
        progress.apply(.timeSpent(seconds: 300), in: thisWeek)
        progress.apply(.tickedTask(tick(8)), in: thisWeek)
        progress.apply(.practised(DayKey(year: 2026, month: 9, day: 8)), in: thisWeek)
        let data = try JSONEncoder().encode(progress)
        #expect(try JSONDecoder().decode(Progress.self, from: data) == progress)
    }

    @Test func tracingAGlyphEarnsAStar() {
        var progress = Progress()
        progress.apply(.tracedGlyph("7", clean: true), in: thisWeek)
        #expect(progress.stars == 1)
        #expect(progress.week(thisWeek).timesTraced("7") == 1)
        #expect(progress.week(thisWeek).timesTracedCleanly("7") == 1)
        #expect(progress.week(thisWeek).record(for: .trace).solvedFirstTry == 1)
    }

    /// Writing a letter well says nothing about hearing it, so tracing must not
    /// make a letter look mastered and stop it being asked.
    @Test func tracingDoesNotCountAsListening() {
        var progress = Progress()
        for _ in 0..<10 { progress.apply(.tracedGlyph("a", clean: true), in: thisWeek) }
        #expect(progress.week(thisWeek).record(for: "a") == CharacterRecord())
        #expect(progress.week(thisWeek).record(for: "a").weakness == 1)
        #expect(progress.week(thisWeek).timesTraced("a") == 10)
    }

    /// Scribbling until the checkpoints happen to be hit still finishes the
    /// glyph, but the parent screen can tell it apart.
    @Test func aScribbledTraceIsCountedSeparately() {
        var progress = Progress()
        progress.apply(.tracedGlyph("a", clean: true), in: thisWeek)
        progress.apply(.tracedGlyph("a", clean: false), in: thisWeek)
        #expect(progress.week(thisWeek).timesTraced("a") == 2)
        #expect(progress.week(thisWeek).timesTracedCleanly("a") == 1)
        #expect(progress.stars == 2)
    }

    /// A week reaching 10 used to trap: a two digit number has no single
    /// character form. The parent screen tripped on the same thing.
    @Test func handlesATwoDigitNumber() {
        var progress = Progress()
        progress.apply(.answered(key: "10", drill: .hearNumber, firstTry: true, correct: true), in: thisWeek)
        #expect(progress.stars == 1)
        #expect(progress.week(thisWeek).record(for: "10").firstTries == 1)
        let keys = NumberPlan(from: 0, to: 20, counting: true).digits.map(String.init)
        #expect(keys.contains("20"))
        #expect(progress.week(thisWeek).timesTraced("20") == 0)
    }
}
