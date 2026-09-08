import Foundation

/// The vowels the lesson plan asks for, lowercase and uppercase, in the order
/// the pen goes.
extension GlyphLibrary {
    static let vowels: [GlyphSpec] = [
        lowerA, lowerE, lowerI, lowerO, lowerU,
        upperA, upperE, upperI, upperO, upperU,
    ]

    /// The single storey a: the circle first, anticlockwise from its right
    /// side, then the downstroke on the right.
    private static let lowerA = GlyphSpec(character: "a", strokes: [
        GlyphStroke(start: UnitPoint2(x: 0.66, y: 0.65), segments: [
            .arc(centre: UnitPoint2(x: 0.47, y: 0.65), rx: 0.19, ry: 0.21, from: 0, to: -1),
        ]),
        GlyphStroke(start: UnitPoint2(x: 0.66, y: 0.44), segments: [
            .line(to: UnitPoint2(x: 0.66, y: Rule.base)),
        ]),
    ])

    /// One stroke: out along the bar, up and around anticlockwise, then away
    /// to the right at the bottom.
    private static let lowerE = GlyphSpec(character: "e", strokes: [
        GlyphStroke(start: UnitPoint2(x: 0.30, y: 0.655), segments: [
            .line(to: UnitPoint2(x: 0.66, y: 0.655)),
            .curve(to: UnitPoint2(x: 0.48, y: 0.44),
                   control1: UnitPoint2(x: 0.68, y: 0.52),
                   control2: UnitPoint2(x: 0.62, y: 0.44)),
            .curve(to: UnitPoint2(x: 0.29, y: 0.65),
                   control1: UnitPoint2(x: 0.34, y: 0.44),
                   control2: UnitPoint2(x: 0.29, y: 0.52)),
            .curve(to: UnitPoint2(x: 0.49, y: 0.86),
                   control1: UnitPoint2(x: 0.29, y: 0.78),
                   control2: UnitPoint2(x: 0.37, y: 0.86)),
            .curve(to: UnitPoint2(x: 0.68, y: 0.76),
                   control1: UnitPoint2(x: 0.59, y: 0.86),
                   control2: UnitPoint2(x: 0.65, y: 0.82)),
        ]),
    ])

    /// The downstroke, then the dot, which is a tap rather than a gesture.
    private static let lowerI = GlyphSpec(character: "i", strokes: [
        GlyphStroke(start: UnitPoint2(x: 0.50, y: 0.44), segments: [
            .line(to: UnitPoint2(x: 0.50, y: Rule.base)),
        ]),
        GlyphStroke(start: UnitPoint2(x: 0.50, y: Rule.dot - 0.01), segments: [
            .line(to: UnitPoint2(x: 0.50, y: Rule.dot + 0.01)),
        ]),
    ])

    /// A full circle anticlockwise from the top.
    private static let lowerO = GlyphSpec(character: "o", strokes: [
        GlyphStroke(start: UnitPoint2(x: 0.50, y: 0.44), segments: [
            .arc(centre: UnitPoint2(x: 0.50, y: 0.65), rx: 0.20, ry: 0.21, from: -0.25, to: -1.25),
        ]),
    ])

    /// Down, round the bottom, up the right, then the second downstroke.
    private static let lowerU = GlyphSpec(character: "u", strokes: [
        GlyphStroke(start: UnitPoint2(x: 0.31, y: 0.44), segments: [
            .line(to: UnitPoint2(x: 0.31, y: 0.70)),
            .curve(to: UnitPoint2(x: 0.69, y: 0.70),
                   control1: UnitPoint2(x: 0.31, y: 0.88),
                   control2: UnitPoint2(x: 0.69, y: 0.88)),
            .line(to: UnitPoint2(x: 0.69, y: 0.44)),
        ]),
        GlyphStroke(start: UnitPoint2(x: 0.69, y: 0.44), segments: [
            .line(to: UnitPoint2(x: 0.69, y: Rule.base)),
        ]),
    ])

    private static let upperA = GlyphSpec(character: "A", strokes: [
        GlyphStroke(start: UnitPoint2(x: 0.50, y: Rule.cap), segments: [
            .line(to: UnitPoint2(x: 0.24, y: Rule.base)),
        ]),
        GlyphStroke(start: UnitPoint2(x: 0.50, y: Rule.cap), segments: [
            .line(to: UnitPoint2(x: 0.76, y: Rule.base)),
        ]),
        GlyphStroke(start: UnitPoint2(x: 0.33, y: 0.58), segments: [
            .line(to: UnitPoint2(x: 0.67, y: 0.58)),
        ]),
    ])

    private static let upperE = GlyphSpec(character: "E", strokes: [
        GlyphStroke(start: UnitPoint2(x: 0.31, y: Rule.cap), segments: [
            .line(to: UnitPoint2(x: 0.31, y: Rule.base)),
        ]),
        GlyphStroke(start: UnitPoint2(x: 0.31, y: Rule.cap), segments: [
            .line(to: UnitPoint2(x: 0.71, y: Rule.cap)),
        ]),
        GlyphStroke(start: UnitPoint2(x: 0.31, y: 0.49), segments: [
            .line(to: UnitPoint2(x: 0.64, y: 0.49)),
        ]),
        GlyphStroke(start: UnitPoint2(x: 0.31, y: Rule.base), segments: [
            .line(to: UnitPoint2(x: 0.71, y: Rule.base)),
        ]),
    ])

    private static let upperI = GlyphSpec(character: "I", strokes: [
        GlyphStroke(start: UnitPoint2(x: 0.50, y: Rule.cap), segments: [
            .line(to: UnitPoint2(x: 0.50, y: Rule.base)),
        ]),
    ])

    private static let upperO = GlyphSpec(character: "O", strokes: [
        GlyphStroke(start: UnitPoint2(x: 0.50, y: Rule.cap), segments: [
            .arc(centre: UnitPoint2(x: 0.50, y: 0.49), rx: 0.24, ry: 0.37, from: -0.25, to: -1.25),
        ]),
    ])

    private static let upperU = GlyphSpec(character: "U", strokes: [
        GlyphStroke(start: UnitPoint2(x: 0.28, y: Rule.cap), segments: [
            .line(to: UnitPoint2(x: 0.28, y: 0.58)),
            .curve(to: UnitPoint2(x: 0.72, y: 0.58),
                   control1: UnitPoint2(x: 0.28, y: 0.88),
                   control2: UnitPoint2(x: 0.72, y: 0.88)),
            .line(to: UnitPoint2(x: 0.72, y: Rule.cap)),
        ]),
    ])
}
