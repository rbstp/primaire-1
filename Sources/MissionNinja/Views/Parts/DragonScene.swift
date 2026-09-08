import SwiftUI

/// The dragon and, once he is whole, the ninja who fights him: lunge and
/// slash, then a jump back as the dragon breathes fire. The fight starts on
/// its own, with sound for its first round only; a touch makes him roar again.
struct DragonScene: View {
    let done: Int
    let total: Int
    let onRoar: () -> Void
    let onSlash: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var roarCue = 0
    @State private var lunging = false
    @State private var airborne = false
    @State private var fight: Task<Void, Never>?

    private var isComplete: Bool { total > 0 && done >= total }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            DragonBuild(done: done, total: total, roarCue: roarCue, hit: lunging, onRoar: onRoar)
            if isComplete {
                fighter
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .onChange(of: isComplete, initial: true) { _, complete in
            complete ? startFight() : stopFight()
        }
        .onDisappear(perform: stopFight)
    }

    /// Mirrored, so the katana hand faces the dragon.
    private var fighter: some View {
        NinjaMascot(mood: .happy, size: 52, fullBody: true)
            .scaleEffect(x: -1)
            .rotationEffect(.degrees(lunging ? -16 : 4), anchor: .bottom)
            .offset(x: lunging ? -34 : 6, y: airborne ? -26 : 0)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    private func startFight() {
        guard fight == nil, !reduceMotion else { return }
        fight = Task { [onSlash] in
            var round = 0
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(round == 0 ? 900 : 1400))
                guard !Task.isCancelled else { return }
                withAnimation(.spring(duration: 0.28, bounce: 0.35)) { lunging = true }
                if round == 0 { onSlash() }
                try? await Task.sleep(for: .milliseconds(420))
                guard !Task.isCancelled else { return }
                withAnimation(.spring(duration: 0.32, bounce: 0.5)) {
                    lunging = false
                    airborne = true
                }
                if round == 0 { roarCue += 1 }
                try? await Task.sleep(for: .milliseconds(360))
                guard !Task.isCancelled else { return }
                withAnimation(.spring(duration: 0.3, bounce: 0.3)) { airborne = false }
                round += 1
            }
        }
    }

    private func stopFight() {
        fight?.cancel()
        fight = nil
        lunging = false
        airborne = false
    }
}
