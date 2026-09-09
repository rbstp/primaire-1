import SwiftUI

/// A title spelled out on little bricks, one letter each, set a bit askew the
/// way a child lines them up.
struct BrickTitle: View {
    let text: String

    var body: some View {
        HStack(spacing: 3) {
            ForEach(Array(text.enumerated()), id: \.offset) { index, letter in
                if letter == " " {
                    Color.clear.frame(width: 8, height: 1)
                } else {
                    Brick(tone: index.isMultiple(of: 2) ? .blue : .azure, studs: 1, depth: 3, cornerRadius: 4) {
                        Text(String(letter))
                            .font(.system(size: 17, weight: .black, design: .rounded))
                            .foregroundStyle(index.isMultiple(of: 2) ? Color.ninjaCream : Color.ninjaInk)
                            .frame(width: 22, height: 24)
                    }
                    .rotationEffect(.degrees(Double((index * 7) % 5) * 2 - 4))
                    .offset(y: index.isMultiple(of: 2) ? 0 : 2)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
        .accessibilityAddTraits(.isHeader)
    }
}
