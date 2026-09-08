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
    let tasks: [HomeworkTask]

    static let currentSchema = 1

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

    var digits: [Int] { Array(from...max(from, to)) }
}

struct HomeworkTask: Codable, Equatable, Sendable, Identifiable {
    let id: String
    let title: String
    let place: String?
}
