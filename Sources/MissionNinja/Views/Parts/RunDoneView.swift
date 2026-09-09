import SwiftUI

/// The end of a run: one of the three little scenes, drawn when the screen
/// appears so the ending is not always the same, and the stars it earned.
struct RunDoneView: View {
    let stars: Int
    let again: () -> Void
    let leave: () -> Void

    @State private var celebration = Celebration.draw()

    var body: some View {
        VStack(spacing: 26) {
            CelebrationView(kind: celebration)
                .frame(maxHeight: 200)
            Text("Entraînement terminé!")
                .font(Typography.screenTitle)
                .foregroundStyle(.ninjaCream)
            Label("\(stars) étoiles gagnées", systemImage: "star.fill")
                .font(Typography.counter)
                .foregroundStyle(.ninjaGold)

            VStack(spacing: 12) {
                Button("Encore une fois", action: again)
                    .buttonStyle(NinjaButtonStyle(prominent: true))
                Button("Retour au dojo", action: leave)
                    .buttonStyle(NinjaButtonStyle(prominent: false))
            }
            .padding(.horizontal, 32)
        }
        .padding(24)
    }
}
