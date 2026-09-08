import SwiftUI

/// Writing the letters and digits with a finger. Nothing here can fail: the
/// cursor stops rather than rejecting him, and help arrives on its own when he
/// stalls.
struct TraceModeView: View {
    let week: Week

    @Environment(Speaker.self) private var speaker
    @Environment(SoundEffects.self) private var effects
    @Environment(ProgressStore.self) private var store
    @Environment(\.verticalSizeClass) private var verticalSize

    @State private var index = 0
    @State private var attempt = 0

    private var glyphs: [Character] {
        week.tracing.characters.filter { GlyphLibrary.glyph(for: $0) != nil }
    }

    private var character: Character { glyphs[min(index, glyphs.count - 1)] }

    /// Landscape on a phone leaves almost no height, so the canvas takes the
    /// full height and the controls move beside it.
    private var isShort: Bool { verticalSize == .compact }

    var body: some View {
        ZStack(alignment: .top) {
            LinearGradient.ninjaBackdrop.ignoresSafeArea()
            if glyphs.isEmpty {
                Text("Aucun tracé pour cette semaine.")
                    .font(Typography.body)
                    .foregroundStyle(.ninjaCream)
            } else if isShort {
                sideBySide
            } else {
                stacked
            }
        }
        .navigationTitle("Le tracé")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { speaker.stop() }
    }

    private var stacked: some View {
        VStack(spacing: 14) {
            picker(.horizontal)
            canvas
            controls
            Spacer(minLength: 0)
        }
        .padding(.top, 8)
        .frame(maxWidth: 620)
        .frame(maxWidth: .infinity)
    }

    private var sideBySide: some View {
        HStack(spacing: 18) {
            canvas
            VStack(spacing: 14) {
                picker(.vertical)
                controls
            }
            .frame(maxWidth: 260)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 8)
    }

    @ViewBuilder private var canvas: some View {
        if let glyph = GlyphLibrary.glyph(for: character) {
            TracingCanvas(
                glyph: glyph,
                attempt: attempt,
                onStrokeDone: { effects.play(.stroke) },
                onGlyphDone: finish
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var controls: some View {
        HStack(spacing: 12) {
            Button("Effacer") { attempt += 1 }
                .buttonStyle(NinjaButtonStyle(prominent: false))
            Button(index + 1 < glyphs.count ? "Suivant" : "Recommencer", action: advance)
                .buttonStyle(NinjaButtonStyle(prominent: true))
        }
        .padding(.horizontal, isShort ? 0 : 20)
    }

    private func picker(_ axis: Axis.Set) -> some View {
        ScrollView(axis, showsIndicators: false) {
            let cells = ForEach(glyphs.indices, id: \.self) { position in
                Button {
                    index = position
                    attempt += 1
                } label: {
                    Text(String(glyphs[position]))
                        .font(Typography.glyph(24))
                        .foregroundStyle(position == index ? .ninjaInk : .ninjaCream)
                        .frame(width: 46, height: 46)
                        .background(
                            position == index ? Color.ninjaAzure : Palette.slate.color,
                            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Tracer \(glyphs[position])")
            }

            if axis == .vertical {
                LazyVGrid(columns: Array(repeating: GridItem(spacing: 8), count: 4), spacing: 8) { cells }
                    .padding(.horizontal, 4)
            } else {
                HStack(spacing: 10) { cells }
                    .padding(.horizontal, 20)
            }
        }
        .frame(maxHeight: axis == .vertical ? 160 : 60)
    }

    private func finish() {
        effects.play(.star)
        speaker.say([Pronunciation.praise(index), Pronunciation.letterName(character)])
        store.apply(.tracedGlyph(character))
    }

    private func advance() {
        index = (index + 1) % glyphs.count
        attempt += 1
    }
}
