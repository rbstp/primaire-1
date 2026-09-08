import Testing

@testable import MissionNinja

@Suite struct DragonBlueprintTests {
    let dragon = DragonBlueprint.standard

    @Test func hasAHeadToStartFrom() {
        #expect(dragon.eye != nil)
        #expect(dragon.mouth != nil)
        #expect(dragon.cells.count > 26, "il faut au moins une brique par lettre")
    }

    /// The build grows out from the mouth, so the first letters already show
    /// what he is making.
    @Test func laysTheHeadFirst() {
        let first = dragon.cells.prefix(dragon.cells.count / 3)
        #expect(first.contains { $0 == dragon.eye })
        #expect(first.contains { $0 == dragon.mouth })
    }

    @Test func everyLetterLaysAtLeastOneBrick() {
        var previous = 0
        for done in 1...26 {
            let laid = dragon.laid(after: done, of: 26)
            #expect(laid > previous, "la lettre \(done) ne pose rien")
            previous = laid
        }
    }

    @Test func theLastLetterFinishesTheDragon() {
        #expect(dragon.laid(after: 26, of: 26) == dragon.cells.count)
        #expect(dragon.laid(after: 25, of: 26) < dragon.cells.count)
        #expect(dragon.laid(after: 0, of: 26) == 0)
    }

    @Test func aDegenerateRunDoesNotTrap() {
        #expect(dragon.laid(after: 0, of: 0) == 0)
        #expect(dragon.laid(after: 3, of: 0) == 0)
        #expect(dragon.laid(after: 5, of: 3) == dragon.cells.count)
    }

    @Test func cellsAreUniqueAndInsideTheGrid() {
        #expect(Set(dragon.cells).count == dragon.cells.count)
        for cell in dragon.cells {
            #expect((0..<dragon.columns).contains(cell.x))
            #expect((0..<dragon.rows).contains(cell.y))
        }
    }
}

extension DragonBlueprintTests {
    /// Blue bricks all around, dark ones inside, so the shape reads on a dark plate.
    @Test func rimIsBlueAndBodyIsDark() {
        let occupied = Set(dragon.cells.map { [$0.x, $0.y] })
        for cell in dragon.cells where cell.tone == .blue || cell.tone == .black {
            let neighbours = [[cell.x - 1, cell.y], [cell.x + 1, cell.y], [cell.x, cell.y - 1], [cell.x, cell.y + 1]]
            let onEdge = neighbours.contains { !occupied.contains($0) }
            #expect(cell.tone == (onEdge ? .blue : .black), "brique (\(cell.x), \(cell.y))")
        }
        #expect(dragon.cells.contains { $0.tone == .blue })
        #expect(dragon.cells.contains { $0.tone == .black })
    }
}
