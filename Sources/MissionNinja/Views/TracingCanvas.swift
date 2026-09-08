import SwiftUI

/// The tracing surface, and nothing else. All the fast changing state lives
/// here so a finger movement cannot invalidate the screen around it.
///
/// Three layers, static to dynamic: the paper, the dotted reference as a plain
/// Shape that rasterises once, and the live ink in a Canvas over it. No shadow,
/// blur or gradient on the ink layer, which is where the frame budget goes.
struct TracingCanvas: View {
    let glyph: TraceGlyph
    let attempt: Int
    let onStrokeDone: () -> Void
    let onGlyphDone: (Bool) -> Void

    var body: some View {
        GeometryReader { frame in
            let side = min(frame.size.width, frame.size.height)
            Surface(
                glyph: glyph,
                side: side,
                attempt: attempt,
                onStrokeDone: onStrokeDone,
                onGlyphDone: onGlyphDone
            )
            .frame(width: side, height: side)
            .frame(width: frame.size.width, height: frame.size.height)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

private struct Surface: View {
    let glyph: TraceGlyph
    let side: Double
    let attempt: Int
    let onStrokeDone: () -> Void
    let onGlyphDone: (Bool) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var engine: TracingEngine?
    @State private var pulse = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Palette.slate.color)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Palette.blade.opacity(0.3).color, lineWidth: 2)
                )
                .overlay(alignment: .top) {
                    StudRow(count: 8, tone: .night, height: 9)
                        .offset(y: -5)
                }

            RuleLines()

            if let engine {
                GlyphGuide(
                    strokes: engine.reference,
                    currentIndex: engine.strokeIndex,
                    width: engine.guideWidth,
                    halo: engine.haloWidth,
                    side: side
                )

                InkLayer(strokes: engine.strokes, width: engine.inkWidth, side: side, straying: engine.isStraying)

                if engine.needsStartTouch || engine.showsHint {
                    StartDot(at: engine.startPoint, side: side, pulsing: pulse && !reduceMotion)
                }

                if engine.showsHint, !engine.isComplete {
                    StrokeHint(
                        stroke: engine.reference[min(engine.strokeIndex, engine.reference.count - 1)],
                        from: engine.tracer.validator.cursor,
                        side: side,
                        animates: !reduceMotion
                    )
                }

                if engine.isComplete {
                    DoneMark()
                }
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        // minimumDistance must be 0: the default of 10 swallows the start of
        // every stroke and any single tap, such as the dot on an i.
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    guard let engine else { return }
                    let point = UnitPoint2(x: value.location.x, y: value.location.y)
                    if value.translation == .zero {
                        engine.began(atScreen: point)
                    } else {
                        engine.moved(toScreen: point)
                    }
                }
                .onEnded { _ in engine?.lifted() }
        )
        .onAppear(perform: reset)
        .onChange(of: attempt) { reset() }
        .onChange(of: side) { reset() }
        .onDisappear { engine?.cancel() }
        .accessibilityLabel("Trace la lettre \(glyph.character)")
    }

    private func reset() {
        engine?.cancel()
        engine = TracingEngine(
            glyph: glyph,
            side: side,
            attempt: attempt,
            onStrokeDone: onStrokeDone,
            onGlyphDone: onGlyphDone
        )
        guard !reduceMotion else { return }
        pulse = false
        withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) { pulse = true }
    }
}

/// The school lines, so a letter sits where it does on paper.
private struct RuleLines: View {
    var body: some View {
        GeometryReader { frame in
            let side = min(frame.size.width, frame.size.height)
            Path { path in
                for rule in [GlyphLibrary.Rule.cap, GlyphLibrary.Rule.middle, GlyphLibrary.Rule.base] {
                    path.move(to: CGPoint(x: side * 0.08, y: side * rule))
                    path.addLine(to: CGPoint(x: side * 0.92, y: side * rule))
                }
            }
            .stroke(Palette.blade.opacity(0.16).color, style: StrokeStyle(lineWidth: 1.5, dash: [6, 8]))
        }
    }
}

/// A plain Shape, so it rasterises once instead of once per frame.
private struct GlyphGuide: View {
    let strokes: [Polyline]
    let currentIndex: Int
    let width: Double
    let halo: Double
    let side: Double

    private var done: Range<Int> { 0..<min(currentIndex, strokes.count) }
    private var todo: Range<Int> { min(currentIndex, strokes.count)..<strokes.count }

    var body: some View {
        ZStack {
            StrokePath(strokes: strokes, range: 0..<strokes.count, side: side)
                .stroke(Palette.blade.opacity(0.08).color, style: rounded(halo))

            StrokePath(strokes: strokes, range: done, side: side)
                .stroke(Palette.bamboo.opacity(0.55).color, style: rounded(width))
            StrokePath(strokes: strokes, range: todo, side: side)
                .stroke(Palette.blade.opacity(0.32).color, style: rounded(width))

            if strokes.indices.contains(currentIndex) {
                StrokePath(strokes: strokes, range: currentIndex..<(currentIndex + 1), side: side)
                    .stroke(Palette.blade.opacity(0.6).color, style: StrokeStyle(lineWidth: 2.5, dash: [6, 8]))
            }
        }
    }

    private func rounded(_ width: Double) -> StrokeStyle {
        StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round)
    }
}

private struct StrokePath: Shape {
    let strokes: [Polyline]
    let range: Range<Int>
    let side: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()
        for index in range where strokes.indices.contains(index) {
            let points = strokes[index].points
            guard let first = points.first else { continue }
            path.move(to: CGPoint(x: first.x * side, y: first.y * side))
            for point in points.dropFirst() {
                path.addLine(to: CGPoint(x: point.x * side, y: point.y * side))
            }
        }
        return path
    }
}

/// The only layer that redraws while the finger moves.
private struct InkLayer: View {
    let strokes: [[UnitPoint2]]
    let width: Double
    let side: Double
    let straying: Bool

    var body: some View {
        // Read the strokes here, in the body, not inside the renderer: the
        // Canvas closure runs at draw time and does not register a dependency.
        let drawn = strokes
        let colour = straying ? Palette.gold.color : Palette.azure.color
        return Canvas(opaque: false, colorMode: .nonLinear, rendersAsynchronously: false) { context, _ in
            let style = StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round)
            for stroke in drawn where stroke.count > 1 {
                var path = Path()
                path.move(to: CGPoint(x: stroke[0].x * side, y: stroke[0].y * side))
                for point in stroke.dropFirst() {
                    path.addLine(to: CGPoint(x: point.x * side, y: point.y * side))
                }
                context.stroke(path, with: .color(colour), style: style)
            }
        }
        .allowsHitTesting(false)
    }
}

/// Where the pencil goes down: a gold stud, the one gold thing on the plate.
private struct StartDot: View {
    let at: UnitPoint2
    let side: Double
    let pulsing: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(Palette.gold.mixed(with: Palette.ink, amount: 0.35).color)
                .frame(width: 24, height: 24)
            Circle()
                .fill(Palette.gold.color)
                .frame(width: 22, height: 22)
                .offset(y: -2)
        }
            .scaleEffect(pulsing ? 1.35 : 1)
            .position(x: at.x * side, y: at.y * side)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

/// The help that arrives when he stalls: a light sliding along what comes next.
private struct StrokeHint: View {
    let stroke: Polyline
    let from: Int
    let side: Double
    let animates: Bool

    @State private var along = 0.0

    private var window: [UnitPoint2] {
        let end = stroke.lastIndex(within: stroke.length * 0.25, from: from)
        guard end > from else { return [] }
        return Array(stroke.points[from...end])
    }

    var body: some View {
        let path = window
        ZStack {
            if path.count > 1 {
                let position = path[min(Int(along * Double(path.count - 1)), path.count - 1)]
                Circle()
                    .fill(Palette.cream.color)
                    .frame(width: 18, height: 18)
                    .position(x: position.x * side, y: position.y * side)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear {
            guard animates else { return }
            along = 0
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: false)) { along = 1 }
        }
    }
}

private struct DoneMark: View {
    var body: some View {
        Image(systemName: "checkmark.seal.fill")
            .font(.system(size: 68, weight: .bold))
            .foregroundStyle(.ninjaBamboo)
            .transition(.scale.combined(with: .opacity))
            .allowsHitTesting(false)
    }
}
