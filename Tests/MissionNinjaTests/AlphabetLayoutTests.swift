import Testing

@testable import MissionNinja

@Suite struct AlphabetLayoutTests {
    /// The reason the layout exists: five to a row left a twenty-sixth letter
    /// alone on a sixth row, which pushed the dragon off an iPhone in portrait.
    @Test func spreadsTheAlphabetWithoutALonelyRow() {
        let sizes = AlphabetLayout.rows(26).map(\.count)
        #expect(sizes == [6, 5, 5, 5, 5])
    }

    @Test func neverGoesWiderThanTheGrid() {
        for count in 1...40 {
            let sizes = AlphabetLayout.rows(count).map(\.count)
            #expect(sizes.allSatisfy { $0 <= AlphabetLayout.maxColumns }, "\(count) déborde")
            #expect((sizes.max() ?? 0) - (sizes.min() ?? 0) <= 1, "\(count) mal réparti")
        }
    }

    @Test func coversEveryLetterOnce() {
        for count in 0...40 {
            let covered = AlphabetLayout.rows(count).flatMap { Array($0) }
            #expect(covered == Array(0..<count), "\(count) mal découpé")
        }
    }

    @Test func handlesAShortAlphabet() {
        #expect(AlphabetLayout.rows(0).isEmpty)
        #expect(AlphabetLayout.rows(2) == [0..<2])
    }

    /// The hint lights a whole row, so it has to know which one holds a letter.
    @Test func findsTheRowHoldingALetter() {
        #expect(AlphabetLayout.row(of: 0, count: 26) == 0)
        #expect(AlphabetLayout.row(of: 5, count: 26) == 0)
        #expect(AlphabetLayout.row(of: 6, count: 26) == 1)
        #expect(AlphabetLayout.row(of: 25, count: 26) == 4)
        #expect(AlphabetLayout.row(of: 26, count: 26) == nil)
    }
}
