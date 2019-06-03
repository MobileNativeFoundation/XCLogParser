import Foundation

public struct FlatJsonReporter: LogReporter {

    public func report(build: Any, output: ReporterOutput) throws {
        guard let steps = build as? BuildStep else {
            throw Error.errorCreatingReport("Type not supported \(type(of: build))")
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let json = try encoder.encode(steps.flatten())
        try output.write(report: json)
    }

}
