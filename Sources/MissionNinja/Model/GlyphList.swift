import Foundation

/// A list of single characters in JSON, kept as characters in memory.
/// Decoding rejects "ab" or "" rather than silently keeping something the
/// tracing and drill code cannot use.
struct GlyphList: Codable, Equatable, Sendable, ExpressibleByArrayLiteral {
    let characters: [Character]

    init(_ characters: [Character]) {
        self.characters = characters
    }

    init(arrayLiteral elements: Character...) {
        self.init(elements)
    }

    init(from decoder: any Decoder) throws {
        let raw = try [String](from: decoder)
        characters = try raw.map { text in
            guard text.count == 1, let character = text.first else {
                throw DecodingError.dataCorruptedError(
                    in: try decoder.singleValueContainer(),
                    debugDescription: "\"\(text)\" is not a single character"
                )
            }
            return character
        }
    }

    func encode(to encoder: any Encoder) throws {
        try characters.map(String.init).encode(to: encoder)
    }
}

extension GlyphList: RandomAccessCollection {
    var startIndex: Int { characters.startIndex }
    var endIndex: Int { characters.endIndex }
    subscript(position: Int) -> Character { characters[position] }
}
