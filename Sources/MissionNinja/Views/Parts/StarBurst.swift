import SwiftUI

/// The reward. Runs once when a star lands, then gets out of the way.
struct StarBurst: View {
    let trigger: Int
    var count = 8

    // Starts spent, so nothing shows until a star is actually earned.
    @State private var progress = 1.0

    var body: some View {
        ZStack {
            ForEach(0..<count, id: \.self) { index in
                let angle = Double(index) / Double(count) * 2 * .pi
                Image(systemName: "star.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(.ninjaGold)
                    .offset(
                        x: cos(angle) * 110 * progress,
                        y: sin(angle) * 110 * progress
                    )
                    .opacity(1 - progress)
                    .scaleEffect(0.5 + progress)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onChange(of: trigger) {
            progress = 0
            withAnimation(.easeOut(duration: 0.7)) { progress = 1 }
        }
    }
}
