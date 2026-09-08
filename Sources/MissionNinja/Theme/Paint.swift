import Foundation

/// A colour as plain components so the icon generator can link this file
/// without pulling in SwiftUI.
struct Paint: Equatable, Sendable {
    let red: Double
    let green: Double
    let blue: Double
    var alpha: Double = 1

    func opacity(_ value: Double) -> Paint {
        Paint(red: red, green: green, blue: blue, alpha: value)
    }

    func mixed(with other: Paint, amount: Double) -> Paint {
        let t = min(max(amount, 0), 1)
        return Paint(
            red: red + (other.red - red) * t,
            green: green + (other.green - green) * t,
            blue: blue + (other.blue - blue) * t,
            alpha: alpha + (other.alpha - alpha) * t
        )
    }
}

/// Black and blue carry the app: black grounds every screen, blue is the only
/// accent that means "this is yours to touch". Gold is reserved for stars,
/// green for a right answer, red only for a gentle miss.
enum Palette {
    static let ink = Paint(red: 0.031, green: 0.035, blue: 0.047)
    static let night = Paint(red: 0.051, green: 0.063, blue: 0.098)
    static let slate = Paint(red: 0.075, green: 0.098, blue: 0.157)
    static let slateLight = Paint(red: 0.106, green: 0.145, blue: 0.235)

    static let blade = Paint(red: 0.239, green: 0.545, blue: 0.992)
    static let bladeDeep = Paint(red: 0.106, green: 0.278, blue: 0.573)
    static let azure = Paint(red: 0.373, green: 0.827, blue: 0.953)

    static let cream = Paint(red: 0.949, green: 0.965, blue: 0.988)
    static let gold = Paint(red: 0.976, green: 0.749, blue: 0.216)
    static let bamboo = Paint(red: 0.290, green: 0.784, blue: 0.482)
    static let crimson = Paint(red: 0.898, green: 0.353, blue: 0.325)
}

enum BeltPaint {
    static let white = Paint(red: 0.949, green: 0.965, blue: 0.988)
    static let yellow = Paint(red: 0.976, green: 0.812, blue: 0.267)
    static let orange = Paint(red: 0.937, green: 0.549, blue: 0.200)
    static let green = Paint(red: 0.290, green: 0.784, blue: 0.482)
    static let blue = Paint(red: 0.239, green: 0.545, blue: 0.992)
    static let brown = Paint(red: 0.545, green: 0.365, blue: 0.220)
    static let black = Paint(red: 0.098, green: 0.114, blue: 0.157)
}
