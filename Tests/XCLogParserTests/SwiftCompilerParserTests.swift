// Copyright (c) 2019 Spotify AB.
//
// Licensed to the Apache Software Foundation (ASF) under one
// or more contributor license agreements.  See the NOTICE file
// distributed with this work for additional information
// regarding copyright ownership.  The ASF licenses this file
// to you under the Apache License, Version 2.0 (the
// "License"); you may not use this file except in compliance
// with the License.  You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import XCTest
@testable import XCLogParser

class SwiftCompilerParserTests: XCTestCase {

    let parser = SwiftCompilerParser()

    func testParseSwiftFunctionTimes() throws {
        try runParseSwiftFunctionTimesTest(rawFile: "myapp/MyView", escapedFile: "myapp/MyView")
        try runParseSwiftFunctionTimesTest(rawFile: "my app/MyView", escapedFile: "my%20app/MyView")
    }

    private func runParseSwiftFunctionTimesTest(rawFile: String,
                                                escapedFile: String,
                                                file: StaticString = #file,
                                                line: UInt = #line) throws {
        let emptylogSection = getFakeSwiftcSection(text: "text",
                                              commandDescription: "command")
        let text =
        "0.05ms\t/Users/user/\(rawFile).swift:9:9\tgetter textLabel\r" +
        "4.96ms\t/Users/user/\(rawFile).swift:11:14\tinitializer init(frame:)\r" +
        "0.04ms\t<invalid loc>\tgetter None\r"
        let swiftTimesLogSection = getFakeSwiftcSection(text:
            text, commandDescription: "-debug-time-function-bodies")

        let duplicatedSwiftTimeslogSection = getFakeSwiftcSection(text:
            text, commandDescription: "-debug-time-function-bodies")
        let expectedFile = "file:///Users/user/\(escapedFile).swift"
        parser.addLogSection(emptylogSection)
        parser.addLogSection(swiftTimesLogSection)
        parser.addLogSection(duplicatedSwiftTimeslogSection)

        parser.parse()
        guard let functionTimes = parser.findFunctionTimesForFilePath(expectedFile) else {
            XCTFail("The command should have swiftc function times", file: file, line: line)
            return
        }
        XCTAssertEqual(2, functionTimes.count, file: file, line: line)
        let getter = functionTimes[0]
        let initializer = functionTimes[1]
        XCTAssertEqual(0.05, getter.durationMS, file: file, line: line)
        XCTAssertEqual(9, getter.startingLine, file: file, line: line)
        XCTAssertEqual(9, getter.startingColumn, file: file, line: line)
        XCTAssertEqual(2, getter.occurrences, file: file, line: line)
        XCTAssertEqual(expectedFile.removingPercentEncoding, getter.file, file: file, line: line)
        XCTAssertEqual("getter textLabel", getter.signature, file: file, line: line)
        XCTAssertEqual("initializer init(frame:)", initializer.signature, file: file, line: line)
        XCTAssertEqual(2, initializer.occurrences, file: file, line: line)
    }

    func testParseSwiftTypeCheckTimes() throws {
        try runTestParseSwiftTypeCheckTimes(rawFile: "project/CreatorHeaderViewModel",
                                            escapedFile: "project/CreatorHeaderViewModel")
        try runTestParseSwiftTypeCheckTimes(rawFile: "my project/CreatorHeaderViewModel",
                                            escapedFile: "my%20project/CreatorHeaderViewModel")
    }

    private func runTestParseSwiftTypeCheckTimes(rawFile: String,
                                                 escapedFile: String,
                                                 file: StaticString = #file,
                                                 line: UInt = #line) throws {
        let emptylogSection = getFakeSwiftcSection(text: "text",
                                              commandDescription: "command")

        let swiftTimesLogSection = getFakeSwiftcSection(text:
            "0.72ms\t/Users/\(rawFile).swift:19:15\r",
        commandDescription: "-debug-time-expression-type-checking")

        let duplicatedSwiftTimeslogSection = getFakeSwiftcSection(text:
            "0.72ms\t/Users/\(rawFile).swift:19:15\r",
        commandDescription: "-debug-time-expression-type-checking")
        let expectedFile = "file:///Users/\(escapedFile).swift"
        parser.addLogSection(emptylogSection)
        parser.addLogSection(swiftTimesLogSection)
        parser.addLogSection(duplicatedSwiftTimeslogSection)

        parser.parse()

        guard let typeChecks = parser.findTypeChecksForFilePath(expectedFile)
            else {
            XCTFail("The command should have swiftc type check times")
            return
        }
        XCTAssertEqual(1, typeChecks.count)
        XCTAssertEqual(19, typeChecks[0].startingLine)
        XCTAssertEqual(15, typeChecks[0].startingColumn)
        XCTAssertEqual(0.72, typeChecks[0].durationMS)
        XCTAssertEqual(expectedFile.removingPercentEncoding, typeChecks[0].file)
        XCTAssertEqual(2, typeChecks[0].occurrences)
    }

    private func getFakeSwiftcSection(text: String, commandDescription: String) -> IDEActivityLogSection {
        return IDEActivityLogSection(sectionType: 1,
                                     domainType: "",
                                     title: "Swiftc Compilation",
                                     signature: "",
                                     timeStartedRecording: 0.0,
                                     timeStoppedRecording: 0.0,
                                     subSections: [],
                                     text: text,
                                     messages: [],
                                     wasCancelled: false,
                                     isQuiet: false,
                                     wasFetchedFromCache: false,
                                     subtitle: "",
                                     location: DVTDocumentLocation(documentURLString: "", timestamp: 0.0),
                                     commandDetailDesc: commandDescription,
                                     uniqueIdentifier: "",
                                     localizedResultString: "",
                                     xcbuildSignature: "",
                                     attachments: [],
                                     unknown: 0)
    }

}
