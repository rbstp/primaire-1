import SwiftUI

/// The one thing he touches. Big, blue, and honest about what just happened:
/// green when he is right, a soft red only on the tile he actually picked.
struct BigChoiceButton: View {
    enum State: Sendable {
        case idle
        case correct
        case wrong
        case revealed
    }

    let label: String
    var glyphSize: CGFloat = 74
    var state: State = .idle
    var isEnabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(Typography.glyph(glyphSize))
                .foregroundStyle(foreground)
                .frame(maxWidth: .infinity, minHeight: 112)
                .background(background, in: shape)
                .overlay(shape.stroke(edge, lineWidth: 3))
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .animation(.easeOut(duration: 0.18), value: state)
        .accessibilityLabel(label)
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 26, style: .continuous)
    }

    private var background: Color {
        switch state {
        case .idle: Palette.slate.color
        case .correct, .revealed: Palette.bamboo.opacity(0.24).color
        case .wrong: Palette.crimson.opacity(0.20).color
        }
    }

    private var edge: Color {
        switch state {
        case .idle: Palette.blade.opacity(0.55).color
        case .correct, .revealed: .ninjaBamboo
        case .wrong: .ninjaCrimson
        }
    }

    private var foreground: Color {
        switch state {
        case .idle: .ninjaCream
        case .correct, .revealed: .ninjaBamboo
        case .wrong: .ninjaCrimson
        }
    }
}
