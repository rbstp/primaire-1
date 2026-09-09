import Foundation

/// The thin observable shell around Progress. Every rule lives in the value
/// type; this only holds it, hands it to the views, and writes it out.
@MainActor
@Observable
final class ProgressStore {
    static let saveDelay = Duration.seconds(1)

    private(set) var progress: Progress
    private let persistence: any ProgressPersisting
    private let calendar: Calendar
    private var pendingSave: Task<Void, Never>?
    private var activeSince: Date?

    init(persistence: any ProgressPersisting = UserDefaultsProgress(), calendar: Calendar = .current) {
        self.persistence = persistence
        self.calendar = calendar
        progress = persistence.load()
    }

    var stars: Int { progress.stars }
    var lostAPreviousDocument: Bool { persistence.hasSalvagedDocument }

    /// The week under way, which is what the belt and the parent screen read.
    var thisWeek: WeekProgress { progress.week(weekKey()) }
    var belt: Belt { thisWeek.belt }
    var beltAdvance: Double { thisWeek.beltAdvance }

    /// Time in the foreground during the week of that date, counting the
    /// stretch still open.
    func secondsThisWeek(at date: Date = Date()) -> Int {
        progress.week(weekKey(date)).seconds + (activeSince.map { max(Int(date.timeIntervalSince($0)), 0) } ?? 0)
    }

    func streak(on date: Date = Date()) -> Int {
        progress.streak(on: DayKey(date, calendar: calendar), calendar: calendar)
    }

    func apply(_ event: ProgressEvent) {
        progress.apply(event, in: weekKey())
        scheduleSave()
    }

    func apply(_ events: [ProgressEvent]) {
        let week = weekKey()
        for event in events { progress.apply(event, in: week) }
        scheduleSave()
    }

    func markPractised(on date: Date = Date()) {
        apply(.practised(DayKey(date, calendar: calendar)))
    }

    /// The foreground stretch is only filed when it ends, so a crash costs the
    /// minutes of the current stretch and nothing before it.
    func resume(at date: Date = Date()) {
        if activeSince == nil { activeSince = date }
    }

    func pause(at date: Date = Date()) {
        guard let since = activeSince else { return }
        activeSince = nil
        let seconds = Int(date.timeIntervalSince(since))
        if seconds > 0 {
            progress.apply(.timeSpent(seconds: seconds), in: weekKey(date))
            scheduleSave()
        }
    }

    func isTicked(_ tick: TaskTick) -> Bool { progress.isTicked(tick) }

    func toggle(_ tick: TaskTick) {
        apply(progress.isTicked(tick) ? .untickedTask(tick) : .tickedTask(tick))
    }

    func today(_ date: Date = Date()) -> DayKey {
        DayKey(date, calendar: calendar)
    }

    func weekKey(_ date: Date = Date()) -> String {
        today(date).monday(in: calendar).isoDay
    }

    /// Called when the app leaves the foreground: the one moment we know he
    /// might be closing it for good.
    func flush() {
        pendingSave?.cancel()
        pendingSave = nil
        persistence.save(progress)
    }

    func reset() {
        progress = Progress()
        // The open stretch restarts here, or its minutes before the reset
        // would land in the wiped document.
        if activeSince != nil { activeSince = Date() }
        flush()
    }

    private func scheduleSave() {
        pendingSave?.cancel()
        let snapshot = progress
        let persistence = persistence
        pendingSave = Task { [weak self] in
            try? await Task.sleep(for: ProgressStore.saveDelay)
            guard !Task.isCancelled else { return }
            persistence.save(snapshot)
            self?.pendingSave = nil
        }
    }
}
