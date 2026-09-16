import SwiftUI

/// The wait before the next hint, as a small brick in the corner. It shows up
/// the moment a hint is spent and counts itself down; missing on purpose to
/// light up the answer only makes this number bigger.
struct HintCountdown: View {
    let readyAt: Date

    var body: some View {
        TimelineView(.explicit(ticks)) { context in
            let left = Int(ceil(readyAt.timeIntervalSince(context.date)))
            if left > 0 {
                Brick(tone: .night, studs: 2, depth: 4, cornerRadius: 7) {
                    HStack(spacing: 6) {
                        Image(systemName: "hourglass")
                            .font(.system(size: 13, weight: .bold))
                        Text("\(left)")
                            .font(Typography.counter)
                            .monospacedDigit()
                    }
                    .foregroundStyle(Palette.cream.opacity(0.55).color)
                    .padding(.horizontal, 10)
                    .frame(minHeight: 28)
                }
                .accessibilityLabel("Prochain indice dans \(left) secondes")
            }
        }
    }

    /// A tick a second, and no more: a schedule that runs forever would redraw
    /// a corner of the screen all evening for a counter that is not there.
    private var ticks: [Date] {
        let now = Date.now
        let left = readyAt.timeIntervalSince(now)
        guard left > 0 else { return [now] }
        return stride(from: 0, to: left, by: 1).map { now.addingTimeInterval($0) } + [readyAt]
    }
}
