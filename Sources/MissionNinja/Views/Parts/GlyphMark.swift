import SwiftUI

/// A character drawn with the strokes of GlyphLibrary rather than with the
/// shape a font happens to have. Without it the a on a brick is SF Pro's two
/// storey a while the a he traces has one storey, and at six they read as two
/// different letters. What the library does not cover keeps the font.
struct GlyphMark: View {
    let text: String
    let size: CGFloat

    /// The library square holds the accent, the dot on the i and the space
    /// below the line, so the ink inside it is smaller than the square. These
    /// three numbers put that ink where the font would have put its own: a
    /// square a little taller than the type size, lifted so the letter sits
    /// on the same middle line, and a narrower step from one character to the
    /// next so a two digit number does not spread out.
    private static let box = 1.24
    private static let rise = 0.10
    private static let step = 0.66
    private static let ink = 0.145

    init(_ text: String, size: CGFloat) {
        self.text = text
        self.size = size
    }

    init(_ character: Character, size: CGFloat) {
        self.init(String(character), size: size)
    }

    var body: some View {
        let side = size * GlyphMark.box
        let lift = size * GlyphMark.rise
        return HStack(alignment: .firstTextBaseline, spacing: 0) {
            ForEach(Array(text.enumerated()), id: \.offset) { _, character in
                if let glyph = GlyphLibrary.glyph(for: character) {
                    Strokes(glyph: glyph)
                        .stroke(.foreground, style: StrokeStyle(lineWidth: size * GlyphMark.ink, lineCap: .round, lineJoin: .round))
                        .frame(width: side, height: side)
                        .offset(y: -lift)
                        .frame(width: size * GlyphMark.step, height: side)
                        .alignmentGuide(.firstTextBaseline) { _ in side * GlyphLibrary.Rule.base - lift }
                } else {
                    Text(String(character))
                        .font(Typography.glyph(size))
                }
            }
        }
        .accessibilityLabel(text)
    }
}

private struct Strokes: Shape {
    let glyph: TraceGlyph

    func path(in rect: CGRect) -> Path {
        let side = min(rect.width, rect.height)
        var path = Path()
        for stroke in glyph.strokes {
            guard let first = stroke.points.first else { continue }
            path.move(to: CGPoint(x: first.x * side, y: first.y * side))
            for point in stroke.points.dropFirst() {
                path.addLine(to: CGPoint(x: point.x * side, y: point.y * side))
            }
        }
        return path
    }
}
