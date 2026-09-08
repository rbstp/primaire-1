import SwiftUI

/// The one card shape the whole app uses.
struct NinjaCard<Content: View>: View {
    var tinted = false
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(18)
            .background(background, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(Palette.blade.opacity(tinted ? 0.7 : 0.25).color, lineWidth: 2)
            )
    }

    private var background: AnyShapeStyle {
        guard tinted else { return AnyShapeStyle(Palette.slate.color) }
        return AnyShapeStyle(LinearGradient(
            colors: [Palette.bladeDeep.color, Palette.slate.color],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ))
    }
}
