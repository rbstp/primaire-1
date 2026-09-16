import Foundation

/// How the shuffled letters fall into rows. Six to a row at most, and the
/// count spread evenly, because twenty-six over five rows left a lone letter
/// on a sixth row that pushed the dragon off the screen.
enum AlphabetLayout {
    static let maxColumns = 6

    /// One range of indices per row, the fullest rows first. Twenty-six comes
    /// out 6, 5, 5, 5, 5 rather than 5, 5, 5, 5, 5, 1.
    static func rows(_ count: Int) -> [Range<Int>] {
        guard count > 0 else { return [] }
        let rows = (count + maxColumns - 1) / maxColumns
        let base = count / rows
        let wide = count % rows
        var ranges: [Range<Int>] = []
        var start = 0
        for row in 0..<rows {
            let size = base + (row < wide ? 1 : 0)
            ranges.append(start..<(start + size))
            start += size
        }
        return ranges
    }

    /// The row holding a letter, for the hint that lights a whole row up.
    static func row(of index: Int, count: Int) -> Int? {
        rows(count).firstIndex { $0.contains(index) }
    }
}
