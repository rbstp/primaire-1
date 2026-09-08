import SwiftUI

/// The little ninja. Blue headband, black hood, and an expression that reacts
/// to what just happened.
struct NinjaMascot: View {
    enum Mood: Sendable {
        case calm
        case happy
        case thinking
    }

    var mood: Mood = .calm
    var size: CGFloat = 120

    private var eyeHeight: CGFloat {
        switch mood {
        case .calm: 0.16
        case .happy: 0.10
        case .thinking: 0.13
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(.ninjaInk)
                .overlay(Circle().stroke(Palette.slateLight.color, lineWidth: size * 0.03))

            // The headband, with its two tails trailing to the right.
            Capsule()
                .fill(LinearGradient.ninjaBlade)
                .frame(width: size * 0.98, height: size * 0.24)
                .offset(y: -size * 0.14)

            // Hinged where the band ends, so they read as tails and not as
            // two bars floating next to his head.
            Capsule()
                .fill(Palette.blade.color)
                .frame(width: size * 0.30, height: size * 0.075)
                .rotationEffect(.degrees(24), anchor: .leading)
                .offset(x: size * 0.57, y: -size * 0.11)
            Capsule()
                .fill(Palette.bladeDeep.color)
                .frame(width: size * 0.24, height: size * 0.06)
                .rotationEffect(.degrees(-4), anchor: .leading)
                .offset(x: size * 0.53, y: -size * 0.17)

            HStack(spacing: size * 0.16) {
                eye
                eye
            }
            .offset(y: size * 0.10)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private var eye: some View {
        Capsule()
            .fill(.ninjaCream)
            .frame(width: size * 0.20, height: size * eyeHeight)
            .overlay(
                Circle()
                    .fill(.ninjaInk)
                    .frame(width: size * 0.075, height: size * 0.075)
                    .offset(x: mood == .thinking ? size * 0.04 : 0)
            )
    }
}
