import _math

final class Operator {

    // MARK: - Configuration

    var sampleRate: Double = 44100
    var amplitude: Double = 1
    var frequencyRatio: Double = 1

    var inputOperators: [Operator] = []

    // MARK: - Output

    func requestSamples(
        at frequency: Double,
        count: Int,
        modulationLevel: Double
    ) -> [Double] {
        let ownSamples = cleanSamples(at: frequency, count: count)

        return ownSamples
    }

    func requestSamples(
        at frequency: Double,
        modulations: [Double],
        modulationLevel: Double
    ) -> [Double] {
        return modulations.enumerated().map { index, modulation in
            let time: Double
            = .init(index) / self.sampleRate
            let phase = 2 * .pi * frequency * frequencyRatio * time

            return .init(
                amplitude * sin(phase + (modulation * modulationLevel))
            )
        }
    }

    private func cleanSamples(at frequency: Double, count: Int) -> [Double] {
        requestSamples(
            at: frequency,
            modulations: .init(repeating: 0, count: count),
            modulationLevel: 1
        )
    }
}
