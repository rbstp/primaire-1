import Testing

@testable import MissionNinja

@Suite struct CountingLayoutTests {
    /// Whole fives stand as stacks with a 5 on top, the rest lies loose.
    @Test func groupsByFive() {
        #expect(CountingLayout.stacks(count: 4) == 0)
        #expect(CountingLayout.loose(count: 4) == 4)
        #expect(CountingLayout.stacks(count: 5) == 1)
        #expect(CountingLayout.loose(count: 5) == 0)
        #expect(CountingLayout.stacks(count: 13) == 2)
        #expect(CountingLayout.loose(count: 13) == 3)
        #expect(CountingLayout.stacks(count: 20) == 4)
        #expect(CountingLayout.loose(count: 20) == 0)
    }

    @Test func theLooseGridHoldsWhatIsLeftOfAFive() {
        #expect(CountingLayout.columns * CountingLayout.rows >= CountingLayout.stackSize - 1)
        for count in 1..<CountingLayout.stackSize {
            let slots = CountingLayout.slots(count: count, seed: 4)
            #expect(slots.count == count)
            #expect(Set(slots).count == count, "deux briques sur la même case")
            #expect(slots.allSatisfy { (0..<(CountingLayout.columns * CountingLayout.rows)).contains($0) })
        }
    }

    /// The pile must hold still while he counts, so the same drill always
    /// lands the same way.
    @Test func isStableForOneDrill() {
        #expect(CountingLayout.slots(count: 3, seed: 11) == CountingLayout.slots(count: 3, seed: 11))
    }

    /// And it must not always be the same pile, or the shape gives the count.
    @Test func changesFromOneDrillToTheNext() {
        let layouts = Set((0..<12).map { CountingLayout.slots(count: 3, seed: $0) })
        #expect(layouts.count > 4)
    }

    @Test func neverAsksForMoreThanTheGridHolds() {
        #expect(CountingLayout.slots(count: 40, seed: 1).count == CountingLayout.columns * CountingLayout.rows)
        #expect(CountingLayout.slots(count: 0, seed: 1).isEmpty)
    }
}
