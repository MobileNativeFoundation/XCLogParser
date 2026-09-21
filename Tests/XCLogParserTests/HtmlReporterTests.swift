import XCTest
@testable import XCLogParser

class HtmlReporterTests: XCTestCase {

    func testIndexFileCountsComeFromAllTargets() throws {
        let compile = { (title: String, type: DetailStepType) -> BuildStep in
            makeFakeBuildStep(title: title, type: .detail, detailStepType: type,
                              startTimestamp: 0, fetchedFromCache: false)
        }
        let foo = makeFakeBuildStep(title: "Build target Foo", type: .target, detailStepType: .none,
                                    startTimestamp: 0, fetchedFromCache: false)
            .with(subSteps: [compile("Compile a.swift", .swiftCompilation),
                             compile("Compile b.swift", .swiftCompilation),
                             compile("Compile c.c", .cCompilation)])
        let bar = makeFakeBuildStep(title: "Build target Bar", type: .target, detailStepType: .none,
                                    startTimestamp: 0, fetchedFromCache: false)
            .with(subSteps: [compile("Compile d.swift", .swiftCompilation)])
        let build = makeFakeBuildStep(title: "Build", type: .main, detailStepType: .none,
                                      startTimestamp: 0, fetchedFromCache: false)
            .with(subSteps: [foo, bar])
        let dir = try TestUtils.createRandomTestDir()

        try HtmlReporter().report(build: build, output: FileOutput(path: dir.path), rootOutput: dir.path)

        let topFiles = try String(contentsOf: dir.appendingPathComponent("js/top_files.js"))
        XCTAssertTrue(topFiles.contains("const swiftFilesCount = 3;"))
        XCTAssertTrue(topFiles.contains("const cFilesCount = 1;"))
    }
}
