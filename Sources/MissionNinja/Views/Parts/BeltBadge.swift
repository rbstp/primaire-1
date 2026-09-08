import SwiftUI

/// The belt, the star count and the streak, on one black brick. A three
/// second press opens the parent screen, which he will not find by accident.
struct BeltBadge: View {
    let belt: Belt
    let stars: Int
    let advance: Double
    let streak: Int
    var onParentAccess: (() -> Void)?

    var body: some View {
        Brick(tone: .night, studs: 6, depth: 7, cornerRadius: 12) {
            HStack(spacing: 14) {
                ring
                VStack(alignment: .leading, spacing: 2) {
                    Text(belt.name.capitalizedFirst)
                        .font(Typography.counter)
                        .foregroundStyle(.ninjaCream)
                    HStack(spacing: 10) {
                        Label("\(stars)", systemImage: "star.fill")
                            .foregroundStyle(.ninjaGold)
                        if streak > 1 {
                            Label("\(streak) jours", systemImage: "flame.fill")
                                .foregroundStyle(.ninjaBlade)
                        }
                    }
                    .font(Typography.caption)
                    .labelStyle(.titleAndIcon)
                }
                Spacer(minLength: 0)
                MinifigHead(mood: .calm, size: 48)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .onLongPressGesture(minimumDuration: 3) { onParentAccess?() }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(belt.name), \(stars) étoiles")
        .accessibilityHint("Appui long de trois secondes pour l'écran des parents")
    }

    private var ring: some View {
        ZStack {
            Circle()
                .stroke(Palette.slateLight.color, lineWidth: 6)
            Circle()
                .trim(from: 0, to: advance)
                .stroke(belt.paint.color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
            ShurikenBadge(size: 26, fill: belt.paint.color, edge: .ninjaInk)
        }
        .frame(width: 52, height: 52)
    }
}

extension String {
    var capitalizedFirst: String {
        guard let first else { return self }
        return String(first).uppercased() + dropFirst()
    }
}
