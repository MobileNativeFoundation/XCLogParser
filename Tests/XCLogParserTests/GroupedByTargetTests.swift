import XCTest
@testable import XCLogParser

class GroupedByTargetTests: XCTestCase {

    func testUntaggedSectionsAreGroupedUnderOneTarget() {
        let main = makeSection(title: "Build", subSections: [
            makeSection(title: "Create build description", start: 0),
            makeSection(title: "Compiling Clang module Foundation", start: 1),
            makeSection(title: "CompileC a.o", command: "CompileC a.o (in target 'Foo' from project 'P')", start: 2),
            makeSection(title: "Compiling Clang module UIKit", start: 3),
            makeSection(title: "CompileC b.o", command: "CompileC b.o (in target 'Bar' from project 'P')", start: 4),
        ])

        let grouped = main.groupedByTarget()

        XCTAssertEqual(["Build system", "Build target Foo", "Build target Bar"],
                       grouped.subSections.map { $0.title })
        let buildSystem = grouped.subSections[0]
        XCTAssertEqual(["Create build description",
                        "Compiling Clang module Foundation",
                        "Compiling Clang module UIKit"],
                       buildSystem.subSections.map { $0.title })
    }

    func testTargetsKeepTheirOrder() {
        let main = makeSection(title: "Build", subSections: [
            makeSection(title: "Ld Bar", command: "Ld Bar (in target 'Bar' from project 'P')", start: 2),
            makeSection(title: "CompileC a.o", command: "CompileC a.o (in target 'Foo' from project 'P')", start: 1),
        ])

        XCTAssertEqual(["Build target Foo", "Build target Bar"],
                       main.groupedByTarget().subSections.map { $0.title })
    }

    private func makeSection(title: String,
                             command: String = "",
                             start: Double = 0,
                             subSections: [IDEActivityLogSection] = []) -> IDEActivityLogSection {
        return IDEActivityLogSection(sectionType: 1,
                                     domainType: "",
                                     title: title,
                                     signature: "",
                                     timeStartedRecording: start,
                                     timeStoppedRecording: start,
                                     subSections: subSections,
                                     text: "",
                                     messages: [],
                                     wasCancelled: false,
                                     isQuiet: false,
                                     wasFetchedFromCache: false,
                                     subtitle: "",
                                     location: DVTDocumentLocation(documentURLString: "", timestamp: 0.0),
                                     commandDetailDesc: command,
                                     uniqueIdentifier: "",
                                     localizedResultString: "",
                                     xcbuildSignature: "",
                                     attachments: [],
                                     unknown: 0)
    }
}
