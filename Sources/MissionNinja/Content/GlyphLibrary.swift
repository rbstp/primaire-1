import Foundation
import Synchronization

/// Strokes are authored by hand, not pulled out of a font. A font outline
/// describes the edge of a filled shape rather than the path of a pen, it
/// carries no writing order, and its letterforms are not the school ones: SF
/// Pro draws a two storey a, while first grade teaches the single storey a
/// below.
enum GlyphLibrary {
    /// The school lines the glyphs sit on, as fractions of the square.
    enum Rule {
        static let cap = 0.12
        static let middle = 0.44
        static let base = 0.86
        static let dot = 0.26
    }

    static func spec(for character: Character) -> GlyphSpec? {
        specs[character]
    }

    static func glyph(for character: Character) -> TraceGlyph? {
        cache.withLock { store in
            if let ready = store[character] { return ready }
            guard let spec = specs[character] else { return nil }
            let ready = TraceGlyph(spec)
            store[character] = ready
            return ready
        }
    }

    static var available: [Character] { specs.keys.sorted() }

    private static let cache = Mutex<[Character: TraceGlyph]>([:])

    private static let specs: [Character: GlyphSpec] = {
        var all: [Character: GlyphSpec] = [:]
        for spec in GlyphLibrary.vowels + GlyphLibrary.digits {
            all[spec.character] = spec
        }
        return all
    }()
}
