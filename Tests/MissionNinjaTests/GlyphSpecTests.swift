import Testing

@testable import MissionNinja

@Suite struct GlyphStrokeTests {
    @Test func flattensAStraightLine() {
        let stroke = GlyphStroke(start: UnitPoint2(x: 0, y: 0), segments: [
            .line(to: UnitPoint2(x: 1, y: 0)),
        ])
        let line = stroke.polyline()
        #expect(line.first == UnitPoint2(x: 0, y: 0))
        #expect(line.last == UnitPoint2(x: 1, y: 0))
        #expect(abs(line.length - 1) < 1e-9)
    }

    @Test func flattensAFullCircleToItsCircumference() {
        let radius = 0.25
        let stroke = GlyphStroke(start: UnitPoint2(x: 0.5 + radius, y: 0.5), segments: [
            .arc(centre: UnitPoint2(x: 0.5, y: 0.5), rx: radius, ry: radius, from: 0, to: 1),
        ])
        let circle = stroke.polyline()
        let circumference = 2 * Double.pi * radius
        #expect(abs(circle.length - circumference) < circumference * 0.01)
        #expect(circle.first.distance(to: circle.last) < 0.01)
    }

    /// Angles grow clockwise on screen, because y points down.
    @Test func aQuarterTurnGoesClockwise() {
        let stroke = GlyphStroke(start: UnitPoint2(x: 0.8, y: 0.5), segments: [
            .arc(centre: UnitPoint2(x: 0.5, y: 0.5), rx: 0.3, ry: 0.3, from: 0, to: 0.25),
        ])
        let quarter = stroke.polyline()
        #expect(abs(quarter.last.x - 0.5) < 0.02)
        #expect(quarter.last.y > 0.7)
    }

    @Test func flattensAnEllipseWiderThanItIsTall() {
        let stroke = GlyphStroke(start: UnitPoint2(x: 0.9, y: 0.5), segments: [
            .arc(centre: UnitPoint2(x: 0.5, y: 0.5), rx: 0.4, ry: 0.2, from: 0, to: 1),
        ])
        let points = stroke.polyline().points
        #expect((points.map(\.x).max() ?? 0) > 0.88)
        #expect((points.map(\.y).max() ?? 0) < 0.72)
    }

    @Test func aCubicPassesThroughBothEnds() {
        let stroke = GlyphStroke(start: UnitPoint2(x: 0.1, y: 0.9), segments: [
            .curve(to: UnitPoint2(x: 0.9, y: 0.1),
                   control1: UnitPoint2(x: 0.1, y: 0.1),
                   control2: UnitPoint2(x: 0.9, y: 0.9)),
        ])
        let curve = stroke.polyline()
        #expect(curve.first.distance(to: UnitPoint2(x: 0.1, y: 0.9)) < 0.01)
        #expect(curve.last.distance(to: UnitPoint2(x: 0.9, y: 0.1)) < 0.01)
        #expect(curve.length > 1.1)
    }

    @Test func chainsSegmentsFromWhereTheLastOneEnded() {
        let stroke = GlyphStroke(start: UnitPoint2(x: 0.2, y: 0.2), segments: [
            .line(to: UnitPoint2(x: 0.8, y: 0.2)),
            .line(to: UnitPoint2(x: 0.8, y: 0.8)),
        ])
        let path = stroke.polyline()
        #expect(abs(path.length - 1.2) < 0.01)
        #expect(path.last == UnitPoint2(x: 0.8, y: 0.8))
    }
}
