import Testing

@testable import MissionNinja

@Suite struct TimeLabelTests {
    @Test func speaksInMinutesAndHours() {
        #expect(TimeLabel.spent(0) == "moins d'une minute")
        #expect(TimeLabel.spent(59) == "moins d'une minute")
        #expect(TimeLabel.spent(60) == "1 min")
        #expect(TimeLabel.spent(12 * 60 + 30) == "12 min")
        #expect(TimeLabel.spent(3600) == "1 h 00 min")
        #expect(TimeLabel.spent(2 * 3600 + 5 * 60) == "2 h 05 min")
        #expect(TimeLabel.spent(-10) == "moins d'une minute")
    }
}
