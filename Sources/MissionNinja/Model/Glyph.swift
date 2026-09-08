import Foundation

/// One pen movement, authored as segments rather than as a dense polyline: an
/// o is two arcs, not sixty points.
enum GlyphSegment: Equatable, Sendable {
    case line(to: UnitPoint2)
    /// Angles in turns, 0 at three o'clock, growing clockwise on screen
    /// because y points down. A circle is simply rx equal to ry.
    case arc(centre: UnitPoint2, rx: Double, ry: Double, from: Double, to: Double)
    case curve(to: UnitPoint2, control1: UnitPoint2, control2: UnitPoint2)
}

struct GlyphStroke: Equatable, Sendable {
    let start: UnitPoint2
    let segments: [GlyphSegment]
}

/// A character as it is taught to write it: strokes in order, each one in the
/// direction the pen actually goes.
struct GlyphSpec: Equatable, Sendable {
    let character: Character
    let strokes: [GlyphStroke]
}

/// A stroke flattened to evenly spaced samples. Even spacing is what lets every
/// tolerance below be expressed as a fraction of arc length.
struct Polyline: Equatable, Sendable {
    static let sampleStep = 0.02

    let points: [UnitPoint2]
    let cumulative: [Double]

    init(points: [UnitPoint2]) {
        self.points = points
        var running = [0.0]
        running.reserveCapacity(points.count)
        for index in 1..<max(points.count, 1) {
            running.append(running[index - 1] + points[index].distance(to: points[index - 1]))
        }
        cumulative = running
    }

    var length: Double { cumulative.last ?? 0 }
    var first: UnitPoint2 { points.first ?? .zero }
    var last: UnitPoint2 { points.last ?? .zero }

    func arcLength(at index: Int) -> Double {
        cumulative[min(max(index, 0), cumulative.count - 1)]
    }

    /// The direction the pen should be going at this sample.
    func tangent(at index: Int) -> UnitPoint2 {
        guard points.count > 1 else { return .zero }
        let ahead = min(index + 1, points.count - 1)
        let behind = max(ahead - 1, 0)
        return (points[ahead] - points[behind]).normalized
    }

    /// The furthest sample whose arc length is within span of the one at index.
    func lastIndex(within span: Double, from index: Int) -> Int {
        let limit = arcLength(at: index) + span
        var found = index
        var probe = index + 1
        while probe < points.count, cumulative[probe] <= limit {
            found = probe
            probe += 1
        }
        return found
    }

    /// Even samples along the path, so a tolerance in arc length behaves the
    /// same everywhere no matter how the glyph was authored.
    func resampled(step: Double = Polyline.sampleStep) -> Polyline {
        guard points.count > 1, length > 0, step > 0 else { return self }
        var out = [first]
        var target = step
        var index = 1
        var walked = 0.0
        var anchor = first

        while index < points.count {
            let next = points[index]
            let span = anchor.distance(to: next)
            if span <= 0 {
                index += 1
                continue
            }
            if walked + span >= target {
                let cut = (target - walked) / span
                anchor = anchor.lerp(to: next, cut)
                out.append(anchor)
                walked = target
                target += step
            } else {
                walked += span
                anchor = next
                index += 1
            }
        }
        if out.last?.distance(to: last) ?? 1 > step / 4 { out.append(last) }
        return Polyline(points: out)
    }
}

extension GlyphStroke {
    /// Flatten the authored segments, then even out the spacing.
    func polyline(curveSteps: Int = 24, arcSteps: Int = 28) -> Polyline {
        var points = [start]
        var cursor = start
        for segment in segments {
            switch segment {
            case let .line(to):
                points.append(to)
                cursor = to
            case let .arc(centre, rx, ry, from, to):
                let steps = max(arcSteps, Int(abs(to - from) * Double(arcSteps)))
                for step in 1...steps {
                    let turn = from + (to - from) * Double(step) / Double(steps)
                    let angle = turn * 2 * .pi
                    points.append(UnitPoint2(
                        x: centre.x + cos(angle) * rx,
                        y: centre.y + sin(angle) * ry
                    ))
                }
                cursor = points[points.count - 1]
            case let .curve(to, control1, control2):
                for step in 1...curveSteps {
                    let t = Double(step) / Double(curveSteps)
                    points.append(GlyphStroke.cubic(cursor, control1, control2, to, t))
                }
                cursor = to
            }
        }
        return Polyline(points: points).resampled()
    }

    private static func cubic(
        _ a: UnitPoint2, _ b: UnitPoint2, _ c: UnitPoint2, _ d: UnitPoint2, _ t: Double
    ) -> UnitPoint2 {
        let ab = a.lerp(to: b, t)
        let bc = b.lerp(to: c, t)
        let cd = c.lerp(to: d, t)
        return ab.lerp(to: bc, t).lerp(to: bc.lerp(to: cd, t), t)
    }
}

/// A glyph ready to trace.
struct TraceGlyph: Equatable, Sendable {
    let character: Character
    let strokes: [Polyline]

    init(_ spec: GlyphSpec) {
        character = spec.character
        strokes = spec.strokes.map { $0.polyline() }
    }
}
