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

class ParserTests: XCTestCase {

    let parser = ParserBuildSteps()

    func testDateFormatterUsesJSONFormat() {
        let jsonDateString = "2014-09-27T12:30:00.450000Z"
        let date = parser.dateFormatter.date(from: jsonDateString)
        XCTAssertNotNil(date)
        if let date = date {
            let formattedDate = parser.dateFormatter.string(from: date)
            XCTAssertEqual(jsonDateString, formattedDate)
        }
    }

    func testBuildIdentifierShouldUseMachineName() throws {
        let machineName = UUID.init().uuidString
        let uniqueIdentifier = "uniqueIdentifier"
        let timestamp = Date().timeIntervalSinceNow
        let parser = ParserBuildSteps(machineName: machineName)
        let fakeMainSection = IDEActivityLogSection(sectionType: 1,
                                                    domainType: "",
                                                    title: "Main",
                                                    signature: "",
                                                    timeStartedRecording: timestamp,
                                                    timeStoppedRecording: timestamp,
                                                    subSections: [],
                                                    text: "",
                                                    messages: [],
                                                    wasCancelled: false,
                                                    isQuiet: false,
                                                    wasFetchedFromCache: false,
                                                    subtitle: "",
                                                    location: DVTDocumentLocation(documentURLString: "",
                                                                                  timestamp: timestamp),
                                                    commandDetailDesc: "",
                                                    uniqueIdentifier: uniqueIdentifier,
                                                    localizedResultString: "",
                                                    xcbuildSignature: "",
                                                    unknown: 0)
        let fakeActivityLog = IDEActivityLog(version: 10, mainSection: fakeMainSection)
        let buildStep = try parser.parse(activityLog: fakeActivityLog)
        XCTAssertEqual("\(machineName)_\(uniqueIdentifier)", buildStep.buildIdentifier)

        if let hostName = Host.current().localizedName {
            let parserNoMachineName = ParserBuildSteps(machineName: nil)
            let buildStepNoMachineName = try parserNoMachineName.parse(activityLog: fakeActivityLog)
            XCTAssertEqual("\(hostName)_\(uniqueIdentifier)", buildStepNoMachineName.buildIdentifier)
        }
    }

    func testParseNote() throws {
        let timestamp = Date().timeIntervalSinceReferenceDate
        let noteMessage = IDEActivityLogMessage(title: "Using legacy build system",
            shortTitle: "",
            timeEmitted: timestamp,
            rangeEndInSectionText: 18446744073709551615,
            rangeStartInSectionText: 0,
            subMessages: [],
            severity: 0,
            type: "",
            location: DVTDocumentLocation(documentURLString: "", timestamp: timestamp),
            categoryIdent: "",
            secondaryLocations: [],
            additionalDescription: "")
        let fakeLog = getFakeIDEActivityLogWithMessage(noteMessage,
                                                       andText: "text")
        let build = try parser.parse(activityLog: fakeLog)
        XCTAssertNotNil(build.notes, "Build's notes are empty")
        guard let note = build.notes?.first else {
            XCTFail("There should be one note")
            return
        }
        XCTAssertEqual(noteMessage.title, note.title)
    }

    func testParseWarning() throws {
        let timestamp = Date().timeIntervalSinceReferenceDate
        let textDocumentLocation = DVTTextDocumentLocation(documentURLString: "file://project/file.m",
                                                           timestamp: timestamp,
                                                           startingLineNumber: 10,
                                                           startingColumnNumber: 11,
                                                           endingLineNumber: 12,
                                                           endingColumnNumber: 13,
                                                           characterRangeEnd: 14,
                                                           characterRangeStart: 15,
                                                           locationEncoding: 16)
        let warningMessage = IDEActivityLogMessage(title: "ABC is deprecated",
                                                shortTitle: "",
                                                timeEmitted: timestamp,
                                                rangeEndInSectionText: 18446744073709551615,
                                                rangeStartInSectionText: 0,
                                                subMessages: [],
                                                severity: 1,
                                                type: "com.apple.dt.IDE.diagnostic",
                                                location: textDocumentLocation,
                                                categoryIdent: "",
                                                secondaryLocations: [],
                                                additionalDescription: "")
        let fakeLog = getFakeIDEActivityLogWithMessage(warningMessage,
                                                       andText: "This is deprecated, [-Wdeprecated-declarations]")
        let build = try parser.parse(activityLog: fakeLog)
        XCTAssertNotNil(build.warnings, "Warnings shouldn't be empty")
        guard let warning = build.warnings?.first else {
            XCTFail("Build's warnings are empty")
            return
        }
        XCTAssertEqual(warningMessage.title, warning.title)
        XCTAssertEqual("[-Wdeprecated-declarations]", warning.clangFlag ?? "empty")
        XCTAssertNil(warning.interfaceBuilderIdentifier)
    }

    func testParseInterfaceBuilderWarning() throws {
        let timestamp = Date().timeIntervalSinceReferenceDate
        let memberId = IBMemberID(memberIdentifier: "ABC")
        let ibDocumentLocation = IBDocumentMemberLocation(
            documentURLString: "file://project/Base.lproj/Main.storyboard",
            timestamp: timestamp,
            memberIdentifier: memberId,
            attributeSearchLocation: nil)
        let warningMessage = IDEActivityLogMessage(title: "Automatically Adjusts Font requires using a Dynamic Type",
                                                shortTitle: "",
                                                timeEmitted: timestamp,
                                                rangeEndInSectionText: 0,
                                                rangeStartInSectionText: 0,
                                                subMessages: [],
                                                severity: 1,
                                                type: "",
                                                location: ibDocumentLocation,
                                                categoryIdent: "",
                                                secondaryLocations: [],
                                                additionalDescription: "")
        let fakeLog = getFakeIDEActivityLogWithMessage(warningMessage,
                                                       andText: "/* com.apple.ibtool.document.warnings */ " +
                                                       "/project/Base.lproj/Main.storyboard:ABC: warning:")
        let build = try parser.parse(activityLog: fakeLog)
        guard let warning = build.warnings?.first else {
            XCTFail("Build's warnings are empty")
            return
        }
        XCTAssertEqual(NoticeType.interfaceBuilderWarning, warning.type)
        XCTAssertEqual(warningMessage.title, warning.title)
        XCTAssertNil(warning.clangFlag)
        XCTAssertEqual(memberId.memberIdentifier, warning.interfaceBuilderIdentifier)
    }

    func testParseTargetName() {
        let timestamp = Date().timeIntervalSinceReferenceDate
        let fakeSection = IDEActivityLogSection(sectionType: 1,
        domainType: "",
        title: "Run Something",
        signature: "",
        timeStartedRecording: timestamp,
        timeStoppedRecording: timestamp,
        subSections: [],
        text: "",
        messages: [],
        wasCancelled: false,
        isQuiet: false,
        wasFetchedFromCache: false,
        subtitle: "",
        location: DVTDocumentLocation(documentURLString: "",
                                      timestamp: timestamp),
        commandDetailDesc: command,
        uniqueIdentifier: "ABC",
        localizedResultString: "",
        xcbuildSignature: "",
        unknown: 0)

        let parsedTarget = fakeSection.getTargetFromCommand()

        XCTAssertEqual(parsedTarget, "ServicesPlist")
    }

    let command = """
    PhaseScriptExecution Services.plist /Users/spotify-buildagent/buildAgent/work/6878303d676e66/
    build/DerivedData/Build/Intermediates.noindex/
    Spotify.build/Debug-iphonesimulator/GenerateServicesPlist.build/Script-7AD9607C371622036A6BC748.sh
    (in target 'ServicesPlist' from project 'Services')

    export CLANG_ANALYZER_SECURITY_INSECUREAPI_VFORK=YES
    export CLANG_ANALYZER_SECURITY_KEYCHAIN_API=YES
    export CLANG_ANALYZER_USE_AFTER_MOVE=YES_AGGRESSIVE
    export CLANG_CXX_LANGUAGE_STANDARD=c++17
    export CLANG_CXX_LIBRARY=libc++
    export CLANG_ENABLE_MODULES=NO
    export CLANG_ENABLE_OBJC_ARC=YES
    export CLANG_ENABLE_OBJC_WEAK=YES

    /bin/sh -c /DerivedData/Build/Intermediates.noindex/Services.build/Debug-iphonesimulator/
    ServicesPlist.build/Script-7AD9607C371622036A6BC748.sh
    """

    private func getFakeIDEActivityLogWithMessage(_ message: IDEActivityLogMessage,
                                                  andText text: String) -> IDEActivityLog {
        let timestamp = Date().timeIntervalSinceReferenceDate
        let fakeMainStep = IDEActivityLogSection(sectionType: 1,
                                                 domainType: "",
                                                 title: "",
                                                 signature: "",
                                                 timeStartedRecording: timestamp,
                                                 timeStoppedRecording: timestamp,
                                                 subSections: [],
                                                 text: text,
                                                 messages: [message],
                                                 wasCancelled: false,
                                                 isQuiet: true,
                                                 wasFetchedFromCache: true,
                                                 subtitle: "",
                                                 location: DVTDocumentLocation(documentURLString: "",
                                                                               timestamp: timestamp),
                                                 commandDetailDesc: "",
                                                 uniqueIdentifier: "uniqueIdentifier",
                                                 localizedResultString: "",
                                                 xcbuildSignature: "",
                                                 unknown: 0)
        return IDEActivityLog(version: 10, mainSection: fakeMainStep)
    }

}
