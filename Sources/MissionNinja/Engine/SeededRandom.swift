import Dispatch

struct SeededRandom: RandomNumberGenerator, Sendable {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    mutating func nextUnit() -> Double {
        Double(next() >> 11) / Double(1 << 53)
    }

    mutating func nextDouble(in range: ClosedRange<Double>) -> Double {
        range.lowerBound + nextUnit() * (range.upperBound - range.lowerBound)
    }
}

extension SeededRandom {
    /// Fisher and Yates, driven by this generator so a seed always gives the
    /// same order.
    mutating func shuffled<T>(_ items: [T]) -> [T] {
        var out = items
        guard out.count > 1 else { return out }
        for index in stride(from: out.count - 1, to: 0, by: -1) {
            let swap = min(Int(nextUnit() * Double(index + 1)), index)
            out.swapAt(index, swap)
        }
        return out
    }
}

extension SeededRandom {
    /// A fresh seed each call, unlike a seed taken from the clock in seconds,
    /// which repeats when a screen is reopened quickly.
    static func fresh() -> SeededRandom {
        SeededRandom(seed: DispatchTime.now().uptimeNanoseconds)
    }
}
