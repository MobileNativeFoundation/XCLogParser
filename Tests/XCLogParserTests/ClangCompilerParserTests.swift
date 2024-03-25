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

    func testParseLinkerStatistics() throws {
        let text = """
        ld total time:  561.6 milliseconds ( 100.0%)\r\
        option parsing time:   51.7 milliseconds (   9.2%)\r\
        object file processing:    0.0 milliseconds (   0.0%)\r\
        resolve symbols:  336.1 milliseconds (  59.8%)\r\
        build atom list:    0.0 milliseconds (   0.0%)\r\
        passess:   97.3 milliseconds (  17.3%)\r\
        write output:   76.3 milliseconds (  13.5%)\r\
        pageins=7464, pageouts=0, faults=31012\r\
        processed   5 object files,  totaling         140,932 bytes\r\
        processed  42 archive files, totaling      24,362,016 bytes\r\
        processed  87 dylib files\r\
        wrote output file            totaling       8,758,732 bytes\r
        """
        let clangCompileLogSection = getFakeClangSection(text: text, commandDescription: "-print_statistics")
        let statistics = parser.parseLinkerStatistics(clangCompileLogSection)!
        XCTAssertEqual(statistics.totalMS, 561.6, accuracy: 0.0001)
        XCTAssertEqual(statistics.optionParsingMS, 51.7, accuracy: 0.0001)
        XCTAssertEqual(statistics.optionParsingPercent, 9.2, accuracy: 0.0001)
        XCTAssertEqual(statistics.objectFileProcessingMS, 0.0, accuracy: 0.0001)
        XCTAssertEqual(statistics.objectFileProcessingPercent, 0.0, accuracy: 0.0001)
        XCTAssertEqual(statistics.resolveSymbolsMS, 336.1, accuracy: 0.0001)
        XCTAssertEqual(statistics.resolveSymbolsPercent, 59.8, accuracy: 0.0001)
        XCTAssertEqual(statistics.buildAtomListMS, 0.0, accuracy: 0.0001)
        XCTAssertEqual(statistics.buildAtomListPercent, 0.0, accuracy: 0.0001)
        XCTAssertEqual(statistics.runPassesMS, 97.3, accuracy: 0.0001)
        XCTAssertEqual(statistics.runPassesPercent, 17.3, accuracy: 0.0001)
        XCTAssertEqual(statistics.writeOutputMS, 76.3, accuracy: 0.0001)
        XCTAssertEqual(statistics.writeOutputPercent, 13.5, accuracy: 0.0001)
        XCTAssertEqual(statistics.pageins, 7464)
        XCTAssertEqual(statistics.pageouts, 0)
        XCTAssertEqual(statistics.faults, 31012)
        XCTAssertEqual(statistics.objectFiles, 5)
        XCTAssertEqual(statistics.objectFilesBytes, 140932)
        XCTAssertEqual(statistics.archiveFiles, 42)
        XCTAssertEqual(statistics.archiveFilesBytes, 24362016)
        XCTAssertEqual(statistics.dylibFiles, 87)
        XCTAssertEqual(statistics.wroteOutputFileBytes, 8758732)
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
                                     attachments: [],
                                     unknown: 0)
    }
}
