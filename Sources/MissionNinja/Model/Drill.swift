import Foundation

enum DrillKind: String, CaseIterable, Codable, Sendable {
    case hearLetter
    case hearNumber
    case hearName
    case hearWord
    case buildName
    case countObjects
    case pictureLetter
    case alphabetOrder
    case trace

    var title: String {
        switch self {
        case .hearLetter: "Trouve la lettre"
        case .hearNumber: "Trouve le chiffre ou le nombre"
        case .hearName: "Trouve le prénom"
        case .hearWord: "Trouve le mot"
        case .buildName: "Construis le prénom"
        case .countObjects: "Compte les briques"
        case .pictureLetter: "Trouve la première lettre"
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
    case spokenName(String)
    case spokenWord(String)
    case bricks(Int)
    /// An object drawn in bricks, named by its word. The word is spoken and
    /// never written: on screen it would hand him the letter he is looking for.
    case object(String)
}

enum DrillChoice: Equatable, Hashable, Sendable {
    case letter(Character)
    case number(Int)
    case name(String)
    case word(String)

    var label: String {
        switch self {
        case let .letter(character): String(character)
        case let .number(value): String(value)
        case let .name(name): name
        case let .word(word): word
        }
    }

    /// What these stats are filed under. A string, not a character: a week
    /// reaching 10 has no single character form for it, and forcing one traps.
    var statKey: String {
        switch self {
        case let .letter(character): String(character)
        case let .number(value): String(value)
        case let .name(name): name
        case let .word(word): word
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
