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

/// Functions to parser Notices from `IDELogSection` and `IDELogMessage`
extension Notice {

    /// Parses an `IDEActivityLogSection` looking for Warnings, Errors and Notes in its `IDEActivityLogMessage`.
    /// Uses the `categoryIdent` of `IDEActivityLogMessage` to categorize them.
    /// For CLANG warnings, it parses the `IDEActivityLogSection` text property looking for a *-W-warning-name* pattern
    /// - parameter logSection: An `IDEActivityLogSection`
    /// - parameter forType: The `DetailStepType` of the logSection
    /// - parameter truncLargeIssues: If true, if a task have more than 100 `Notice`, will be truncated to 100
    /// - returns: An Array of `Notice`
    public static func parseFromLogSection(_ logSection: IDEActivityLogSection,
                                           forType type: DetailStepType,
                                           truncLargeIssues: Bool)
        -> [Notice] {
        var logSection = logSection
        if truncLargeIssues && logSection.messages.count > 100 {
            logSection = self.logSectionWithTruncatedIssues(logSection: logSection)
        }
        // we look for clangWarnings parsing the text of the logSection
        let clangWarningsFlags = self.parseClangWarningFlags(text: logSection.text)
        let clangWarnings = self.parseClangWarnings(clangFlags: clangWarningsFlags, logSection: logSection)

        // Remove the messages that were categorized as clangWarnings
        let remainingLogMessages = logSection.messages.filter { message in
            return clangWarnings.contains { $0.title == message.title } == false
        }
        // parse details for Swift issues
        let swiftErrorDetails = parseSwiftIssuesDetailsByLocation(logSection.text)
        // we look for analyzer warnings, swift warnings, notes and errors
        return clangWarnings + remainingLogMessages.compactMap { message -> [Notice]? in
            if let resultMessage = message as? IDEActivityLogAnalyzerResultMessage {
                return resultMessage.subMessages.compactMap {
                    if let stepMessage = $0 as? IDEActivityLogAnalyzerEventStepMessage {
                        return Notice(withType: .analyzerWarning, logMessage: stepMessage)
                    }
                    return nil
                }
            }
            // Special case, Interface builder warning can only be spotted by checking the whole text of the
            // log section
            let noticeTypeTitle = message.categoryIdent.isEmpty ? logSection.text : message.categoryIdent
            if var notice = Notice(withType: NoticeType.fromTitle(noticeTypeTitle),
                                   logMessage: message,
                                   detail: logSection.text) {
                // Add the right details to Swift errors
                if notice.type == NoticeType.swiftError || notice.type == .swiftWarning {
                    // Special case, if Swiftc fails for a whole module,
                    // we don't have location and the detail already has
                    // enough information
                    let noticeDetail = notice.detail ?? ""
                    if noticeDetail.starts(with: "error:") == false {
                        var errorLocation = notice.documentURL.replacingOccurrences(of: "file://", with: "")
                        errorLocation += ":\(notice.startingLineNumber):\(notice.startingColumnNumber):"
                        // do not report error in a file that it does not belong to (we'll ended
                        // up having duplicated errors)
                        if !logSection.location.documentURLString.isEmpty
                            && logSection.location.documentURLString != notice.documentURL {
                            return nil
                        }
                        notice = notice.with(detail: swiftErrorDetails[errorLocation])
                    }
                }

                // Handle special cases

                if isDeprecatedWarning(type: notice.type, text: notice.title, clangFlags: notice.clangFlag) {
                    return [notice.with(type: .deprecatedWarning)]
                }
                // Ld command errors
                if notice.type == .error && type == .linker {
                    return [notice.with(type: .linkerError)]
                }
                // Build phase's script errors
                if notice.type == .scriptPhaseError {
                    // Decorate script phase error with the signature that contains the name of the
                    // phase and the target
                    return [notice.with(detail: "\(notice.detail ?? "") \(logSection.signature)")]
                }
                return [notice]
            }
            return nil
        }.reduce([Notice]()) { flatten, notices -> [Notice] in
            flatten + notices
        }
    }

    /// Xcode reports the details of Swift errors and warnings as a mixed text with all the errors in a
    /// compilation unit in the same Text. This functions parses.
    /// - parameter text: The LogSection.text with the error details
    /// - returns: A Dictionary where the keys are the error location in the form pathToFile:line:column:
    /// and the values are the error details for that location
    public static func parseSwiftIssuesDetailsByLocation(_ text: String) -> [String: String] {
        return text
            .split(separator: "\r")
            .reduce([]) { (details, line) -> [String] in
                var details = details
                if line.contains(": error:") || line.contains(": warning:") {
                    details.append(String(line))
                } else {
                    guard let current = details.last else {
                        return details
                    }
                    details.removeLast()
                    details.append("\(current)\n\(line)")
                }
                return details
        }
        .reduce([String: String]()) { (detailsByLoc, detail) -> [String: String] in
            let range: Range<String.Index>?
            if detail.contains(": error:") {
                range = detail.range(of: ": error:")
            } else {
                range = detail.range(of: ": warning:")
            }
            if let range = range {
                let location = detail[...range.lowerBound]
                var detailsByLoc = detailsByLoc
                detailsByLoc[String(location)] = detail
                return detailsByLoc
            }
            return detailsByLoc
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

    private static func parseClangWarnings(clangFlags: [String]?, logSection: IDEActivityLogSection) -> [Notice] {
        guard let clangFlags = clangFlags else {
            return [Notice]()
        }
        return zip(logSection.messages, clangFlags)
            .compactMap { (message, warningFlag) -> Notice? in
                // If the warning is treated as error, we marked the issue as error
                let type: NoticeType = warningFlag.contains("-Werror") ? .clangError : .clangWarning
                let notice = Notice(withType: type, logMessage: message, clangFlag: warningFlag)

                if let notice = notice,
                    isDeprecatedWarning(type: type, text: notice.title, clangFlags: warningFlag) {
                    // Fixes a bug where Xcode logs add more than one message to report one
                    // deprecation warning. Only one has the right documentURL
                    if notice.documentURL != logSection.location.documentURLString {
                        return nil
                    }
                    return notice.with(type: .deprecatedWarning)
                }
                return notice
        }
    }

    private static func isDeprecatedWarning(type: NoticeType, text: String, clangFlags: String?) -> Bool {
        // Mark clang deprecated flags (https://clang.llvm.org/docs/DiagnosticsReference.html)
        if let clangFlags = clangFlags, clangFlags.contains("-Wdeprecated") {
            return true
        }
        // Support for Swift and ObjC code marked as deprecated
        if type == .swiftError || type == .swiftWarning || type == .projectWarning || type == .clangWarning
            || type == .note {
            return text.contains(" deprecated:")
                || text.contains("was deprecated in")
                || text.contains("has been deprecated")
                || text.contains("is deprecated")
        }
        return false
    }

    private static func logSectionWithTruncatedIssues(logSection: IDEActivityLogSection) -> IDEActivityLogSection {
        let issuesKept = min(99, logSection.messages.count)
        var truncatedMessages = Array(logSection.messages[0..<issuesKept])
        truncatedMessages.append(getTruncatedIssuesWarning(logSection: logSection, issuesKept: issuesKept))
        return logSection.with(messages: truncatedMessages)
    }

    private static func getTruncatedIssuesWarning(logSection: IDEActivityLogSection, issuesKept: Int)
    -> IDEActivityLogMessage {
        let title = "Warning: \(logSection.messages.count - issuesKept) issues were truncated"
        return IDEActivityLogMessage(title: title,
                                     shortTitle: "",
                                     timeEmitted: 0,
                                     rangeEndInSectionText: 0,
                                     rangeStartInSectionText: 0,
                                     subMessages: [],
                                     severity: 0,
                                     type: "",
                                     location: DVTDocumentLocation(documentURLString: "", timestamp: 0),
                                     categoryIdent: "Warning",
                                     secondaryLocations: [],
                                     additionalDescription: "")
    }
}
