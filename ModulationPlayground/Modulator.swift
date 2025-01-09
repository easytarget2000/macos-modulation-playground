protocol Modulator {
    func setUp() throws
    func tearDown() throws
    func playSound() async throws
}

final class PreviewModulator: Modulator {
    func setUp() throws {}
    func tearDown() throws {}
    func playSound() async throws {}
}
