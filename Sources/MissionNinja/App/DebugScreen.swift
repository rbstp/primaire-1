#if DEBUG
import SwiftUI

/// Jump straight to a screen with `-screen <name>` at launch. The drawn
/// material is proofread the same way: `-screen glyphs` shows every letter
/// with its stroke order and direction, `-screen pictures` every object of the
/// vowel game with the word it stands for.
enum DebugScreen: String {
    case dojo
    case letters
    case numbers
    case names
    case build
    case vowels
    case alphabet
    case trace
    case log
    case glyphs
    case pictures
    case scenes
    case summary
    case parent

    static var requested: DebugScreen? {
        guard let index = ProcessInfo.processInfo.arguments.firstIndex(of: "-screen"),
              let name = ProcessInfo.processInfo.arguments[safe: index + 1]
        else { return nil }
        return DebugScreen(rawValue: name)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

/// The three end-of-run scenes, side by side, so their timing can be watched
/// without finishing a run.
struct SceneProofView: View {
    var body: some View {
        ZStack {
            Baseplate().ignoresSafeArea()
            ScrollView {
                VStack(spacing: 24) {
                    ForEach(Celebration.allCases, id: \.self) { kind in
                        CelebrationView(kind: kind)
                            .frame(height: 200)
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Relecture des scènes")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Every object of the vowel game with its word, so a mosaic that does not
/// read as what it is can be spotted without playing.
struct PictureProofView: View {
    var body: some View {
        ZStack {
            Baseplate().ignoresSafeArea()
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(spacing: 10), count: 3), spacing: 14) {
                    ForEach(PictureLibrary.words) { word in
                        VStack(spacing: 6) {
                            BrickPictureView(picture: word.picture)
                                .frame(height: 96)
                            Text(word.word)
                                .font(Typography.caption)
                                .foregroundStyle(Palette.cream.opacity(0.7).color)
                        }
                    }
                }
                .padding(14)
            }
        }
        .navigationTitle("Relecture des objets")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Every glyph with numbered start points and direction arrows.
struct GlyphProofView: View {
    private let characters = GlyphLibrary.available

    var body: some View {
        ZStack {
            Baseplate().ignoresSafeArea()
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(spacing: 10), count: 4), spacing: 10) {
                    ForEach(characters, id: \.self) { character in
                        if let glyph = GlyphLibrary.glyph(for: character) {
                            GlyphProof(glyph: glyph)
                        }
                    }
                }
                .padding(14)
            }
        }
        .navigationTitle("Relecture des tracés")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct GlyphProof: View {
    let glyph: TraceGlyph

    var body: some View {
        GeometryReader { frame in
            let side = min(frame.size.width, frame.size.height)
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 14).fill(Palette.slate.color)
                ForEach(glyph.strokes.indices, id: \.self) { index in
                    let stroke = glyph.strokes[index]
                    Path { path in
                        guard let first = stroke.points.first else { return }
                        path.move(to: CGPoint(x: first.x * side, y: first.y * side))
                        for point in stroke.points.dropFirst() {
                            path.addLine(to: CGPoint(x: point.x * side, y: point.y * side))
                        }
                    }
                    .stroke(Palette.azure.opacity(1 - Double(index) * 0.22).color, lineWidth: 3)

                    Text("\(index + 1)")
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(.ninjaInk)
                        .frame(width: 16, height: 16)
                        .background(Palette.gold.color, in: Circle())
                        .position(x: stroke.first.x * side, y: stroke.first.y * side)

                    Arrow(at: stroke.points[min(stroke.points.count - 1, stroke.points.count / 4)],
                          heading: stroke.tangent(at: stroke.points.count / 4),
                          side: side)
                }
                Text(String(glyph.character))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Palette.cream.opacity(0.6).color)
                    .padding(6)
            }
            .frame(width: side, height: side)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

private struct Arrow: View {
    let at: UnitPoint2
    let heading: UnitPoint2
    let side: Double

    var body: some View {
        Image(systemName: "arrowtriangle.right.fill")
            .font(.system(size: 10))
            .foregroundStyle(.ninjaCream)
            .rotationEffect(.radians(atan2(heading.y, heading.x)))
            .position(x: at.x * side, y: at.y * side)
    }
}
#endif
