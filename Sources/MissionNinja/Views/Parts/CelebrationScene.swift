import SwiftUI

/// What plays at the end of a run. The alphabet always ends on its dragon;
/// the drills draw one of the three so the ending stays a surprise.
enum Celebration: CaseIterable, Sendable {
    case dragon
    case shurikens
    case tower

    static func draw() -> Celebration {
        var random = SeededRandom.fresh()
        return random.shuffled(allCases)[0]
    }
}

struct CelebrationView: View {
    let kind: Celebration

    @Environment(SoundEffects.self) private var effects

    var body: some View {
        switch kind {
        case .dragon:
            DragonScene(
                done: 1,
                total: 1,
                onRoar: { effects.play(.roar) },
                onSlash: { effects.play(.stroke) }
            )
        case .shurikens:
            ShurikenScene(onThrow: { effects.play(.stroke) }, onHit: { effects.play(.snap) })
        case .tower:
            TowerScene(onSnap: { effects.play(.snap) }, onTop: { effects.play(.star) })
        }
    }
}

/// The ninja knocks a stack of bricks down one shuriken at a time, then
/// the stack comes back for another go.
private struct ShurikenScene: View {
    let onThrow: () -> Void
    let onHit: () -> Void

    private static let stackHeight = 4

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var standing = ShurikenScene.stackHeight
    @State private var flying = false
    @State private var winding = false
    @State private var loop: Task<Void, Never>?

    var body: some View {
        ZStack(alignment: .bottom) {
            HStack(alignment: .bottom) {
                NinjaMascot(mood: .thinking, size: 52, fullBody: true)
                    .rotationEffect(.degrees(winding ? -10 : 6), anchor: .bottom)
                Spacer()
                // Negative spacing so each brick hides the studs of the one below.
                VStack(spacing: -13) {
                    ForEach(0..<standing, id: \.self) { index in
                        Brick(tone: index % 2 == 0 ? .blue : .black, studs: 2, depth: 5, cornerRadius: 4) {
                            Color.clear.frame(width: 64, height: 18)
                        }
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .offset(x: 40, y: 70).combined(with: .opacity)
                        ))
                    }
                }
                .padding(.trailing, 12)
            }
            .padding(.horizontal, 20)

            ShurikenBadge(size: 26, fill: .ninjaBlade, edge: .ninjaAzure)
                .rotationEffect(.degrees(flying ? 900 : 0))
                .offset(x: flying ? 100 : -70, y: flying ? -CGFloat(standing) * 15 - 6 : -48)
                .opacity(flying || winding ? 1 : 0)
        }
        .frame(maxWidth: 360)
        .frame(height: 190)
        .accessibilityHidden(true)
        .onAppear(perform: start)
        .onDisappear(perform: stop)
    }

    private func start() {
        guard loop == nil, !reduceMotion else { return }
        loop = Task {
            var round = 0
            while !Task.isCancelled {
                if standing == 0 {
                    try? await Task.sleep(for: .milliseconds(700))
                    for _ in 0..<ShurikenScene.stackHeight {
                        guard !Task.isCancelled else { return }
                        withAnimation(.spring(duration: 0.3, bounce: 0.4)) { standing += 1 }
                        try? await Task.sleep(for: .milliseconds(160))
                    }
                    round += 1
                }
                try? await Task.sleep(for: .milliseconds(round == 0 ? 700 : 900))
                guard !Task.isCancelled else { return }
                withAnimation(.easeOut(duration: 0.2)) { winding = true }
                try? await Task.sleep(for: .milliseconds(260))
                guard !Task.isCancelled else { return }
                if round == 0 { onThrow() }
                withAnimation(.easeIn(duration: 0.32)) {
                    flying = true
                    winding = false
                }
                try? await Task.sleep(for: .milliseconds(330))
                guard !Task.isCancelled else { return }
                if round == 0 { onHit() }
                flying = false
                withAnimation(.easeIn(duration: 0.35)) { standing -= 1 }
                try? await Task.sleep(for: .milliseconds(200))
            }
        }
    }

    private func stop() {
        loop?.cancel()
        loop = nil
    }
}

/// Bricks drop into a tower one by one; the ninja climbs the wall, stands on
/// top, then backflips down to his spot before the whole thing tumbles.
private struct TowerScene: View {
    let onSnap: () -> Void
    let onTop: () -> Void

    private static let floors = 5
    /// A floor is a brick minus the studs the next one covers.
    private static let floorHeight: CGFloat = 15.5
    private static let groundX: CGFloat = -92
    /// Hands on the wall: half the tower plus half the ninja, less a grip.
    private static let wallX: CGFloat = -68

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var stacked = 0
    @State private var ninjaX = TowerScene.groundX
    @State private var ninjaY: CGFloat = 0
    @State private var lean = 0.0
    @State private var spin = 0.0
    @State private var onTopOfTower = false
    @State private var loop: Task<Void, Never>?

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: -13) {
                ForEach((0..<stacked).reversed(), id: \.self) { index in
                    Brick(tone: index % 2 == 0 ? .blue : .black, studs: 3, depth: 5, cornerRadius: 4) {
                        Color.clear.frame(width: 96, height: 16)
                    }
                    .transition(.asymmetric(
                        insertion: .offset(y: -120).combined(with: .opacity),
                        removal: .offset(x: index % 2 == 0 ? -60 : 60, y: 90).combined(with: .opacity)
                    ))
                }
            }

            NinjaMascot(mood: onTopOfTower ? .happy : .calm, size: 52, fullBody: true)
                .rotationEffect(.degrees(lean + spin))
                .offset(x: ninjaX, y: ninjaY)
        }
        .frame(height: 190)
        .accessibilityHidden(true)
        .onAppear(perform: start)
        .onDisappear(perform: stop)
    }

    private func start() {
        guard loop == nil, !reduceMotion else { return }
        loop = Task {
            var round = 0
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(500))
                for _ in 0..<TowerScene.floors {
                    guard !Task.isCancelled else { return }
                    withAnimation(.spring(duration: 0.32, bounce: 0.45)) { stacked += 1 }
                    if round == 0 { onSnap() }
                    try? await Task.sleep(for: .milliseconds(300))
                }

                // Wall climb: one floor at a time, leaning into the bricks.
                for floor in 1...TowerScene.floors {
                    guard !Task.isCancelled else { return }
                    withAnimation(.spring(duration: 0.22, bounce: 0.3)) {
                        ninjaX = TowerScene.wallX
                        ninjaY = -CGFloat(floor) * TowerScene.floorHeight + 4
                        lean = 16
                    }
                    try? await Task.sleep(for: .milliseconds(230))
                }

                guard !Task.isCancelled else { return }
                withAnimation(.spring(duration: 0.4, bounce: 0.5)) {
                    ninjaX = 0
                    ninjaY = -(CGFloat(TowerScene.floors) * TowerScene.floorHeight + 5)
                    lean = 0
                    onTopOfTower = true
                }
                if round == 0 { onTop() }
                try? await Task.sleep(for: .milliseconds(1100))

                // Backflip home: up and over in one turn, then a soft landing.
                guard !Task.isCancelled else { return }
                withAnimation(.easeOut(duration: 0.3)) {
                    ninjaY -= 44
                    ninjaX = TowerScene.groundX * 0.5
                    onTopOfTower = false
                }
                withAnimation(.linear(duration: 0.62)) { spin = -360 }
                try? await Task.sleep(for: .milliseconds(300))
                guard !Task.isCancelled else { return }
                withAnimation(.easeIn(duration: 0.32)) {
                    ninjaY = 0
                    ninjaX = TowerScene.groundX
                }
                try? await Task.sleep(for: .milliseconds(340))
                var landing = Transaction()
                landing.disablesAnimations = true
                withTransaction(landing) { spin = 0 }

                guard !Task.isCancelled else { return }
                try? await Task.sleep(for: .milliseconds(350))
                withAnimation(.easeIn(duration: 0.4)) { stacked = 0 }
                try? await Task.sleep(for: .milliseconds(600))
                round += 1
            }
        }
    }

    private func stop() {
        loop?.cancel()
        loop = nil
    }
}
