import Foundation

/// One weekly lesson plan, decoded from Resources/Weeks/<id>.json.
struct Week: Codable, Equatable, Sendable, Identifiable {
    let schema: Int
    let id: String
    let title: String
    let grade: String
    let teacher: String
    let days: [SchoolDay]
    let letters: LetterPlan
    let numbers: NumberPlan
    let tracing: GlyphList
    /// The classmates' first names, written as they are on the bus cards.
    /// Optional in the file, and two children sharing a name are one card.
    let names: [String]
    let tasks: [HomeworkTask]

    static let currentSchema = 1

    init(
        schema: Int, id: String, title: String, grade: String, teacher: String,
        days: [SchoolDay], letters: LetterPlan, numbers: NumberPlan,
        tracing: GlyphList, names: [String] = [], tasks: [HomeworkTask]
    ) {
        self.schema = schema
        self.id = id
        self.title = title
        self.grade = grade
        self.teacher = teacher
        self.days = days
        self.letters = letters
        self.numbers = numbers
        self.tracing = tracing
        self.names = Week.unique(names)
        self.tasks = tasks
    }

    init(from decoder: any Decoder) throws {
        let box = try decoder.container(keyedBy: CodingKeys.self)
        schema = try box.decode(Int.self, forKey: .schema)
        id = try box.decode(String.self, forKey: .id)
        title = try box.decode(String.self, forKey: .title)
        grade = try box.decode(String.self, forKey: .grade)
        teacher = try box.decode(String.self, forKey: .teacher)
        days = try box.decode([SchoolDay].self, forKey: .days)
        letters = try box.decode(LetterPlan.self, forKey: .letters)
        numbers = try box.decode(NumberPlan.self, forKey: .numbers)
        tracing = try box.decode(GlyphList.self, forKey: .tracing)
        names = Week.unique(try box.decodeIfPresent([String].self, forKey: .names) ?? [])
        tasks = try box.decode([HomeworkTask].self, forKey: .tasks)
    }

    private static func unique(_ names: [String]) -> [String] {
        var seen: Set<String> = []
        return names.filter { seen.insert($0).inserted }
    }

    var monday: DayKey? { DayKey(isoDay: id) }

    var schoolDays: [SchoolDay] { days.filter(\.atSchool) }
}

struct SchoolDay: Codable, Equatable, Sendable, Identifiable {
    let name: String
    let atSchool: Bool
    let note: String?

    var id: String { name }
}

struct LetterPlan: Codable, Equatable, Sendable {
    let vowels: GlyphList
    let alphabet: Bool

    static let frenchAlphabet: [Character] = Array("abcdefghijklmnopqrstuvwxyz")
}

struct NumberPlan: Codable, Equatable, Sendable {
    let from: Int
    let to: Int
    let counting: Bool
    /// The part of the range the drills dwell on, when the week goes further
    /// than what he is actually working on.
    var focus: NumberSpan? = nil

    var digits: [Int] { Array(from...max(from, to)) }

    /// The numbers to ask most of the time. Empty when there is no focus or it
    /// lies outside the week, so callers fall back to the whole range.
    var focused: [Int] {
        guard let focus else { return [] }
        return digits.filter { (focus.from...max(focus.from, focus.to)).contains($0) }
    }
}

struct NumberSpan: Codable, Equatable, Sendable {
    let from: Int
    let to: Int
}

struct HomeworkTask: Codable, Equatable, Sendable, Identifiable {
    let id: String
    let title: String
    let place: String?
}
