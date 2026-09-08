import Foundation

/// One training run. There is no failure state: a miss shows the right answer,
/// then the drill comes back later in the same run. Only a first-try success
/// earns a star.
struct DrillSession: Equatable, Sendable {
    /// A drill dropped after this many misses so a run can never stall.
    static let maxAttempts = 3

    struct Answer: Equatable, Sendable {
        let correct: Bool
        let firstTry: Bool
        let expected: DrillChoice
        let events: [ProgressEvent]
    }

    private var queue: [Drill]
    private var attempts: [Int: Int]
    let total: Int
    private(set) var settled = 0
    private(set) var stars = 0

    init(drills: [Drill]) {
        queue = drills
        attempts = [:]
        total = drills.count
    }

    var current: Drill? { queue.first }
    var isFinished: Bool { queue.isEmpty }
    var advance: Double { total > 0 ? Double(settled) / Double(total) : 1 }
    var attemptsOnCurrent: Int { current.map { attempts[$0.id] ?? 0 } ?? 0 }

    mutating func answer(_ choice: DrillChoice) -> Answer? {
        guard let drill = current else { return nil }
        let taken = (attempts[drill.id] ?? 0) + 1
        attempts[drill.id] = taken
        let firstTry = taken == 1
        let correct = drill.isCorrect(choice)

        queue.removeFirst()
        if correct {
            settled += 1
            if firstTry { stars += 1 }
        } else if taken >= DrillSession.maxAttempts {
            settled += 1
        } else {
            queue.append(drill)
        }

        return Answer(
            correct: correct,
            firstTry: firstTry,
            expected: drill.answer,
            events: [.answered(character: drill.answer.statKey, drill: drill.kind, firstTry: firstTry, correct: correct)]
        )
    }
}
