import Foundation

/// The colour of one brick: its top face, its shaded underside and its studs.
/// Plain Paint so the icon generator can build bricks too.
struct BrickTone: Equatable, Sendable {
    let face: Paint
    let shade: Paint
    let stud: Paint

    static let blue = BrickTone(
        face: Palette.blade,
        shade: Palette.bladeDeep,
        stud: Palette.blade.mixed(with: Palette.cream, amount: 0.22)
    )
    static let black = BrickTone(
        face: Palette.slateLight,
        shade: Palette.slate,
        stud: Palette.slateLight.mixed(with: Palette.cream, amount: 0.10)
    )
    static let night = BrickTone(
        face: Palette.slate,
        shade: Palette.night,
        stud: Palette.slate.mixed(with: Palette.cream, amount: 0.08)
    )
    static let azure = BrickTone(
        face: Palette.azure,
        shade: Palette.azure.mixed(with: Palette.bladeDeep, amount: 0.45),
        stud: Palette.azure.mixed(with: Palette.cream, amount: 0.35)
    )
    static let gold = BrickTone(
        face: Palette.gold,
        shade: Palette.gold.mixed(with: Palette.ink, amount: 0.35),
        stud: Palette.gold.mixed(with: Palette.cream, amount: 0.35)
    )
    static let green = BrickTone(
        face: Palette.bamboo,
        shade: Palette.bamboo.mixed(with: Palette.ink, amount: 0.4),
        stud: Palette.bamboo.mixed(with: Palette.cream, amount: 0.3)
    )
    static let red = BrickTone(
        face: Palette.crimson.mixed(with: Palette.slate, amount: 0.45),
        shade: Palette.crimson.mixed(with: Palette.ink, amount: 0.6),
        stud: Palette.crimson.mixed(with: Palette.slate, amount: 0.3)
    )
    static let cream = BrickTone(
        face: Palette.cream,
        shade: Palette.cream.mixed(with: Palette.slate, amount: 0.5),
        stud: Palette.cream
    )
}
