import SwiftUI

extension Paint {
    var color: Color {
        Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}

extension ShapeStyle where Self == Color {
    static var ninjaInk: Color { Palette.ink.color }
    static var ninjaNight: Color { Palette.night.color }
    static var ninjaSlate: Color { Palette.slate.color }
    static var ninjaSlateLight: Color { Palette.slateLight.color }
    static var ninjaBlade: Color { Palette.blade.color }
    static var ninjaBladeDeep: Color { Palette.bladeDeep.color }
    static var ninjaAzure: Color { Palette.azure.color }
    static var ninjaCream: Color { Palette.cream.color }
    static var ninjaGold: Color { Palette.gold.color }
    static var ninjaBamboo: Color { Palette.bamboo.color }
    static var ninjaCrimson: Color { Palette.crimson.color }
}

extension LinearGradient {
    /// The night sky every screen sits on.
    static var ninjaBackdrop: LinearGradient {
        LinearGradient(
            colors: [Palette.night.color, Palette.ink.color],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// The blue every touchable thing wears.
    static var ninjaBlade: LinearGradient {
        LinearGradient(
            colors: [Palette.blade.color, Palette.bladeDeep.color],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
