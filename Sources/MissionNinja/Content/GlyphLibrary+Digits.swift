import Foundation

/// The digits nought to nine. The writing order for 4, 5 and 8 varies between
/// schools, so these follow the common Quebec sequence and are worth checking
/// against his teacher's before he uses them much.
extension GlyphLibrary {
    static let digits: [GlyphSpec] = [
        zero, one, two, three, four, five, six, seven, eight, nine,
    ]

    private static let zero = GlyphSpec(character: "0", strokes: [
        GlyphStroke(start: UnitPoint2(x: 0.50, y: Rule.cap), segments: [
            .arc(centre: UnitPoint2(x: 0.50, y: 0.49), rx: 0.20, ry: 0.37, from: -0.25, to: -1.25),
        ]),
    ])

    /// The little flag, then straight down, in one movement.
    private static let one = GlyphSpec(character: "1", strokes: [
        GlyphStroke(start: UnitPoint2(x: 0.36, y: 0.28), segments: [
            .line(to: UnitPoint2(x: 0.53, y: Rule.cap)),
            .line(to: UnitPoint2(x: 0.53, y: Rule.base)),
        ]),
    ])

    private static let two = GlyphSpec(character: "2", strokes: [
        GlyphStroke(start: UnitPoint2(x: 0.29, y: 0.26), segments: [
            .curve(to: UnitPoint2(x: 0.69, y: 0.32),
                   control1: UnitPoint2(x: 0.33, y: 0.09),
                   control2: UnitPoint2(x: 0.70, y: 0.10)),
            .curve(to: UnitPoint2(x: 0.30, y: Rule.base),
                   control1: UnitPoint2(x: 0.68, y: 0.53),
                   control2: UnitPoint2(x: 0.43, y: 0.66)),
            .line(to: UnitPoint2(x: 0.73, y: Rule.base)),
        ]),
    ])

    private static let three = GlyphSpec(character: "3", strokes: [
        GlyphStroke(start: UnitPoint2(x: 0.31, y: 0.22), segments: [
            .curve(to: UnitPoint2(x: 0.49, y: 0.48),
                   control1: UnitPoint2(x: 0.42, y: 0.09),
                   control2: UnitPoint2(x: 0.71, y: 0.19)),
            .curve(to: UnitPoint2(x: 0.31, y: 0.83),
                   control1: UnitPoint2(x: 0.75, y: 0.53),
                   control2: UnitPoint2(x: 0.69, y: 0.89)),
        ]),
    ])

    /// The slant and the bar first, then the downstroke.
    private static let four = GlyphSpec(character: "4", strokes: [
        GlyphStroke(start: UnitPoint2(x: 0.61, y: Rule.cap), segments: [
            .line(to: UnitPoint2(x: 0.25, y: 0.62)),
            .line(to: UnitPoint2(x: 0.77, y: 0.62)),
        ]),
        GlyphStroke(start: UnitPoint2(x: 0.61, y: Rule.cap), segments: [
            .line(to: UnitPoint2(x: 0.61, y: Rule.base)),
        ]),
    ])

    /// Down and round the belly first, then the hat, which is how it is taught
    /// even though it looks backwards.
    private static let five = GlyphSpec(character: "5", strokes: [
        GlyphStroke(start: UnitPoint2(x: 0.34, y: 0.14), segments: [
            .line(to: UnitPoint2(x: 0.34, y: 0.45)),
            .curve(to: UnitPoint2(x: 0.34, y: 0.85),
                   control1: UnitPoint2(x: 0.78, y: 0.41),
                   control2: UnitPoint2(x: 0.76, y: 0.89)),
        ]),
        GlyphStroke(start: UnitPoint2(x: 0.34, y: 0.14), segments: [
            .line(to: UnitPoint2(x: 0.71, y: 0.14)),
        ]),
    ])

    /// In from the top right, down the left, then the loop clockwise.
    private static let six = GlyphSpec(character: "6", strokes: [
        GlyphStroke(start: UnitPoint2(x: 0.67, y: 0.16), segments: [
            .curve(to: UnitPoint2(x: 0.32, y: 0.66),
                   control1: UnitPoint2(x: 0.46, y: 0.19),
                   control2: UnitPoint2(x: 0.32, y: 0.40)),
            .arc(centre: UnitPoint2(x: 0.50, y: 0.66), rx: 0.18, ry: 0.20, from: 0.5, to: 1.5),
        ]),
    ])

    private static let seven = GlyphSpec(character: "7", strokes: [
        GlyphStroke(start: UnitPoint2(x: 0.27, y: 0.14), segments: [
            .line(to: UnitPoint2(x: 0.75, y: 0.14)),
            .line(to: UnitPoint2(x: 0.42, y: Rule.base)),
        ]),
    ])

    /// One movement that crosses itself twice: over the top and down the left
    /// to the crossing, round the bottom loop, then back up the right to close.
    /// The crossing is exactly the case the validator's forward window and
    /// direction check exist for.
    private static let eight = GlyphSpec(character: "8", strokes: [
        GlyphStroke(start: UnitPoint2(x: 0.61, y: 0.21), segments: [
            .curve(to: UnitPoint2(x: 0.35, y: 0.30),
                   control1: UnitPoint2(x: 0.55, y: 0.10),
                   control2: UnitPoint2(x: 0.35, y: 0.13)),
            .curve(to: UnitPoint2(x: 0.50, y: 0.49),
                   control1: UnitPoint2(x: 0.35, y: 0.42),
                   control2: UnitPoint2(x: 0.42, y: 0.46)),
            .curve(to: UnitPoint2(x: 0.50, y: 0.87),
                   control1: UnitPoint2(x: 0.38, y: 0.56),
                   control2: UnitPoint2(x: 0.29, y: 0.81)),
            .curve(to: UnitPoint2(x: 0.50, y: 0.49),
                   control1: UnitPoint2(x: 0.72, y: 0.82),
                   control2: UnitPoint2(x: 0.62, y: 0.57)),
            .curve(to: UnitPoint2(x: 0.61, y: 0.21),
                   control1: UnitPoint2(x: 0.59, y: 0.44),
                   control2: UnitPoint2(x: 0.67, y: 0.29)),
        ]),
    ])

    /// The loop anticlockwise from its right side, then straight down.
    private static let nine = GlyphSpec(character: "9", strokes: [
        GlyphStroke(start: UnitPoint2(x: 0.68, y: 0.34), segments: [
            .arc(centre: UnitPoint2(x: 0.50, y: 0.34), rx: 0.18, ry: 0.20, from: 0, to: -1),
            .line(to: UnitPoint2(x: 0.65, y: Rule.base)),
        ]),
    ])
}
