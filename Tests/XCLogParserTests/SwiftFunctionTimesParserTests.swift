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

class SwiftFunctionTimesParserTests: XCTestCase {

    let parser = SwiftFunctionTimesParser()

    func testFindRawSwiftFunctionTimes() throws {
        let emptylogSection = getFakeSwiftcSection(text: "text",
                                              commandDescription: "command")

        let swiftTimesLogSection = getFakeSwiftcSection(text:
            "0.05ms\t/Users/user/myapp/MyView.swift:9:9\tgetter textLabel\r",
        commandDescription: "-debug-time-function-bodies")

        let duplicatedSwiftTimeslogSection = getFakeSwiftcSection(text:
            "0.05ms\t/Users/user/myapp/MyView.swift:9:9\tgetter textLabel\r",
        commandDescription: "-debug-time-function-bodies")

        parser.addLogSection(emptylogSection)
        parser.addLogSection(swiftTimesLogSection)
        parser.addLogSection(duplicatedSwiftTimeslogSection)

        let commandsWithFunctionTimes = parser.findRawSwiftFunctionTimes()
        XCTAssertEqual(1, commandsWithFunctionTimes.count)
        guard let command = commandsWithFunctionTimes.first else {
            XCTFail("The command should have Swift function times")
            return
        }
        XCTAssertEqual(swiftTimesLogSection.text, command)
    }

    func testParseFunctionTimes() {
        let text =
        "0.05ms\t/Users/user/myapp/MyView.swift:9:9\tgetter textLabel\r" +
        "4.96ms\t/Users/user/myapp/MyView.swift:11:14\tinitializer init(frame:)\r" +
        "0.04ms\t<invalid loc>\tgetter None\r"
        guard let functionTimes = parser.parseFunctionTimes(from: text) else {
            XCTFail("Function times should have two elements")
            return
        }
        XCTAssertEqual(2, functionTimes.count)
        let getter = functionTimes[0]
        let initializer = functionTimes[1]
        XCTAssertEqual(0.05, getter.durationMS)
        XCTAssertEqual(9, getter.startingLine)
        XCTAssertEqual(9, getter.startingColumn)
        XCTAssertEqual("file:///Users/user/myapp/MyView.swift", getter.file)
        XCTAssertEqual("getter textLabel", getter.signature)
        XCTAssertEqual("initializer init(frame:)", initializer.signature)

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
                                     unknown: 0)
    }

}
