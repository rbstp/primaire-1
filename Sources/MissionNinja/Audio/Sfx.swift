import Foundation

/// Every sound is synthesised at launch, so nothing ships as an audio file.
/// A miss is deliberately soft and low: it should read as "try again", never
/// as a buzzer.
enum Sfx: CaseIterable, Sendable {
    case right
    case wrong
    case star
    case belt
    case stroke
    case tap

    var recipe: ToneRecipe {
        switch self {
        case .right:
            ToneRecipe(wave: .triangle, segments: [
                .note(Note.e5, 0.07, gain: 0.30),
                .note(Note.g5, 0.07, gain: 0.30),
                .note(Note.c6, 0.20, gain: 0.30, release: 0.14),
            ])
        case .wrong:
            ToneRecipe(wave: .triangle, segments: [
                .note(Note.g4, 0.10, gain: 0.18),
                .note(Note.e4, 0.18, gain: 0.16, release: 0.12),
            ])
        case .star:
            ToneRecipe(wave: .square(duty: 0.25), segments: [
                .note(Note.c6, 0.05, gain: 0.22),
                .note(Note.e6, 0.16, gain: 0.22, release: 0.12),
            ])
        case .belt:
            ToneRecipe(wave: .triangle, segments: [
                .note(Note.c5, 0.09, gain: 0.32),
                .note(Note.e5, 0.09, gain: 0.32),
                .note(Note.g5, 0.09, gain: 0.32),
                .note(Note.c6, 0.34, gain: 0.34, release: 0.24),
            ])
        case .stroke:
            ToneRecipe(wave: .square(duty: 0.5), segments: [
                .sweep(520, 900, 0.05, gain: 0.16),
            ])
        case .tap:
            ToneRecipe(wave: .square(duty: 0.5), segments: [
                .note(Note.c5, 0.03, gain: 0.12),
            ])
        }
    }
}
