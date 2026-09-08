import Foundation

enum DrillKind: String, CaseIterable, Codable, Sendable {
    case hearLetter
    case hearNumber
    case countObjects
    case alphabetOrder
    case trace

    var title: String {
        switch self {
        case .hearLetter: "Trouve la lettre"
        case .hearNumber: "Trouve le chiffre"
        case .countObjects: "Compte les shurikens"
        case .alphabetOrder: "L'alphabet dans l'ordre"
        case .trace: "Le tracé"
        }
    }
}

/// What the child is asked. The prompt is always spoken, because he cannot
/// read the question yet.
enum DrillPrompt: Equatable, Sendable {
    case spokenLetter(Character)
    case spokenNumber(Int)
    case shurikens(Int)
}

enum DrillChoice: Equatable, Hashable, Sendable {
    case letter(Character)
    case number(Int)

    var label: String {
        switch self {
        case let .letter(character): String(character)
        case let .number(value): String(value)
        }
    }

    /// What these stats are filed under. A string, not a character: a week
    /// reaching 10 has no single character form for it, and forcing one traps.
    var statKey: String {
        switch self {
        case let .letter(character): String(character)
        case let .number(value): String(value)
        }
    }
}

struct Drill: Identifiable, Equatable, Sendable {
    let id: Int
    let kind: DrillKind
    let prompt: DrillPrompt
    let choices: [DrillChoice]
    let answerIndex: Int

    var answer: DrillChoice { choices[answerIndex] }

    func isCorrect(_ choice: DrillChoice) -> Bool { choice == answer }
}
