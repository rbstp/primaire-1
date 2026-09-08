import SwiftUI

/// A brick seen from the front and a little above: a face with crisp corners,
/// a row of round studs standing on top, and a darker underside that gives it
/// thickness. Pressing one sinks it onto the underside, the way a brick clicks
/// onto a plate.
struct Brick<Content: View>: View {
    var tone: BrickTone = .blue
    var studs = 3
    var depth: CGFloat = 6
    var cornerRadius: CGFloat = 8
    var pressed = false
    @ViewBuilder var content: Content

    private var studHeight: CGFloat { depth * 1.5 }
    private var shape: RoundedRectangle { RoundedRectangle(cornerRadius: cornerRadius, style: .continuous) }
    private var sink: CGFloat { pressed ? depth * 0.75 : 0 }

    var body: some View {
        content
            .background {
                shape.fill(tone.shade.color).offset(y: depth)
                shape.fill(LinearGradient(
                    colors: [tone.face.color, tone.face.mixed(with: tone.shade, amount: 0.25).color],
                    startPoint: .top,
                    endPoint: .bottom
                ))
                shape.strokeBorder(Palette.cream.opacity(0.12).color, lineWidth: 1)
            }
            .overlay(alignment: .top) {
                StudRow(count: studs, tone: tone, height: studHeight)
                    .offset(y: -studHeight + 1)
            }
            .offset(y: sink)
            .padding(.top, studHeight)
            .padding(.bottom, depth)
            .animation(.spring(duration: 0.18, bounce: 0.2), value: pressed)
    }
}

/// The studs along the top of a brick, spaced like the real thing.
struct StudRow: View {
    let count: Int
    let tone: BrickTone
    var height: CGFloat = 9

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<max(count, 0), id: \.self) { _ in
                Stud(tone: tone, height: height)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, height * 0.6)
        .allowsHitTesting(false)
    }
}

/// One stud: a short cylinder with a lit top.
struct Stud: View {
    let tone: BrickTone
    var height: CGFloat = 9

    private var width: CGFloat { height * 2 }

    var body: some View {
        ZStack(alignment: .top) {
            UnevenRoundedRectangle(
                topLeadingRadius: width / 2,
                bottomLeadingRadius: 1,
                bottomTrailingRadius: 1,
                topTrailingRadius: width / 2,
                style: .continuous
            )
            .fill(LinearGradient(
                colors: [tone.face.color, tone.shade.color],
                startPoint: .top,
                endPoint: .bottom
            ))
            Ellipse()
                .fill(tone.stud.color)
                .frame(width: width, height: height * 0.7)
                .offset(y: -height * 0.05)
        }
        .frame(width: width, height: height)
    }
}

/// The plate every screen sits on: the night sky with a faint grid of studs.
/// Drawn once, so it costs nothing while a finger moves over it.
struct Baseplate: View {
    var body: some View {
        ZStack {
            LinearGradient.ninjaBackdrop
            Canvas(opaque: false, rendersAsynchronously: true) { context, size in
                let pitch = 28.0
                let radius = 4.2
                let colour = Palette.blade.opacity(0.09).color
                var x = pitch / 2
                while x < size.width {
                    var y = pitch / 2
                    while y < size.height {
                        let rect = CGRect(x: x - radius, y: y - radius * 0.8, width: radius * 2, height: radius * 1.6)
                        context.fill(Path(ellipseIn: rect), with: .color(colour))
                        y += pitch
                    }
                    x += pitch
                }
            }
        }
        .accessibilityHidden(true)
    }
}
