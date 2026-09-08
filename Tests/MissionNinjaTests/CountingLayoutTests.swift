import Testing

@testable import MissionNinja

@Suite struct CountingLayoutTests {
    @Test func placesExactlyTheBricksAsked() {
        for count in 1...9 {
            let slots = CountingLayout.slots(count: count, seed: 4)
            #expect(slots.count == count)
            #expect(Set(slots).count == count, "deux briques sur la même case")
            #expect(slots.allSatisfy { (0..<(CountingLayout.columns * CountingLayout.rows)).contains($0) })
        }
    }

    /// The pile must hold still while he counts, so the same drill always
    /// lands the same way.
    @Test func isStableForOneDrill() {
        #expect(CountingLayout.slots(count: 6, seed: 11) == CountingLayout.slots(count: 6, seed: 11))
    }

    /// And it must not always be the same pile, or the shape gives the count.
    @Test func changesFromOneDrillToTheNext() {
        let layouts = Set((0..<12).map { CountingLayout.slots(count: 6, seed: $0) })
        #expect(layouts.count > 6)
    }

    @Test func neverAsksForMoreThanTheGridHolds() {
        #expect(CountingLayout.slots(count: 40, seed: 1).count == CountingLayout.columns * CountingLayout.rows)
        #expect(CountingLayout.slots(count: 0, seed: 1).isEmpty)
    }
}
