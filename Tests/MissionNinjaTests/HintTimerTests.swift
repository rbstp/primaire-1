import Foundation
import Testing

@testable import MissionNinja

@Suite struct HintTimerTests {
    /// The first hint of a screen costs nothing: he may be genuinely stuck.
    @Test func opensReady() {
        let timer = HintTimer()
        #expect(timer.isReady(at: Date(timeIntervalSince1970: 0)))
        #expect(timer.remaining(at: Date(timeIntervalSince1970: 0)) == 0)
    }

    @Test func closesForAMinuteOnceSpent() {
        let start = Date(timeIntervalSince1970: 1_000)
        var timer = HintTimer()
        timer.spend(at: start)
        #expect(!timer.isReady(at: start))
        #expect(timer.remaining(at: start) == 60)
        #expect(!timer.isReady(at: start.addingTimeInterval(59)))
        #expect(timer.remaining(at: start.addingTimeInterval(59)) == 1)
        #expect(timer.isReady(at: start.addingTimeInterval(60)))
        #expect(timer.remaining(at: start.addingTimeInterval(60)) == 0)
    }

    /// The counter never runs backwards past zero, or the corner brick would
    /// come back long after the hint did.
    @Test func neverCountsBelowZero() {
        let start = Date(timeIntervalSince1970: 1_000)
        var timer = HintTimer()
        timer.spend(at: start)
        #expect(timer.remaining(at: start.addingTimeInterval(600)) == 0)
    }
}
