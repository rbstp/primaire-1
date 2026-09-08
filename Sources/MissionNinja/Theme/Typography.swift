import SwiftUI

enum Typography {
    /// Interface text follows Dynamic Type so the parent can size it up.
    static let screenTitle = Font.system(.title, design: .rounded, weight: .heavy)
    static let sectionTitle = Font.system(.title3, design: .rounded, weight: .bold)
    static let body = Font.system(.body, design: .rounded, weight: .medium)
    static let caption = Font.system(.caption, design: .rounded, weight: .semibold)
    static let counter = Font.system(.headline, design: .rounded, weight: .heavy)

    /// A letter or digit he has to recognise keeps a fixed size: its shape is
    /// the lesson, so it must not shrink or grow with a text setting.
    static func glyph(_ size: CGFloat) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }
}
