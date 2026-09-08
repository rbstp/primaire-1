import Foundation

/// The reward ladder. Stars only ever go up, so a belt is never lost.
enum Belt: Int, CaseIterable, Codable, Sendable, Comparable {
    case white, yellow, orange, green, blue, brown, black

    var starsRequired: Int {
        switch self {
        case .white: 0
        case .yellow: 25
        case .orange: 60
        case .green: 120
        case .blue: 200
        case .brown: 320
        case .black: 500
        }
    }

    var name: String {
        switch self {
        case .white: "ceinture blanche"
        case .yellow: "ceinture jaune"
        case .orange: "ceinture orange"
        case .green: "ceinture verte"
        case .blue: "ceinture bleue"
        case .brown: "ceinture brune"
        case .black: "ceinture noire"
        }
    }

    var paint: Paint {
        switch self {
        case .white: BeltPaint.white
        case .yellow: BeltPaint.yellow
        case .orange: BeltPaint.orange
        case .green: BeltPaint.green
        case .blue: BeltPaint.blue
        case .brown: BeltPaint.brown
        case .black: BeltPaint.black
        }
    }

    var next: Belt? { Belt(rawValue: rawValue + 1) }

    static func earned(stars: Int) -> Belt {
        allCases.last { stars >= $0.starsRequired } ?? .white
    }

    /// How far along we are towards the next belt, from 0 to 1. A black belt
    /// sits at 1 so the ring reads as complete rather than empty.
    static func advance(stars: Int) -> Double {
        let belt = earned(stars: stars)
        guard let next = belt.next else { return 1 }
        let span = next.starsRequired - belt.starsRequired
        guard span > 0 else { return 1 }
        return min(max(Double(stars - belt.starsRequired) / Double(span), 0), 1)
    }

    static func < (lhs: Belt, rhs: Belt) -> Bool { lhs.rawValue < rhs.rawValue }
}
