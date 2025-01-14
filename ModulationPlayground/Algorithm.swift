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
        let operators: [Operator] = .init(repeating: .init(), count: 6)

        operators[0].inputOperators = [operators[1]]
        operators[2].inputOperators = [operators[3], operators[4]]
        operators[4].inputOperators = [operators[5]]

        let outputOperators = [operators[0], operators[2]]

        return .init(operators: operators, outputOperators: outputOperators)
    }

    // MARK: - Output

    func requestSamples(at frequency: Double, count: Int) -> [Double] {
        return self.operators[0].requestSamples(at: frequency, count: count)
    }
}
