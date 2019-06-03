import Foundation

public struct JsonReporter: LogReporter {

    public func report(build: Any, output: ReporterOutput) throws {
        switch build {
        case let steps as BuildStep:
            try report(encodable: steps, output: output)
        case let logEntries as [LogManifestEntry]:
            try report(encodable: logEntries, output: output)
        case let activityLog as IDEActivityLog:
            try report(encodable: activityLog, output: output)
        default:
            throw Error.errorCreatingReport("Type not supported \(type(of: build))")
        }
    }

    private func report<T: Encodable>(encodable: T, output: ReporterOutput) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let json = try encoder.encode(encodable)
        try output.write(report: json)
    }

}
