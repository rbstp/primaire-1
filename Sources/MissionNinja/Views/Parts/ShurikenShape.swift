import SwiftUI

/// The four bladed star: a curved cutting edge into each notch, a straight
/// back out to the next tip. Also the app icon, drawn the same way.
struct ShurikenShape: Shape {
    var notchRatio = 0.31

    func path(in rect: CGRect) -> Path {
        let centre = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        let inner = outer * notchRatio
        let quarter = Double.pi / 2
        let start = quarter / 2

        func point(_ angle: Double, _ radius: Double) -> CGPoint {
            CGPoint(x: centre.x + cos(angle) * radius, y: centre.y + sin(angle) * radius)
        }

        var path = Path()
        path.move(to: point(start, outer))
        for index in 0..<4 {
            let tip = start + Double(index) * quarter
            path.addQuadCurve(
                to: point(tip + quarter / 2, inner),
                control: point(tip + quarter * 0.28, (outer + inner) * 0.42)
            )
            path.addLine(to: point(tip + quarter, outer))
        }
        path.closeSubpath()
        return path
    }
}

/// One shuriken, drawn the way the icon is so the app reads as one thing.
struct ShurikenBadge: View {
    var size: CGFloat = 44
    var fill: Color = .ninjaInk
    var edge: Color = .ninjaAzure

    var body: some View {
        ShurikenShape()
            .fill(fill)
            .overlay(ShurikenShape().stroke(edge, lineWidth: max(1.5, size * 0.045)))
            .overlay(
                Circle()
                    .fill(.ninjaInk)
                    .frame(width: size * 0.18, height: size * 0.18)
            )
            .frame(width: size, height: size)
    }
}
