import SwiftUI

struct NinjaButtonStyle: ButtonStyle {
    var prominent = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.counter)
            .foregroundStyle(prominent ? Color.ninjaCream : Color.ninjaBlade)
            .frame(maxWidth: .infinity, minHeight: 58)
            .background(background, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Palette.blade.opacity(prominent ? 0 : 0.6).color, lineWidth: 2)
            )
            .opacity(configuration.isPressed ? 0.75 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }

    private var background: AnyShapeStyle {
        prominent ? AnyShapeStyle(LinearGradient.ninjaBlade) : AnyShapeStyle(Palette.slate.color)
    }
}
