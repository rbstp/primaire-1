import Foundation
import Testing

@testable import MissionNinja

@Suite struct DayKeyTests {
    @Test func parsesAnIsoDay() {
        let key = DayKey(isoDay: "2026-09-07")
        #expect(key == DayKey(year: 2026, month: 9, day: 7))
        #expect(key?.isoDay == "2026-09-07")
    }

    @Test func rejectsNonsense() {
        #expect(DayKey(isoDay: "2026-09") == nil)
        #expect(DayKey(isoDay: "2026-13-01") == nil)
        #expect(DayKey(isoDay: "pas-une-date-x") == nil)
    }

    @Test func ordersChronologically() {
        #expect(DayKey(year: 2026, month: 9, day: 7) < DayKey(year: 2026, month: 10, day: 1))
        #expect(DayKey(year: 2025, month: 12, day: 31) < DayKey(year: 2026, month: 1, day: 1))
    }

    /// A task ticked late on a Saturday must stay on that Saturday, even across
    /// the switch off daylight saving time in Quebec.
    @Test func doesNotDriftAcrossTheClockChange() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "America/Toronto"))
        let saturdayLate = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 31, hour: 23, minute: 30)))
        #expect(DayKey(saturdayLate, calendar: calendar) == DayKey(year: 2026, month: 10, day: 31))
        #expect(DayKey(year: 2026, month: 10, day: 31).adding(days: 1, in: calendar) == DayKey(year: 2026, month: 11, day: 1))
    }
}
