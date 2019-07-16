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
public class ActivityParser {

    /// Some IDEActivitlyLog have an extra int at the end
    /// This flag is turn on if is the case, so the parse will take
    /// that into account
    var isCommandLineLog = false

    /// Parses the xcacticitylog argument into a `IDEActivityLog`
    /// - parameter logURL: `URL` of the xcactivitylog
    /// - parameter redacted: If true, the username will be replaced
    /// in the file paths inside the logs for the word `redacted`.
    /// This flag is iseful to preserve the privacy of the users.
    /// - returns: An instance of `IDEActivityLog1
    /// - throws: An Error if the file is not valid.
    public func parseActivityLogInURL(_ logURL: URL, redacted: Bool) throws -> IDEActivityLog {
        let logLoader = LogLoader()
        let content = try logLoader.loadFromURL(logURL)
        let lexer = Lexer(filePath: logURL.path)
        let tokens = try lexer.tokenize(contents: content, redacted: redacted)
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
                                                 unknown: isCommandLineLog ? Int(try parseAsInt(token: iterator.next())) : 0,
                                                 logConsoleItems: try parseIDEConsoleItems(iterator: &iterator)
                                                 )
    }

    private func parseMessages(iterator: inout IndexingIterator<[Token]>) throws -> [IDEActivityLogMessage] {
        guard let listToken = iterator.next() else {
            throw Error.parseError("Parsing [IDEActivityLogMessage]")
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
            throw Error.parseError("Unexpected token parsing array of IDEActivityLogMessage \(listToken)")
        }
    }

    private func parseDocumentLocations(iterator: inout IndexingIterator<[Token]>) throws -> [DVTDocumentLocation] {
        guard let listToken = iterator.next() else {
            throw Error.parseError("Unexpected EOF parsing [DocumentLocation]")
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
            throw Error.parseError("Unexpected token parsing array of DocumentLocation \(listToken)")
        }
    }

    private func parseDocumentLocation(iterator: inout IndexingIterator<[Token]>) throws -> DVTDocumentLocation {
        let classRefToken = try getClassRefToken(iterator: &iterator)
        if case Token.null = classRefToken {
            return DVTDocumentLocation(documentURLString: "", timestamp: 0.0)
        }
        guard case Token.classNameRef(let className) = classRefToken else {
            throw Error.parseError("Unexpected token found parsing DocumentLocation \(classRefToken)")
        }
        if className == String(describing: DVTTextDocumentLocation.self) {
            return try parseDVTTextDocumentLocation(iterator: &iterator)
        } else if className == String(describing: DVTDocumentLocation.self) {
            return try parseDVTDocumentLocation(iterator: &iterator)
        }
        throw Error.parseError("Unexpected className found parsing DocumentLocation \(className)")
    }

    private func parseLogMessage(iterator: inout IndexingIterator<[Token]>) throws -> IDEActivityLogMessage {
        let classRefToken = try getClassRefToken(iterator: &iterator)
        guard
            case Token.classNameRef(let className) = classRefToken
        else {
            throw Error.parseError("Unexpected token found parsing IDEActivityLogMessage \(classRefToken)")
        }
        if className == String(describing: IDEActivityLogMessage.self) ||
           className == "IDEClangDiagnosticActivityLogMessage" {
            return try parseIDEActivityLogMessage(iterator: &iterator)
        }
        throw Error.parseError("Unexpected className found parsing IDEActivityLogMessage \(className)")
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
                throw Error.parseError("Unexpected token found parsing IDEActivityLogSection \(classRefToken)")
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
        throw Error.parseError("Unexpected className found parsing IDEActivityLogSection \(className)")
    }

    private func getClassRefToken(iterator: inout IndexingIterator<[Token]>) throws -> Token {
        guard let classRefToken = iterator.next() else {
            throw Error.parseError("Unexpected EOF parsing ClassRef")
        }
        //The first time there is a classRef of an specific Type,
        //There is a className before that defines the Type
        if case Token.className = classRefToken {
            guard let classRefToken = iterator.next() else {
                throw Error.parseError("Unexpected EOF parsing ClassRef")
            }
            if case Token.classNameRef = classRefToken {
                return classRefToken
            } else {
                throw Error.parseError("Unexpected EOF parsing ClassRef: \(classRefToken)")
            }

        }
        return classRefToken
    }

    private func parseIDEActivityLogSections(iterator: inout IndexingIterator<[Token]>)
        throws -> [IDEActivityLogSection] {
            guard let listToken = iterator.next() else {
                throw Error.parseError("Unexpected EOF parsing array of IDEActivityLogSection")
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
                throw Error.parseError("Unexpected token parsing array of IDEActivityLogSection: \(listToken)")
            }
    }

    private func parseIDEConsoleItem(iterator: inout IndexingIterator<[Token]>)
        throws -> IDEConsoleItem? {
            let classRefToken = try getClassRefToken(iterator: &iterator)
            if case Token.null = classRefToken {
               return nil
            }
            guard case Token.classNameRef(let className) = classRefToken else {
                throw Error.parseError("Unexpected token found parsing IDEConsoleItem \(classRefToken)")
            }

            if className == String(describing: IDEConsoleItem.self) {
                return IDEConsoleItem(adaptorType: try parseAsInt(token: iterator.next()),
                                      content: try parseAsString(token: iterator.next()),
                                      kind: try parseAsInt(token: iterator.next()),
                                      timestamp: try parseAsDouble(token: iterator.next()))
            }
            throw Error.parseError("Unexpected className found parsing IDEConsoleItem \(className)")
    }

    private func parseIDEConsoleItems(iterator: inout IndexingIterator<[Token]>)
        throws -> [IDEConsoleItem] {
            guard let listToken = iterator.next() else {
                throw Error.parseError("Unexpected EOF parsing array of IDEConsoleItem")
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
                throw Error.parseError("Unexpected token parsing array of IDEConsoleItem: \(listToken)")
            }
    }

    private func parseAsString(token: Token?) throws -> String {
        guard let token = token else {
            throw Error.parseError("Unexpected EOF parsing String")
        }
        switch token {
        case .string(let string):
            return string
        case .null:
            return ""
        default:
            throw Error.parseError("Unexpected token parsing String: \(token)")
        }
    }

    private func parseAsInt(token: Token?) throws -> UInt64 {
        guard let token = token else {
            throw Error.parseError("Unexpected EOF parsing Int")
        }
        if case Token.int(let value) = token {
            return value
        }
        throw Error.parseError("Unexpected token parsing Int: \(token))")
    }

    private func parseAsDouble(token: Token?) throws -> Double {
        guard let token = token else {
            throw Error.parseError("Unexpected EOF parsing Double")
        }
        if case Token.double(let value) = token {
            return value
        }
        throw Error.parseError("Unexpected token parsing Double: \(token)")
    }

    private func parseBoolean(token: Token?) throws -> Bool {
        guard let token = token else {
            throw Error.parseError("Unexpected EOF parsing Bool")
        }
        if case Token.int(let value) = token {
            if value > 1 {
                throw Error.parseError("Unexpected value parsing Bool: \(value)")
            }
            return value == 1
        }
        throw Error.parseError("Unexpected token parsing Bool: \(token)")
    }

}
