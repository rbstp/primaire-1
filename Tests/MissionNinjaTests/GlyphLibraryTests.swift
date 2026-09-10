import Testing

@testable import MissionNinja

@Suite struct GlyphLibraryTests {
    private let shipped: [Character] = Array("aeéèiouAEIOU0123456789")

    @Test func coversEverythingTheWeekAsksToTrace() throws {
        let week = try #require(WeekCatalog.bundled().week(id: "2026-09-07"))
        for character in week.tracing.characters {
            #expect(GlyphLibrary.glyph(for: character) != nil, "\(character) n'a pas de tracé")
        }
    }

    @Test func hasAGlyphForEveryVowelAndDigit() {
        for character in shipped {
            #expect(GlyphLibrary.glyph(for: character) != nil, "\(character) manque")
        }
    }

    @Test func hasNoGlyphForSomethingItDoesNotKnow() {
        #expect(GlyphLibrary.glyph(for: "ß") == nil)
    }

    @Test func everyStrokeHasRealLength() {
        for character in shipped {
            guard let glyph = GlyphLibrary.glyph(for: character) else { continue }
            #expect(!glyph.strokes.isEmpty)
            for (index, stroke) in glyph.strokes.enumerated() {
                #expect(stroke.points.count >= 2, "\(character) trait \(index) est vide")
                #expect(stroke.length > 0, "\(character) trait \(index) est de longueur nulle")
            }
        }
    }

    /// Nothing may sit outside the square, or part of a letter would be drawn
    /// off the canvas.
    @Test func everyPointStaysInsideTheSquare() {
        for character in shipped {
            guard let glyph = GlyphLibrary.glyph(for: character) else { continue }
            for stroke in glyph.strokes {
                for point in stroke.points {
                    #expect((0...1).contains(point.x), "\(character) sort en x: \(point.x)")
                    #expect((0...1).contains(point.y), "\(character) sort en y: \(point.y)")
                }
            }
        }
    }

    @Test func samplesAreEvenlySpacedAfterFlattening() {
        for character in shipped {
            guard let glyph = GlyphLibrary.glyph(for: character) else { continue }
            for stroke in glyph.strokes where stroke.length > Polyline.sampleStep * 3 {
                let gaps = zip(stroke.points, stroke.points.dropFirst()).map { $0.distance(to: $1) }
                #expect(gaps.dropLast().allSatisfy { $0 < Polyline.sampleStep * 1.2 }, "\(character)")
            }
        }
    }

    /// The dot on an i is the one stroke short enough to be a tap.
    @Test func onlyTheDotOnAnIIsATap() {
        for character in shipped {
            guard let glyph = GlyphLibrary.glyph(for: character) else { continue }
            for (index, stroke) in glyph.strokes.enumerated() {
                let validator = TraceValidator(stroke: stroke, canvasSide: 360)
                if character == "i" && index == 1 {
                    #expect(validator.isDot)
                } else {
                    #expect(!validator.isDot, "\(character) trait \(index) est trop court")
                }
            }
        }
    }

    @Test func strokeCountsFollowHowTheyAreTaught() {
        let expected: [Character: Int] = [
            "a": 2, "e": 1, "é": 2, "è": 2, "i": 2, "o": 1, "u": 2,
            "A": 3, "E": 4, "I": 1, "O": 1, "U": 1,
            "0": 1, "1": 1, "2": 1, "3": 1, "4": 2,
            "5": 2, "6": 1, "7": 1, "8": 1, "9": 1,
        ]
        for (character, count) in expected {
            #expect(GlyphLibrary.glyph(for: character)?.strokes.count == count, "\(character)")
        }
    }

    /// The o and the 0 must come back to where they started, or the loop is
    /// not closed.
    @Test func closedShapesActuallyClose() {
        for character in Array("oO08") {
            guard let glyph = GlyphLibrary.glyph(for: character), let stroke = glyph.strokes.first else {
                Issue.record("\(character) manque")
                continue
            }
            #expect(stroke.first.distance(to: stroke.last) < 0.06, "\(character) ne se referme pas")
        }
    }
}
