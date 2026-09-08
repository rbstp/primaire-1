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

    init(persistence: any ProgressPersisting = UserDefaultsProgress(), calendar: Calendar = .current) {
        self.persistence = persistence
        self.calendar = calendar
        progress = persistence.load()
    }

    var stars: Int { progress.stars }
    var belt: Belt { progress.belt }
    var beltAdvance: Double { progress.beltAdvance }

    func streak(on date: Date = Date()) -> Int {
        progress.streak(on: DayKey(date, calendar: calendar), calendar: calendar)
    }

    func apply(_ event: ProgressEvent) {
        progress.apply(event)
        scheduleSave()
    }

    func apply(_ events: [ProgressEvent]) {
        for event in events { progress.apply(event) }
        scheduleSave()
    }

    func markPractised(on date: Date = Date()) {
        apply(.practised(DayKey(date, calendar: calendar)))
    }

    func isTicked(_ tick: TaskTick) -> Bool { progress.isTicked(tick) }

    func toggle(_ tick: TaskTick) {
        apply(progress.isTicked(tick) ? .untickedTask(tick) : .tickedTask(tick))
    }

    func today(_ date: Date = Date()) -> DayKey {
        DayKey(date, calendar: calendar)
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
