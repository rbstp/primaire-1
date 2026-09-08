import Foundation
import Testing

@testable import MissionNinja

private func scratchDefaults() -> UserDefaults {
    UserDefaults(suiteName: "test-\(UUID().uuidString)") ?? .standard
}

@Suite struct ProgressPersistenceTests {
    @Test func roundTripsThroughUserDefaults() {
        let defaults = scratchDefaults()
        let store = UserDefaultsProgress(defaults: defaults)
        var progress = Progress()
        progress.apply(.answered(key: "a", drill: .hearLetter, firstTry: true, correct: true))
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
        stored.apply(.tracedGlyph("7", clean: true))
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
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "America/Toronto"))
        let store = ProgressStore(persistence: InMemoryProgress(), calendar: calendar)
        let tuesday = try #require(calendar.date(from: DateComponents(year: 2026, month: 9, day: 8, hour: 19)))
        let wednesday = try #require(calendar.date(from: DateComponents(year: 2026, month: 9, day: 9, hour: 7)))

        store.markPractised(on: tuesday)
        store.markPractised(on: wednesday)
        #expect(store.streak(on: wednesday) == 2)
    }

    @Test func resetClearsEverythingAndWritesIt() {
        let persistence = InMemoryProgress()
        let store = ProgressStore(persistence: persistence)
        store.apply(.tracedGlyph("3", clean: true))
        store.reset()
        #expect(store.stars == 0)
        #expect(persistence.load() == Progress())
    }

    @Test func aBeltFollowsTheStarCount() {
        var stored = Progress()
        stored.stars = 61
        let store = ProgressStore(persistence: InMemoryProgress(stored))
        #expect(store.belt == .orange)
        #expect(store.beltAdvance > 0)
    }
}
