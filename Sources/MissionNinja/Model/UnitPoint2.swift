import Foundation

/// A point in the glyph's unit square, y pointing down like the screen.
/// Plain arithmetic so every geometry rule stays testable without SwiftUI.
struct UnitPoint2: Equatable, Hashable, Sendable {
    var x: Double
    var y: Double

    static let zero = UnitPoint2(x: 0, y: 0)

    init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }

    static func + (lhs: Self, rhs: Self) -> Self { UnitPoint2(x: lhs.x + rhs.x, y: lhs.y + rhs.y) }
    static func - (lhs: Self, rhs: Self) -> Self { UnitPoint2(x: lhs.x - rhs.x, y: lhs.y - rhs.y) }
    static func * (lhs: Self, rhs: Double) -> Self { UnitPoint2(x: lhs.x * rhs, y: lhs.y * rhs) }

    var length: Double { (x * x + y * y).squareRoot() }

    var normalized: UnitPoint2 {
        let size = length
        return size > 0 ? self * (1 / size) : .zero
    }

    func distance(to other: UnitPoint2) -> Double { (self - other).length }

    func dot(_ other: UnitPoint2) -> Double { x * other.x + y * other.y }

    func lerp(to other: UnitPoint2, _ amount: Double) -> UnitPoint2 {
        self + (other - self) * amount
    }

    /// Distance to the segment ab, not to the infinite line through it.
    func distance(toSegment a: UnitPoint2, _ b: UnitPoint2) -> Double {
        let span = b - a
        let squared = span.dot(span)
        guard squared > 0 else { return distance(to: a) }
        let t = min(max((self - a).dot(span) / squared, 0), 1)
        return distance(to: a.lerp(to: b, t))
    }
}
