import SwiftUI

/// Every button is a brick. Prominent ones are blue, the rest black, and a
/// press sinks the brick instead of dimming it.
struct NinjaButtonStyle: ButtonStyle {
    var prominent = true

    func makeBody(configuration: Configuration) -> some View {
        BrickButtonStyle(tone: prominent ? .blue : .black, minHeight: 56)
            .makeBody(configuration: configuration)
    }
}

/// A round button is a single big stud: a blue cylinder with a lit top that
/// sinks when pressed.
struct StudButtonStyle: ButtonStyle {
    var diameter: CGFloat = 60

    func makeBody(configuration: Configuration) -> some View {
        let depth = diameter * 0.11
        let sink = configuration.isPressed ? depth * 0.75 : 0
        configuration.label
            .foregroundStyle(.ninjaCream)
            .frame(width: diameter, height: diameter)
            .background {
                Circle().fill(Palette.bladeDeep.color).offset(y: depth)
                Circle().fill(LinearGradient.ninjaBlade)
                Circle().strokeBorder(Palette.cream.opacity(0.18).color, lineWidth: 1.5)
            }
            .offset(y: sink)
            .padding(.bottom, depth)
            .animation(.spring(duration: 0.18, bounce: 0.2), value: configuration.isPressed)
    }
}

struct BrickButtonStyle: ButtonStyle {
    var tone: BrickTone = .blue
    var studs = 4
    var minHeight: CGFloat = 56
    var cornerRadius: CGFloat = 10
    var depth: CGFloat = 7

    /// Blue text on a black brick, dark text on a light one, cream elsewhere.
    private var foreground: Color {
        switch tone {
        case .black, .night: .ninjaBlade
        case .azure, .gold, .cream, .green: .ninjaInk
        default: .ninjaCream
        }
    }

    func makeBody(configuration: Configuration) -> some View {
        Brick(tone: tone, studs: studs, depth: depth, cornerRadius: cornerRadius, pressed: configuration.isPressed) {
            configuration.label
                .font(Typography.counter)
                .foregroundStyle(foreground)
                .frame(maxWidth: .infinity, minHeight: minHeight)
        }
    }
}
