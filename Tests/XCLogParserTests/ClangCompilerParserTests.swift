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

class ClangCompilerParserTests: XCTestCase {
    let parser = ClangCompilerParser()

    func testParseTimeTraceFile() throws {
        let text = """
        Time trace json-file dumped to /Users/project/ObjectsDirectory/UIViewController+Utility.json\r\
        Use chrome://tracing or Speedscope App (https://www.speedscope.app) for flamegraph visualization\r
        """
        let clangCompileLogSection = getFakeClangSection(text: text, commandDescription: "-ftime-trace")

        let expectedFile = "/Users/project/ObjectsDirectory/UIViewController+Utility.json"
        let timeTraceFile = parser.parseTimeTraceFile(clangCompileLogSection)
        XCTAssertEqual(expectedFile, timeTraceFile)
    }

    private func getFakeClangSection(text: String, commandDescription: String) -> IDEActivityLogSection {
        return IDEActivityLogSection(sectionType: 1,
                                     domainType: "",
                                     title: "Clang Compilation",
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
