import Foundation

/// One tick of one task on one day.
struct TaskTick: Codable, Hashable, Sendable {
    let week: String
    let task: String
    let day: DayKey
}

struct CharacterRecord: Codable, Equatable, Sendable {
    var attempts = 0
    var successes = 0
    var firstTries = 0

    var successRate: Double {
        attempts > 0 ? Double(successes) / Double(attempts) : 0
    }

    /// A character we have never seen counts as weak so it gets asked.
    var weakness: Double {
        attempts == 0 ? 1 : 1 - Double(firstTries) / Double(attempts)
    }
}

struct DrillRecord: Codable, Equatable, Sendable {
    var asked = 0
    var solvedFirstTry = 0
}

enum ProgressEvent: Equatable, Sendable {
    /// The key is a string, not a character: a two digit number has no single
    /// character form, and forcing one traps at runtime.
    case answered(key: String, drill: DrillKind, firstTry: Bool, correct: Bool)
    case tracedGlyph(Character, clean: Bool)
    case tickedTask(TaskTick)
    case untickedTask(TaskTick)
    case practised(DayKey)
}

/// Everything the app remembers. A plain value, so every rule below is a pure
/// function and testable without SwiftUI or UserDefaults.
struct Progress: Codable, Equatable, Sendable {
    static let currentSchema = 1
    static let dayHistoryLimit = 400

    var schema = Progress.currentSchema
    var stars = 0
    /// Listening and reading, keyed by the character or number asked.
    var characters: [String: CharacterRecord] = [:]
    /// Handwriting, kept apart: writing an a well says nothing about hearing
    /// it, and mixing the two made a well traced letter stop being asked.
    var traced: [String: Int] = [:]
    /// Of those, the ones where the finger stayed on the line. Shown to the
    /// parent rather than used against him.
    var tracedClean: [String: Int] = [:]
    var drills: [String: DrillRecord] = [:]
    var tickedTasks: Set<TaskTick> = []
    var practiceDays: Set<DayKey> = []
    /// Ticks that have already paid out a star, so unticking and reticking a
    /// task cannot farm stars.
    var paidTicks: Set<TaskTick> = []

    init() {}

    init(from decoder: any Decoder) throws {
        let box = try decoder.container(keyedBy: CodingKeys.self)
        schema = try box.decodeIfPresent(Int.self, forKey: .schema) ?? Progress.currentSchema
        stars = try box.decodeIfPresent(Int.self, forKey: .stars) ?? 0
        characters = try box.decodeIfPresent([String: CharacterRecord].self, forKey: .characters) ?? [:]
        traced = try box.decodeIfPresent([String: Int].self, forKey: .traced) ?? [:]
        tracedClean = try box.decodeIfPresent([String: Int].self, forKey: .tracedClean) ?? [:]
        drills = try box.decodeIfPresent([String: DrillRecord].self, forKey: .drills) ?? [:]
        tickedTasks = try box.decodeIfPresent(Set<TaskTick>.self, forKey: .tickedTasks) ?? []
        practiceDays = try box.decodeIfPresent(Set<DayKey>.self, forKey: .practiceDays) ?? []
        paidTicks = try box.decodeIfPresent(Set<TaskTick>.self, forKey: .paidTicks) ?? []
    }

    var belt: Belt { Belt.earned(stars: stars) }
    var beltAdvance: Double { Belt.advance(stars: stars) }

    func record(for key: String) -> CharacterRecord {
        characters[key] ?? CharacterRecord()
    }

    func record(for character: Character) -> CharacterRecord {
        record(for: String(character))
    }

    func record(for drill: DrillKind) -> DrillRecord {
        drills[drill.rawValue] ?? DrillRecord()
    }

    func timesTraced(_ character: Character) -> Int {
        traced[String(character)] ?? 0
    }

    func timesTracedCleanly(_ character: Character) -> Int {
        tracedClean[String(character)] ?? 0
    }

    func isTicked(_ tick: TaskTick) -> Bool { tickedTasks.contains(tick) }

    mutating func apply(_ event: ProgressEvent) {
        switch event {
        case let .answered(key, drill, firstTry, correct):
            var entry = record(for: key)
            entry.attempts += 1
            if correct { entry.successes += 1 }
            if correct && firstTry { entry.firstTries += 1 }
            characters[key] = entry

            var kind = record(for: drill)
            kind.asked += 1
            if correct && firstTry {
                kind.solvedFirstTry += 1
                stars += 1
            }
            drills[drill.rawValue] = kind

        case let .tracedGlyph(character, clean):
            traced[String(character), default: 0] += 1
            if clean { tracedClean[String(character), default: 0] += 1 }
            var kind = record(for: .trace)
            kind.asked += 1
            kind.solvedFirstTry += 1
            drills[DrillKind.trace.rawValue] = kind
            stars += 1

        case let .tickedTask(tick):
            tickedTasks.insert(tick)
            if paidTicks.insert(tick).inserted { stars += 1 }

        case let .untickedTask(tick):
            tickedTasks.remove(tick)

        case let .practised(day):
            practiceDays.insert(day)
            trimHistory()
        }
    }

    /// Consecutive days of practice ending today, or ending yesterday when
    /// today has not been played yet so the streak still reads as alive.
    func streak(on today: DayKey, calendar: Calendar) -> Int {
        var cursor = today
        if !practiceDays.contains(cursor) {
            guard let yesterday = today.adding(days: -1, in: calendar),
                  practiceDays.contains(yesterday)
            else { return 0 }
            cursor = yesterday
        }
        var length = 0
        while practiceDays.contains(cursor) {
            length += 1
            guard let earlier = cursor.adding(days: -1, in: calendar) else { break }
            cursor = earlier
        }
        return length
    }

    private mutating func trimHistory() {
        guard practiceDays.count > Progress.dayHistoryLimit else { return }
        practiceDays = Set(practiceDays.sorted().suffix(Progress.dayHistoryLimit))
    }
}
