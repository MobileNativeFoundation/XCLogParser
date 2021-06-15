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

/// Xcode reports warnings, errors and notes as IDEActivityLogMessage. This class
/// wraps that data
public class Notice: Codable {

    public let type: NoticeType
    public let title: String
    public let clangFlag: String?
    public let documentURL: String
    public let severity: Int
    public let startingLineNumber: UInt64
    public let endingLineNumber: UInt64
    public let startingColumnNumber: UInt64
    public let endingColumnNumber: UInt64
    public let characterRangeEnd: UInt64
    public let characterRangeStart: UInt64
    public let interfaceBuilderIdentifier: String?
    public let detail: String?

    static var clangWarningRegexp: NSRegularExpression? = {
        let pattern = "\\[(-W[\\w-,]*)\\]+"
        return NSRegularExpression.fromPattern(pattern)
    }()

    /// Public initializer 
    public init(type: NoticeType,
                title: String,
                clangFlag: String?,
                documentURL: String,
                severity: Int,
                startingLineNumber: UInt64,
                endingLineNumber: UInt64,
                startingColumnNumber: UInt64,
                endingColumnNumber: UInt64,
                characterRangeEnd: UInt64,
                characterRangeStart: UInt64,
                interfaceBuilderIdentifier: String? = nil,
                detail: String? = nil) {
        self.type = type
        self.title = title
        self.clangFlag = clangFlag
        self.documentURL = documentURL
        self.severity = severity
        self.startingLineNumber = startingLineNumber
        self.endingLineNumber = endingLineNumber
        self.startingColumnNumber = startingColumnNumber
        self.endingColumnNumber = endingColumnNumber
        self.characterRangeEnd = characterRangeEnd
        self.characterRangeStart = characterRangeStart
        self.interfaceBuilderIdentifier = interfaceBuilderIdentifier
        self.detail = detail
    }

    public init?(withType type: NoticeType?,
                 logMessage: IDEActivityLogMessage,
                 clangFlag: String? = nil,
                 detail: String? = nil) {
        guard let type = type else {
            return nil
        }
        if let location = logMessage.location as? IBDocumentMemberLocation {
            self.interfaceBuilderIdentifier = location.memberIdentifier.memberIdentifier
        } else {
            self.interfaceBuilderIdentifier = nil
        }
        self.detail = detail
        if let location = logMessage.location as? DVTTextDocumentLocation {
            self.type = type
            if let analyzerMessage = logMessage as? IDEActivityLogAnalyzerEventStepMessage {
                self.title = analyzerMessage.description
            } else {
                self.title = logMessage.title
            }
            self.documentURL = location.documentURLString
            self.severity = logMessage.severity
            self.characterRangeEnd = location.characterRangeEnd
            self.characterRangeStart = location.characterRangeStart
            // Xcode reports line and column numbers using zero-based numbers
            self.startingLineNumber = Self.realLocationNumber(location.startingLineNumber)
            self.endingLineNumber = Self.realLocationNumber(location.endingLineNumber)
            self.startingColumnNumber = Self.realLocationNumber(location.startingColumnNumber)
            self.endingColumnNumber = Self.realLocationNumber(location.endingColumnNumber)
            self.clangFlag = clangFlag
        } else {
            self.type = type
            if let analyzerMessage = logMessage as? IDEActivityLogAnalyzerEventStepMessage {
                self.title = analyzerMessage.description
            } else {
                self.title = logMessage.title
            }
            self.documentURL = logMessage.location.documentURLString
            self.severity = logMessage.severity
            self.startingLineNumber = 0
            self.endingLineNumber = 0
            self.startingColumnNumber = 0
            self.endingColumnNumber = 0
            self.characterRangeEnd = 0
            self.characterRangeStart = 0
            self.clangFlag = clangFlag
        }
    }

    public func with(detail newDetail: String?) -> Notice {
        return Notice(type: type,
                      title: title,
                      clangFlag: clangFlag,
                      documentURL: documentURL,
                      severity: severity,
                      startingLineNumber: startingLineNumber,
                      endingLineNumber: endingLineNumber,
                      startingColumnNumber: startingColumnNumber,
                      endingColumnNumber: endingColumnNumber,
                      characterRangeEnd: characterRangeEnd,
                      characterRangeStart: characterRangeStart,
                      interfaceBuilderIdentifier: interfaceBuilderIdentifier,
                      detail: newDetail)
    }

    public func with(type newType: NoticeType) -> Notice {
        return Notice(type: newType,
                      title: title,
                      clangFlag: clangFlag,
                      documentURL: documentURL,
                      severity: severity,
                      startingLineNumber: startingLineNumber,
                      endingLineNumber: endingLineNumber,
                      startingColumnNumber: startingColumnNumber,
                      endingColumnNumber: endingColumnNumber,
                      characterRangeEnd: characterRangeEnd,
                      characterRangeStart: characterRangeStart,
                      interfaceBuilderIdentifier: interfaceBuilderIdentifier,
                      detail: detail)
    }

    /// Xcode reports the line and column number based on a zero-index location
    /// This adds a 1 to report the real location
    /// If there is no location, Xcode reports UIInt64.max. In that case this function
    /// doesn't do anything and returns the same number
    private static func realLocationNumber(_ number: UInt64) -> UInt64 {
        if number != UInt64.max {
            return number + 1
        }
        return number
    }
}

extension Notice: Hashable {
    public static func == (lhs: Notice, rhs: Notice) -> Bool {
        return
            lhs.characterRangeEnd == rhs.characterRangeEnd &&
            lhs.characterRangeStart == rhs.characterRangeStart &&
            lhs.detail == rhs.detail &&
            lhs.documentURL == rhs.documentURL &&
            lhs.endingColumnNumber == rhs.endingColumnNumber &&
            lhs.endingLineNumber == rhs.endingLineNumber &&
            lhs.startingColumnNumber == rhs.startingColumnNumber &&
            lhs.startingLineNumber == rhs.startingLineNumber &&
            lhs.title == rhs.title &&
            lhs.type == rhs.type
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(characterRangeEnd)
        hasher.combine(characterRangeStart)
        hasher.combine(detail)
        hasher.combine(documentURL)
        hasher.combine(endingColumnNumber)
        hasher.combine(endingLineNumber)
        hasher.combine(startingColumnNumber)
        hasher.combine(startingLineNumber)
        hasher.combine(title)
        hasher.combine(type)
    }
}
