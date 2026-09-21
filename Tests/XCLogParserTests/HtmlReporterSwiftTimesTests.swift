import XCTest
@testable import XCLogParser

class HtmlReporterSwiftTimesTests: XCTestCase {

    /// From Xcode 14 on a SwiftCompile step is a batch and the per file times are on its substeps.
    func testFunctionTimesOfBatchSubstepsReachTheIndexPage() throws {
        var file = makeFakeBuildStep(title: "Compile MyView.swift", type: .detail,
                                     detailStepType: .swiftCompilation,
                                     startTimestamp: 0, fetchedFromCache: false)
        file.swiftFunctionTimes = [SwiftFunctionTime(file: "file:///myapp/MyView.swift", durationMS: 4.96,
                                                     startingLine: 11, startingColumn: 14,
                                                     signature: "initializer init(frame:)", occurrences: 1)]
        let batch = makeFakeBuildStep(title: "Compiling MyView.swift, Other.swift", type: .detail,
                                      detailStepType: .swiftCompilation,
                                      startTimestamp: 0, fetchedFromCache: false)
            .with(subSteps: [file])
        let target = makeFakeBuildStep(title: "Build target Foo", type: .target, detailStepType: .none,
                                       startTimestamp: 0, fetchedFromCache: false)
            .with(subSteps: [batch])
        let build = makeFakeBuildStep(title: "Build", type: .main, detailStepType: .none,
                                      startTimestamp: 0, fetchedFromCache: false)
            .with(subSteps: [target])
        let dir = try TestUtils.createRandomTestDir()

        try HtmlReporter().report(build: build, output: FileOutput(path: dir.path), rootOutput: dir.path)

        let topFiles = try String(contentsOf: dir.appendingPathComponent("js/top_files.js"))
        let topFunctions = topFiles.components(separatedBy: "const topSwiftFunctions = ")[1]
            .components(separatedBy: "const ")[0]
        XCTAssertTrue(topFunctions.contains("initializer init(frame:)"))
    }
}
