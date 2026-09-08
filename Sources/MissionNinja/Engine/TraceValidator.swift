import Foundation

/// Follows the finger along one stroke. Never fails: the cursor simply stops
/// advancing, which is what keeps a six year old from getting stuck.
///
/// Two guards make closed loops and crossings work. The cursor only ever moves
/// forward, and only within a short window of arc length, so finishing an o
/// cannot snap back to its start. On top of that the finger has to be roughly
/// going the way the pen goes, which is what stops an 8 jumping across its own
/// crossing. There is deliberately no nearest neighbour search anywhere.
struct TraceValidator: Equatable, Sendable {
    struct Tolerance: Equatable, Sendable {
        /// How far off the line still counts, in unit lengths.
        let capture: Double
        /// Past this, he is drawing somewhere else entirely.
        let stray: Double
        /// How far ahead the cursor may jump, as a fraction of arc length.
        let lookAhead: Double
        /// A stroke is done a little before its very end: closing an o to the
        /// pixel is impossible at six, and the first reason children give up.
        let completion: Double
        /// Finger direction against pen direction. Very permissive, so
        /// hesitating does not block him.
        let alignment: Double
        /// Drag events arrive coalesced and can be far apart, so the path
        /// between two of them is walked in steps this long.
        let interpolation: Double

        /// The radius has to be physical: a six year old's fingertip is over a
        /// centimetre across, and the same fraction of a phone and of an iPad
        /// would be two very different targets.
        /// A fingertip is about a centimetre across whatever the screen, so
        /// the radius has a floor and a ceiling in points, not a fixed
        /// fraction: nine percent of an iPad would be a very loose target.
        static func forCanvas(side: Double) -> Tolerance {
            let side = max(side, 1)
            let capture = min(max(30, side * 0.09), 48) / side
            return Tolerance(
                capture: capture,
                stray: capture * 2.2,
                lookAhead: 0.10,
                completion: 0.92,
                alignment: -0.2,
                interpolation: 8 / side
            )
        }

        /// After a couple of tries we widen the target rather than let him fail.
        func eased(by factor: Double) -> Tolerance {
            Tolerance(
                capture: capture * factor,
                stray: stray * factor,
                lookAhead: lookAhead,
                completion: completion,
                alignment: alignment,
                interpolation: interpolation
            )
        }
    }

    enum Step: Equatable, Sendable {
        case ignored
        case advanced
        case strayed
        case finished
    }

    let stroke: Polyline
    var tolerance: Tolerance

    private(set) var cursor = 0
    private(set) var isDown = false
    private(set) var isComplete = false

    init(stroke: Polyline, tolerance: Tolerance) {
        self.stroke = stroke
        self.tolerance = tolerance
    }

    init(stroke: Polyline, canvasSide: Double) {
        self.init(stroke: stroke, tolerance: .forCanvas(side: canvasSide))
    }

    var cursorPoint: UnitPoint2 { stroke.points[min(cursor, stroke.points.count - 1)] }
    var startPoint: UnitPoint2 { stroke.first }

    var advance: Double {
        stroke.length > 0 ? min(stroke.arcLength(at: cursor) / stroke.length, 1) : 1
    }

    /// The start dot has to be touched to begin, and it pulses to say so. It is
    /// the only refusal in the whole screen, and it is visible.
    static let dotLength = 0.06

    /// The dot on an i is a tap, not a gesture, so a stroke this short is done
    /// the moment it is touched.
    var isDot: Bool { stroke.length < TraceValidator.dotLength }

    mutating func began(at point: UnitPoint2) -> Step {
        guard !isComplete else { return .ignored }
        if isDot, point.distance(to: startPoint) <= tolerance.stray {
            cursor = stroke.points.count - 1
            isComplete = true
            return .finished
        }
        if point.distance(to: cursorPoint) <= tolerance.capture {
            isDown = true
            return .advanced
        }
        // Lifting a finger mid stroke is normal; coming back near the start
        // restarts this stroke only, never the whole letter.
        if point.distance(to: startPoint) <= tolerance.capture {
            cursor = 0
            isDown = true
            return .advanced
        }
        return .ignored
    }

    mutating func dragged(from previous: UnitPoint2, to point: UnitPoint2) -> Step {
        guard isDown, !isComplete else { return .ignored }
        let heading = (point - previous).normalized
        let span = previous.distance(to: point)
        let hops = max(1, Int((span / max(tolerance.interpolation, 1e-6)).rounded(.up)))
        var moved = false
        var last = Step.ignored
        for hop in 1...hops {
            let along = previous.lerp(to: point, Double(hop) / Double(hops))
            last = advanceCursor(to: along, heading: heading)
            if last == .finished { return .finished }
            if last == .advanced { moved = true }
        }
        if last == .strayed { return .strayed }
        return moved ? .advanced : last
    }

    mutating func lifted() {
        isDown = false
    }

    mutating func restart() {
        cursor = 0
        isDown = false
        isComplete = false
    }

    private mutating func advanceCursor(to point: UnitPoint2, heading: UnitPoint2) -> Step {
        let window = stroke.lastIndex(within: tolerance.lookAhead * stroke.length, from: cursor)
        let aligned = heading == .zero || heading.dot(stroke.tangent(at: cursor)) > tolerance.alignment

        if aligned, window > cursor {
            var reached = cursor
            for index in (cursor + 1)...window where point.distance(to: stroke.points[index]) <= tolerance.capture {
                reached = index
            }
            if reached > cursor {
                cursor = reached
                if stroke.arcLength(at: cursor) >= stroke.length * tolerance.completion {
                    cursor = stroke.points.count - 1
                    isComplete = true
                    return .finished
                }
                return .advanced
            }
        }

        var nearest = Double.greatestFiniteMagnitude
        for index in cursor...window {
            nearest = min(nearest, point.distance(to: stroke.points[index]))
        }
        return nearest > tolerance.stray ? .strayed : .ignored
    }
}

/// The whole character: strokes in the order they are taught, one after the
/// other.
struct GlyphTracer: Equatable, Sendable {
    let glyph: TraceGlyph
    private(set) var strokeIndex = 0
    private(set) var validator: TraceValidator
    private(set) var isComplete = false
    private var tolerance: TraceValidator.Tolerance

    init(glyph: TraceGlyph, canvasSide: Double) {
        self.glyph = glyph
        tolerance = .forCanvas(side: canvasSide)
        validator = TraceValidator(stroke: glyph.strokes.first ?? Polyline(points: [.zero]), tolerance: tolerance)
    }

    var strokeCount: Int { glyph.strokes.count }

    var advance: Double {
        guard strokeCount > 0, !isComplete else { return 1 }
        return min((Double(strokeIndex) + validator.advance) / Double(strokeCount), 1)
    }

    mutating func began(at point: UnitPoint2) -> TraceValidator.Step {
        let step = validator.began(at: point)
        if step == .finished { finishStroke() }
        return step
    }

    mutating func dragged(from previous: UnitPoint2, to point: UnitPoint2) -> TraceValidator.Step {
        let step = validator.dragged(from: previous, to: point)
        if step == .finished { finishStroke() }
        return step
    }

    mutating func lifted() {
        validator.lifted()
    }

    mutating func restartStroke() {
        validator.restart()
    }

    /// Widen the target after a couple of stuck attempts, for this glyph and
    /// every stroke still to come.
    mutating func ease(by factor: Double) {
        tolerance = tolerance.eased(by: factor)
        validator.tolerance = tolerance
    }

    private mutating func finishStroke() {
        guard strokeIndex + 1 < strokeCount else {
            isComplete = true
            return
        }
        strokeIndex += 1
        validator = TraceValidator(stroke: glyph.strokes[strokeIndex], tolerance: tolerance)
    }
}
