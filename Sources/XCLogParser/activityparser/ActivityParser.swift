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

/// Parses an xcactivitylog into a Swift representation
/// Used by the Dump command
// swiftlint:disable type_body_length
// swiftlint:disable file_length
public class ActivityParser {

    /// Some IDEActivitlyLog have an extra int at the end
    /// This flag is turn on if is the case, so the parse will take
    /// that into account
    var isCommandLineLog = false

    public init() {}

    /// Parses the xcacticitylog argument into a `IDEActivityLog`
    /// - parameter logURL: `URL` of the xcactivitylog
    /// - parameter redacted: If true, the username will be replaced
    /// in the file paths inside the logs for the word `redacted`.
    /// This flag is useful to preserve the privacy of the users.
    /// - parameter withoutBuildSpecificInformation: If true, build specific
    /// information will be removed from the logs (for example `bolnckhlbzxpxoeyfujluasoupft`
    /// will be removed from  `DerivedData/Product-bolnckhlbzxpxoeyfujluasoupft/Build`).
    /// This flag is useful for grouping logs by its content.
    /// - returns: An instance of `IDEActivityLog1
    /// - throws: An Error if the file is not valid.
    public func parseActivityLogInURL(_ logURL: URL,
                                      redacted: Bool,
                                      withoutBuildSpecificInformation: Bool) throws -> IDEActivityLog {
        let tokens = try getTokens(logURL, redacted: redacted,
                                   withoutBuildSpecificInformation: withoutBuildSpecificInformation)
        return try parseIDEActiviyLogFromTokens(tokens)
    }

    public func parseIDEActiviyLogFromTokens(_ tokens: [Token]) throws -> IDEActivityLog {
        var iterator = tokens.makeIterator()
        return IDEActivityLog(version: Int8(try parseAsInt(token: iterator.next())),
                              mainSection: try parseLogSection(iterator: &iterator))
    }

    public func parseDVTTextDocumentLocation(iterator: inout IndexingIterator<[Token]>)
        throws -> DVTTextDocumentLocation {
        return DVTTextDocumentLocation(documentURLString: try parseAsString(token: iterator.next()),
                                       timestamp: try parseAsDouble(token: iterator.next()),
                                       startingLineNumber: try parseAsInt(token: iterator.next()),
                                       startingColumnNumber: try parseAsInt(token: iterator.next()),
                                       endingLineNumber: try parseAsInt(token: iterator.next()),
                                       endingColumnNumber: try parseAsInt(token: iterator.next()),
                                       characterRangeEnd: try parseAsInt(token: iterator.next()),
                                       characterRangeStart: try parseAsInt(token: iterator.next()),
                                       locationEncoding: try parseAsInt(token: iterator.next()))
    }

    public func parseDVTDocumentLocation(iterator: inout IndexingIterator<[Token]>) throws -> DVTDocumentLocation {
        return DVTDocumentLocation(documentURLString: try parseAsString(token: iterator.next()),
                                       timestamp: try parseAsDouble(token: iterator.next()))
    }

    public func parseIDEActivityLogMessage(iterator: inout IndexingIterator<[Token]>) throws -> IDEActivityLogMessage {
        return IDEActivityLogMessage(title: try parseAsString(token: iterator.next()),
                                     shortTitle: try parseAsString(token: iterator.next()),
                                     timeEmitted: try Double(parseAsInt(token: iterator.next())),
                                     rangeEndInSectionText: try parseAsInt(token: iterator.next()),
                                     rangeStartInSectionText: try parseAsInt(token: iterator.next()),
                                     subMessages: try parseMessages(iterator: &iterator),
                                     severity: Int(try parseAsInt(token: iterator.next())),
                                     type: try parseAsString(token: iterator.next()),
                                     location: try parseDocumentLocation(iterator: &iterator),
                                     categoryIdent: try parseAsString(token: iterator.next()),
                                     secondaryLocations: try parseDocumentLocations(iterator: &iterator),
                                     additionalDescription: try parseAsString(token: iterator.next()))
    }

    public func parseIDEActivityLogSection(iterator: inout IndexingIterator<[Token]>)
        throws -> IDEActivityLogSection {
        return IDEActivityLogSection(sectionType: Int8(try parseAsInt(token: iterator.next())),
                                     domainType: try parseAsString(token: iterator.next()),
                                     title: try parseAsString(token: iterator.next()),
                                     signature: try parseAsString(token: iterator.next()),
                                     timeStartedRecording: try parseAsDouble(token: iterator.next()),
                                     timeStoppedRecording: try parseAsDouble(token: iterator.next()),
                                     subSections: try parseIDEActivityLogSections(iterator: &iterator),
                                     text: try parseAsString(token: iterator.next()),
                                     messages: try parseMessages(iterator: &iterator),
                                     wasCancelled: try parseBoolean(token: iterator.next()),
                                     isQuiet: try parseBoolean(token: iterator.next()),
                                     wasFetchedFromCache: try parseBoolean(token: iterator.next()),
                                     subtitle: try parseAsString(token: iterator.next()),
                                     location: try parseDocumentLocation(iterator: &iterator),
                                     commandDetailDesc: try parseAsString(token: iterator.next()),
                                     uniqueIdentifier: try parseAsString(token: iterator.next()),
                                     localizedResultString: try parseAsString(token: iterator.next()),
                                     xcbuildSignature: try parseAsString(token: iterator.next()),
                                     attachments: try parseIDEActivityLogSectionAttachments(iterator: &iterator),
                                     unknown: isCommandLineLog ? Int(try parseAsInt(token: iterator.next())) : 0)
    }

    public func parseIDEActivityLogUnitTestSection(iterator: inout IndexingIterator<[Token]>)
        throws -> IDEActivityLogUnitTestSection {
            return IDEActivityLogUnitTestSection(sectionType: Int8(try parseAsInt(token: iterator.next())),
                                         domainType: try parseAsString(token: iterator.next()),
                                         title: try parseAsString(token: iterator.next()),
                                         signature: try parseAsString(token: iterator.next()),
                                         timeStartedRecording: try parseAsDouble(token: iterator.next()),
                                         timeStoppedRecording: try parseAsDouble(token: iterator.next()),
                                         subSections: try parseIDEActivityLogSections(iterator: &iterator),
                                         text: try parseAsString(token: iterator.next()),
                                         messages: try parseMessages(iterator: &iterator),
                                         wasCancelled: try parseBoolean(token: iterator.next()),
                                         isQuiet: try parseBoolean(token: iterator.next()),
                                         wasFetchedFromCache: try parseBoolean(token: iterator.next()),
                                         subtitle: try parseAsString(token: iterator.next()),
                                         location: try parseDocumentLocation(iterator: &iterator),
                                         commandDetailDesc: try parseAsString(token: iterator.next()),
                                         uniqueIdentifier: try parseAsString(token: iterator.next()),
                                         localizedResultString: try parseAsString(token: iterator.next()),
                                         xcbuildSignature: try parseAsString(token: iterator.next()),
                                         attachments: try parseIDEActivityLogSectionAttachments(iterator: &iterator),
                                         unknown: isCommandLineLog ? Int(try parseAsInt(token: iterator.next())) : 0,
                                         testsPassedString: try parseAsString(token: iterator.next()),
                                         durationString: try parseAsString(token: iterator.next()),
                                         summaryString: try parseAsString(token: iterator.next()),
                                         suiteName: try parseAsString(token: iterator.next()),
                                         testName: try parseAsString(token: iterator.next()),
                                         performanceTestOutputString: try parseAsString(token: iterator.next()))
    }

    public func parseDBGConsoleLog(iterator: inout IndexingIterator<[Token]>)
        throws -> DBGConsoleLog {
            return DBGConsoleLog(sectionType: Int8(try parseAsInt(token: iterator.next())),
                                                 domainType: try parseAsString(token: iterator.next()),
                                                 title: try parseAsString(token: iterator.next()),
                                                 signature: try parseAsString(token: iterator.next()),
                                                 timeStartedRecording: try parseAsDouble(token: iterator.next()),
                                                 timeStoppedRecording: try parseAsDouble(token: iterator.next()),
                                                 subSections: try parseIDEActivityLogSections(iterator: &iterator),
                                                 text: try parseAsString(token: iterator.next()),
                                                 messages: try parseMessages(iterator: &iterator),
                                                 wasCancelled: try parseBoolean(token: iterator.next()),
                                                 isQuiet: try parseBoolean(token: iterator.next()),
                                                 wasFetchedFromCache: try parseBoolean(token: iterator.next()),
                                                 subtitle: try parseAsString(token: iterator.next()),
                                                 location: try parseDocumentLocation(iterator: &iterator),
                                                 commandDetailDesc: try parseAsString(token: iterator.next()),
                                                 uniqueIdentifier: try parseAsString(token: iterator.next()),
                                                 localizedResultString: try parseAsString(token: iterator.next()),
                                                 xcbuildSignature: try parseAsString(token: iterator.next()),
                                                 // swiftlint:disable:next line_length
                                                 attachments: try parseIDEActivityLogSectionAttachments(iterator: &iterator),
                                                 // swiftlint:disable:next line_length
                                                 unknown: isCommandLineLog ? Int(try parseAsInt(token: iterator.next())) : 0,
                                                 logConsoleItems: try parseIDEConsoleItems(iterator: &iterator)
                                                 )
    }

    public func parseIDEActivityLogAnalyzerResultMessage(iterator: inout IndexingIterator<[Token]>) throws
        -> IDEActivityLogAnalyzerResultMessage {
        return IDEActivityLogAnalyzerResultMessage(
                                     title: try parseAsString(token: iterator.next()),
                                     shortTitle: try parseAsString(token: iterator.next()),
                                     timeEmitted: try Double(parseAsInt(token: iterator.next())),
                                     rangeEndInSectionText: try parseAsInt(token: iterator.next()),
                                     rangeStartInSectionText: try parseAsInt(token: iterator.next()),
                                     subMessages: try parseMessages(iterator: &iterator),
                                     severity: Int(try parseAsInt(token: iterator.next())),
                                     type: try parseAsString(token: iterator.next()),
                                     location: try parseDocumentLocation(iterator: &iterator),
                                     categoryIdent: try parseAsString(token: iterator.next()),
                                     secondaryLocations: try parseDocumentLocations(iterator: &iterator),
                                     additionalDescription: try parseAsString(token: iterator.next()),
                                     resultType: try parseAsString(token: iterator.next()),
                                     keyEventIndex: try parseAsInt(token: iterator.next()))
    }

    public func parseIDEActivityLogAnalyzerEventStepMessage(iterator: inout IndexingIterator<[Token]>) throws
        -> IDEActivityLogAnalyzerEventStepMessage {
        return IDEActivityLogAnalyzerEventStepMessage(
                                     title: try parseAsString(token: iterator.next()),
                                     shortTitle: try parseAsString(token: iterator.next()),
                                     timeEmitted: try Double(parseAsInt(token: iterator.next())),
                                     rangeEndInSectionText: try parseAsInt(token: iterator.next()),
                                     rangeStartInSectionText: try parseAsInt(token: iterator.next()),
                                     subMessages: try parseMessages(iterator: &iterator),
                                     severity: Int(try parseAsInt(token: iterator.next())),
                                     type: try parseAsString(token: iterator.next()),
                                     location: try parseDocumentLocation(iterator: &iterator),
                                     categoryIdent: try parseAsString(token: iterator.next()),
                                     secondaryLocations: try parseDocumentLocations(iterator: &iterator),
                                     additionalDescription: try parseAsString(token: iterator.next()),
                                     parentIndex: try parseAsInt(token: iterator.next()),
                                     description: try parseAsString(token: iterator.next()),
                                     callDepth: try parseAsInt(token: iterator.next()))
    }

    public func parseIDEActivityLogAnalyzerControlFlowStepMessage(iterator: inout IndexingIterator<[Token]>) throws
        -> IDEActivityLogAnalyzerControlFlowStepMessage {
        return IDEActivityLogAnalyzerControlFlowStepMessage(
                                     title: try parseAsString(token: iterator.next()),
                                     shortTitle: try parseAsString(token: iterator.next()),
                                     timeEmitted: try Double(parseAsInt(token: iterator.next())),
                                     rangeEndInSectionText: try parseAsInt(token: iterator.next()),
                                     rangeStartInSectionText: try parseAsInt(token: iterator.next()),
                                     subMessages: try parseMessages(iterator: &iterator),
                                     severity: Int(try parseAsInt(token: iterator.next())),
                                     type: try parseAsString(token: iterator.next()),
                                     location: try parseDocumentLocation(iterator: &iterator),
                                     categoryIdent: try parseAsString(token: iterator.next()),
                                     secondaryLocations: try parseDocumentLocations(iterator: &iterator),
                                     additionalDescription: try parseAsString(token: iterator.next()),
                                     parentIndex: try parseAsInt(token: iterator.next()),
                                     endLocation: try parseDocumentLocation(iterator: &iterator),
                                     edges: try parseStepEdges(iterator: &iterator))
    }

    public func parseIDEActivityLogAnalyzerControlFlowStepEdge(iterator: inout IndexingIterator<[Token]>) throws
        -> IDEActivityLogAnalyzerControlFlowStepEdge {
        return IDEActivityLogAnalyzerControlFlowStepEdge(
                                     startLocation: try parseDocumentLocation(iterator: &iterator),
                                     endLocation: try parseDocumentLocation(iterator: &iterator))
    }

    public func parseIDEActivityLogActionMessage(iterator: inout IndexingIterator<[Token]>) throws
        -> IDEActivityLogActionMessage {
        return IDEActivityLogActionMessage(
                                     title: try parseAsString(token: iterator.next()),
                                     shortTitle: try parseAsString(token: iterator.next()),
                                     timeEmitted: try Double(parseAsInt(token: iterator.next())),
                                     rangeEndInSectionText: try parseAsInt(token: iterator.next()),
                                     rangeStartInSectionText: try parseAsInt(token: iterator.next()),
                                     subMessages: try parseMessages(iterator: &iterator),
                                     severity: Int(try parseAsInt(token: iterator.next())),
                                     type: try parseAsString(token: iterator.next()),
                                     location: try parseDocumentLocation(iterator: &iterator),
                                     categoryIdent: try parseAsString(token: iterator.next()),
                                     secondaryLocations: try parseDocumentLocations(iterator: &iterator),
                                     additionalDescription: try parseAsString(token: iterator.next()),
                                     action: try parseAsString(token: iterator.next()))
    }

    private func getTokens(_ logURL: URL,
                           redacted: Bool,
                           withoutBuildSpecificInformation: Bool) throws -> [Token] {
        let logLoader = LogLoader()
        var tokens: [Token] = []
        #if os(Linux)
        let content = try logLoader.loadFromURL(logURL)
        let lexer = Lexer(filePath: logURL.path)
        tokens = try lexer.tokenize(contents: content,
                                        redacted: redacted,
                                        withoutBuildSpecificInformation: withoutBuildSpecificInformation)
        #else
        try autoreleasepool {
            let content = try logLoader.loadFromURL(logURL)
            let lexer = Lexer(filePath: logURL.path)
            tokens = try lexer.tokenize(contents: content,
                                            redacted: redacted,
                                            withoutBuildSpecificInformation: withoutBuildSpecificInformation)
        }
        #endif
        return tokens
    }

    private func parseMessages(iterator: inout IndexingIterator<[Token]>) throws -> [IDEActivityLogMessage] {
        guard let listToken = iterator.next() else {
            throw XCLogParserError.parseError("Parsing [IDEActivityLogMessage]")
        }
        switch listToken {
        case .null:
            return []
        case .list(let count):
            var messages = [IDEActivityLogMessage]()
            for _ in 0..<count {
                let message = try parseLogMessage(iterator: &iterator)
                messages.append(message)
            }
            return messages
        default:
            throw XCLogParserError.parseError("Unexpected token parsing array of IDEActivityLogMessage \(listToken)")
        }
    }

    private func parseDocumentLocations(iterator: inout IndexingIterator<[Token]>) throws -> [DVTDocumentLocation] {
        guard let listToken = iterator.next() else {
            throw XCLogParserError.parseError("Unexpected EOF parsing [DocumentLocation]")
        }
        switch listToken {
        case .null:
            return []
        case .list(let count):
            var locations = [DVTDocumentLocation]()
            for _ in 0..<count {
                let location = try parseDocumentLocation(iterator: &iterator)
                locations.append(location)
            }
            return locations
        default:
            throw XCLogParserError.parseError("Unexpected token parsing array of DocumentLocation \(listToken)")
        }
    }

    public func parseDocumentLocation(iterator: inout IndexingIterator<[Token]>) throws -> DVTDocumentLocation {
        let classRefToken = try getClassRefToken(iterator: &iterator)
        if case Token.null = classRefToken {
            return DVTDocumentLocation(documentURLString: "", timestamp: 0.0)
        }
        guard case Token.classNameRef(let className) = classRefToken else {
            throw XCLogParserError.parseError("Unexpected token found parsing DocumentLocation \(classRefToken)")
        }
        if className == String(describing: DVTTextDocumentLocation.self) {
            return try parseDVTTextDocumentLocation(iterator: &iterator)
        } else if className == String(describing: DVTDocumentLocation.self)  ||
            className == "Xcode3ProjectDocumentLocation" || className == "IDELogDocumentLocation" {
            return try parseDVTDocumentLocation(iterator: &iterator)
        } else if className == String(describing: IBDocumentMemberLocation.self) {
            return try parseIBDocumentMemberLocation(iterator: &iterator)
        } else if className == String(describing: DVTMemberDocumentLocation.self) {
            return try parseDVTMemberDocumentLocation(iterator: &iterator)
        }
        throw XCLogParserError.parseError("Unexpected className found parsing DocumentLocation \(className)")
    }

    private func parseLogMessage(iterator: inout IndexingIterator<[Token]>) throws -> IDEActivityLogMessage {
        let classRefToken = try getClassRefToken(iterator: &iterator)
        guard
            case Token.classNameRef(let className) = classRefToken
        else {
            throw XCLogParserError.parseError("Unexpected token found parsing IDEActivityLogMessage \(classRefToken)")
        }
        if className == String(describing: IDEActivityLogMessage.self) ||
            className == "IDEClangDiagnosticActivityLogMessage" ||
            className == "IDEDiagnosticActivityLogMessage" {
            return try parseIDEActivityLogMessage(iterator: &iterator)
        }
        if className ==  String(describing: IDEActivityLogAnalyzerResultMessage.self) {
            return try parseIDEActivityLogAnalyzerResultMessage(iterator: &iterator)
        }
        if className ==  String(describing: IDEActivityLogAnalyzerControlFlowStepMessage.self) {
            return try parseIDEActivityLogAnalyzerControlFlowStepMessage(iterator: &iterator)
        }
        if className == String(describing: IDEActivityLogAnalyzerEventStepMessage.self) {
            return try parseIDEActivityLogAnalyzerEventStepMessage(iterator: &iterator)
        }
        if className == String(describing: IDEActivityLogActionMessage.self) {
            return try parseIDEActivityLogActionMessage(iterator: &iterator)
        }
        throw XCLogParserError.parseError("Unexpected className found parsing IDEActivityLogMessage \(className)")
    }

    private func parseLogSectionAttachment(iterator: inout IndexingIterator<[Token]>)
        throws -> IDEActivityLogSectionAttachment {
            let classRefToken = try getClassRefToken(iterator: &iterator)
            guard case Token.classNameRef(let className) = classRefToken else {
                throw XCLogParserError.parseError("Unexpected token found parsing " +
                                                  "IDEActivityLogSectionAttachment \(classRefToken)")
            }

            if className == "IDEFoundation.\(String(describing: IDEActivityLogSectionAttachment.self))" {
                let jsonType = IDEActivityLogSectionAttachment.BuildOperationTaskMetrics.self
                return try IDEActivityLogSectionAttachment(identifier: try parseAsString(token: iterator.next()),
                                                           majorVersion: try parseAsInt(token: iterator.next()),
                                                           minorVersion: try parseAsInt(token: iterator.next()),
                                                           metrics: try parseAsJson(token: iterator.next(),
                                                                                    type: jsonType))
            }
            throw XCLogParserError.parseError("Unexpected className found parsing IDEConsoleItem \(className)")
    }

    private func parseLogSection(iterator: inout IndexingIterator<[Token]>)
        throws -> IDEActivityLogSection {
        var classRefToken = try getClassRefToken(iterator: &iterator)
        // if we found and extra int field, we should treat this as an commandLineLog
        if case Token.int(_) = classRefToken {
            isCommandLineLog = true
            classRefToken = try getClassRefToken(iterator: &iterator)
        }
        guard
            case Token.classNameRef(let className) = classRefToken
            else {
                throw XCLogParserError.parseError("Unexpected token found parsing " +
                                                  "IDEActivityLogSection \(classRefToken)")
        }
        if className == String(describing: IDEActivityLogSection.self) {
            return try parseIDEActivityLogSection(iterator: &iterator)
        }
        if className == "IDECommandLineBuildLog" ||
            className == "IDEActivityLogMajorGroupSection" ||
            className == "IDEActivityLogCommandInvocationSection" {
            return try parseIDEActivityLogSection(iterator: &iterator)
        }
        if className == "IDEActivityLogUnitTestSection" {
            return try parseIDEActivityLogUnitTestSection(iterator: &iterator)
        }
        if className == String(describing: DBGConsoleLog.self) {
            return try parseDBGConsoleLog(iterator: &iterator)
        }
        throw XCLogParserError.parseError("Unexpected className found parsing IDEActivityLogSection \(className)")
    }

    private func getClassRefToken(iterator: inout IndexingIterator<[Token]>) throws -> Token {
        guard let classRefToken = iterator.next() else {
            throw XCLogParserError.parseError("Unexpected EOF parsing ClassRef")
        }
        // The first time there is a classRef of an specific Type,
        // There is a className before that defines the Type
        if case Token.className = classRefToken {
            guard let classRefToken = iterator.next() else {
                throw XCLogParserError.parseError("Unexpected EOF parsing ClassRef")
            }
            if case Token.classNameRef = classRefToken {
                return classRefToken
            } else {
                throw XCLogParserError.parseError("Unexpected EOF parsing ClassRef: \(classRefToken)")
            }

        }
        return classRefToken
    }

    private func parseIDEActivityLogSections(iterator: inout IndexingIterator<[Token]>)
        throws -> [IDEActivityLogSection] {
            guard let listToken = iterator.next() else {
                throw XCLogParserError.parseError("Unexpected EOF parsing array of IDEActivityLogSection")
            }
            switch listToken {
            case .null:
                return []
            case .list(let count):
                var sections = [IDEActivityLogSection]()
                for _ in 0..<count {
                    let section = try parseLogSection(iterator: &iterator)
                    sections.append(section)
                }
                return sections
            default:
                throw XCLogParserError.parseError("Unexpected token parsing array of " +
                                                  "IDEActivityLogSection: \(listToken)")
            }
    }

    private func parseIDEActivityLogSectionAttachments(iterator: inout IndexingIterator<[Token]>)
        throws -> [IDEActivityLogSectionAttachment] {
            guard let listToken = iterator.next() else {
                throw XCLogParserError.parseError("Unexpected EOF parsing array of IDEActivityLogSectionAttachment")
            }
            switch listToken {
            case .null:
                return []
            case .list(let count):
                var sections = [IDEActivityLogSectionAttachment]()
                for _ in 0..<count {
                    let section = try parseLogSectionAttachment(iterator: &iterator)
                    sections.append(section)
                }
                return sections
            default:
                throw XCLogParserError.parseError("Unexpected token parsing array of " +
                                                  "IDEActivityLogSectionAttachment: \(listToken)")
            }
    }

    private func parseIDEConsoleItem(iterator: inout IndexingIterator<[Token]>)
        throws -> IDEConsoleItem? {
            let classRefToken = try getClassRefToken(iterator: &iterator)
            if case Token.null = classRefToken {
               return nil
            }
            guard case Token.classNameRef(let className) = classRefToken else {
                throw XCLogParserError.parseError("Unexpected token found parsing IDEConsoleItem \(classRefToken)")
            }

            if className == String(describing: IDEConsoleItem.self) {
                return IDEConsoleItem(adaptorType: try parseAsInt(token: iterator.next()),
                                      content: try parseAsString(token: iterator.next()),
                                      kind: try parseAsInt(token: iterator.next()),
                                      timestamp: try parseAsDouble(token: iterator.next()))
            }
            throw XCLogParserError.parseError("Unexpected className found parsing IDEConsoleItem \(className)")
    }

    private func parseIDEConsoleItems(iterator: inout IndexingIterator<[Token]>) throws -> [IDEConsoleItem] {
        guard let listToken = iterator.next() else {
            throw XCLogParserError.parseError("Unexpected EOF parsing array of IDEConsoleItem")
        }
        switch listToken {
        case .null:
            return []
        case .list(let count):
            var items = [IDEConsoleItem]()
            for _ in 0..<count {
                if let item = try parseIDEConsoleItem(iterator: &iterator) {
                    items.append(item)
                }
            }
            return items
        default:
            throw XCLogParserError.parseError("Unexpected token parsing array of IDEConsoleItem: \(listToken)")
        }
    }

    private func parseStepEdge(iterator: inout IndexingIterator<[Token]>)
        throws -> IDEActivityLogAnalyzerControlFlowStepEdge {
        let classRefToken = try getClassRefToken(iterator: &iterator)
        guard case Token.classNameRef(let className) = classRefToken else {
            throw XCLogParserError.parseError("Unexpected token found parsing " +
                "IDEActivityLogAnalyzerControlFlowStepEdge \(classRefToken)")
        }

        if className == String(describing: IDEActivityLogAnalyzerControlFlowStepEdge.self) {
            return try parseIDEActivityLogAnalyzerControlFlowStepEdge(iterator: &iterator)
        }
        throw XCLogParserError.parseError("Unexpected className found parsing " +
            "IDEActivityLogAnalyzerControlFlowStepEdge \(className)")
    }

    private func parseStepEdges(iterator: inout IndexingIterator<[Token]>)
        throws -> [IDEActivityLogAnalyzerControlFlowStepEdge] {
        guard let listToken = iterator.next() else {
            throw XCLogParserError.parseError("Unexpected EOF parsing array of IDEConsoleItem")
        }
        switch listToken {
        case .null:
            return []
        case .list(let count):
            var items = [IDEActivityLogAnalyzerControlFlowStepEdge]()
            for _ in 0..<count {
                items.append(try parseStepEdge(iterator: &iterator))
            }
            return items
        default:
            throw XCLogParserError.parseError("Unexpected token parsing array of IDEConsoleItem: \(listToken)")
        }
    }

    private func parseIBDocumentMemberLocation(iterator: inout IndexingIterator<[Token]>)
        throws -> IBDocumentMemberLocation {
            return IBDocumentMemberLocation(documentURLString: try parseAsString(token: iterator.next()),
                                            timestamp: try parseAsDouble(token: iterator.next()),
                                            memberIdentifier: try parseIBMemberID(iterator: &iterator),
                                            attributeSearchLocation:
                                                try parseIBAttributeSearchLocation(iterator: &iterator))
    }

    private func parseIBMemberID(iterator: inout IndexingIterator<[Token]>)
        throws -> IBMemberID {
        let classRefToken = try getClassRefToken(iterator: &iterator)
        guard case Token.classNameRef(let className) = classRefToken else {
            throw XCLogParserError.parseError("Unexpected token found parsing " +
                "IBMemberID \(classRefToken)")
        }

        if className == String(describing: IBMemberID.self) {
            return IBMemberID(memberIdentifier: try parseAsString(token: iterator.next()))
        }
        throw XCLogParserError.parseError("Unexpected className found parsing " +
            "IBMemberID \(className)")
    }

    private func parseIBAttributeSearchLocation(iterator: inout IndexingIterator<[Token]>)
        throws -> IBAttributeSearchLocation? {
            guard let nextToken = iterator.next() else {
                throw XCLogParserError.parseError("Unexpected EOF parsing IBAttributeSearchLocation")
            }
            if case Token.null = nextToken {
                return nil
            }
            throw XCLogParserError.parseError("Unexpected Token parsing IBAttributeSearchLocation: \(nextToken)")
    }

    private func parseAsString(token: Token?) throws -> String {
        guard let token = token else {
            throw XCLogParserError.parseError("Unexpected EOF parsing String")
        }
        switch token {
        case .string(let string):
            return string.trimmingCharacters(in: .whitespacesAndNewlines)
        case .null:
            return ""
        default:
            throw XCLogParserError.parseError("Unexpected token parsing String: \(token)")
        }
    }

    private func parseAsJson<T: Decodable>(token: Token?, type: T.Type) throws -> T? {
        guard let token = token else {
            throw XCLogParserError.parseError("Unexpected EOF parsing JSON String")
        }
        switch token {
        case .json(let string):
            guard let data = string.data(using: .utf8) else {
                throw XCLogParserError.parseError("Unexpected JSON string \(string)")
            }
            return try JSONDecoder().decode(type, from: data)
        case .null:
            return nil
        default:
            throw XCLogParserError.parseError("Unexpected token parsing JSON String: \(token)")
        }
    }

    private func parseAsInt(token: Token?) throws -> UInt64 {
        guard let token = token else {
            throw XCLogParserError.parseError("Unexpected EOF parsing Int")
        }
        if case Token.int(let value) = token {
            return value
        }
        throw XCLogParserError.parseError("Unexpected token parsing Int: \(token))")
    }

    private func parseAsDouble(token: Token?) throws -> Double {
        guard let token = token else {
            throw XCLogParserError.parseError("Unexpected EOF parsing Double")
        }
        if case Token.double(let value) = token {
            return value
        }
        throw XCLogParserError.parseError("Unexpected token parsing Double: \(token)")
    }

    private func parseBoolean(token: Token?) throws -> Bool {
        guard let token = token else {
            throw XCLogParserError.parseError("Unexpected EOF parsing Bool")
        }
        if case Token.int(let value) = token {
            if value > 1 {
                throw XCLogParserError.parseError("Unexpected value parsing Bool: \(value)")
            }
            return value == 1
        }
        throw XCLogParserError.parseError("Unexpected token parsing Bool: \(token)")
    }

    private func parseDVTMemberDocumentLocation(iterator: inout IndexingIterator<[Token]>)
    throws -> DVTMemberDocumentLocation {
        return DVTMemberDocumentLocation(documentURLString: try parseAsString(token: iterator.next()),
                                         timestamp: try parseAsDouble(token: iterator.next()),
                                         member: try parseAsString(token: iterator.next()))
    }

}
