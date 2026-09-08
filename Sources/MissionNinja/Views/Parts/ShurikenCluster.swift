import SwiftUI

/// The pile to count. Laid out in rows of five, like counting tokens, so five
/// and six are told apart by looking rather than guessing.
struct ShurikenCluster: View {
    let count: Int
    var maxPerRow = 5

    private var rows: [[Int]] {
        stride(from: 0, to: count, by: maxPerRow).map { start in
            Array(start..<min(start + maxPerRow, count))
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            ForEach(rows.indices, id: \.self) { row in
                HStack(spacing: 12) {
                    ForEach(rows[row], id: \.self) { index in
                        ShurikenBadge(size: 48, fill: .ninjaBlade, edge: .ninjaAzure)
                            .rotationEffect(.degrees(Double(index % 3) * 12))
                            .accessibilityHidden(true)
                    }
                }
            }
        }
        .accessibilityElement()
        .accessibilityLabel("\(count) shurikens")
    }
}
