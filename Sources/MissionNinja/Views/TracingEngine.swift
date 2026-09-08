import Foundation

/// Owns the fast changing state of one tracing attempt: the ink under the
/// finger and the cursor along the reference. Kept out of the surrounding
/// screen so a finger movement only invalidates the canvas, not the whole
/// view tree.
@MainActor
@Observable
final class TracingEngine {
    static let stuckDelay = Duration.milliseconds(2500)
    static let easedAfterAttempts = 2
    static let easeFactor = 1.5
    /// Points closer than this to the previous one are dropped: they add
    /// nothing to the drawn line.
    static let minimumInkSpacing = 1.5

    private(set) var tracer: GlyphTracer
    private(set) var strokes: [[UnitPoint2]] = [[]]
    private(set) var isStraying = false
    private(set) var showsHint = false
    private(set) var isComplete = false

    private let side: Double
    private var previous: UnitPoint2?
    private var previousScreen: UnitPoint2?
    private var attempts = 0
    private var stuckWatch: Task<Void, Never>?
    private let onStrokeDone: () -> Void
    private let onGlyphDone: () -> Void

    init(
        glyph: TraceGlyph,
        side: Double,
        onStrokeDone: @escaping () -> Void = {},
        onGlyphDone: @escaping () -> Void = {}
    ) {
        self.side = max(side, 1)
        tracer = GlyphTracer(glyph: glyph, canvasSide: max(side, 1))
        self.onStrokeDone = onStrokeDone
        self.onGlyphDone = onGlyphDone
    }

    var strokeIndex: Int { tracer.strokeIndex }
    var advance: Double { tracer.advance }
    var reference: [Polyline] { tracer.glyph.strokes }
    var cursorPoint: UnitPoint2 { tracer.validator.cursorPoint }
    var startPoint: UnitPoint2 { tracer.validator.startPoint }
    var needsStartTouch: Bool { !tracer.validator.isDown && tracer.validator.cursor == 0 }

    var inkWidth: Double { tracer.validator.tolerance.capture * side * 0.9 }
    /// Drawn as two layers: a faint halo the exact width of the tolerance, so
    /// the target looks as forgiving as it is, and a readable line down the
    /// middle. One layer at the full width turns an a into a blob.
    var haloWidth: Double { tracer.validator.tolerance.capture * side * 2 }
    var guideWidth: Double { max(12, side * 0.035) }

    func began(atScreen point: UnitPoint2) {
        guard !isComplete else { return }
        let unit = normalise(point)
        let step = tracer.began(at: unit)
        guard step != .ignored else {
            showsHint = true
            return
        }
        showsHint = false
        isStraying = false
        previous = unit
        previousScreen = point
        if strokes.count <= strokeIndex { strokes.append([]) }
        strokes[strokeIndex] = [unit]
        settle(step)
        watchForStuck()
    }

    func moved(toScreen point: UnitPoint2) {
        guard !isComplete, let last = previous, let lastScreen = previousScreen else { return }
        let unit = normalise(point)
        guard lastScreen.distance(to: point) >= TracingEngine.minimumInkSpacing else { return }

        // Validate on the raw points; only the drawn copy is thinned.
        let step = tracer.dragged(from: last, to: unit)
        previous = unit
        previousScreen = point
        if strokes.indices.contains(strokeIndex) {
            strokes[strokeIndex].append(unit)
        }
        isStraying = step == .strayed
        if step == .advanced || step == .finished { watchForStuck() }
        settle(step)
    }

    func lifted() {
        // Lifting a finger is normal at six: nothing is reset.
        tracer.lifted()
        previous = nil
        previousScreen = nil
        stuckWatch?.cancel()
        stuckWatch = nil
    }

    func cancel() {
        lifted()
        showsHint = false
        isStraying = false
    }

    /// Only the current stroke restarts, never the whole letter.
    func restartStroke() {
        attempts += 1
        if attempts >= TracingEngine.easedAfterAttempts {
            tracer.ease(by: TracingEngine.easeFactor)
        }
        tracer.restartStroke()
        if strokes.indices.contains(strokeIndex) { strokes[strokeIndex] = [] }
        showsHint = true
        isStraying = false
    }

    private func settle(_ step: TraceValidator.Step) {
        guard step == .finished else { return }
        if strokes.count <= tracer.strokeIndex { strokes.append([]) }
        if tracer.isComplete {
            isComplete = true
            stuckWatch?.cancel()
            onGlyphDone()
        } else {
            attempts = 0
            onStrokeDone()
        }
    }

    private func watchForStuck() {
        stuckWatch?.cancel()
        showsHint = false
        stuckWatch = Task { [weak self] in
            try? await Task.sleep(for: TracingEngine.stuckDelay)
            guard !Task.isCancelled else { return }
            self?.showsHint = true
        }
    }

    private func normalise(_ point: UnitPoint2) -> UnitPoint2 {
        UnitPoint2(x: point.x / side, y: point.y / side)
    }
}
