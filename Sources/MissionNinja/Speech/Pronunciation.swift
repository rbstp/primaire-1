import Foundation

/// Text handed to the synthesiser, with an optional phonetic spelling for the
/// cases where a bare character comes out wrong. The text alone is always
/// correct French, so a voice that ignores the phonetic hint still says the
/// right thing.
struct Utterance: Equatable, Sendable {
    let text: String
    var ipa: String?

    init(_ text: String, ipa: String? = nil) {
        self.text = text
        self.ipa = ipa
    }
}

/// A letter is named the way the class names it: "i grec", and "e accent
/// aigu" for é, which is a letter of its own in first grade.
enum Pronunciation {
    static func letterName(_ character: Character) -> Utterance {
        let letter = Character(String(character).lowercased())
        return names[letter] ?? Utterance(String(character))
    }

    static func numberWord(_ value: Int) -> Utterance {
        Utterance(frenchNumber(value) ?? String(value))
    }

    /// A word as it is written on the card. The "…" of "ne … pas" is there for
    /// the eye; read out loud it becomes noise.
    static func word(_ word: String) -> Utterance {
        Utterance(word.replacingOccurrences(of: " … ", with: " "))
    }

    /// A name as it is said in class. "Mme" on a card is read out in full,
    /// and the few names the French voice mangles carry a phonetic spelling.
    /// To be checked on a real device: the simulator has no voice to check with.
    static func name(_ name: String) -> Utterance {
        let text = name.replacingOccurrences(of: "Mme ", with: "Madame ")
        return Utterance(text, ipa: nameSounds[name])
    }

    static func isVowel(_ character: Character) -> Bool {
        "aeiouy".contains(Character(String(character).lowercased()))
    }

    /// Said twice, with no instruction around it: one would be repeated ten
    /// times a session, and the screen already says what to do. A letter is
    /// named as "la lettre a": bare, a one syllable name went by too fast. One
    /// phrase, not two utterances, or the pause between them makes the name
    /// run into the next "la lettre".
    static func script(for prompt: DrillPrompt) -> [Utterance] {
        switch prompt {
        case let .spokenLetter(character):
            let phrase = Utterance("La lettre \(letterName(character).text)")
            return [phrase, phrase]
        case let .spokenNumber(value):
            let word = numberWord(value)
            return [word, word]
        case let .spokenName(name):
            let spoken = Pronunciation.name(name)
            return [spoken, spoken]
        case let .spokenWord(text):
            let spoken = Pronunciation.word(text)
            return [spoken, spoken]
        case .bricks:
            return [Utterance("Combien de briques vois-tu?")]
        case let .object(word):
            let spoken = Utterance(word)
            return [spoken, spoken]
        }
    }

    static func praise(_ index: Int) -> Utterance {
        Utterance(cheers[abs(index) % cheers.count])
    }

    static func correction(_ choice: DrillChoice) -> [Utterance] {
        switch choice {
        case let .letter(character):
            return [Utterance("C'était"), letterName(character)]
        case let .number(value):
            return [Utterance("C'était"), numberWord(value)]
        case let .name(name):
            return [Utterance("C'était"), Pronunciation.name(name)]
        case let .word(text):
            return [Utterance("C'était"), Pronunciation.word(text)]
        }
    }

    /// Nothing the French voice mangles: "ninja" came out wrong on the device.
    private static let cheers = [
        "Bravo!",
        "Excellent!",
        "Bien joué!",
        "C'est exact!",
        "Tu progresses vite!",
        "Parfait!",
    ]

    /// Standard French, the way the class writes it on the number grid:
    /// soixante-dix, quatre-vingt-dix, and the hyphens all the way through.
    private static func frenchNumber(_ value: Int) -> String? {
        if let known = words[value] { return known }
        switch value {
        case 21...69:
            guard let ten = tens[value / 10] else { return nil }
            let unit = value % 10
            if unit == 0 { return ten }
            return unit == 1 ? "\(ten)-et-un" : "\(ten)-\(words[unit] ?? "")"
        case 70...79:
            let rest = value - 60
            return rest == 11 ? "soixante-et-onze" : "soixante-\(words[rest] ?? "")"
        case 80...99:
            let rest = value - 80
            return rest == 0 ? "quatre-vingts" : "quatre-vingt-\(words[rest] ?? "")"
        case 100:
            return "cent"
        default:
            return nil
        }
    }

    private static let tens: [Int: String] = [
        2: "vingt", 3: "trente", 4: "quarante", 5: "cinquante", 6: "soixante",
    ]

    private static let words: [Int: String] = [
        0: "zéro", 1: "un", 2: "deux", 3: "trois", 4: "quatre",
        5: "cinq", 6: "six", 7: "sept", 8: "huit", 9: "neuf",
        10: "dix", 11: "onze", 12: "douze", 13: "treize", 14: "quatorze",
        15: "quinze", 16: "seize", 17: "dix-sept", 18: "dix-huit", 19: "dix-neuf",
        20: "vingt",
    ]

    private static let nameSounds: [String: String] = [
        "Hayden": "edɛn",
        "Madison": "madisɔn",
    ]

    private static let names: [Character: Utterance] = [
        "a": Utterance("a", ipa: "a"),
        "b": Utterance("bé", ipa: "be"),
        "c": Utterance("cé", ipa: "se"),
        "d": Utterance("dé", ipa: "de"),
        "e": Utterance("e", ipa: "ə"),
        "f": Utterance("effe", ipa: "ɛf"),
        "g": Utterance("gé", ipa: "ʒe"),
        "h": Utterance("hache", ipa: "aʃ"),
        "i": Utterance("i", ipa: "i"),
        "j": Utterance("ji", ipa: "ʒi"),
        "k": Utterance("ka", ipa: "ka"),
        "l": Utterance("elle", ipa: "ɛl"),
        "m": Utterance("emme", ipa: "ɛm"),
        "n": Utterance("enne", ipa: "ɛn"),
        "o": Utterance("o", ipa: "o"),
        "p": Utterance("pé", ipa: "pe"),
        "q": Utterance("qu", ipa: "ky"),
        "r": Utterance("erre", ipa: "ɛʁ"),
        "s": Utterance("esse", ipa: "ɛs"),
        "t": Utterance("té", ipa: "te"),
        "u": Utterance("u", ipa: "y"),
        "v": Utterance("vé", ipa: "ve"),
        "w": Utterance("double vé", ipa: "dubləve"),
        "x": Utterance("ixe", ipa: "iks"),
        "y": Utterance("i grec", ipa: "iɡʁɛk"),
        "z": Utterance("zède", ipa: "zɛd"),
        "é": Utterance("e accent aigu"),
        "è": Utterance("e accent grave"),
        "ê": Utterance("e accent circonflexe"),
        "ç": Utterance("c cédille"),
    ]
}
