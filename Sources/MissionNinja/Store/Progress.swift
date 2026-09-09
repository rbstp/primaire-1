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
    case builtName(clean: Bool)
    case tickedTask(TaskTick)
    case untickedTask(TaskTick)
    case practised(DayKey)
    case timeSpent(seconds: Int)
}

/// What one week earned and taught. The belt is read from here, so every
/// Monday he starts over from white.
struct WeekProgress: Codable, Equatable, Sendable {
    var stars = 0
    /// Time with the app in the foreground.
    var seconds = 0
    /// Listening and reading, keyed by the character, number or name asked.
    var characters: [String: CharacterRecord] = [:]
    /// Handwriting, kept apart: writing an a well says nothing about hearing
    /// it, and mixing the two made a well traced letter stop being asked.
    var traced: [String: Int] = [:]
    /// Of those, the ones where the finger stayed on the line. Shown to the
    /// parent rather than used against him.
    var tracedClean: [String: Int] = [:]
    var drills: [String: DrillRecord] = [:]

    init() {}

    init(from decoder: any Decoder) throws {
        let box = try decoder.container(keyedBy: CodingKeys.self)
        stars = try box.decodeIfPresent(Int.self, forKey: .stars) ?? 0
        seconds = try box.decodeIfPresent(Int.self, forKey: .seconds) ?? 0
        characters = try box.decodeIfPresent([String: CharacterRecord].self, forKey: .characters) ?? [:]
        traced = try box.decodeIfPresent([String: Int].self, forKey: .traced) ?? [:]
        tracedClean = try box.decodeIfPresent([String: Int].self, forKey: .tracedClean) ?? [:]
        drills = try box.decodeIfPresent([String: DrillRecord].self, forKey: .drills) ?? [:]
    }

    var belt: Belt { Belt.earned(stars: stars) }
    var beltAdvance: Double { Belt.advance(stars: stars) }

    var asked: Int { drills.values.reduce(0) { $0 + $1.asked } }
    var solvedFirstTry: Int { drills.values.reduce(0) { $0 + $1.solvedFirstTry } }

    func record(for key: String) -> CharacterRecord {
        characters[key] ?? CharacterRecord()
    }

    func record(for character: Character) -> CharacterRecord {
        record(for: String(character))
    }

    func record(for drill: DrillKind) -> DrillRecord {
        drills[drill.rawValue] ?? DrillRecord()
    }

    func timesTraced(_ key: String) -> Int {
        traced[key] ?? 0
    }

    func timesTracedCleanly(_ key: String) -> Int {
        tracedClean[key] ?? 0
    }

    fileprivate mutating func tally(_ drill: DrillKind, firstTry: Bool) {
        var kind = record(for: drill)
        kind.asked += 1
        if firstTry {
            kind.solvedFirstTry += 1
            stars += 1
        }
        drills[drill.rawValue] = kind
    }
}

/// Everything the app remembers. A plain value, so every rule below is a pure
/// function and testable without SwiftUI or UserDefaults.
struct Progress: Codable, Equatable, Sendable {
    static let currentSchema = 2
    static let dayHistoryLimit = 400

    var schema = Progress.currentSchema
    /// Every star ever earned. Belts read the week, this is for the parent.
    var stars = 0
    /// Keyed by the Monday of the week, as an ISO day.
    var weeks: [String: WeekProgress] = [:]
    var tickedTasks: Set<TaskTick> = []
    var practiceDays: Set<DayKey> = []
    /// Ticks that have already paid out a star, so unticking and reticking a
    /// task cannot farm stars.
    var paidTicks: Set<TaskTick> = []

    init() {}

    /// A document from a newer app is refused rather than half read and then
    /// written back over. Older ones are upgraded on the way in.
    init(from decoder: any Decoder) throws {
        let box = try decoder.container(keyedBy: CodingKeys.self)
        let written = try box.decodeIfPresent(Int.self, forKey: .schema) ?? 1
        guard written <= Progress.currentSchema else {
            throw DecodingError.dataCorruptedError(
                forKey: .schema, in: box, debugDescription: "schema \(written) is newer than \(Progress.currentSchema)"
            )
        }
        stars = try box.decodeIfPresent(Int.self, forKey: .stars) ?? 0
        weeks = try box.decodeIfPresent([String: WeekProgress].self, forKey: .weeks) ?? [:]
        tickedTasks = try box.decodeIfPresent(Set<TaskTick>.self, forKey: .tickedTasks) ?? []
        practiceDays = try box.decodeIfPresent(Set<DayKey>.self, forKey: .practiceDays) ?? []
        paidTicks = try box.decodeIfPresent(Set<TaskTick>.self, forKey: .paidTicks) ?? []
    }

    func week(_ key: String) -> WeekProgress {
        weeks[key] ?? WeekProgress()
    }

    /// Newest first.
    var weekKeys: [String] { weeks.keys.sorted(by: >) }

    func isTicked(_ tick: TaskTick) -> Bool { tickedTasks.contains(tick) }

    mutating func apply(_ event: ProgressEvent, in week: String) {
        var current = self.week(week)
        let before = current.stars

        switch event {
        case let .answered(key, drill, firstTry, correct):
            var entry = current.record(for: key)
            entry.attempts += 1
            if correct { entry.successes += 1 }
            if correct && firstTry { entry.firstTries += 1 }
            current.characters[key] = entry
            current.tally(drill, firstTry: correct && firstTry)

        case let .tracedGlyph(character, clean):
            current.traced[String(character), default: 0] += 1
            if clean { current.tracedClean[String(character), default: 0] += 1 }
            current.tally(.trace, firstTry: true)

        case let .builtName(clean):
            var kind = current.record(for: .buildName)
            kind.asked += 1
            if clean { kind.solvedFirstTry += 1 }
            current.drills[DrillKind.buildName.rawValue] = kind
            current.stars += 1

        case let .tickedTask(tick):
            tickedTasks.insert(tick)
            if paidTicks.insert(tick).inserted { current.stars += 1 }

        case let .untickedTask(tick):
            tickedTasks.remove(tick)

        case let .practised(day):
            practiceDays.insert(day)
            trimHistory()

        case let .timeSpent(seconds):
            current.seconds += max(seconds, 0)
        }

        stars += current.stars - before
        if current != WeekProgress() { weeks[week] = current }
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
