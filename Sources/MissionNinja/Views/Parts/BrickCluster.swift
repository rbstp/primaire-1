import SwiftUI

/// The pile to count: whole fives stand as stacks with a 5 on top, the rest
/// tipped out on the slots CountingLayout picked. VoiceOver hears that there
/// are bricks to count, never how many: that is the answer.
struct BrickCluster: View {
    let count: Int
    let seed: Int

    var body: some View {
        HStack(alignment: .bottom, spacing: 18) {
            ForEach(0..<CountingLayout.stacks(count: count), id: \.self) { stack in
                FiveStack(seed: seed + stack)
            }
            if CountingLayout.loose(count: count) > 0 {
                loose
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Des briques à compter")
    }

    private var loose: some View {
        let filled = Set(CountingLayout.slots(count: CountingLayout.loose(count: count), seed: seed))
        return Grid(horizontalSpacing: 10, verticalSpacing: 14) {
            ForEach(0..<CountingLayout.rows, id: \.self) { row in
                GridRow {
                    ForEach(0..<CountingLayout.columns, id: \.self) { column in
                        let index = row * CountingLayout.columns + column
                        if filled.contains(index) {
                            CountingBrick(tone: index % 2 == 0 ? .blue : .azure, label: nil)
                                .rotationEffect(.degrees(Double((index * 7 + seed) % 5) * 4 - 8))
                        } else {
                            Color.clear.frame(width: 44, height: 31)
                        }
                    }
                }
            }
        }
    }
}

/// Five bricks clicked together, the top one saying so. A stack is one thing
/// to count, which is the whole point of grouping.
private struct FiveStack: View {
    let seed: Int

    var body: some View {
        // Negative spacing so each brick hides the studs of the one below.
        VStack(spacing: -11) {
            ForEach(0..<CountingLayout.stackSize, id: \.self) { index in
                CountingBrick(
                    tone: (index + seed) % 2 == 0 ? .blue : .azure,
                    label: index == 0 ? "\(CountingLayout.stackSize)" : nil
                )
            }
        }
        .rotationEffect(.degrees(Double(seed % 3) - 1))
    }
}

private struct CountingBrick: View {
    let tone: BrickTone
    let label: String?

    var body: some View {
        Brick(tone: tone, studs: 2, depth: 5, cornerRadius: 4) {
            ZStack {
                Color.clear.frame(width: 44, height: 22)
                if let label {
                    Text(label)
                        .font(Typography.glyph(16))
                        .foregroundStyle(tone == .blue ? Color.ninjaCream : Color.ninjaInk)
                }
            }
        }
        .accessibilityHidden(true)
    }
}
