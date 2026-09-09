import Testing

@testable import MissionNinja

@Suite struct BeltTests {
    @Test func startsWhite() {
        #expect(Belt.earned(stars: 0) == .white)
        #expect(Belt.earned(stars: 11) == .white)
    }

    @Test func climbsOnEachThreshold() {
        #expect(Belt.earned(stars: 12) == .yellow)
        #expect(Belt.earned(stars: 30) == .orange)
        #expect(Belt.earned(stars: 55) == .green)
        #expect(Belt.earned(stars: 85) == .blue)
        #expect(Belt.earned(stars: 120) == .brown)
        #expect(Belt.earned(stars: 160) == .black)
        #expect(Belt.earned(stars: 5000) == .black)
    }

    /// A week is five evenings: the black belt has to be within reach of a
    /// six year old who plays a quarter of an hour a day.
    @Test func aBlackBeltFitsInOneWeek() {
        #expect(Belt.black.starsRequired <= 5 * 40)
    }

    @Test func thresholdsOnlyGoUp() {
        let steps = Belt.allCases.map(\.starsRequired)
        #expect(steps == steps.sorted())
        #expect(Set(steps).count == steps.count)
    }

    @Test func advanceRunsFromZeroToOneBetweenBelts() {
        #expect(Belt.advance(stars: 12) == 0)
        #expect(Belt.advance(stars: 21) == 0.5)
        #expect(Belt.advance(stars: 29) < 1)
    }

    @Test func aBlackBeltRingReadsAsComplete() {
        #expect(Belt.advance(stars: 160) == 1)
        #expect(Belt.black.next == nil)
    }
}
