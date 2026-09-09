import Foundation
import Testing

@testable import MissionNinja

private func scratchDefaults() -> UserDefaults {
    UserDefaults(suiteName: "test-\(UUID().uuidString)") ?? .standard
}

private func torontoCalendar() throws -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = try #require(TimeZone(identifier: "America/Toronto"))
    return calendar
}

@Suite struct ProgressPersistenceTests {
    @Test func roundTripsThroughUserDefaults() {
        let defaults = scratchDefaults()
        let store = UserDefaultsProgress(defaults: defaults)
        var progress = Progress()
        progress.apply(.answered(key: "a", drill: .hearLetter, firstTry: true, correct: true), in: "2026-09-07")
        store.save(progress)

        #expect(UserDefaultsProgress(defaults: defaults).load() == progress)
    }

    @Test func startsEmptyWithNothingStored() {
        #expect(UserDefaultsProgress(defaults: scratchDefaults()).load() == Progress())
    }

    /// Losing a six year old's stars to a bad decode is not acceptable, so the
    /// unreadable document is kept aside rather than thrown away.
    @Test func keepsAnUnreadableDocumentAside() {
        let defaults = scratchDefaults()
        defaults.set(Data("pas du json".utf8), forKey: UserDefaultsProgress.key)
        let store = UserDefaultsProgress(defaults: defaults)

        #expect(store.load() == Progress())
        #expect(store.hasSalvagedDocument)
        #expect(defaults.data(forKey: UserDefaultsProgress.salvageKey) == Data("pas du json".utf8))
    }
}

@MainActor
@Suite struct ProgressStoreTests {
    @Test func loadsWhatWasStored() {
        var stored = Progress()
        stored.apply(.tracedGlyph("7", clean: true), in: "2026-09-07")
        let store = ProgressStore(persistence: InMemoryProgress(stored))
        #expect(store.stars == 1)
    }

    @Test func flushWritesImmediately() {
        let persistence = InMemoryProgress()
        let store = ProgressStore(persistence: persistence)
        store.apply(.answered(key: "a", drill: .hearLetter, firstTry: true, correct: true))
        store.flush()
        #expect(persistence.load().stars == 1)
    }

    @Test func appliesABatchOfEvents() {
        let persistence = InMemoryProgress()
        let store = ProgressStore(persistence: persistence)
        store.apply([
            .answered(key: "a", drill: .hearLetter, firstTry: true, correct: true),
            .answered(key: "e", drill: .hearLetter, firstTry: true, correct: true),
        ])
        #expect(store.stars == 2)
        #expect(store.thisWeek.stars == 2)
    }

    @Test func togglingATaskFlipsItBothWays() {
        let store = ProgressStore(persistence: InMemoryProgress())
        let tick = TaskTick(week: "2026-09-07", task: "deux-lignes", day: DayKey(year: 2026, month: 9, day: 8))
        store.toggle(tick)
        #expect(store.isTicked(tick))
        store.toggle(tick)
        #expect(!store.isTicked(tick))
        #expect(store.stars == 1)
    }

    @Test func aStreakUsesTheInjectedCalendar() throws {
        let calendar = try torontoCalendar()
        let store = ProgressStore(persistence: InMemoryProgress(), calendar: calendar)
        let tuesday = try #require(calendar.date(from: DateComponents(year: 2026, month: 9, day: 8, hour: 19)))
        let wednesday = try #require(calendar.date(from: DateComponents(year: 2026, month: 9, day: 9, hour: 7)))

        store.markPractised(on: tuesday)
        store.markPractised(on: wednesday)
        #expect(store.streak(on: wednesday) == 2)
    }

    /// Events file under the Monday of the day they happen, Sunday included.
    @Test func filesEventsUnderTheWeeksMonday() throws {
        let calendar = try torontoCalendar()
        let store = ProgressStore(persistence: InMemoryProgress(), calendar: calendar)
        let sunday = try #require(calendar.date(from: DateComponents(year: 2026, month: 9, day: 13, hour: 20)))
        let monday = try #require(calendar.date(from: DateComponents(year: 2026, month: 9, day: 14, hour: 8)))
        #expect(store.weekKey(sunday) == "2026-09-07")
        #expect(store.weekKey(monday) == "2026-09-14")
    }

    /// The foreground stretch is filed when it ends, into the week it ends in.
    @Test func countsTimeInTheForeground() throws {
        let calendar = try torontoCalendar()
        let store = ProgressStore(persistence: InMemoryProgress(), calendar: calendar)
        let start = try #require(calendar.date(from: DateComponents(year: 2026, month: 9, day: 8, hour: 18)))
        let later = start.addingTimeInterval(125)
        let pause = start.addingTimeInterval(300)

        store.resume(at: start)
        store.resume(at: later)
        #expect(store.secondsThisWeek(at: later) == 125)
        #expect(store.progress.week("2026-09-07").seconds == 0)

        store.pause(at: pause)
        store.pause(at: pause)
        #expect(store.progress.week("2026-09-07").seconds == 300)
        #expect(store.secondsThisWeek(at: pause.addingTimeInterval(60)) == 300)
    }

    @Test func aResetRestartsTheOpenStretch() throws {
        let calendar = try torontoCalendar()
        let store = ProgressStore(persistence: InMemoryProgress(), calendar: calendar)
        let start = try #require(calendar.date(from: DateComponents(year: 2026, month: 9, day: 8, hour: 18)))
        store.resume(at: start)
        store.reset()
        store.pause(at: start.addingTimeInterval(3600))
        #expect(store.progress.week("2026-09-07").seconds < 3600)
    }

    @Test func pausingWithoutResumingDoesNothing() {
        let persistence = InMemoryProgress()
        let store = ProgressStore(persistence: persistence)
        store.pause()
        #expect(store.progress == Progress())
    }

    @Test func resetClearsEverythingAndWritesIt() {
        let persistence = InMemoryProgress()
        let store = ProgressStore(persistence: persistence)
        store.apply(.tracedGlyph("3", clean: true))
        store.reset()
        #expect(store.stars == 0)
        #expect(persistence.load() == Progress())
    }

    @Test func aBeltFollowsTheWeeksStars() {
        let store = ProgressStore(persistence: InMemoryProgress())
        for _ in 0..<31 {
            store.apply(.answered(key: "a", drill: .hearLetter, firstTry: true, correct: true))
        }
        #expect(store.belt == .orange)
        #expect(store.beltAdvance > 0)
    }

    /// Stars from an earlier week count for the total, not for today's belt.
    @Test func lastWeeksStarsDoNotColourThisWeeksBelt() {
        var stored = Progress()
        for _ in 0..<40 {
            stored.apply(.tracedGlyph("a", clean: true), in: "2000-01-03")
        }
        let store = ProgressStore(persistence: InMemoryProgress(stored))
        #expect(store.stars == 40)
        #expect(store.belt == .white)
        #expect(store.thisWeek.stars == 0)
    }
}
