import Foundation

/// A calendar day, never a point in time. Checking off a task on a Saturday
/// evening must not drift into Sunday when the clock changes.
struct DayKey: Codable, Hashable, Sendable, Comparable {
    let year: Int
    let month: Int
    let day: Int

    init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    init(_ date: Date, calendar: Calendar) {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        self.year = parts.year ?? 0
        self.month = parts.month ?? 0
        self.day = parts.day ?? 0
    }

    init?(isoDay: String) {
        let parts = isoDay.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 3,
              let year = Int(parts[0]), let month = Int(parts[1]), let day = Int(parts[2]),
              (1...12).contains(month), (1...31).contains(day)
        else { return nil }
        self.init(year: year, month: month, day: day)
    }

    var isoDay: String {
        String(format: "%04d-%02d-%02d", year, month, day)
    }

    func date(in calendar: Calendar) -> Date? {
        calendar.date(from: DateComponents(year: year, month: month, day: day))
    }

    func adding(days: Int, in calendar: Calendar) -> DayKey? {
        guard let start = date(in: calendar),
              let moved = calendar.date(byAdding: .day, value: days, to: start)
        else { return nil }
        return DayKey(moved, calendar: calendar)
    }

    static func < (lhs: DayKey, rhs: DayKey) -> Bool {
        (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
    }
}
