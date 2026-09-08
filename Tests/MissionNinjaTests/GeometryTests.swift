import Testing

@testable import MissionNinja

@Suite struct UnitPoint2Tests {
    @Test func measuresDistance() {
        #expect(UnitPoint2(x: 0, y: 0).distance(to: UnitPoint2(x: 3, y: 4)) == 5)
    }

    @Test func normalisesToUnitLength() {
        let unit = UnitPoint2(x: 3, y: 4).normalized
        #expect(abs(unit.length - 1) < 1e-12)
        #expect(UnitPoint2.zero.normalized == .zero)
    }

    @Test func dotProductTellsDirectionApart() {
        let right = UnitPoint2(x: 1, y: 0)
        #expect(right.dot(right) == 1)
        #expect(right.dot(UnitPoint2(x: -1, y: 0)) == -1)
        #expect(right.dot(UnitPoint2(x: 0, y: 1)) == 0)
    }

    /// Distance to the segment, not to the infinite line: a point beyond an
    /// endpoint must measure to that endpoint.
    @Test func measuresToTheSegmentNotTheLine() {
        let a = UnitPoint2(x: 0, y: 0)
        let b = UnitPoint2(x: 1, y: 0)
        #expect(UnitPoint2(x: 0.5, y: 0.5).distance(toSegment: a, b) == 0.5)
        #expect(UnitPoint2(x: 2, y: 0).distance(toSegment: a, b) == 1)
        #expect(UnitPoint2(x: -1, y: 0).distance(toSegment: a, b) == 1)
        #expect(UnitPoint2(x: 0.3, y: 0).distance(toSegment: a, a) == 0.3)
    }

    @Test func lerpsBetweenEnds() {
        let mid = UnitPoint2(x: 0, y: 0).lerp(to: UnitPoint2(x: 2, y: 4), 0.5)
        #expect(mid == UnitPoint2(x: 1, y: 2))
    }
}

@Suite struct PolylineTests {
    private let diagonal = Polyline(points: [
        UnitPoint2(x: 0, y: 0),
        UnitPoint2(x: 0.3, y: 0),
        UnitPoint2(x: 1, y: 0),
    ])

    @Test func accumulatesArcLength() {
        #expect(diagonal.length == 1)
        #expect(diagonal.arcLength(at: 1) == 0.3)
        #expect(diagonal.arcLength(at: 99) == 1)
    }

    @Test func pointsTheTangentAlongThePath() {
        #expect(diagonal.tangent(at: 0) == UnitPoint2(x: 1, y: 0))
    }

    /// Even spacing is what makes every tolerance in the validator behave the
    /// same regardless of how the glyph was authored.
    @Test func evensOutTheSpacing() {
        let uneven = Polyline(points: [
            UnitPoint2(x: 0, y: 0),
            UnitPoint2(x: 0.02, y: 0),
            UnitPoint2(x: 0.03, y: 0),
            UnitPoint2(x: 1, y: 0),
        ])
        let even = uneven.resampled(step: 0.1)
        let gaps = zip(even.points, even.points.dropFirst()).map { $0.distance(to: $1) }
        #expect(gaps.dropLast().allSatisfy { abs($0 - 0.1) < 1e-9 })
        #expect(abs(even.length - 1) < 1e-9)
    }

    @Test func resamplingKeepsBothEnds() {
        let even = diagonal.resampled(step: 0.07)
        #expect(even.first == diagonal.first)
        #expect(even.last == diagonal.last)
    }

    @Test func resamplingLeavesADegeneratePathAlone() {
        let dot = Polyline(points: [UnitPoint2(x: 0.5, y: 0.5)])
        #expect(dot.resampled() == dot)
    }

    @Test func windowsForwardByArcLength() {
        let even = Polyline(points: (0...10).map { UnitPoint2(x: Double($0) / 10, y: 0) })
        #expect(even.lastIndex(within: 0.25, from: 0) == 2)
        #expect(even.lastIndex(within: 0.25, from: 4) == 6)
        #expect(even.lastIndex(within: 5, from: 0) == 10)
        #expect(even.lastIndex(within: 0, from: 3) == 3)
    }
}
