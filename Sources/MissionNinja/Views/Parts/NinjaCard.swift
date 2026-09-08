import SwiftUI

/// The one plate the whole app stacks its content on: a wide black brick, or
/// a blue one when it is the thing to look at.
struct NinjaCard<Content: View>: View {
    var tinted = false
    @ViewBuilder var content: Content

    var body: some View {
        Brick(tone: tinted ? .blue : .night, studs: 6, depth: 8, cornerRadius: 12) {
            content
                .padding(18)
                .frame(maxWidth: .infinity)
        }
    }
}
