import SwiftUI

/// The dragon as it stands: bricks laid so far, and the rest as a faint
/// outline so he can see what is coming. Once whole, he breathes, wags his
/// tail, flaps his wing, blinks, and answers a touch with a roar.
///
/// One Canvas draws every brick. A view per brick was fine while he stood
/// still; animating a hundred of them each frame is not.
struct DragonBuild: View {
    var blueprint = DragonBlueprint.standard
    let done: Int
    let total: Int
    /// Bumping this makes him roar without a touch, for the fight.
    var roarCue = 0
    /// True while the ninja's blade lands, so he recoils.
    var hit = false
    /// Off for a thumbnail: a dragon that idles redraws every frame.
    var animated = true
    var onRoar: (() -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var roaring = false
    @State private var roarTask: Task<Void, Never>?

    private var laid: Int { blueprint.laid(after: done, of: total) }
    private var isComplete: Bool { laid >= blueprint.cells.count }
    private var animates: Bool { animated && isComplete && !reduceMotion }

    var body: some View {
        GeometryReader { frame in
            let unit = min(frame.size.width / CGFloat(blueprint.columns), frame.size.height / CGFloat(blueprint.rows))
            let width = unit * CGFloat(blueprint.columns)
            let height = unit * CGFloat(blueprint.rows)
            // Bottom rows first, so a brick covers the studs of the one below it.
            // Sorted here, once per change, not once per frame.
            let drawn = blueprint.cells.prefix(laid).sorted { $0.y > $1.y }
            ZStack(alignment: .topLeading) {
                Ghost(blueprint: blueprint, unit: unit)
                    .opacity(isComplete ? 0 : 1)

                TimelineView(.animation(paused: !animates)) { timeline in
                    let time = animates ? timeline.date.timeIntervalSinceReferenceDate : 0
                    Canvas(opaque: false, rendersAsynchronously: false) { context, _ in
                        let pose = DragonPose(time: time, roaring: roaring, alive: animates)
                        for cell in drawn {
                            let shift = pose.shift(of: cell, in: blueprint)
                            let origin = CGPoint(x: (CGFloat(cell.x) + shift.x) * unit, y: (CGFloat(cell.y) + shift.y) * unit)
                            draw(cell, at: origin, unit: unit, pose: pose, in: &context)
                        }
                    }
                }
                .frame(width: width, height: height)

                // The newest brick pops in on top of the drawing.
                if laid > 0, !isComplete, let cell = blueprint.cells[safe: laid - 1] {
                    PopMark(unit: unit)
                        .position(x: (CGFloat(cell.x) + 0.5) * unit, y: (CGFloat(cell.y) + 0.5) * unit)
                        .id(laid)
                        .transition(.scale(scale: 2.2).combined(with: .opacity))
                }

                if roaring, isComplete, let mouth = blueprint.mouth {
                    Flame(unit: unit)
                        .position(x: (CGFloat(mouth.x) + 2.3) * unit, y: (CGFloat(mouth.y) + 0.4) * unit)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(width: width, height: height)
            .frame(width: frame.size.width, height: frame.size.height)
            .offset(x: hit ? unit * 0.6 : 0)
            .rotationEffect(.degrees(hit ? 2 : 0), anchor: .bottom)
            .animation(.spring(duration: 0.3, bounce: 0.45), value: laid)
            .animation(.spring(duration: 0.25, bounce: 0.5), value: hit)
        }
        .aspectRatio(CGFloat(blueprint.columns) / CGFloat(blueprint.rows), contentMode: .fit)
        .contentShape(Rectangle())
        .onTapGesture { roar() }
        .allowsHitTesting(isComplete)
        .onChange(of: roarCue) { roar() }
        .onChange(of: isComplete) { _, complete in
            if !complete { quiet() }
        }
        .onDisappear(perform: quiet)
        .accessibilityLabel(isComplete ? "Le dragon est fini. Touche-le pour le faire rugir." : "Dragon en construction, \(laid) briques sur \(blueprint.cells.count)")
        .accessibilityAddTraits(isComplete ? .isButton : [])
    }

    private func roar() {
        guard isComplete, !roaring else { return }
        onRoar?()
        withAnimation(.spring(duration: 0.25, bounce: 0.5)) { roaring = true }
        roarTask = Task {
            try? await Task.sleep(for: .milliseconds(900))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.3)) { roaring = false }
        }
    }

    /// A restart mid roar must not leave a pile of zero bricks breathing fire.
    private func quiet() {
        roarTask?.cancel()
        roarTask = nil
        roaring = false
    }

    /// One brick: the underside, the face, and a stud on top.
    private func draw(_ cell: DragonBlueprint.Cell, at origin: CGPoint, unit: CGFloat, pose: DragonPose, in context: inout GraphicsContext) {
        let tone = tone(cell.tone)
        let corner = unit * 0.12
        let isEye = cell.tone == .gold
        let face: Color = isEye && pose.eyesShut ? Palette.ink.color : (isEye && roaring ? Palette.cream.color : tone.face.color)
        let stud: Color = isEye && roaring ? Palette.gold.color : tone.stud.color

        let underside = CGRect(x: origin.x + unit * 0.04, y: origin.y + unit * 0.2, width: unit * 0.92, height: unit * 0.8)
        context.fill(Path(roundedRect: underside, cornerRadius: corner), with: .color(tone.shade.color))
        let top = CGRect(x: origin.x + unit * 0.04, y: origin.y + unit * 0.06, width: unit * 0.92, height: unit * 0.76)
        context.fill(Path(roundedRect: top, cornerRadius: corner), with: .color(face))
        let studRect = CGRect(x: origin.x + unit * 0.3, y: origin.y - unit * 0.06, width: unit * 0.4, height: unit * 0.24)
        context.fill(Path(ellipseIn: studRect), with: .color(stud))
    }

    private func tone(_ tone: DragonBlueprint.Tone) -> BrickTone {
        switch tone {
        case .blue: .blue
        case .black: .black
        case .gold: .gold
        case .cream: .cream
        }
    }
}

/// Where every part of the dragon is at one instant: tail wagging, wing
/// flapping, head bobbing, eyes blinking, and the whole head thrust forward
/// while he roars. Shifts are in brick units.
private struct DragonPose {
    let time: Double
    let roaring: Bool
    let alive: Bool

    var eyesShut: Bool {
        guard alive else { return false }
        return time.truncatingRemainder(dividingBy: 3.4) < 0.14
    }

    func shift(of cell: DragonBlueprint.Cell, in blueprint: DragonBlueprint) -> CGPoint {
        guard alive else { return .zero }
        let x = Double(cell.x)
        let y = Double(cell.y)
        let head = x >= Double(blueprint.columns) * 0.6 && y <= Double(blueprint.rows) * 0.6
        let wing = x >= Double(blueprint.columns) * 0.12 && x < Double(blueprint.columns) * 0.5 && y < Double(blueprint.rows) * 0.65
        let tail = x < Double(blueprint.columns) * 0.3 && !wing && y >= Double(blueprint.rows) * 0.6

        if head {
            let bob = sin(time * 1.7) * 0.10
            let thrust = roaring ? 0.5 : 0
            return CGPoint(x: thrust, y: bob)
        }
        if wing {
            let reach = (Double(blueprint.rows) * 0.65 - y) / (Double(blueprint.rows) * 0.65)
            return CGPoint(x: 0, y: sin(time * 3.1) * 0.22 * reach)
        }
        if tail {
            let reach = (Double(blueprint.columns) * 0.3 - x) / (Double(blueprint.columns) * 0.3)
            return CGPoint(x: 0, y: sin(time * 2.3 + x * 0.6) * 0.28 * reach)
        }
        return CGPoint(x: 0, y: sin(time * 1.7) * 0.03)
    }
}

/// A flash where the newest brick just landed.
private struct PopMark: View {
    let unit: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: unit * 0.12, style: .continuous)
            .stroke(Palette.cream.opacity(0.9).color, lineWidth: max(1.5, unit * 0.12))
            .frame(width: unit * 0.92, height: unit * 0.92)
            .allowsHitTesting(false)
    }
}

/// The dragon still to build, as one dashed silhouette rather than a cell per
/// brick, so the outline reads as a shape and not as a grid.
private struct Ghost: View {
    let blueprint: DragonBlueprint
    let unit: CGFloat

    var body: some View {
        ghostOutline
            .fill(Palette.blade.opacity(0.10).color)
            .overlay(ghostOutline.stroke(Palette.blade.opacity(0.45).color, style: StrokeStyle(lineWidth: 1.2, dash: [3, 3])))
            .frame(width: unit * CGFloat(blueprint.columns), height: unit * CGFloat(blueprint.rows))
    }

    private var ghostOutline: Path {
        Path { path in
            for cell in blueprint.cells {
                let rect = CGRect(
                    x: CGFloat(cell.x) * unit + unit * 0.1,
                    y: CGFloat(cell.y) * unit + unit * 0.1,
                    width: unit * 0.8,
                    height: unit * 0.8
                )
                path.addRoundedRect(in: rect, cornerSize: CGSize(width: unit * 0.15, height: unit * 0.15))
            }
        }
    }
}

/// A short blue flame out of the mouth, his colour rather than orange.
private struct Flame: View {
    let unit: CGFloat

    var body: some View {
        ZStack {
            FlameShape()
                .fill(LinearGradient(colors: [Palette.azure.color, Palette.blade.opacity(0.1).color], startPoint: .leading, endPoint: .trailing))
                .frame(width: unit * 3.2, height: unit * 1.6)
            FlameShape()
                .fill(Palette.cream.opacity(0.85).color)
                .frame(width: unit * 1.6, height: unit * 0.7)
                .offset(x: -unit * 0.7)
        }
        .allowsHitTesting(false)
    }
}

private struct FlameShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.midY),
            control1: CGPoint(x: rect.midX * 0.8, y: rect.minY - rect.height * 0.3),
            control2: CGPoint(x: rect.maxX * 0.9, y: rect.minY + rect.height * 0.2)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX, y: rect.midY),
            control1: CGPoint(x: rect.maxX * 0.9, y: rect.maxY - rect.height * 0.2),
            control2: CGPoint(x: rect.midX * 0.8, y: rect.maxY + rect.height * 0.3)
        )
        return path
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
