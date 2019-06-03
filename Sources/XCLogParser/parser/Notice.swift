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

/// The type of a Notice
public enum NoticeType: String, Encodable {

    /// Notes
    case note

    /// A warning thrown by the Swift compiler
    case swiftWarning

    /// A warning thrown by the C compiler
    case clangWarning

    /// A warning at a project level. For instance:
    /// "Warning Swift 3 mode has been deprecated and will be removed in a later version of Xcode"
    case projectWarning

    /// An error in a non-compilation step. For instance creating a directory or running a shell script phase
    case error

    /// An error thrown by the Swift compiler
    case swiftError

    /// An error thrown by the C compiler
    case clangError

    public static func fromTitle(_ title: String) -> NoticeType? {
        switch title {
        case "Swift Compiler Warning":
            return .swiftWarning
        case "Notice":
            return .note
        case "Swift Compiler Error":
            return .swiftError
        case "ARC Semantic Issue":
            return .clangError
        case "Warning":
            return .projectWarning
        case Suffix("Error"):
            return .error
        case Suffix("Notice"):
            return .note
        default:
            return nil
        }
    }
}

/// Xcode reports warnings, errors and notes as IDEActivityLogMessage. This class
/// wraps that data
public class Notice: Encodable {

    let type: NoticeType
    let title: String
    let clangFlag: String?
    let documentURL: String
    let severity: Int
    let startingLineNumber: UInt64
    let endingLineNumber: UInt64
    let startingColumnNumber: UInt64
    let endingColumnNumber: UInt64
    public let characterRangeEnd: UInt64
    public let characterRangeStart: UInt64

    static var clangWarningRegexp: NSRegularExpression? = {
        let pattern = "\\[(-W[\\w-]*)\\]+"
        return NSRegularExpression.fromPattern(pattern)
    }()

    public init?(withType type: NoticeType?,
                 logMessage: IDEActivityLogMessage,
                 andClangFlag clangFlag: String? = nil) {
        guard let type = type else {
            return nil
        }
        if let location = logMessage.location as? DVTTextDocumentLocation {
            self.type = type
            self.title = logMessage.title
            self.documentURL = location.documentURLString
            self.severity = logMessage.severity
            self.startingLineNumber = location.startingLineNumber
            self.endingLineNumber = location.endingLineNumber
            self.startingColumnNumber = location.startingColumnNumber
            self.endingColumnNumber = location.endingColumnNumber
            self.characterRangeEnd = location.characterRangeEnd
            self.characterRangeStart = location.characterRangeStart
            self.clangFlag = clangFlag
        } else {
            self.type = type
            self.title = logMessage.title
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

    /// Parses an `IDEActivityLogSection` looking for Warnings, Errors and Notes in its `IDEActivityLogMessage`.
    /// Uses the `categoryIdent` of `IDEActivityLogMessage` to categorize them.
    /// For CLANG warnings, it parses the `IDEActivityLogSection` text property looking for a *-W-warning-name* pattern
    /// - parameter logSection: An `IDEActivityLogSection`
    /// - returns: An Array of `Notice`
    public static func parseFromLogSection(_ logSection: IDEActivityLogSection) -> [Notice] {
        // we look for clangWarnings parsing the text of the logSection
        // is it possible to have errors and clang warning in the same step?
        if let clangWarningsFlags = self.parseClangWarningFlags(text: logSection.text),
            clangWarningsFlags.count > 0 {
            return zip(logSection.messages, clangWarningsFlags).compactMap { (message, warningFlag) -> Notice? in
                Notice(withType: .clangWarning, logMessage: message, andClangFlag: warningFlag)
            }
        }
        // we look for commong swift warnings, notes and errors
        return logSection.messages.compactMap {
            Notice(withType: NoticeType.fromTitle($0.categoryIdent), logMessage: $0)
        }
    }

    /// Parses the text of a IDELogSection looking for the pattern [-Wwarning-type]
    /// that means there was a clang warning.
    /// - parameter text: IDELogSection text property
    /// - returns: A list of clang warning flags found in the text, like -Wunused-function
    private static func parseClangWarningFlags(text: String) -> [String]? {
        guard let clangWarningRegexp = Notice.clangWarningRegexp else {
            return nil
        }
        let range = NSRange(location: 0, length: text.count)
        let matches = clangWarningRegexp.matches(in: text, options: .reportCompletion, range: range)
        return matches.map { result -> String in
            String(text.substring(result.range))
        }
    }

}
