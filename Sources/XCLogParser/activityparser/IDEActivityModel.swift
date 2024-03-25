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

import Foundation

// swiftlint:disable file_length
public class IDEActivityLog: Encodable {
    public let version: Int8
    public let mainSection: IDEActivityLogSection

    public init(version: Int8, mainSection: IDEActivityLogSection) {
        self.version = version
        self.mainSection = mainSection
    }
}

public class IDEActivityLogSection: Encodable {
    public let sectionType: Int8
    public let domainType: String
    public let title: String
    public let signature: String
    public let timeStartedRecording: Double
    public var timeStoppedRecording: Double
    public var subSections: [IDEActivityLogSection]
    public let text: String
    public let messages: [IDEActivityLogMessage]
    public let wasCancelled: Bool
    public let isQuiet: Bool
    public var wasFetchedFromCache: Bool
    public let subtitle: String
    public let location: DVTDocumentLocation
    public let commandDetailDesc: String
    public let uniqueIdentifier: String
    public let localizedResultString: String
    public let xcbuildSignature: String
    public let attachments: [IDEActivityLogSectionAttachment]
    public let unknown: Int

    public init(sectionType: Int8,
                domainType: String,
                title: String,
                signature: String,
                timeStartedRecording: Double,
                timeStoppedRecording: Double,
                subSections: [IDEActivityLogSection],
                text: String,
                messages: [IDEActivityLogMessage],
                wasCancelled: Bool,
                isQuiet: Bool,
                wasFetchedFromCache: Bool,
                subtitle: String,
                location: DVTDocumentLocation,
                commandDetailDesc: String,
                uniqueIdentifier: String,
                localizedResultString: String,
                xcbuildSignature: String,
                attachments: [IDEActivityLogSectionAttachment],
                unknown: Int) {
        self.sectionType = sectionType
        self.domainType = domainType
        self.title = title
        self.signature = signature
        self.timeStartedRecording = timeStartedRecording
        self.timeStoppedRecording = timeStoppedRecording
        self.subSections = subSections
        self.text = text
        self.messages = messages
        self.wasCancelled = wasCancelled
        self.isQuiet = isQuiet
        self.wasFetchedFromCache = wasFetchedFromCache
        self.subtitle = subtitle
        self.location = location
        self.commandDetailDesc = commandDetailDesc
        self.uniqueIdentifier = uniqueIdentifier
        self.localizedResultString = localizedResultString
        self.xcbuildSignature = xcbuildSignature
        self.attachments = attachments
        self.unknown = unknown
    }

}

public class IDEActivityLogUnitTestSection: IDEActivityLogSection {
    public let testsPassedString: String
    public let durationString: String
    public let summaryString: String
    public let suiteName: String
    public let testName: String
    public let performanceTestOutputString: String

    public init(sectionType: Int8,
                domainType: String,
                title: String,
                signature: String,
                timeStartedRecording: Double,
                timeStoppedRecording: Double,
                subSections: [IDEActivityLogSection],
                text: String,
                messages: [IDEActivityLogMessage],
                wasCancelled: Bool,
                isQuiet: Bool,
                wasFetchedFromCache: Bool,
                subtitle: String,
                location: DVTDocumentLocation,
                commandDetailDesc: String,
                uniqueIdentifier: String,
                localizedResultString: String,
                xcbuildSignature: String,
                attachments: [IDEActivityLogSectionAttachment],
                unknown: Int,
                testsPassedString: String,
                durationString: String,
                summaryString: String,
                suiteName: String,
                testName: String,
                performanceTestOutputString: String
                ) {
        self.testsPassedString = testsPassedString
        self.durationString = durationString
        self.summaryString = summaryString
        self.suiteName = suiteName
        self.testName = testName
        self.performanceTestOutputString = performanceTestOutputString
        super.init(sectionType: sectionType,
                   domainType: domainType,
                   title: title,
                   signature: signature,
                   timeStartedRecording: timeStartedRecording,
                   timeStoppedRecording: timeStoppedRecording,
                   subSections: subSections,
                   text: text,
                   messages: messages,
                   wasCancelled: wasCancelled,
                   isQuiet: isQuiet,
                   wasFetchedFromCache: wasFetchedFromCache,
                   subtitle: subtitle,
                   location: location,
                   commandDetailDesc: commandDetailDesc,
                   uniqueIdentifier: uniqueIdentifier,
                   localizedResultString: localizedResultString,
                   xcbuildSignature: xcbuildSignature,
                   attachments: attachments,
                   unknown: unknown)
    }

    private enum CodingKeys: String, CodingKey {
        case testsPassedString
        case durationString
        case summaryString
        case suiteName
        case testName
        case performanceTestOutputString
    }

    /// Override the encode method to overcome a constraint where subclasses properties
    /// are not encoded by default
    override public func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(testsPassedString, forKey: .testsPassedString)
        try container.encode(durationString, forKey: .durationString)
        try container.encode(summaryString, forKey: .summaryString)
        try container.encode(suiteName, forKey: .suiteName)
        try container.encode(testName, forKey: .testName)
        try container.encode(performanceTestOutputString, forKey: .performanceTestOutputString)
    }

}

public class IDEActivityLogMessage: Encodable {
    public let title: String
    public let shortTitle: String
    public let timeEmitted: Double
    public let rangeEndInSectionText: UInt64
    public let rangeStartInSectionText: UInt64
    public let subMessages: [IDEActivityLogMessage]
    public let severity: Int
    public let type: String
    public let location: DVTDocumentLocation
    public let categoryIdent: String
    public let secondaryLocations: [DVTDocumentLocation]
    public let additionalDescription: String

    public init(title: String,
                shortTitle: String,
                timeEmitted: Double,
                rangeEndInSectionText: UInt64,
                rangeStartInSectionText: UInt64,
                subMessages: [IDEActivityLogMessage],
                severity: Int,
                type: String,
                location: DVTDocumentLocation,
                categoryIdent: String,
                secondaryLocations: [DVTDocumentLocation],
                additionalDescription: String) {
        self.title = title
        self.shortTitle = shortTitle
        self.timeEmitted = timeEmitted
        self.rangeEndInSectionText = rangeEndInSectionText
        self.rangeStartInSectionText = rangeStartInSectionText
        self.subMessages = subMessages
        self.severity = severity
        self.type = type
        self.location = location
        self.categoryIdent = categoryIdent
        self.secondaryLocations = secondaryLocations
        self.additionalDescription = additionalDescription
    }
}

public class IDEActivityLogAnalyzerResultMessage: IDEActivityLogMessage {

    public let resultType: String
    public let keyEventIndex: UInt64

    public init(title: String,
                shortTitle: String,
                timeEmitted: Double,
                rangeEndInSectionText: UInt64,
                rangeStartInSectionText: UInt64,
                subMessages: [IDEActivityLogMessage],
                severity: Int,
                type: String,
                location: DVTDocumentLocation,
                categoryIdent: String,
                secondaryLocations: [DVTDocumentLocation],
                additionalDescription: String,
                resultType: String,
                keyEventIndex: UInt64) {

        self.resultType = resultType
        self.keyEventIndex = keyEventIndex

        super.init(title: title,
                   shortTitle: shortTitle,
                   timeEmitted: timeEmitted,
                   rangeEndInSectionText: rangeEndInSectionText,
                   rangeStartInSectionText: rangeStartInSectionText,
                   subMessages: subMessages,
                   severity: severity,
                   type: type,
                   location: location,
                   categoryIdent: categoryIdent,
                   secondaryLocations: secondaryLocations,
                   additionalDescription: additionalDescription)
    }

    private enum CodingKeys: String, CodingKey {
        case resultType
        case keyEventIndex
    }

    override public func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(resultType, forKey: .resultType)
        try container.encode(keyEventIndex, forKey: .keyEventIndex)
    }
}

public class IDEActivityLogAnalyzerControlFlowStepMessage: IDEActivityLogMessage {

    public let parentIndex: UInt64
    public let endLocation: DVTDocumentLocation
    public let edges: [IDEActivityLogAnalyzerControlFlowStepEdge]

    public init(title: String,
                shortTitle: String,
                timeEmitted: Double,
                rangeEndInSectionText: UInt64,
                rangeStartInSectionText: UInt64,
                subMessages: [IDEActivityLogMessage],
                severity: Int,
                type: String,
                location: DVTDocumentLocation,
                categoryIdent: String,
                secondaryLocations: [DVTDocumentLocation],
                additionalDescription: String,
                parentIndex: UInt64,
                endLocation: DVTDocumentLocation,
                edges: [IDEActivityLogAnalyzerControlFlowStepEdge]) {

        self.parentIndex = parentIndex
        self.endLocation = endLocation
        self.edges = edges

        super.init(title: title,
                   shortTitle: shortTitle,
                   timeEmitted: timeEmitted,
                   rangeEndInSectionText: rangeEndInSectionText,
                   rangeStartInSectionText: rangeStartInSectionText,
                   subMessages: subMessages,
                   severity: severity,
                   type: type,
                   location: location,
                   categoryIdent: categoryIdent,
                   secondaryLocations: secondaryLocations,
                   additionalDescription: additionalDescription)
    }

    private enum CodingKeys: String, CodingKey {
        case parentIndex
        case endLocation
    }

    override public func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(parentIndex, forKey: .parentIndex)
        try container.encode(endLocation, forKey: .endLocation)
    }
}

public class DVTDocumentLocation: Encodable {
    public let documentURLString: String
    public let timestamp: Double

    public init(documentURLString: String, timestamp: Double) {
        self.documentURLString = documentURLString
        self.timestamp = timestamp
    }

}

public class DVTTextDocumentLocation: DVTDocumentLocation {
    public let startingLineNumber: UInt64
    public let startingColumnNumber: UInt64
    public let endingLineNumber: UInt64
    public let endingColumnNumber: UInt64
    public let characterRangeEnd: UInt64
    public let characterRangeStart: UInt64
    public let locationEncoding: UInt64

    public init(documentURLString: String,
                timestamp: Double,
                startingLineNumber: UInt64,
                startingColumnNumber: UInt64,
                endingLineNumber: UInt64,
                endingColumnNumber: UInt64,
                characterRangeEnd: UInt64,
                characterRangeStart: UInt64,
                locationEncoding: UInt64) {
        self.startingLineNumber = startingLineNumber
        self.startingColumnNumber = startingColumnNumber
        self.endingLineNumber = endingLineNumber
        self.endingColumnNumber = endingColumnNumber
        self.characterRangeEnd = characterRangeEnd
        self.characterRangeStart = characterRangeStart
        self.locationEncoding = locationEncoding
        super.init(documentURLString: documentURLString, timestamp: timestamp)
    }

    private enum CodingKeys: String, CodingKey {
        case startingLineNumber
        case startingColumnNumber
        case endingLineNumber
        case endingColumnNumber
        case characterRangeEnd
        case characterRangeStart
        case locationEncoding
    }

    /// Override the encode method to overcome a constraint where subclasses properties
    /// are not encoded by default
    override public func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(startingLineNumber, forKey: .startingLineNumber)
        try container.encode(startingColumnNumber, forKey: .startingColumnNumber)
        try container.encode(endingLineNumber, forKey: .endingLineNumber)
        try container.encode(endingColumnNumber, forKey: .endingColumnNumber)
        try container.encode(characterRangeEnd, forKey: .characterRangeEnd)
        try container.encode(characterRangeStart, forKey: .characterRangeStart)
        try container.encode(locationEncoding, forKey: .locationEncoding)
    }
}

public class IDEConsoleItem: Encodable {
    public let adaptorType: UInt64
    public let content: String
    public let kind: UInt64
    public let timestamp: Double

    public init(adaptorType: UInt64, content: String, kind: UInt64, timestamp: Double) {
        self.adaptorType = adaptorType
        self.content = content
        self.kind = kind
        self.timestamp = timestamp
    }
}

public class DBGConsoleLog: IDEActivityLogSection {
    public let logConsoleItems: [IDEConsoleItem]

    public init(sectionType: Int8,
                domainType: String,
                title: String,
                signature: String,
                timeStartedRecording: Double,
                timeStoppedRecording: Double,
                subSections: [IDEActivityLogSection],
                text: String,
                messages: [IDEActivityLogMessage],
                wasCancelled: Bool,
                isQuiet: Bool,
                wasFetchedFromCache: Bool,
                subtitle: String,
                location: DVTDocumentLocation,
                commandDetailDesc: String,
                uniqueIdentifier: String,
                localizedResultString: String,
                xcbuildSignature: String,
                attachments: [IDEActivityLogSectionAttachment],
                unknown: Int,
                logConsoleItems: [IDEConsoleItem]) {
        self.logConsoleItems = logConsoleItems
        super.init(sectionType: sectionType,
                   domainType: domainType,
                   title: title,
                   signature: signature,
                   timeStartedRecording: timeStartedRecording,
                   timeStoppedRecording: timeStoppedRecording,
                   subSections: subSections,
                   text: text,
                   messages: messages,
                   wasCancelled: wasCancelled,
                   isQuiet: isQuiet,
                   wasFetchedFromCache: wasFetchedFromCache,
                   subtitle: subtitle,
                   location: location,
                   commandDetailDesc: commandDetailDesc,
                   uniqueIdentifier: uniqueIdentifier,
                   localizedResultString: localizedResultString,
                   xcbuildSignature: xcbuildSignature,
                   attachments: attachments,
                   unknown: unknown)
    }

    private enum CodingKeys: String, CodingKey {
        case logConsoleItems
    }

    override public func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(logConsoleItems, forKey: .logConsoleItems)
    }
}

public class IDEActivityLogAnalyzerControlFlowStepEdge: Encodable {
    public let startLocation: DVTDocumentLocation
    public let endLocation: DVTDocumentLocation

    public init(startLocation: DVTDocumentLocation, endLocation: DVTDocumentLocation) {
        self.startLocation = startLocation
        self.endLocation = endLocation
    }
}

public class IDEActivityLogAnalyzerEventStepMessage: IDEActivityLogMessage {

    public let parentIndex: UInt64
    public let description: String
    public let callDepth: UInt64

    public init(title: String,
                shortTitle: String,
                timeEmitted: Double,
                rangeEndInSectionText: UInt64,
                rangeStartInSectionText: UInt64,
                subMessages: [IDEActivityLogMessage],
                severity: Int,
                type: String,
                location: DVTDocumentLocation,
                categoryIdent: String,
                secondaryLocations: [DVTDocumentLocation],
                additionalDescription: String,
                parentIndex: UInt64,
                description: String,
                callDepth: UInt64) {

        self.parentIndex = parentIndex
        self.description = description
        self.callDepth = callDepth

        super.init(title: title,
                   shortTitle: shortTitle,
                   timeEmitted: timeEmitted,
                   rangeEndInSectionText: rangeEndInSectionText,
                   rangeStartInSectionText: rangeStartInSectionText,
                   subMessages: subMessages,
                   severity: severity,
                   type: type,
                   location: location,
                   categoryIdent: categoryIdent,
                   secondaryLocations: secondaryLocations,
                   additionalDescription: additionalDescription)
    }

    private enum CodingKeys: String, CodingKey {
        case parentIndex
        case description
        case callDepth
    }

    override public func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(description, forKey: .description)
        try container.encode(parentIndex, forKey: .parentIndex)
        try container.encode(callDepth, forKey: .callDepth)
    }
}

public class IDEActivityLogActionMessage: IDEActivityLogMessage {

    public let action: String

    public init(title: String,
                shortTitle: String,
                timeEmitted: Double,
                rangeEndInSectionText: UInt64,
                rangeStartInSectionText: UInt64,
                subMessages: [IDEActivityLogMessage],
                severity: Int,
                type: String,
                location: DVTDocumentLocation,
                categoryIdent: String,
                secondaryLocations: [DVTDocumentLocation],
                additionalDescription: String,
                action: String) {

        self.action = action

        super.init(title: title,
                   shortTitle: shortTitle,
                   timeEmitted: timeEmitted,
                   rangeEndInSectionText: rangeEndInSectionText,
                   rangeStartInSectionText: rangeStartInSectionText,
                   subMessages: subMessages,
                   severity: severity,
                   type: type,
                   location: location,
                   categoryIdent: categoryIdent,
                   secondaryLocations: secondaryLocations,
                   additionalDescription: additionalDescription)
    }

    private enum CodingKeys: String, CodingKey {
        case action
    }

    override public func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(action, forKey: .action)
    }
}

// MARK: IDEInterfaceBuilderKit

public class IBMemberID: Encodable {
    public let memberIdentifier: String

    public init(memberIdentifier: String) {
        self.memberIdentifier = memberIdentifier
    }
}

public class IBAttributeSearchLocation: Encodable {
    public let offsetFromStart: UInt64
    public let offsetFromEnd: UInt64
    public let keyPath: String

    public init(offsetFromStart: UInt64, offsetFromEnd: UInt64, keyPath: String) {
        self.offsetFromEnd = offsetFromEnd
        self.offsetFromStart = offsetFromStart
        self.keyPath = keyPath
    }
}

public class IBDocumentMemberLocation: DVTDocumentLocation {
    public let memberIdentifier: IBMemberID
    public let attributeSearchLocation: IBAttributeSearchLocation?

    public init(documentURLString: String,
                timestamp: Double,
                memberIdentifier: IBMemberID,
                attributeSearchLocation: IBAttributeSearchLocation?) {
        self.memberIdentifier = memberIdentifier
        self.attributeSearchLocation = attributeSearchLocation
        super.init(documentURLString: documentURLString, timestamp: timestamp)
    }

    private enum CodingKeys: String, CodingKey {
        case memberIdentifier
        case attributeSearchLocation
    }

    override public func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(memberIdentifier, forKey: .memberIdentifier)
        try container.encode(attributeSearchLocation, forKey: .attributeSearchLocation)
    }
}

// MARK: Added in Xcode 14

////  From DVTFoundation.framework
public class DVTMemberDocumentLocation: DVTDocumentLocation, Equatable {

    public let member: String

    public init(documentURLString: String, timestamp: Double, member: String) {
        self.member = member
        super.init(documentURLString: documentURLString, timestamp: timestamp)
    }

    // MARK: Equatable method

    public static func == (lhs: DVTMemberDocumentLocation, rhs: DVTMemberDocumentLocation) -> Bool {
        return lhs.documentURLString == rhs.documentURLString &&
        lhs.timestamp == rhs.timestamp &&
        lhs.member == rhs.member
    }

}

// MARK: Added in Xcode 15.3

public class IDEActivityLogSectionAttachment: Encodable {
    public struct BuildOperationTaskMetrics: Codable {
        public let utime: UInt64
        public let stime: UInt64
        public let maxRSS: UInt64
        public let wcStartTime: UInt64
        public let wcDuration: UInt64
    }

    public let identifier: String
    public let majorVersion: UInt64
    public let minorVersion: UInt64
    public let metrics: BuildOperationTaskMetrics?

    public init(
        identifier: String,
        majorVersion: UInt64,
        minorVersion: UInt64,
        metrics: BuildOperationTaskMetrics?
    ) throws {
        self.identifier = identifier
        self.majorVersion = majorVersion
        self.minorVersion = minorVersion
        self.metrics = metrics
    }
}
