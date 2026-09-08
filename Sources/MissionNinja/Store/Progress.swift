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

    static func merged(_ lhs: Self, _ rhs: Self) -> Self {
        CharacterRecord(
            attempts: max(lhs.attempts, rhs.attempts),
            successes: max(lhs.successes, rhs.successes),
            firstTries: max(lhs.firstTries, rhs.firstTries)
        )
    }
}

struct DrillRecord: Codable, Equatable, Sendable {
    var asked = 0
    var solvedFirstTry = 0

    static func merged(_ lhs: Self, _ rhs: Self) -> Self {
        DrillRecord(
            asked: max(lhs.asked, rhs.asked),
            solvedFirstTry: max(lhs.solvedFirstTry, rhs.solvedFirstTry)
        )
    }
}

enum ProgressEvent: Equatable, Sendable {
    case answered(character: Character, drill: DrillKind, firstTry: Bool, correct: Bool)
    case tracedGlyph(Character)
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
    var characters: [String: CharacterRecord] = [:]
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
        drills = try box.decodeIfPresent([String: DrillRecord].self, forKey: .drills) ?? [:]
        tickedTasks = try box.decodeIfPresent(Set<TaskTick>.self, forKey: .tickedTasks) ?? []
        practiceDays = try box.decodeIfPresent(Set<DayKey>.self, forKey: .practiceDays) ?? []
        paidTicks = try box.decodeIfPresent(Set<TaskTick>.self, forKey: .paidTicks) ?? []
    }

    var belt: Belt { Belt.earned(stars: stars) }
    var beltAdvance: Double { Belt.advance(stars: stars) }

    func record(for character: Character) -> CharacterRecord {
        characters[String(character)] ?? CharacterRecord()
    }

    func record(for drill: DrillKind) -> DrillRecord {
        drills[drill.rawValue] ?? DrillRecord()
    }

    func isTicked(_ tick: TaskTick) -> Bool { tickedTasks.contains(tick) }

    mutating func apply(_ event: ProgressEvent) {
        switch event {
        case let .answered(character, drill, firstTry, correct):
            var entry = record(for: character)
            entry.attempts += 1
            if correct { entry.successes += 1 }
            if correct && firstTry { entry.firstTries += 1 }
            characters[String(character)] = entry

            var kind = record(for: drill)
            kind.asked += 1
            if correct && firstTry {
                kind.solvedFirstTry += 1
                stars += 1
            }
            drills[drill.rawValue] = kind

        case let .tracedGlyph(character):
            var entry = record(for: character)
            entry.attempts += 1
            entry.successes += 1
            entry.firstTries += 1
            characters[String(character)] = entry
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

    /// The characters to ask most, weakest first.
    func weakest(among candidates: [Character], limit: Int) -> [Character] {
        candidates
            .map { (character: $0, weakness: record(for: $0).weakness) }
            .sorted { ($0.weakness, String($0.character)) > ($1.weakness, String($1.character)) }
            .prefix(limit)
            .map(\.character)
    }

    /// Union on the sets, max on the counters: merging two devices can never
    /// take a star away.
    static func merged(_ lhs: Progress, _ rhs: Progress) -> Progress {
        var out = Progress()
        out.schema = max(lhs.schema, rhs.schema)
        out.stars = max(lhs.stars, rhs.stars)
        out.characters = lhs.characters.merging(rhs.characters, uniquingKeysWith: CharacterRecord.merged)
        out.drills = lhs.drills.merging(rhs.drills, uniquingKeysWith: DrillRecord.merged)
        out.tickedTasks = lhs.tickedTasks.union(rhs.tickedTasks)
        out.practiceDays = lhs.practiceDays.union(rhs.practiceDays)
        out.paidTicks = lhs.paidTicks.union(rhs.paidTicks)
        out.trimHistory()
        return out
    }

    private mutating func trimHistory() {
        guard practiceDays.count > Progress.dayHistoryLimit else { return }
        practiceDays = Set(practiceDays.sorted().suffix(Progress.dayHistoryLimit))
    }
}
