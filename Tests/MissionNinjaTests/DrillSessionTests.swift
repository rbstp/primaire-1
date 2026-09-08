import Testing

@testable import MissionNinja

private func drill(_ id: Int, answer: Character = "a", decoy: Character = "e") -> Drill {
    Drill(
        id: id,
        kind: .hearLetter,
        prompt: .spokenLetter(answer),
        choices: [.letter(answer), .letter(decoy)],
        answerIndex: 0
    )
}

@Suite struct DrillSessionTests {
    @Test func walksThroughEveryDrill() {
        var session = DrillSession(drills: [drill(0), drill(1), drill(2)])
        #expect(session.current?.id == 0)
        #expect(session.advance == 0)
        for _ in 0..<3 { _ = session.answer(.letter("a")) }
        #expect(session.isFinished)
        #expect(session.stars == 3)
        #expect(session.advance == 1)
    }

    @Test func onlyAFirstTryEarnsAStar() {
        var session = DrillSession(drills: [drill(0)])
        #expect(session.answer(.letter("e"))?.correct == false)
        #expect(session.answer(.letter("a"))?.correct == true)
        #expect(session.stars == 0)
        #expect(session.isFinished)
    }

    @Test func aMissedDrillComesBackLater() {
        var session = DrillSession(drills: [drill(0), drill(1)])
        _ = session.answer(.letter("e"))
        #expect(session.current?.id == 1)
        _ = session.answer(.letter("a"))
        #expect(session.current?.id == 0)
        #expect(!session.isFinished)
    }

    @Test func aMissTellsTheViewWhatToHighlight() {
        var session = DrillSession(drills: [drill(0)])
        let answer = session.answer(.letter("e"))
        #expect(answer?.expected == .letter("a"))
        #expect(answer?.firstTry == true)
    }

    @Test func aRunNeverStalls() {
        var session = DrillSession(drills: [drill(0)])
        for _ in 0..<DrillSession.maxAttempts { _ = session.answer(.letter("e")) }
        #expect(session.isFinished)
        #expect(session.stars == 0)
        #expect(session.advance == 1)
    }

    @Test func countsAttemptsOnTheDrillInFront() {
        var session = DrillSession(drills: [drill(0)])
        #expect(session.attemptsOnCurrent == 0)
        _ = session.answer(.letter("e"))
        #expect(session.attemptsOnCurrent == 1)
    }

    @Test func reportsOneEventPerAnswer() {
        var session = DrillSession(drills: [drill(0)])
        let answer = session.answer(.letter("a"))
        #expect(answer?.events == [.answered(character: "a", drill: .hearLetter, firstTry: true, correct: true)])
    }

    @Test func doesNothingOnceFinished() {
        var session = DrillSession(drills: [drill(0)])
        _ = session.answer(.letter("a"))
        #expect(session.answer(.letter("a")) == nil)
    }

    @Test func anEmptySessionIsAlreadyDone() {
        let session = DrillSession(drills: [])
        #expect(session.isFinished)
        #expect(session.advance == 1)
    }
}
