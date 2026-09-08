import Foundation

protocol ProgressPersisting: Sendable {
    func load() -> Progress
    func save(_ progress: Progress)
    /// True when a previous document could not be decoded and was set aside,
    /// so the parent screen can say why the stars went back to zero.
    var hasSalvagedDocument: Bool { get }
}

/// UserDefaults is documented as thread safe but the SDK does not annotate it
/// as Sendable, so the instance stays confined here.
final class UserDefaultsProgress: ProgressPersisting, @unchecked Sendable {
    static let key = "progress"
    static let salvageKey = "progress.unreadable"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> Progress {
        guard let data = defaults.data(forKey: Self.key) else { return Progress() }
        do {
            return try JSONDecoder().decode(Progress.self, from: data)
        } catch {
            // Never wipe his stars in silence: keep the unreadable document so
            // the parent screen can say something happened.
            defaults.set(data, forKey: Self.salvageKey)
            return Progress()
        }
    }

    func save(_ progress: Progress) {
        guard let data = try? JSONEncoder().encode(progress) else { return }
        defaults.set(data, forKey: Self.key)
    }

    var hasSalvagedDocument: Bool { defaults.data(forKey: Self.salvageKey) != nil }
}

final class InMemoryProgress: ProgressPersisting, @unchecked Sendable {
    private let lock = NSLock()
    private var stored: Progress
    private(set) var saveCount = 0
    let hasSalvagedDocument = false

    init(_ progress: Progress = Progress()) {
        stored = progress
    }

    func load() -> Progress {
        lock.withLock { stored }
    }

    func save(_ progress: Progress) {
        lock.withLock {
            stored = progress
            saveCount += 1
        }
    }
}
