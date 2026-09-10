import Foundation

/// An object and the letter its name starts with.
struct PictureWord: Equatable, Sendable, Identifiable {
    let word: String
    let picture: BrickPicture

    var id: String { word }

    /// Taken from the word so the two can never disagree. The accent is part
    /// of the letter: école starts with é, escargot with e.
    var letter: Character { word.first ?? " " }
}

/// The objects of the vowel game, drawn in bricks. A word only earns its
/// place if a six year old can name the picture without help and the French
/// voice says the word cleanly, which is why there is no igloo here.
enum PictureLibrary {
    static func words(startingWith letter: Character) -> [PictureWord] {
        words.filter { $0.letter == letter }
    }

    static func word(_ word: String) -> PictureWord? {
        words.first { $0.word == word }
    }

    /// The one on the dojo tile, so the tile says what the game is. The
    /// cream blade is the one object that reads on a blue brick.
    static var dojo: PictureWord { epee }

    static let words: [PictureWord] = [
        avion, arbre, ananas,
        escalier, escargot,
        epee, ecole, echelle,
        insecte, iguane,
        oiseau, os,
        usine, ukulele,
        yoyo, yogourt,
    ]

    private static let avion = PictureWord(word: "avion", picture: BrickPicture([
        ".....bb.....",
        "....bwwb....",
        "....bbbb....",
        "...bbbbbb...",
        "bbbbbbbbbbbb",
        ".bbbbbbbbbb.",
        "....bbbb....",
        "....bbbb....",
        "..bbbbbbbb..",
        ".....bb.....",
    ]))

    private static let arbre = PictureWord(word: "arbre", picture: BrickPicture([
        "....bbb....",
        "...bbbbb...",
        "..bbbbbbb..",
        ".bbbbbbbbb.",
        "..bbbbbbb..",
        ".bbbbbbbbb.",
        "....www....",
        "....www....",
        "...wwwww...",
    ]))

    private static let ananas = PictureWord(word: "ananas", picture: BrickPicture([
        "...b.b.b...",
        "....bbb....",
        "...bbbbb...",
        "..wawawaw..",
        ".wawawawaw.",
        ".awawawawa.",
        ".wawawawaw.",
        "..awawawa..",
        "...wawaw...",
    ]))

    private static let escalier = PictureWord(word: "escalier", picture: BrickPicture([
        "..........aa",
        "..........bb",
        "........aabb",
        "........bbbb",
        "......aabbbb",
        "......bbbbbb",
        "....aabbbbbb",
        "....bbbbbbbb",
        "..aabbbbbbbb",
        "..bbbbbbbbbb",
    ]))

    private static let escargot = PictureWord(word: "escargot", picture: BrickPicture([
        "...bbbbb.....",
        "..bb...bb....",
        ".bb.bbb.bb..w",
        ".bb.b.b.bb.ww",
        ".bb.bbb.bb.ag",
        "..bb...bbb.aa",
        "...bbbbb..aaa",
        ".aaaaaaaaaaa.",
        "..aaaaaaaaa..",
    ]))

    private static let epee = PictureWord(word: "épée", picture: BrickPicture([
        ".....w.....",
        "....www....",
        "....www....",
        "....www....",
        "....www....",
        "....www....",
        "..bbbbbbb..",
        ".....a.....",
        ".....a.....",
        ".....a.....",
        "....aaa....",
    ]))

    private static let ecole = PictureWord(word: "école", picture: BrickPicture([
        "......b......",
        ".....bbb.....",
        "....bbbbb....",
        "...bbbbbbb...",
        "..bbbbbbbbb..",
        ".wwwwwwwwwww.",
        ".wkkwwwwwkkw.",
        ".wkkwwwwwkkw.",
        ".wwwwwbbwwww.",
        ".wwwwwbbwwww.",
    ]))

    private static let echelle = PictureWord(word: "échelle", picture: BrickPicture([
        "..b.....b..",
        "..b.....b..",
        "..bbbbbbb..",
        "..b.....b..",
        "..b.....b..",
        "..bbbbbbb..",
        "..b.....b..",
        "..b.....b..",
        "..bbbbbbb..",
        "..b.....b..",
        "..b.....b..",
        "..bbbbbbb..",
    ]))

    /// A plain bug rather than a ladybug: spots would make him say
    /// coccinelle, and the word here is insecte.
    private static let insecte = PictureWord(word: "insecte", picture: BrickPicture([
        "...w...w...",
        "....bbb....",
        "...bbbbb...",
        "w..bbbbb..w",
        "..bbbbbbb..",
        "w.bbbbbbb.w",
        "..bbbbbbb..",
        "w..bbbbb..w",
        "...bbbbb...",
    ]))

    private static let iguane = PictureWord(word: "iguane", picture: BrickPicture([
        "...b.b.b.bbb..",
        ".bbbbbbbbbbbbb",
        "bbbbbbbbbbbbgb",
        ".bbbbbbbbbbbb.",
        "..bb...bb.....",
        "..bb...bb.....",
    ]))

    private static let oiseau = PictureWord(word: "oiseau", picture: BrickPicture([
        "......bbbb..",
        "....bbbbbbb.",
        "...bbbbbbgb.",
        "..bbbbbbbbww",
        ".bbbaaaabbb.",
        ".bbaaaaabb..",
        "..bbbbbbb...",
        "....w.w.....",
        "...ww.ww....",
    ]))

    private static let os = PictureWord(word: "os", picture: BrickPicture([
        "ww.......ww",
        "www.....www",
        ".wwwwwwwww.",
        ".wwwwwwwww.",
        "www.....www",
        "ww.......ww",
    ]))

    private static let usine = PictureWord(word: "usine", picture: BrickPicture([
        ".aa..........",
        "aa...aa......",
        ".bb..bb......",
        ".bb..bb......",
        ".bb..bb......",
        "wwwwwwwwwwwww",
        "wkkwwkkwwkkww",
        "wkkwwkkwwkkww",
        "wwwwwwbbwwwww",
        "wwwwwwbbwwwww",
    ]))

    private static let ukulele = PictureWord(word: "ukulélé", picture: BrickPicture([
        "....www....",
        ".....w.....",
        ".....w.....",
        ".....w.....",
        "...bbbbb...",
        "..bbbbbbb..",
        "...bbbbb...",
        "..bbbbbbb..",
        ".bbbkkkbbb.",
        ".bbbbbbbbb.",
        "..bbbbbbb..",
    ]))

    private static let yoyo = PictureWord(word: "yoyo", picture: BrickPicture([
        ".....w.....",
        ".....w.....",
        ".....w.....",
        "...bbbbb...",
        "..bbbbbbb..",
        ".bbbbbbbbb.",
        ".bbbwwwbbb.",
        ".bbbbbbbbb.",
        "..bbbbbbb..",
        "...bbbbb...",
    ]))

    private static let yogourt = PictureWord(word: "yogourt", picture: BrickPicture([
        ".wwwwwwwww.",
        "..bbbbbbb..",
        "..bbbbbbb..",
        "..bwwwwwb..",
        "..bbbbbbb..",
        "...bbbbb...",
        "...bbbbb...",
        "....bbb....",
    ]))
}
