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

// swiftlint:disable type_body_length file_length
class ParserTests: XCTestCase {

    let parser = ParserBuildSteps(omitWarningsDetails: false,
                                  omitNotesDetails: false,
                                  truncLargeIssues: false)

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
        let parser = ParserBuildSteps(machineName: machineName,
                                      omitWarningsDetails: false,
                                      omitNotesDetails: false,
                                      truncLargeIssues: false)
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
                                                    attachments: [],
                                                    unknown: 0)
        let fakeActivityLog = IDEActivityLog(version: 10, mainSection: fakeMainSection)
        let buildStep = try parser.parse(activityLog: fakeActivityLog)
        XCTAssertEqual("\(machineName)_\(uniqueIdentifier)", buildStep.buildIdentifier)

        if let hostName = Host.current().localizedName {
            let parserNoMachineName = ParserBuildSteps(machineName: nil,
                                                       omitWarningsDetails: false,
                                                       omitNotesDetails: false,
                                                       truncLargeIssues: false)
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
        let fakeLog = getFakeIDEActivityLogWithMessages([noteMessage],
                                                       andText: "text")
        let build = try parser.parse(activityLog: fakeLog)
        XCTAssertNotNil(build.notes, "Build's notes are empty")
        guard let note = build.notes?.first else {
            XCTFail("There should be one note")
            return
        }
        XCTAssertEqual(noteMessage.title, note.title)
    }

    // swiftlint:disable:next function_body_length
    func testParseWarningsAndErrors() throws {
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
        let textWrongDocumentLocation = DVTTextDocumentLocation(documentURLString: "file://project/header.h",
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
        let duplicatedWarningMessage = IDEActivityLogMessage(title: "ABC is deprecated",
                                                   shortTitle: "",
                                                   timeEmitted: timestamp,
                                                   rangeEndInSectionText: 18446744073709551615,
                                                   rangeStartInSectionText: 0,
                                                   subMessages: [],
                                                   severity: 1,
                                                   type: "com.apple.dt.IDE.diagnostic",
                                                   location: textWrongDocumentLocation,
                                                   categoryIdent: "",
                                                   secondaryLocations: [],
                                                   additionalDescription: "")
        let clangErrorMessage = IDEActivityLogMessage(title: "Void is not a type",
                                                 shortTitle: "",
                                                 timeEmitted: timestamp,
                                                 rangeEndInSectionText: 18446744073709551615,
                                                 rangeStartInSectionText: 0,
                                                 subMessages: [],
                                                 severity: 2,
                                                 type: "com.apple.dt.IDE.diagnostic",
                                                 location: textDocumentLocation,
                                                 categoryIdent: "Semantic Issue",
                                                 secondaryLocations: [],
                                                 additionalDescription: "")
        let fakeLog = getFakeIDEActivityLogWithMessages([warningMessage, clangErrorMessage, duplicatedWarningMessage],
                                                       andText: "This is deprecated, [-Wdeprecated-declarations]",
                                                       loc: textDocumentLocation)
        let build = try parser.parse(activityLog: fakeLog)
        XCTAssertNotNil(build.warnings, "Warnings shouldn't be empty")
        guard let warning = build.warnings?.first else {
            XCTFail("Build's warnings are empty")
            return
        }
        XCTAssertEqual(1, build.warningCount)
        XCTAssertEqual(warningMessage.title, warning.title)
        XCTAssertEqual("[-Wdeprecated-declarations]", warning.clangFlag ?? "empty")
        XCTAssertEqual(NoticeType.deprecatedWarning, warning.type)
        XCTAssertEqual(textDocumentLocation.documentURLString, warning.documentURL)
        XCTAssertEqual(textDocumentLocation.startingLineNumber + 1, warning.startingLineNumber)
        XCTAssertEqual(textDocumentLocation.startingColumnNumber + 1, warning.startingColumnNumber)
        XCTAssertNil(warning.interfaceBuilderIdentifier)
        guard let error = build.errors?.first else {
            XCTFail("Build's errors are empty")
            return
        }
        XCTAssertEqual(clangErrorMessage.title, error.title)
        XCTAssertEqual(NoticeType.clangError, error.type)
        XCTAssertEqual(textDocumentLocation.startingLineNumber + 1, error.startingLineNumber)
        XCTAssertEqual(textDocumentLocation.startingColumnNumber + 1, error.startingColumnNumber)
    }

    func testParseSwiftIssuesDetails() {
        let detailsText = """
/project/SwiftProject/ContentView.swift:33:8: error: expected type\renum a:\r \
^\r/project/SwiftProject/ContentView.swift:33:8: error: expected '{' in enum\renum a:\r \
^\r/project/SwiftProject/ContentView.swift:28:31: error: use of undeclared type 'Views' \
\r    static var previews: some Views {\r ^~~~~\r/project/SwiftProject/ContentView.swift:27:8: error: \
type 'ContentView_Previews' does not conform to protocol 'PreviewProvider'\rstruct \
        ContentView_Previews: PreviewProvider {\r       ^\r/project/SwiftProject/ContentView.swift:27:8: \
note: do you want to add protocol stubs?\rstruct ContentView_Previews: PreviewProvider {\r       \
^\r/project/SwiftProject/ContentView.swift:13:9: warning: 'doSomething()' is deprecated: renamed \
to 'updatedDoSomething'\r        doSomething()\r        ^\r/project/SwiftProject/ContentView.swift:13:9: \
note: use 'updatedDoSomething' instead\r doSomething()\r        ^~~~~~~~~~~\r        updatedDoSomething\r
"""
        let detailsByLocation = Notice.parseSwiftIssuesDetailsByLocation(detailsText)
        XCTAssertEqual(detailsByLocation.count, 4)
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
        let fakeLog = getFakeIDEActivityLogWithMessages([warningMessage],
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
                                                attachments: [],
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

    private func getFakeIDEActivityLogWithMessages(_ messages: [IDEActivityLogMessage],
                                                   andText text: String,
                                                   loc: DVTDocumentLocation = DVTDocumentLocation(documentURLString: "",
                                                                                                       timestamp: 0))
    -> IDEActivityLog {
        let timestamp = Date().timeIntervalSinceReferenceDate
        let fakeMainStep = IDEActivityLogSection(sectionType: 1,
                                                 domainType: "",
                                                 title: "",
                                                 signature: "",
                                                 timeStartedRecording: timestamp,
                                                 timeStoppedRecording: timestamp,
                                                 subSections: [],
                                                 text: text,
                                                 messages: messages,
                                                 wasCancelled: false,
                                                 isQuiet: true,
                                                 wasFetchedFromCache: true,
                                                 subtitle: "",
                                                 location: loc,
                                                 commandDetailDesc: "",
                                                 uniqueIdentifier: "uniqueIdentifier",
                                                 localizedResultString: "",
                                                 xcbuildSignature: "",
                                                 attachments: [],
                                                 unknown: 0)
        return IDEActivityLog(version: 10, mainSection: fakeMainStep)
    }

    func testParseTargetCompilationTimes() {
        let expectedCompilationDuration = 10.0
        let now = Date().timeIntervalSince1970
        let compilationTime = now + expectedCompilationDuration
        let linkingTime = now + expectedCompilationDuration + 20

        let compilationStep = makeFakeBuildStep(title: "Compilation",
                                                type: .detail,
                                                detailStepType: .cCompilation,
                                                startTimestamp: now,
                                                fetchedFromCache: false)
            .with(newCompilationEndTimestamp: compilationTime, andCompilationDuration: expectedCompilationDuration)
        let linkingStep = makeFakeBuildStep(title: "Linking",
                                            type: .detail,
                                            detailStepType: .linker,
                                            startTimestamp: now + expectedCompilationDuration,
                                            fetchedFromCache: false)
            .with(newCompilationEndTimestamp: linkingTime, andCompilationDuration: 20)
        var targetStep = makeFakeBuildStep(title: "Build Target",
                                           type: .target,
                                           detailStepType: .none,
                                           startTimestamp: now,
                                           fetchedFromCache: false).with(subSteps: [compilationStep, linkingStep])

        targetStep = parser.addCompilationTimes(step: targetStep)
        XCTAssertEqual(compilationTime, targetStep.compilationEndTimestamp)
        XCTAssertEqual(expectedCompilationDuration, targetStep.compilationDuration)
    }

    func testParseAppCompilationTimes() {
        let expectedCompilationDuration = 50.0
        let now = Date().timeIntervalSince1970
        let target1 = makeFakeBuildStep(title: "Target1",
                                                type: .target,
                                                detailStepType: .none,
                                                startTimestamp: now,
                                                fetchedFromCache: false)
            .with(newCompilationEndTimestamp: now + 25.0,
                  andCompilationDuration: 25.0)
        let target2 = makeFakeBuildStep(title: "Target2",
                                            type: .target,
                                            detailStepType: .none,
                                            startTimestamp: now + 25.0,
                                            fetchedFromCache: false)
        .with(newCompilationEndTimestamp: now + 50.0,
              andCompilationDuration: 25.0)
        var app = makeFakeBuildStep(title: "My App",
                                           type: .main,
                                           detailStepType: .none,
                                           startTimestamp: now,
                                           fetchedFromCache: false).with(subSteps: [target1, target2])
        app = parser.addCompilationTimes(step: app)
        XCTAssertEqual(now + expectedCompilationDuration, app.compilationEndTimestamp)
        XCTAssertEqual(expectedCompilationDuration, app.compilationDuration)
    }

    func testParseAppNoopCompilationTimes() {
        let now = Date().timeIntervalSince1970
        let target1 = makeFakeBuildStep(title: "Target1",
                                                type: .target,
                                                detailStepType: .none,
                                                startTimestamp: now,
                                                fetchedFromCache: true)

        let target2 = makeFakeBuildStep(title: "Target2",
                                            type: .target,
                                            detailStepType: .none,
                                            startTimestamp: now + 25.0,
                                            fetchedFromCache: true)

        var app = makeFakeBuildStep(title: "My App",
                                           type: .main,
                                           detailStepType: .none,
                                           startTimestamp: now,
                                           fetchedFromCache: true).with(subSteps: [target1, target2])
        app = parser.addCompilationTimes(step: app)
        XCTAssertEqual(app.startTimestamp, app.compilationEndTimestamp)
        XCTAssertEqual(0.0, app.compilationDuration)
    }

    func testGetIndividualSteps() throws {
        let buildStep = try parser.parseLogSection(logSection: fakeSwiftCompilation,
                                                   type: .detail,
                                                   parentSection: nil)
        let expectedDocumentURLs = ["file:///test_project/PodsTest/Pods/Alamofire/Source/AFError.swift",
                                    "file:///test_project/PodsTest/Pods/Alamofire/Source/Alamofire.swift",
                                    "file:///test_project/PodsTest/Pods/Alamofire/Source/AlamofireExtended.swift",
                                    "file:///test_project/PodsTest/Pods/Alamofire/Source/CachedResponseHandler.swift",
                                    "file:///test_project/PodsTest/Pods/Alamofire/Source/DispatchQueue+Alamofire.swift",
                                    "file:///test_project/PodsTest/Pods/Alamofire/Source/EventMonitor.swift"]
        let documentURLs = buildStep.subSteps.map { $0.documentURL }
        XCTAssertEqual(expectedDocumentURLs, documentURLs)

        let parsedBuild = buildStep.flatten()
        var idsDict: [String: String] = [:]
        parsedBuild.compactMap { step -> String? in
            if step.detailStepType == .swiftCompilation {
                return step.identifier
            }
            return nil
        }.forEach { identifier in
            if idsDict[identifier] == nil {
                idsDict[identifier] = identifier
            } else {
                XCTFail("Duplicated identifier \(identifier)")
            }
        }
    }

    func testParseOmitWarnings() throws {
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

        let fakeLog = getFakeIDEActivityLogWithMessages([warningMessage],
                                                       andText: "This is deprecated, [-Wdeprecated-declarations]",
                                                       loc: textDocumentLocation)
        let parser = ParserBuildSteps(omitWarningsDetails: true,
                                      omitNotesDetails: false,
                                      truncLargeIssues: false)
        let build = try parser.parse(activityLog: fakeLog)
        XCTAssertEqual(0, build.warnings?.count ?? 0, "Warnings should be empty")
        XCTAssertEqual(1, build.warningCount, "Number of warnings should be reported")
    }

    func testParseOmitNotes() throws {
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

        let noteMessage = IDEActivityLogMessage(title: "This is a npte",
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

        let fakeLog = getFakeIDEActivityLogWithMessages([noteMessage],
                                                       andText: "Log",
                                                       loc: textDocumentLocation)
        let parser = ParserBuildSteps(omitWarningsDetails: false,
                                      omitNotesDetails: true,
                                      truncLargeIssues: false)
        let build = try parser.parse(activityLog: fakeLog)
        XCTAssertEqual(0, build.notes?.count ?? 0, "Notes should be empty")
    }

    func testParseTruncateLargeIssues() throws {
        let timestamp = Date().timeIntervalSinceReferenceDate
        let textDocumentLocation = DVTTextDocumentLocation(documentURLString: "file://project/file.swift",
                                                           timestamp: timestamp,
                                                           startingLineNumber: 10,
                                                           startingColumnNumber: 11,
                                                           endingLineNumber: 12,
                                                           endingColumnNumber: 13,
                                                           characterRangeEnd: 14,
                                                           characterRangeStart: 15,
                                                           locationEncoding: 16)
        let aThousandWarnings = (0...999).map { _ in
            IDEActivityLogMessage(title: "Swift Compiler Warning",
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
        }
        let fakeLog = getFakeIDEActivityLogWithMessages(aThousandWarnings,
                                                       andText: "Swift Compiler Warning",
                                                       loc: textDocumentLocation)
        let parser = ParserBuildSteps(omitWarningsDetails: false,
                                      omitNotesDetails: false,
                                      truncLargeIssues: true)
        let build = try parser.parse(activityLog: fakeLog)
        XCTAssertEqual(100, build.warnings?.count ?? 0, "Warnings should be truncated up to 100")
    }

    // swiftlint:disable line_length
    let commandDetailSwiftSteps = """
CompileSwift normal x86_64 (in target 'Alamofire' from project 'Pods')
 cd /test_project/PodsTest/Pods
 /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift -frontend -c /test_project/PodsTest/Pods/Alamofire/Source/AFError.swift /test_project/PodsTest/Pods/Alamofire/Source/Alamofire.swift /test_project/PodsTest/Pods/Alamofire/Source/AlamofireExtended.swift /test_project/PodsTest/Pods/Alamofire/Source/CachedResponseHandler.swift /test_project/PodsTest/Pods/Alamofire/Source/DispatchQueue+Alamofire.swift /test_project/PodsTest/Pods/Alamofire/Source/EventMonitor.swift -supplementary-output-file-map /var/folders/yx/4910621d0wn8z3lm16fz0svr0000gp/T/supplementaryOutputs-d0af4e -target x86_64-apple-ios10.0-simulator -enable-objc-interop -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator13.2.sdk -I /Library/Developer/Xcode/DerivedData/PodsTest-cdhbxhkhhokztxftsdepcfjhnfqg/Build/Products/Debug-iphonesimulator/Alamofire -F /Library/Developer/Xcode/DerivedData/PodsTest-cdhbxhkhhokztxftsdepcfjhnfqg/Build/Products/Debug-iphonesimulator/Alamofire -enable-testing -g -import-underlying-module -module-cache-path /Library/Developer/Xcode/DerivedData/ModuleCache.noindex -swift-version 5 -enforce-exclusivity=checked -Onone -D DEBUG -D COCOAPODS -serialize-debugging-options -Xcc -working-directory -Xcc
"""
    lazy var fakeSwiftCompilation: IDEActivityLogSection = {
        return IDEActivityLogSection(sectionType: 1,
                                     domainType: "",
                                     title: "CompileSwift",
                                     signature: "CompileSwift normal x86_64",
                                     timeStartedRecording: 1.0,
                                     timeStoppedRecording: 2.0,
                                     subSections: [],
                                     text: "",
                                     messages: [],
                                     wasCancelled: false,
                                     isQuiet: true,
                                     wasFetchedFromCache: true,
                                     subtitle: "",
                                     location: DVTDocumentLocation(documentURLString: "",
                                                                   timestamp: 1.0),
                                     commandDetailDesc: commandDetailSwiftSteps,
                                     uniqueIdentifier: "uniqueIdentifier",
                                     localizedResultString: "",
                                     xcbuildSignature: "",
                                     attachments: [],
                                     unknown: 0)
    }()
}
