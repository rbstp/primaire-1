import Testing

@testable import MissionNinja

private let canvas = 360.0

/// A straight line across the middle, evenly sampled.
private func straight() -> Polyline {
    Polyline(points: (0...50).map { UnitPoint2(x: 0.1 + Double($0) / 50 * 0.8, y: 0.5) }).resampled()
}

/// A closed circle, which is the shape that breaks a naive nearest neighbour
/// search.
private func circle() -> Polyline {
    GlyphStroke(start: UnitPoint2(x: 0.5, y: 0.28), segments: [
        .arc(centre: UnitPoint2(x: 0.5, y: 0.5), rx: 0.22, ry: 0.22, from: -0.25, to: -1.25),
    ]).polyline()
}

/// Walks the finger along a stroke, in steps that stay inside the tolerance.
private func trace(
    _ validator: inout TraceValidator,
    _ stroke: Polyline,
    stride: Int = 2,
    upTo limit: Double = 1
) -> TraceValidator.Step {
    var step = validator.began(at: stroke.first)
    var previous = stroke.first
    var index = 0
    let last = Int(Double(stroke.points.count - 1) * limit)
    while index < last {
        index = min(index + stride, last)
        let point = stroke.points[index]
        step = validator.dragged(from: previous, to: point)
        previous = point
        if step == .finished { return step }
    }
    return step
}

@Suite struct TraceValidatorTests {
    @Test func toleranceIsPhysicalNotProportional() {
        let phone = TraceValidator.Tolerance.forCanvas(side: 300)
        let pad = TraceValidator.Tolerance.forCanvas(side: 700)
        #expect(phone.capture * 300 >= 30)
        #expect(pad.capture * 700 >= 30)
        // The same fraction on both would make a phone target far too small.
        #expect(phone.capture > pad.capture)
    }

    @Test func aStrokeMustBeStartedAtItsStart() {
        let stroke = straight()
        var validator = TraceValidator(stroke: stroke, canvasSide: canvas)
        #expect(validator.began(at: UnitPoint2(x: 0.9, y: 0.1)) == .ignored)
        #expect(!validator.isDown)
        #expect(validator.began(at: stroke.first) == .advanced)
        #expect(validator.isDown)
    }

    @Test func followingTheLineCompletesIt() {
        let stroke = straight()
        var validator = TraceValidator(stroke: stroke, canvasSide: canvas)
        #expect(trace(&validator, stroke) == .finished)
        #expect(validator.isComplete)
        #expect(validator.advance == 1)
    }

    /// Closing an o to the very last sample is impossible at six, and the first
    /// reason a child gives up.
    @Test func aStrokeEndsALittleBeforeItsEnd() {
        let stroke = straight()
        var validator = TraceValidator(stroke: stroke, canvasSide: canvas)
        #expect(trace(&validator, stroke, upTo: 0.94) == .finished)
    }

    @Test func stoppingShortDoesNotComplete() {
        let stroke = straight()
        var validator = TraceValidator(stroke: stroke, canvasSide: canvas)
        #expect(trace(&validator, stroke, upTo: 0.5) == .advanced)
        #expect(!validator.isComplete)
        #expect(validator.advance > 0.4)
        // The capture radius is generous by design, so the cursor picks up a
        // few samples beyond where the finger actually stopped.
        #expect(validator.advance < 0.72)
    }

    @Test func drawingSomewhereElseIsReportedButNeverFails() {
        let stroke = straight()
        var validator = TraceValidator(stroke: stroke, canvasSide: canvas)
        _ = validator.began(at: stroke.first)
        let step = validator.dragged(from: stroke.first, to: UnitPoint2(x: 0.15, y: 0.05))
        #expect(step == .strayed)
        #expect(!validator.isComplete)
    }

    /// A straight jump across a circle does not follow the arc, so nothing
    /// along the way is captured. This is what stops a swipe from filling in
    /// an o or an 8.
    @Test func aStraightJumpAcrossACurveCapturesNothing() {
        let stroke = circle()
        var validator = TraceValidator(stroke: stroke, canvasSide: canvas)
        _ = validator.began(at: stroke.first)
        _ = validator.dragged(from: stroke.first, to: stroke.points[stroke.points.count / 2])
        #expect(!validator.isComplete)
        #expect(validator.advance < 0.4)
    }

    @Test func theCursorNeverGoesBackwards() {
        let stroke = straight()
        var validator = TraceValidator(stroke: stroke, canvasSide: canvas)
        _ = trace(&validator, stroke, upTo: 0.5)
        let reached = validator.cursor
        _ = validator.dragged(from: stroke.points[reached], to: stroke.first)
        #expect(validator.cursor >= reached)
    }

    /// Coming back around a circle passes right next to the start, which a
    /// nearest neighbour search would latch onto.
    @Test func aClosedLoopDoesNotSnapBackToItsStart() {
        let stroke = circle()
        var validator = TraceValidator(stroke: stroke, canvasSide: canvas)
        #expect(trace(&validator, stroke, stride: 1) == .finished)
        #expect(validator.isComplete)
    }

    @Test func aLoopTracedHalfwayIsHalfDone() {
        let stroke = circle()
        var validator = TraceValidator(stroke: stroke, canvasSide: canvas)
        _ = trace(&validator, stroke, stride: 1, upTo: 0.5)
        #expect(validator.advance > 0.4)
        #expect(validator.advance < 0.6)
        #expect(!validator.isComplete)
    }

    /// He lifts his finger three times per letter. Nothing may be lost.
    @Test func liftingAFingerKeepsTheProgress() {
        let stroke = straight()
        var validator = TraceValidator(stroke: stroke, canvasSide: canvas)
        _ = trace(&validator, stroke, upTo: 0.5)
        let reached = validator.cursor
        validator.lifted()
        #expect(validator.cursor == reached)
        #expect(!validator.isDown)
        #expect(validator.began(at: validator.cursorPoint) == .advanced)
        #expect(validator.cursor == reached)
    }

    @Test func comingBackAtTheStartRestartsOnlyThisStroke() {
        let stroke = straight()
        var validator = TraceValidator(stroke: stroke, canvasSide: canvas)
        _ = trace(&validator, stroke, upTo: 0.5)
        validator.lifted()
        #expect(validator.began(at: stroke.first) == .advanced)
        #expect(validator.cursor == 0)
    }

    @Test func comingBackNowhereNearIsIgnored() {
        let stroke = straight()
        var validator = TraceValidator(stroke: stroke, canvasSide: canvas)
        _ = trace(&validator, stroke, upTo: 0.5)
        validator.lifted()
        #expect(validator.began(at: UnitPoint2(x: 0.9, y: 0.05)) == .ignored)
    }

    /// Drag events arrive coalesced and far apart; the validator has to walk
    /// the path between them itself.
    @Test func interpolatesBetweenCoalescedPoints() {
        let stroke = straight()
        var validator = TraceValidator(stroke: stroke, canvasSide: canvas)
        _ = validator.began(at: stroke.first)
        let jump = stroke.points[min(20, stroke.points.count - 1)]
        #expect(validator.dragged(from: stroke.first, to: jump) == .advanced)
        #expect(validator.cursor >= 18)
    }

    @Test func easingWidensTheTarget() {
        let stroke = straight()
        var tight = TraceValidator(stroke: stroke, canvasSide: canvas)
        let before = tight.tolerance.capture
        tight.tolerance = tight.tolerance.eased(by: 1.5)
        #expect(tight.tolerance.capture > before)
    }

    @Test func restartClearsEverything() {
        let stroke = straight()
        var validator = TraceValidator(stroke: stroke, canvasSide: canvas)
        _ = trace(&validator, stroke)
        validator.restart()
        #expect(validator.cursor == 0)
        #expect(!validator.isComplete)
        #expect(!validator.isDown)
    }
}

@Suite struct GlyphTracerTests {
    @Test func walksTheStrokesInOrder() throws {
        let glyph = try #require(GlyphLibrary.glyph(for: "A"))
        var tracer = GlyphTracer(glyph: glyph, canvasSide: canvas)
        #expect(tracer.strokeCount == 3)

        for index in 0..<tracer.strokeCount {
            #expect(tracer.strokeIndex == index)
            let stroke = glyph.strokes[index]
            var step = tracer.began(at: stroke.first)
            var previous = stroke.first
            for point in stroke.points.dropFirst() where step != .finished {
                step = tracer.dragged(from: previous, to: point)
                previous = point
            }
            #expect(step == .finished, "trait \(index) inachevé")
        }
        #expect(tracer.isComplete)
        #expect(tracer.advance == 1)
    }

    @Test func aDotIsDoneOnTouch() throws {
        let glyph = try #require(GlyphLibrary.glyph(for: "i"))
        var tracer = GlyphTracer(glyph: glyph, canvasSide: canvas)

        let bar = glyph.strokes[0]
        var previous = bar.first
        _ = tracer.began(at: previous)
        for point in bar.points.dropFirst() {
            if tracer.dragged(from: previous, to: point) == .finished { break }
            previous = point
        }
        #expect(tracer.strokeIndex == 1)

        #expect(tracer.began(at: glyph.strokes[1].first) == .finished)
        #expect(tracer.isComplete)
    }

    @Test func advanceGrowsAcrossStrokes() throws {
        let glyph = try #require(GlyphLibrary.glyph(for: "u"))
        var tracer = GlyphTracer(glyph: glyph, canvasSide: canvas)
        #expect(tracer.advance == 0)

        let first = glyph.strokes[0]
        var previous = first.first
        _ = tracer.began(at: previous)
        for point in first.points.dropFirst() {
            if tracer.dragged(from: previous, to: point) == .finished { break }
            previous = point
        }
        #expect(tracer.advance >= 0.5)
        #expect(!tracer.isComplete)
    }

    @Test func easingCarriesToTheStrokesStillToCome() throws {
        let glyph = try #require(GlyphLibrary.glyph(for: "a"))
        var tracer = GlyphTracer(glyph: glyph, canvasSide: canvas)
        let before = tracer.validator.tolerance.capture
        tracer.ease(by: 1.5)
        #expect(tracer.validator.tolerance.capture > before)
    }

    /// Every shipped glyph has to be traceable end to end, or it is unusable.
    @Test func everyGlyphCanBeTraced() {
        for character in GlyphLibrary.available {
            guard let glyph = GlyphLibrary.glyph(for: character) else { continue }
            var tracer = GlyphTracer(glyph: glyph, canvasSide: canvas)
            for stroke in glyph.strokes {
                var step = tracer.began(at: stroke.first)
                // A dot is done the moment it is touched.
                if step == .finished { continue }
                var previous = stroke.first
                for point in stroke.points.dropFirst() {
                    step = tracer.dragged(from: previous, to: point)
                    previous = point
                    if step == .finished { break }
                }
                #expect(step == .finished, "\(character): un trait ne se termine pas")
            }
            #expect(tracer.isComplete, "\(character) ne se termine pas")
        }
    }
}
