import Foundation

/// How often a hint may show. Two misses in a row still open it, but only once
/// a minute: he had worked out that a pair of wrong taps on purpose lights up
/// the answer, so the hint now has to be waited for.
struct HintTimer: Equatable, Sendable {
    static let cooldown: TimeInterval = 60

    /// The first hint of a screen is free; each one spent pushes this forward.
    private(set) var readyAt: Date = .distantPast

    func isReady(at now: Date) -> Bool { now >= readyAt }

    /// Seconds still to wait, for the corner counter. Zero when the hint is
    /// there for the taking, which is when the counter disappears.
    func remaining(at now: Date) -> TimeInterval { max(0, readyAt.timeIntervalSince(now)) }

    mutating func spend(at now: Date) { readyAt = now.addingTimeInterval(HintTimer.cooldown) }
}
