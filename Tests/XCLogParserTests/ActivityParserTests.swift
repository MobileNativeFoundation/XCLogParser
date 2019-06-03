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

class ActivityParserTests: XCTestCase {

    let parser = ActivityParser()

    lazy var expectedDVTTextDocumentLocation: DVTTextDocumentLocation = {
        return DVTTextDocumentLocation(documentURLString: "file:///project/EntityComponentView.m",
                                       timestamp: 2.2,
                                       startingLineNumber: 6,
                                       startingColumnNumber: 7,
                                       endingLineNumber: 8,
                                       endingColumnNumber: 9,
                                       characterRangeEnd: 10,
                                       characterRangeStart: 0,
                                       locationEncoding: 1)
    }()

    lazy var textDocumentLocationTokens: [Token] = {
        return [Token.string("file:///project/EntityComponentView.m"),
                Token.double(2.2),
                Token.int(6),
                Token.int(7),
                Token.int(8),
                Token.int(9),
                Token.int(10),
                Token.int(0),
                Token.int(1)]
    }()

    lazy var IDEActivityLogTokens: [Token] = {
        let startTokens = [
            Token.int(10),
            Token.className("IDECommandLineBuildLog"),
            Token.classNameRef("IDECommandLineBuildLog")]
        return startTokens + IDEActivityLogSectionTokens
    }()

    lazy var IDEActivityLogMessageTokens: [Token] = {
        let startTokens = [Token.string("Using legacy build system"),
                           Token.null,
                           Token.int(575479851),
                           Token.int(18446744073709551615),
                           Token.int(0),
                           Token.null,
                           Token.int(9),
                           Token.null,
                           Token.className("DVTTextDocumentLocation"),
                           Token.classNameRef("DVTTextDocumentLocation")]
        let endTokens = [Token.string("categoryIdent"),
                         Token.null,
                         Token.string("additionalDescription")]
        return startTokens + textDocumentLocationTokens + endTokens
    }()

    lazy var IDEActivityLogSectionTokens: [Token] = {
        let startTokens = [Token.int(2),
                           Token.string("com.apple.dt.IDE.BuildLogSection"),
                           Token.string("Prepare build"),
                           Token.string("Prepare build"),
                           Token.double(575479851.278759),
                           Token.double(575479851.778325),
                           Token.null,
                           Token.string("note: Using legacy build system"),
                           Token.list(1),
                           Token.className("IDEActivityLogMessage"),
                           Token.classNameRef("IDEActivityLogMessage"),
        ]
        let logMessageTokens = IDEActivityLogMessageTokens
        let endTokens = [Token.int(1),
                         Token.int(0),
                         Token.int(1),
                         Token.string("subtitle"),
                         Token.null,
                         Token.string("commandDetailDesc"),
                         Token.string("501796C4-6BE4-4F80-9F9D-3269617ECC17"),
                         Token.string("localizedResultString"),
                         Token.string("xcbuildSignature"),
                         Token.int(0)
        ]
        return startTokens + logMessageTokens + endTokens
    }()

    func testParseDVTTextDocumentLocation() throws {
        let tokens = textDocumentLocationTokens
        var iterator = tokens.makeIterator()
        let documentLocation = try parser.parseDVTTextDocumentLocation(iterator: &iterator)
        XCTAssertEqual(expectedDVTTextDocumentLocation.documentURLString, documentLocation.documentURLString)
        XCTAssertEqual(expectedDVTTextDocumentLocation.timestamp, documentLocation.timestamp)
    }

    func testParseIDEActivityLogMessage() throws {
        let tokens = IDEActivityLogMessageTokens
        var iterator = tokens.makeIterator()
        let activityLogMessage = try parser.parseIDEActivityLogMessage(iterator: &iterator)
        XCTAssertEqual("Using legacy build system", activityLogMessage.title)
        XCTAssertEqual("", activityLogMessage.shortTitle)
        XCTAssertEqual(575479851.0, activityLogMessage.timeEmitted)
        XCTAssertEqual(0, activityLogMessage.rangeStartInSectionText)
        XCTAssertEqual(18446744073709551615, activityLogMessage.rangeEndInSectionText)
        XCTAssertEqual(0, activityLogMessage.subMessages.count)
        XCTAssertEqual(9, activityLogMessage.severity)
        XCTAssertEqual("", activityLogMessage.type)
        XCTAssertNotNil(activityLogMessage.location)
        guard let documentLocation = activityLogMessage.location as? DVTTextDocumentLocation else {
            XCTFail("documentLocation is nil")
            return
        }
        XCTAssertEqual(expectedDVTTextDocumentLocation.documentURLString, documentLocation.documentURLString)
        XCTAssertEqual(expectedDVTTextDocumentLocation.timestamp, documentLocation.timestamp)
        XCTAssertEqual("categoryIdent", activityLogMessage.categoryIdent)
        XCTAssertEqual(0, activityLogMessage.secondaryLocations.count)
        XCTAssertEqual("additionalDescription", activityLogMessage.additionalDescription)
    }

    func testParseIDEActivityLogSection() throws {
        let tokens = IDEActivityLogSectionTokens
        var iterator = tokens.makeIterator()
        let logSection = try parser.parseIDEActivityLogSection(iterator: &iterator)
        XCTAssertEqual(2, logSection.sectionType)
        XCTAssertEqual("com.apple.dt.IDE.BuildLogSection", logSection.domainType)
        XCTAssertEqual("Prepare build", logSection.title)
        XCTAssertEqual("Prepare build", logSection.signature)
        XCTAssertEqual(575479851.278759, logSection.timeStartedRecording)
        XCTAssertEqual(575479851.778325, logSection.timeStoppedRecording)
        XCTAssertEqual(0, logSection.subSections.count)
        XCTAssertEqual("note: Using legacy build system", logSection.text)
        XCTAssertEqual(1, logSection.messages.count)
        XCTAssertTrue(logSection.wasCancelled)
        XCTAssertFalse(logSection.isQuiet)
        XCTAssertTrue(logSection.wasFetchedFromCache)
        XCTAssertEqual("subtitle", logSection.subtitle)
        XCTAssertEqual("", logSection.location.documentURLString)
        XCTAssertEqual(0, logSection.location.timestamp)
        XCTAssertEqual("commandDetailDesc", logSection.commandDetailDesc)
        XCTAssertEqual("501796C4-6BE4-4F80-9F9D-3269617ECC17", logSection.uniqueIdentifier)
        XCTAssertEqual("localizedResultString", logSection.localizedResultString)
        XCTAssertEqual("xcbuildSignature", logSection.xcbuildSignature)
        XCTAssertEqual(0, logSection.unknown)
    }

    func testParseActivityLog() throws {
        let activityLog = try parser.parseIDEActiviyLogFromTokens(IDEActivityLogTokens)
        XCTAssertEqual(10, activityLog.version)
    }

}
