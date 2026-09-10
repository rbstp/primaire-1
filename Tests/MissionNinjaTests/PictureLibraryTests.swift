import Testing

@testable import MissionNinja

@Suite struct PictureLibraryTests {
    /// The letters the pictures can answer. No word starts with è in French,
    /// so the grave accent is only ever offered beside the acute one.
    private let answerable: [Character] = Array("aeéiouy")

    @Test func hasAtLeastOneObjectForEveryVowelOfTheWeek() {
        for letter in answerable {
            #expect(!PictureLibrary.words(startingWith: letter).isEmpty, "\(letter) n'a pas d'objet")
        }
    }

    @Test func namesEveryObjectOnce() {
        let words = PictureLibrary.words.map(\.word)
        #expect(Set(words).count == words.count)
    }

    /// The letter is read off the word, so a picture filed under the wrong
    /// letter is impossible. A word carrying an accent the week never teaches
    /// is not: île starts with î, which no drill would ever offer.
    @Test func everyWordStartsWithAVowel() {
        for word in PictureLibrary.words {
            #expect(answerable.contains(word.letter), "\(word.word)")
        }
    }

    @Test func everyPictureHasBricksInsideItsGrid() {
        for word in PictureLibrary.words {
            let picture = word.picture
            #expect(picture.columns > 0, "\(word.word)")
            #expect(picture.rows > 0, "\(word.word)")
            #expect(picture.cells.count > 12, "\(word.word)")
            for cell in picture.cells {
                #expect((0..<picture.columns).contains(cell.x), "\(word.word)")
                #expect((0..<picture.rows).contains(cell.y), "\(word.word)")
            }
        }
    }

    /// Bottom rows first, so a brick covers the studs of the one below it.
    @Test func laysTheBottomRowsFirst() {
        for word in PictureLibrary.words {
            let rows = word.picture.cells.map(\.y)
            #expect(rows == rows.sorted(by: >), "\(word.word)")
        }
    }

    @Test func readsTheToneOfEveryBrick() {
        let picture = BrickPicture([".b.", "kwg", "?a?"])
        #expect(picture.columns == 3)
        #expect(picture.rows == 3)
        #expect(picture.cells.count == 5)
        #expect(picture.cells.contains(BrickPicture.Cell(x: 1, y: 1, tone: .cream)))
    }
}
