import Foundation

/// The dragon he builds one letter at a time. A mosaic of bricks seen from the
/// side, laid out as text so it can be read and redrawn here. The build grows
/// out from the mouth, so the first letters already show him who he is making.
struct DragonBlueprint: Equatable, Sendable {
    enum Tone: Character, Sendable {
        case blue = "b"
        case black = "k"
        case gold = "g"
        case cream = "w"
    }

    struct Cell: Hashable, Sendable {
        let x: Int
        let y: Int
        let tone: Tone
    }

    /// Neck up to the head on the right, wing on the back, tail off to the
    /// left. Gold for the eye, cream for the teeth; every other letter is
    /// body, and the colours are worked out from the shape.
    static let standard = DragonBlueprint(rows: [
        "...................bb...",
        "..................bbbbb.",
        ".................bbbbbbb",
        "................bbgbbbbw",
        "......bb........bbbbbbbw",
        ".....bbbb......bbbbbbbb.",
        "....bbbbbb....bbbb......",
        "...bbbbbbbbb.bbbb.......",
        "..bbbbbbbbbbbbbbb.......",
        ".bbbbbbbbbbbbbbbb.......",
        "bb...bbb.....bbb........",
        "bb...bb......bb.........",
    ])

    let columns: Int
    let rows: Int
    /// Every brick, in the order they are laid.
    let cells: [Cell]
    /// The cell to breathe fire from: the front of the mouth.
    let mouth: Cell?
    let eye: Cell?

    init(rows text: [String]) {
        rows = text.count
        columns = text.map(\.count).max() ?? 0
        var raw: [Cell] = []
        for (y, row) in text.enumerated() {
            for (x, character) in row.enumerated() {
                guard let tone = Tone(rawValue: character) else { continue }
                raw.append(Cell(x: x, y: y, tone: tone))
            }
        }
        // A blue rim around a dark body reads on the night plate; the text
        // only says where the dragon is, the outline is worked out here.
        let occupied = Set(raw.map { [$0.x, $0.y] })
        let found = raw.map { cell -> Cell in
            guard cell.tone == .blue || cell.tone == .black else { return cell }
            let neighbours = [[cell.x - 1, cell.y], [cell.x + 1, cell.y], [cell.x, cell.y - 1], [cell.x, cell.y + 1]]
            let onEdge = neighbours.contains { !occupied.contains($0) }
            return Cell(x: cell.x, y: cell.y, tone: onEdge ? .blue : .black)
        }
        let mouth = found.first { $0.tone == .cream }
        let origin = mouth ?? Cell(x: columns - 1, y: 0, tone: .blue)
        func distance(_ cell: Cell) -> Int {
            (cell.x - origin.x) * (cell.x - origin.x) + (cell.y - origin.y) * (cell.y - origin.y)
        }
        cells = found.sorted { lhs, rhs in
            let (left, right) = (distance(lhs), distance(rhs))
            if left != right { return left < right }
            return lhs.x != rhs.x ? lhs.x > rhs.x : lhs.y < rhs.y
        }
        self.mouth = mouth
        eye = cells.first { $0.tone == .gold }
    }

    /// How many bricks stand after `done` of `total` steps. The last step
    /// always finishes the dragon, and no step lays nothing.
    func laid(after done: Int, of total: Int) -> Int {
        guard total > 0, done > 0 else { return 0 }
        guard done < total else { return cells.count }
        return Int((Double(done) / Double(total) * Double(cells.count)).rounded(.down))
    }

    func standing(after done: Int, of total: Int) -> ArraySlice<Cell> {
        cells.prefix(laid(after: done, of: total))
    }
}
