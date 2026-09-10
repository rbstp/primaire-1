import Foundation

/// A small object built out of bricks, authored as text the way the dragon is,
/// so it can be read and redrawn here. The colours stay the app's own: blue
/// and black, cream for what has to be bright, and gold only for an eye.
struct BrickPicture: Equatable, Sendable {
    enum Tone: Character, Sendable {
        case blue = "b"
        case azure = "a"
        case black = "k"
        case cream = "w"
        case gold = "g"
    }

    struct Cell: Hashable, Sendable {
        let x: Int
        let y: Int
        let tone: Tone
    }

    let columns: Int
    let rows: Int
    /// Bottom rows first, so a brick covers the studs of the one below it.
    let cells: [Cell]

    init(_ text: [String]) {
        rows = text.count
        columns = text.map(\.count).max() ?? 0
        var found: [Cell] = []
        for (y, row) in text.enumerated() {
            for (x, character) in row.enumerated() {
                guard let tone = Tone(rawValue: character) else { continue }
                found.append(Cell(x: x, y: y, tone: tone))
            }
        }
        cells = found.sorted { $0.y != $1.y ? $0.y > $1.y : $0.x < $1.x }
    }
}
