import Foundation

public protocol LogReporter {

    func report(build: Any, output: ReporterOutput) throws

}
