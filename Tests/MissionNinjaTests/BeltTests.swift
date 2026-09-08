import Testing

@testable import MissionNinja

@Suite struct BeltTests {
    @Test func startsWhite() {
        #expect(Belt.earned(stars: 0) == .white)
        #expect(Belt.earned(stars: 24) == .white)
    }

    @Test func climbsOnEachThreshold() {
        #expect(Belt.earned(stars: 25) == .yellow)
        #expect(Belt.earned(stars: 60) == .orange)
        #expect(Belt.earned(stars: 120) == .green)
        #expect(Belt.earned(stars: 200) == .blue)
        #expect(Belt.earned(stars: 320) == .brown)
        #expect(Belt.earned(stars: 500) == .black)
        #expect(Belt.earned(stars: 5000) == .black)
    }

    @Test func thresholdsOnlyGoUp() {
        let steps = Belt.allCases.map(\.starsRequired)
        #expect(steps == steps.sorted())
        #expect(Set(steps).count == steps.count)
    }

    @Test func advanceRunsFromZeroToOneBetweenBelts() {
        #expect(Belt.advance(stars: 25) == 0)
        #expect(Belt.advance(stars: 42) > 0.4)
        #expect(Belt.advance(stars: 42) < 0.6)
        #expect(Belt.advance(stars: 59) < 1)
    }

    @Test func aBlackBeltRingReadsAsComplete() {
        #expect(Belt.advance(stars: 500) == 1)
        #expect(Belt.black.next == nil)
    }
}
