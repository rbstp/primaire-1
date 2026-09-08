import Foundation

/// Every lesson plan shipped in the app, newest first.
struct WeekCatalog: Equatable, Sendable {
    let weeks: [Week]

    init(weeks: [Week]) {
        self.weeks = weeks.sorted { $0.id > $1.id }
    }

    var newest: Week? { weeks.first }

    /// The week we open on: the most recent one that has already started, or
    /// the nearest upcoming one when the school year has not begun yet.
    func current(on today: DayKey) -> Week? {
        weeks.first { week in
            guard let monday = week.monday else { return false }
            return monday <= today
        } ?? newest
    }

    func week(id: String) -> Week? {
        weeks.first { $0.id == id }
    }

    static func decode(from data: [Data]) -> WeekCatalog {
        let decoder = JSONDecoder()
        let weeks = data.compactMap { payload -> Week? in
            guard let week = try? decoder.decode(Week.self, from: payload) else { return nil }
            return week.schema <= Week.currentSchema ? week : nil
        }
        return WeekCatalog(weeks: weeks)
    }

    static func bundled(in bundle: Bundle = .missionNinja) -> WeekCatalog {
        let urls = bundle.urls(forResourcesWithExtension: "json", subdirectory: "Weeks") ?? []
        return decode(from: urls.compactMap { try? Data(contentsOf: $0) })
    }
}

private final class BundleToken {}

extension Bundle {
    /// The app bundle, resolved through a class of this module so unit tests
    /// hosted by the app find the shipped week files too.
    static let missionNinja = Bundle(for: BundleToken.self)
}
