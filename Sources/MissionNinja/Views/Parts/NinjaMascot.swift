import SwiftUI

/// The little ninja, built like a minifig. A black hood covers the whole head,
/// stud included; only the eye slit shows skin, and the eyes carry the mood.
struct NinjaMascot: View {
    enum Mood: Sendable {
        case calm
        case happy
        case thinking
    }

    var mood: Mood = .calm
    var size: CGFloat = 120
    /// The head alone, or the whole figure standing on its legs.
    var fullBody = false

    var body: some View {
        if fullBody {
            // The body draws after the head so the katana passes in front of
            // the hood; the neck starts exactly where the hood ends.
            VStack(spacing: -size * 0.056) {
                MinifigHead(mood: mood, size: size * 0.62)
                MinifigBody(size: size * 0.62)
            }
            .frame(width: size, height: size * 1.55)
            .accessibilityHidden(true)
        } else {
            MinifigHead(mood: mood, size: size)
                .accessibilityHidden(true)
        }
    }
}

/// The rim that keeps black cloth readable on the night background.
enum MinifigRim {
    static let paint = Palette.slateLight.mixed(with: Palette.cream, amount: 0.32)

    static func width(_ size: CGFloat) -> CGFloat { max(1.5, size * 0.024) }
}

struct MinifigHead: View {
    var mood: NinjaMascot.Mood = .calm
    var size: CGFloat = 120

    private var eyeHeight: CGFloat {
        switch mood {
        case .calm: 0.13
        case .happy: 0.075
        case .thinking: 0.11
        }
    }

    var body: some View {
        ZStack {
            // The stud on top, part of the hood.
            RoundedRectangle(cornerRadius: size * 0.06, style: .continuous)
                .fill(Palette.slateLight.color)
                .overlay(RoundedRectangle(cornerRadius: size * 0.06, style: .continuous).stroke(MinifigRim.paint.color, lineWidth: MinifigRim.width(size)))
                .frame(width: size * 0.34, height: size * 0.16)
                .offset(y: -size * 0.44)

            RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                .fill(LinearGradient(
                    colors: [Palette.slateLight.color, Palette.slate.color],
                    startPoint: .top,
                    endPoint: .bottom
                ))
                .overlay(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous).stroke(MinifigRim.paint.color, lineWidth: MinifigRim.width(size)))
                .frame(width: size * 0.78, height: size * 0.86)
                .offset(y: -size * 0.02)

            // The eye slit.
            RoundedRectangle(cornerRadius: size * 0.1, style: .continuous)
                .fill(Palette.skin.color)
                .frame(width: size * 0.62, height: size * 0.2)
                .offset(y: size * 0.03)

            // The headband, tied behind, with its two tails to the right.
            Capsule()
                .fill(LinearGradient.ninjaBlade)
                .frame(width: size * 0.9, height: size * 0.16)
                .offset(y: -size * 0.13)
            Capsule()
                .fill(Palette.blade.color)
                .frame(width: size * 0.3, height: size * 0.07)
                .rotationEffect(.degrees(22), anchor: .leading)
                .offset(x: size * 0.55, y: -size * 0.11)
            Capsule()
                .fill(Palette.bladeDeep.color)
                .frame(width: size * 0.24, height: size * 0.06)
                .rotationEffect(.degrees(-6), anchor: .leading)
                .offset(x: size * 0.52, y: -size * 0.17)

            HStack(spacing: size * 0.2) {
                eye
                eye
            }
            .offset(y: size * 0.04)
        }
        .frame(width: size, height: size)
    }

    private var eye: some View {
        Capsule()
            .fill(Palette.ink.color)
            .frame(width: size * 0.13, height: size * eyeHeight)
            .overlay(alignment: .topLeading) {
                Circle()
                    .fill(Palette.cream.opacity(0.85).color)
                    .frame(width: size * 0.035, height: size * 0.035)
                    .offset(x: size * (mood == .thinking ? 0.075 : 0.03), y: size * 0.02)
            }
    }
}

/// All in black, blue belt, katana in hand: a ninja, not a workman. Torso,
/// hips and legs are one silhouette so he reads as one figure, not a stack of
/// parts.
struct MinifigBody: View {
    var size: CGFloat = 80

    var body: some View {
        ZStack {
            HStack {
                arm
                Spacer()
                arm
            }
            .frame(width: size * 1.08)
            .offset(y: -size * 0.28)

            FigureSilhouette()
                .fill(LinearGradient(
                    colors: [Palette.slateLight.color, Palette.slate.color],
                    startPoint: .top,
                    endPoint: .bottom
                ))
                .overlay(FigureSilhouette().stroke(MinifigRim.paint.color, lineWidth: MinifigRim.width(size)))

            Capsule()
                .fill(Palette.blade.color)
                .frame(width: size * 0.82, height: size * 0.1)
                .offset(y: -size * 0.06)

            katana
        }
        .frame(width: size * 1.1, height: size * 1.15)
    }

    /// Gripped in the right hand: the handle runs through the hand, the blade
    /// rises beside the head, clear of the face.
    private var katana: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(LinearGradient(colors: [Palette.cream.color, Palette.azure.color], startPoint: .top, endPoint: .bottom))
                .frame(width: size * 0.09, height: size * 0.78)
            RoundedRectangle(cornerRadius: size * 0.02)
                .fill(Palette.blade.color)
                .frame(width: size * 0.2, height: size * 0.06)
            Capsule()
                .fill(Palette.ink.color)
                .overlay(Capsule().stroke(MinifigRim.paint.color, lineWidth: MinifigRim.width(size) * 0.7))
                .frame(width: size * 0.09, height: size * 0.22)
        }
        .rotationEffect(.degrees(28), anchor: .bottom)
        .offset(x: size * 0.41, y: -size * 0.49)
    }

    private var arm: some View {
        VStack(spacing: -size * 0.02) {
            Capsule()
                .fill(Palette.slate.color)
                .overlay(Capsule().stroke(MinifigRim.paint.color, lineWidth: MinifigRim.width(size)))
                .frame(width: size * 0.16, height: size * 0.48)
            Circle()
                .fill(Palette.slateLight.color)
                .overlay(Circle().stroke(MinifigRim.paint.color, lineWidth: MinifigRim.width(size)))
                .frame(width: size * 0.15, height: size * 0.15)
        }
    }
}

/// Neck, torso, hips and both legs as one outline. Proportions in units of
/// the frame width; the slit between the legs stops at the hips.
private struct FigureSilhouette: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let midX = rect.midX
        let torsoHalf = w * 0.37
        let hipHalf = w * 0.36
        let neckHalf = w * 0.12
        let top = rect.minY + h * 0.1
        let hipTop = rect.minY + h * 0.62
        let legTop = rect.minY + h * 0.72
        let bottom = rect.maxY
        let slit = w * 0.02
        let corner = w * 0.05

        var path = Path()
        path.move(to: CGPoint(x: midX - neckHalf, y: rect.minY))
        path.addLine(to: CGPoint(x: midX + neckHalf, y: rect.minY))
        path.addLine(to: CGPoint(x: midX + neckHalf, y: top))
        path.addLine(to: CGPoint(x: midX + torsoHalf - corner, y: top))
        path.addQuadCurve(to: CGPoint(x: midX + torsoHalf, y: top + corner), control: CGPoint(x: midX + torsoHalf, y: top))
        path.addLine(to: CGPoint(x: midX + torsoHalf, y: hipTop))
        path.addLine(to: CGPoint(x: midX + hipHalf, y: hipTop))
        path.addLine(to: CGPoint(x: midX + hipHalf, y: bottom - corner))
        path.addQuadCurve(to: CGPoint(x: midX + hipHalf - corner, y: bottom), control: CGPoint(x: midX + hipHalf, y: bottom))
        path.addLine(to: CGPoint(x: midX + slit, y: bottom))
        path.addLine(to: CGPoint(x: midX + slit, y: legTop))
        path.addLine(to: CGPoint(x: midX - slit, y: legTop))
        path.addLine(to: CGPoint(x: midX - slit, y: bottom))
        path.addLine(to: CGPoint(x: midX - hipHalf + corner, y: bottom))
        path.addQuadCurve(to: CGPoint(x: midX - hipHalf, y: bottom - corner), control: CGPoint(x: midX - hipHalf, y: bottom))
        path.addLine(to: CGPoint(x: midX - hipHalf, y: hipTop))
        path.addLine(to: CGPoint(x: midX - torsoHalf, y: hipTop))
        path.addLine(to: CGPoint(x: midX - torsoHalf, y: top + corner))
        path.addQuadCurve(to: CGPoint(x: midX - torsoHalf + corner, y: top), control: CGPoint(x: midX - torsoHalf, y: top))
        path.addLine(to: CGPoint(x: midX - neckHalf, y: top))
        path.closeSubpath()
        return path
    }
}
