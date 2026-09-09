import Foundation
import Testing

@testable import MissionNinja

private func week(id: String) -> Week {
    Week(
        schema: 1,
        id: id,
        title: "Semaine \(id)",
        grade: "1re année",
        teacher: "Mme Catherine",
        days: [SchoolDay(name: "lundi", atSchool: true, note: nil)],
        letters: LetterPlan(vowels: ["a"], alphabet: true),
        numbers: NumberPlan(from: 0, to: 9, counting: true),
        tracing: ["a"],
        names: [],
        tasks: []
    )
}

@Suite struct WeekCatalogTests {
    @Test func sortsNewestFirst() {
        let catalog = WeekCatalog(weeks: [week(id: "2026-09-07"), week(id: "2026-09-21"), week(id: "2026-09-14")])
        #expect(catalog.weeks.map(\.id) == ["2026-09-21", "2026-09-14", "2026-09-07"])
        #expect(catalog.newest?.id == "2026-09-21")
    }

    @Test func opensOnTheWeekAlreadyUnderway() {
        let catalog = WeekCatalog(weeks: [week(id: "2026-09-07"), week(id: "2026-09-14"), week(id: "2026-09-21")])
        let wednesday = DayKey(year: 2026, month: 9, day: 16)
        #expect(catalog.current(on: wednesday)?.id == "2026-09-14")
    }

    @Test func opensOnTheMondayItself() {
        let catalog = WeekCatalog(weeks: [week(id: "2026-09-07"), week(id: "2026-09-14")])
        #expect(catalog.current(on: DayKey(year: 2026, month: 9, day: 14))?.id == "2026-09-14")
    }

    @Test func fallsBackToTheNewestBeforeTheYearStarts() {
        let catalog = WeekCatalog(weeks: [week(id: "2026-09-07"), week(id: "2026-09-14")])
        #expect(catalog.current(on: DayKey(year: 2026, month: 8, day: 30))?.id == "2026-09-14")
    }

    @Test func isEmptyWithoutWeeks() {
        #expect(WeekCatalog(weeks: []).current(on: DayKey(year: 2026, month: 9, day: 8)) == nil)
    }

    /// Older week files carry no names and no focus.
    @Test func decodesAWeekWithoutNamesOrFocus() throws {
        let payload = Data(#"{"schema":1,"id":"2026-09-14","title":"x","grade":"x","teacher":"x","days":[],"letters":{"vowels":["a"],"alphabet":true},"numbers":{"from":0,"to":9,"counting":true},"tracing":[],"tasks":[]}"#.utf8)
        let week = try #require(WeekCatalog.decode(from: [payload]).weeks.first)
        #expect(week.names.isEmpty)
        #expect(week.numbers.focus == nil)
        #expect(week.numbers.focused.isEmpty)
    }

    /// Two children with the same first name are one card on the bus.
    @Test func keepsEachNameOnce() {
        let week = Week(
            schema: 1, id: "2026-09-07", title: "x", grade: "x", teacher: "x", days: [],
            letters: LetterPlan(vowels: ["a"], alphabet: true),
            numbers: NumberPlan(from: 0, to: 9, counting: true),
            tracing: [], names: ["Noah", "Zoé", "Noah"], tasks: []
        )
        #expect(week.names == ["Noah", "Zoé"])
    }

    @Test func skipsFilesFromAFutureSchema() {
        let payload = Data(#"{"schema":99,"id":"2027-01-04","title":"x","grade":"x","teacher":"x","days":[],"letters":{"vowels":["a"],"alphabet":true},"numbers":{"from":0,"to":9,"counting":true},"tracing":[],"tasks":[]}"#.utf8)
        #expect(WeekCatalog.decode(from: [payload]).weeks.isEmpty)
    }

    @Test func decodesTheShippedWeek() throws {
        let shipped = try #require(WeekCatalog.bundled().week(id: "2026-09-07"))
        #expect(shipped.letters.vowels == ["a", "e", "i", "o", "u", "y"])
        #expect(shipped.numbers.digits == Array(0...20))
        #expect(shipped.numbers.focused == Array(10...20))
        #expect(shipped.schoolDays.count == 4)
        #expect(shipped.tracing.count == 15)
        #expect(shipped.names.count == 22)
        #expect(shipped.names.contains("Mme Catherine"))
        #expect(shipped.days.first?.note == "Congé, Fête du travail")
        #expect(shipped.monday == DayKey(year: 2026, month: 9, day: 7))
    }
}
