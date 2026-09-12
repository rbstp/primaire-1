import SwiftUI

/// The one thing he touches. A big brick, honest about what just happened:
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
    var minHeight: CGFloat = 104
    var state: State = .idle
    var isEnabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(Typography.glyph(glyphSize))
                .foregroundStyle(foreground)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: .infinity, minHeight: minHeight)
        }
        .buttonStyle(BrickButtonStyle(tone: tone, studs: 3, minHeight: minHeight, cornerRadius: 12, depth: 10))
        .disabled(!isEnabled)
        .animation(.easeOut(duration: 0.18), value: state)
        .accessibilityLabel(label)
    }

    private var tone: BrickTone {
        switch state {
        case .idle: .black
        case .correct, .revealed: .green
        case .wrong: .red
        }
    }

    private var foreground: Color {
        switch state {
        case .idle: .ninjaCream
        case .correct, .revealed: .ninjaInk
        case .wrong: .ninjaCream
        }
    }
}
