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
        progress.apply(.answered(character: "a", drill: .hearLetter, firstTry: true, correct: true))
        #expect(progress.stars == 1)
        #expect(progress.record(for: "a").firstTries == 1)
        #expect(progress.record(for: .hearLetter).solvedFirstTry == 1)
    }

    @Test func aSecondTryAnswerEarnsNothing() {
        var progress = Progress()
        progress.apply(.answered(character: "a", drill: .hearLetter, firstTry: false, correct: true))
        #expect(progress.stars == 0)
        #expect(progress.record(for: "a").successes == 1)
        #expect(progress.record(for: "a").firstTries == 0)
    }

    @Test func aMissIsRecordedWithoutPunishment() {
        var progress = Progress()
        progress.apply(.answered(character: "e", drill: .hearLetter, firstTry: true, correct: false))
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

    @Test func neverSeenCharactersComeFirst() {
        var progress = Progress()
        for _ in 0..<5 {
            progress.apply(.answered(character: "a", drill: .hearLetter, firstTry: true, correct: true))
        }
        progress.apply(.answered(character: "e", drill: .hearLetter, firstTry: true, correct: false))
        let order = progress.weakest(among: ["a", "e", "i"], limit: 3)
        #expect(order.first == "i")
        #expect(order.last == "a")
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

    @Test func mergingTwoDevicesNeverLosesAStar() {
        var phone = Progress()
        phone.apply(.answered(character: "a", drill: .hearLetter, firstTry: true, correct: true))
        phone.apply(.practised(DayKey(year: 2026, month: 9, day: 8)))
        var pad = Progress()
        for _ in 0..<3 {
            pad.apply(.answered(character: "e", drill: .hearNumber, firstTry: true, correct: true))
        }
        pad.apply(.practised(DayKey(year: 2026, month: 9, day: 9)))

        let merged = Progress.merged(phone, pad)
        #expect(merged.stars == 3)
        #expect(merged.practiceDays.count == 2)
        #expect(Progress.merged(phone, pad) == Progress.merged(pad, phone))
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
        progress.apply(.answered(character: "o", drill: .countObjects, firstTry: true, correct: true))
        progress.apply(.tickedTask(tick(8)))
        progress.apply(.practised(DayKey(year: 2026, month: 9, day: 8)))
        let data = try JSONEncoder().encode(progress)
        #expect(try JSONDecoder().decode(Progress.self, from: data) == progress)
    }

    @Test func tracingAGlyphEarnsAStar() {
        var progress = Progress()
        progress.apply(.tracedGlyph("7"))
        #expect(progress.stars == 1)
        #expect(progress.record(for: "7").firstTries == 1)
    }
}
