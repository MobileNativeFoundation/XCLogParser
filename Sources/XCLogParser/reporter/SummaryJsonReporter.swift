import Foundation

public struct SummaryJsonReporter: LogReporter {

    public func report(build: Any, output: ReporterOutput) throws {
        guard let steps = build as? BuildStep else {
            throw Error.errorCreatingReport("Type not supported \(type(of: build))")
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let json = try encoder.encode(steps.summarize())
        try output.write(report: json)
    }

}
