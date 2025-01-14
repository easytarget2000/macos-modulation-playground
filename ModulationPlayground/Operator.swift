import _math

final class Operator {

    // MARK: - Configuration

    var sampleRate: Double = 44100.0
    var numberOfChannels: Int = 2
    var amplitude: Double = 1

    // MARK: - Output

    func cleanSamples(at frequency: Double, count: Int) -> [Double] {
        return (0 ..< count).map { frameIndex in
            let time: Double
            = .init(frameIndex) / self.sampleRate / .init(self.numberOfChannels)

            return .init(amplitude * sin(2.0 * .pi * frequency * time))
        }
    }

    func modulateSamples( _ a: [Double], _ b: [Double]) -> [Double] {
        zip(a, b).map(*)
    }

}
