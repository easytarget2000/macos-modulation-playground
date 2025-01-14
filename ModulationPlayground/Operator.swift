import _math

final class Operator {

    // MARK: - Configuration

    var sampleRate: Double = 44100
    var numberOfChannels: Int = 2
    var amplitude: Double = 1

    var inputOperators: [Operator] = []

    // MARK: - Output

    func requestSamples(at frequency: Double, count: Int) -> [Double] {
        let ownSamples = cleanSamples(at: frequency, count: count)

        return ownSamples
//        return inputOperators.reduce(ownSamples) { samples, op in
//            modulateSamples(
//                samples,
//                op.requestSamples(at: frequency, count: count)
//            )
//        }
    }

    private func cleanSamples(at frequency: Double, count: Int) -> [Double] {
        return (0 ..< count).map { frameIndex in
            let time: Double
            = .init(frameIndex) / self.sampleRate / .init(self.numberOfChannels)

            return .init(amplitude * sin(2.0 * .pi * frequency * time))
        }
    }

    private func modulateSamples( _ a: [Double], _ b: [Double]) -> [Double] {
        zip(a, b).map(*)
    }

}
