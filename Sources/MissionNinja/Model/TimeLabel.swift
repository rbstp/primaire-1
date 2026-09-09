import Foundation

enum TimeLabel {
    /// Minutes are what a parent wants to know; seconds would only wobble.
    static func spent(_ seconds: Int) -> String {
        let minutes = max(seconds, 0) / 60
        if minutes < 1 { return "moins d'une minute" }
        if minutes < 60 { return "\(minutes) min" }
        return String(format: "%d h %02d min", minutes / 60, minutes % 60)
    }
}
