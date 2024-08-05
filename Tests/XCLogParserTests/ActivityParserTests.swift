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

// swiftlint:disable type_body_length
// swiftlint:disable file_length
class ActivityParserTests: XCTestCase {

    let parser = ActivityParser()

    let expectedDVTTextDocumentLocation: DVTTextDocumentLocation = DVTTextDocumentLocation(
        documentURLString: "file:///project/EntityComponentView.m",
        timestamp: 2.2,
        startingLineNumber: 6,
        startingColumnNumber: 7,
        endingLineNumber: 8,
        endingColumnNumber: 9,
        characterRangeEnd: 10,
        characterRangeStart: 0,
        locationEncoding: 1)

    let textDocumentLocationTokens: [Token] = {
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
                         Token.list(1),
                         Token.classNameRef("IDEFoundation.IDEActivityLogSectionAttachment"),
                         Token.string("com.apple.dt.ActivityLogSectionAttachment.TaskMetrics"),
                         Token.int(1),
                         Token.int(0),
                         Token.json("{\"wcStartTime\":1,\"maxRSS\":1,\"utime\":1,\"wcDuration\":1,\"stime\":1}"),
                         Token.int(0)
        ]
        return startTokens + logMessageTokens + endTokens
    }()

    let IDEConsoleItemTokens: [Token] = [
        Token.className("IDEConsoleItem"),
        Token.classNameRef("IDEConsoleItem"),
        Token.int(2),
        Token.string("Internal launch error: process launch failed: Security"),
        Token.int(10),
        Token.double(582169311.441566)]

    lazy var DBGConsoleLogTokens: [Token] = {
        let startTokens = [Token.int(0),
                           Token.string("Xcode.IDEActivityLogDomainType.DebugLog"),
                           Token.string("Debug iOSDemo"),
                           Token.string("Debug iOSDemo"),
                           Token.double(582169296.793495),
                           Token.double(582169312.039075),
                           Token.null,
                           Token.null,
                           Token.null,
                           Token.int(0),
                           Token.int(0),
                           Token.int(0),
                           Token.null,
                           Token.null,
                           Token.null,
                           Token.string("79D9C1DE-F736-4743-A7C6-B08ED42A1DFE"),
                           Token.null,
                           Token.null,
                           Token.list(1),
                           Token.classNameRef("IDEFoundation.IDEActivityLogSectionAttachment"),
                           Token.string("com.apple.dt.ActivityLogSectionAttachment.TaskMetrics"),
                           Token.int(1),
                           Token.int(0),
                           Token.json("{\"wcStartTime\":1,\"maxRSS\":1,\"utime\":1,\"wcDuration\":1,\"stime\":1}"),
                           Token.list(1),
        ]
        return startTokens + IDEConsoleItemTokens
    }()

    let IDEActivityLogAnalyzerResultMessageTokens: [Token] = [
        Token.string("Localized string macro should include a non-empty comment for translators"),
        Token.null,
        Token.int(590842212),
        Token.int(18446744073709551615),
        Token.int(0),
        Token.list(1),
        Token.classNameRef("IDEActivityLogAnalyzerEventStepMessage"),
        Token.string("Localized string macro should include a non-empty comment for translators"),
        Token.null,
        Token.int(590842212),
        Token.int(18446744073709551615),
        Token.int(0),
        Token.null,
        Token.int(1),
        Token.string("com.apple.dt.IDE.analyzer.result"),
        Token.classNameRef("DVTTextDocumentLocation"),
        Token.string("file:///MyClass.m"),
        Token.double(0.0),
        Token.int(196),
        Token.int(11),
        Token.int(196),
        Token.int(11),
        Token.int(18446744073709551615),
        Token.int(0),
        Token.int(0),
        Token.null,
        Token.list(1),
        Token.classNameRef("DVTTextDocumentLocation"),
        Token.string("file:///MyClass.m"),
        Token.double(0.0),
        Token.int(196),
        Token.int(11),
        Token.int(196),
        Token.int(11),
        Token.int(18446744073709551615),
        Token.int(0),
        Token.int(0),
        Token.null,
        Token.int(18446744073709551615),
        Token.string("Localized string macro should include a non-empty comment for translators"),
        Token.int(0),
        Token.int(1),
        Token.string("com.apple.dt.IDE.analyzer.result"),
        Token.classNameRef("DVTTextDocumentLocation"),
        Token.string("file:///MyClass.m"),
        Token.double(0.0),
        Token.int(196),
        Token.int(11),
        Token.int(196),
        Token.int(11),
        Token.int(18446744073709551615),
        Token.int(0),
        Token.int(0),
        Token.string("Localizability Issue (Apple)"),
        Token.list(1),
        Token.classNameRef("DVTTextDocumentLocation"),
        Token.string("file:///MyClass.m"),
        Token.double(0.0),
        Token.int(196),
        Token.int(11),
        Token.int(196),
        Token.int(11),
        Token.int(18446744073709551615),
        Token.int(0),
        Token.int(0),
        Token.null,
        Token.string("Context Missing"),
        Token.int(18446744073709551615),
        Token.int(0),
        Token.int(0),
        Token.int(0),
        Token.null]

    let IBDocumentMemberLocationTokens: [Token] = [
        Token.className("IBDocumentMemberLocation"),
        Token.classNameRef("IBDocumentMemberLocation"),
        Token.string("file:///projects/WarningTest/WarningTest/Base.lproj/Main.storyboard"),
        Token.double(0.0),
        Token.className("IBMemberID"),
        Token.classNameRef("IBMemberID"),
        Token.string("RgO-vd-uiQ"),
        Token.null
    ]

    let xcode3ProjectDocumentLocationTokens: [Token] = {
        return [
            Token.className("Xcode3ProjectDocumentLocation"),
            Token.classNameRef("Xcode3ProjectDocumentLocation"),
            Token.string("file:///project/Project.xcodeproj"),
            Token.double(2.2)]
    }()

    lazy var IDEActivityLogActionMessageTokens: [Token] = {
        let startTokens = [Token.string("The identity of “XYZ.xcframework” is not recorded in your project."),
                           Token.null,
                           Token.int(9),
                           Token.int(18446744073709551615),
                           Token.int(575479851),
                           Token.null,
                           Token.int(0),
                           Token.null,
                           Token.classNameRef("DVTTextDocumentLocation")]
       let endTokens = [Token.string("categoryIdent"),
                        Token.null,
                        Token.string("additionalDescription")]
        return startTokens + textDocumentLocationTokens + endTokens + [Token.string("action")]
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

    func testParseDBGConsoleLog() throws {
        let tokens = DBGConsoleLogTokens
        var iterator = tokens.makeIterator()
        let DBGConsoleLog = try parser.parseDBGConsoleLog(iterator: &iterator)
        XCTAssertEqual(1, DBGConsoleLog.logConsoleItems.count)
        guard let consoleItem = DBGConsoleLog.logConsoleItems.first else {
            XCTFail("logConsoleItems is empty")
            return
        }
        XCTAssertEqual(2, consoleItem.adaptorType)
        XCTAssertEqual("Internal launch error: process launch failed: Security", consoleItem.content)
        XCTAssertEqual(10, consoleItem.kind)
        XCTAssertEqual(582169311.441566, consoleItem.timestamp)
    }

    func testParseIDEActivityLogAnalyzerResultMessage() throws {
        var iterator = IDEActivityLogAnalyzerResultMessageTokens.makeIterator()
        let logAnalyzerResultMessage = try parser.parseIDEActivityLogAnalyzerResultMessage(iterator: &iterator)
        XCTAssertEqual("Context Missing", logAnalyzerResultMessage.resultType)
        XCTAssertEqual(1, logAnalyzerResultMessage.subMessages.count)
        if let stepMessage = logAnalyzerResultMessage.subMessages.first as?
            IDEActivityLogAnalyzerEventStepMessage {
            XCTAssertEqual("Localized string macro should include a non-empty comment for translators",
                           stepMessage.description)
        } else {
            XCTFail("IDEActivityLogAnalyzerEventStepMessage not parsed")
        }
    }

    func testParseIDEActivityLogActionMessage() throws {
        var iterator = IDEActivityLogActionMessageTokens.makeIterator()
        let logActionMessage = try parser.parseIDEActivityLogActionMessage(iterator: &iterator)
        XCTAssertEqual("The identity of “XYZ.xcframework” is not recorded in your project.", logActionMessage.title)
        XCTAssertEqual("", logActionMessage.shortTitle)
        XCTAssertEqual(9.0, logActionMessage.timeEmitted)
        XCTAssertEqual(575479851, logActionMessage.rangeStartInSectionText)
        XCTAssertEqual(18446744073709551615, logActionMessage.rangeEndInSectionText)
        XCTAssertEqual(0, logActionMessage.subMessages.count)
        XCTAssertEqual(0, logActionMessage.severity)
        XCTAssertEqual("", logActionMessage.type)
        XCTAssertNotNil(logActionMessage.location)
        guard let documentLocation = logActionMessage.location as? DVTTextDocumentLocation else {
            XCTFail("documentLocation is nil")
            return
        }
        XCTAssertEqual(expectedDVTTextDocumentLocation.documentURLString, documentLocation.documentURLString)
        XCTAssertEqual(expectedDVTTextDocumentLocation.timestamp, documentLocation.timestamp)
        XCTAssertEqual("categoryIdent", logActionMessage.categoryIdent)
        XCTAssertEqual(0, logActionMessage.secondaryLocations.count)
        XCTAssertEqual("additionalDescription", logActionMessage.additionalDescription)
        XCTAssertEqual(logActionMessage.action, "action")
    }

    func testParseIBDocumentMemberLocation() throws {
        var iterator = IBDocumentMemberLocationTokens.makeIterator()
        let documentLocation = try parser.parseDocumentLocation(iterator: &iterator)
        XCTAssert(documentLocation is IBDocumentMemberLocation,
                  "Document location should be a IBDocumentMemberLocation")
        XCTAssertEqual("file:///projects/WarningTest/WarningTest/Base.lproj/Main.storyboard",
                       documentLocation.documentURLString, "The url should be correctly parsed")
        guard let documentMemberLocation = documentLocation as? IBDocumentMemberLocation else {
            return
        }
        XCTAssertEqual("RgO-vd-uiQ",
                       documentMemberLocation.memberIdentifier.memberIdentifier,
                       "IBMember's identifier should be parsed")
    }

    func testParseXcode3ProjectLocation() throws {
        var iterator = xcode3ProjectDocumentLocationTokens.makeIterator()
        let documentLocation = try parser.parseDocumentLocation(iterator: &iterator)
        XCTAssertEqual("file:///project/Project.xcodeproj", documentLocation.documentURLString)
        XCTAssertEqual(2.2, documentLocation.timestamp)
    }

    func testTrimmingWhiteCharsInStrings() throws {
        var locationTokens = textDocumentLocationTokens
        locationTokens[0] = Token.string(" file:///project/EntityComponentView.m\n")
        var iterator = locationTokens.makeIterator()
        let documentLocation = try parser.parseDVTTextDocumentLocation(iterator: &iterator)

        XCTAssertEqual("file:///project/EntityComponentView.m", documentLocation.documentURLString)
    }

    let expectedDVTMemberDocumentLocation: DVTMemberDocumentLocation = DVTMemberDocumentLocation(
        documentURLString: "file:///project/EntityComponentView.m",
        timestamp: 2.2,
        member: "abcdef")

    let memberDocumentLocationTokens: [Token] = {
        return [
            Token.className("DVTMemberDocumentLocation"),
            Token.classNameRef("DVTMemberDocumentLocation"),
            Token.string("file:///project/EntityComponentView.m"),
            Token.double(2.2),
            Token.string("abcdef")]
    }()

    func testParseDVTMemberDocumentLocation() throws {
        var iterator = memberDocumentLocationTokens.makeIterator()
        let documentLocation = try parser.parseDocumentLocation(iterator: &iterator)
        XCTAssert(documentLocation is DVTMemberDocumentLocation,
                  "Document location should be a DVTMemberDocumentLocation")

        guard let documentMemberLocation = documentLocation as? DVTMemberDocumentLocation else {
            return
        }
        XCTAssertEqual(expectedDVTMemberDocumentLocation, documentMemberLocation)
    }

}
