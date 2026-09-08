import SwiftUI

/// The pile to count, tipped out on the slots CountingLayout picked. VoiceOver
/// hears that there are bricks to count, never how many: that is the answer.
struct BrickCluster: View {
    let count: Int
    let seed: Int

    var body: some View {
        let filled = Set(CountingLayout.slots(count: count, seed: seed))
        Grid(horizontalSpacing: 14, verticalSpacing: 16) {
            ForEach(0..<CountingLayout.rows, id: \.self) { row in
                GridRow {
                    ForEach(0..<CountingLayout.columns, id: \.self) { column in
                        let index = row * CountingLayout.columns + column
                        if filled.contains(index) {
                            Brick(tone: index % 2 == 0 ? .blue : .azure, studs: 2, depth: 6, cornerRadius: 4) {
                                Color.clear.frame(width: 50, height: 26)
                            }
                            .rotationEffect(.degrees(Double((index * 7 + seed) % 5) * 4 - 8))
                            .accessibilityHidden(true)
                        } else {
                            Color.clear.frame(width: 50, height: 37)
                        }
                    }
                }
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Des briques à compter")
    }
}
