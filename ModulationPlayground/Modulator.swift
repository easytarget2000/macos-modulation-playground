protocol Modulator {
    func setUp() throws
    func tearDown() throws
    func play(frequency: Double) async throws
}

final class PreviewModulator: Modulator {
    func setUp() throws {}
    func tearDown() throws {}
    func play(frequency: Double) async throws {}
}
