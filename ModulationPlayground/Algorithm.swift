final class Algorithm {

    // MARK: - Internals

    private let operators: [Operator]
    private let outputOperators: [Operator]

    private init(operators: [Operator], outputOperators: [Operator]) {
        self.operators = operators
        self.outputOperators = outputOperators
    }

    // MARK: - Initializers

    static func dx7Algorithm8() -> Self {
        let operators: [Operator] = (0 ..< 6).map { _ in .init() }

        operators[0].inputOperators = [operators[1]]
        operators[1].frequencyRatio = 2.5

        operators[2].inputOperators = [operators[3], operators[4]]
        operators[4].inputOperators = [operators[5]]

        let outputOperators = [operators[0], operators[2]]

        return .init(operators: operators, outputOperators: outputOperators)
    }

    // MARK: - Output

    func requestSamples(at frequency: Double, count: Int) -> [Double] {
//        self.operators[0].requestSamples(
//            at: frequency,
//            count: count,
//            modulationLevel: 0.5
//        )

        let modulatingSamples = self.operators[1].requestSamples(
            at: frequency,
            count: count,
            modulationLevel: 0
        )

        return self.operators[0].requestSamples(
            at: frequency,
            modulations: modulatingSamples,
            modulationLevel: 0.5
            )
    }
}
