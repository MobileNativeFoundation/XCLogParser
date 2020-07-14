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

public class ClangCompilerParser {
    private static let timeTraceCompilerFlag = "-ftime-trace"
    private static let printStatisticsLinkerFlag = "-print_statistics"

    private lazy var timeTraceRegexp: NSRegularExpression? = {
        let pattern = "Time trace json-file dumped to (.*?)\\r"
        return NSRegularExpression.fromPattern(pattern)
    }()

    public func parseTimeTraceFile(_ logSection: IDEActivityLogSection) -> String? {
        guard let regex = timeTraceRegexp else {
            return nil
        }

        guard hasTimeTraceCompilerFlag(commandDesc: logSection.commandDetailDesc) else {
            return nil
        }

        let text = logSection.text
        let range = NSRange(location: 0, length: text.count)
        let matches = regex.matches(in: text, options: .reportProgress, range: range)
        guard let fileRange = matches.first?.range(at: 1) else {
            return nil
        }

        return text.substring(fileRange)
    }

    fileprivate func parseTimeAndPercentage(_ text: String, _ range: NSRange, _ pattern: String) -> (Double, Double) {
        var time = 0.0
        var percentage = 0.0

        if let regex = NSRegularExpression.fromPattern(pattern) {
            if let match = regex.firstMatch(in: text, options: [], range: range) {
                if let timeRange = Range(match.range(at: 1), in: text) {
                    time = Double(text[timeRange]) ?? 0.0
                }

                if let percentageRange = Range(match.range(at: 2), in: text) {
                    percentage = Double(text[percentageRange]) ?? 0.0
                }
            }
        }

        return (time, percentage)
    }

    // swiftlint:disable large_tuple
    fileprivate func parsePagingInfo(_ text: String, _ range: NSRange) -> (Int, Int, Int) {
        var pageins = 0, pageouts = 0, faults = 0
        let pagingInfoPattern = "pageins=(\\d+), pageouts=(\\d+), faults=(\\d+)\r"
        if let regex = NSRegularExpression.fromPattern(pagingInfoPattern) {
            if let match = regex.firstMatch(in: text, options: [], range: range) {
                if let pageinsRange = Range(match.range(at: 1), in: text) {
                    pageins = Int(text[pageinsRange]) ?? 0
                }
                if let pageoutsRange = Range(match.range(at: 2), in: text) {
                    pageouts = Int(text[pageoutsRange]) ?? 0
                }
                if let faultsRange = Range(match.range(at: 3), in: text) {
                    faults = Int(text[faultsRange]) ?? 0
                }
            }
        }

        return (pageins, pageouts, faults)
    }

    // swiftlint:disable function_body_length
    public func parseLinkerStatistics(_ logSection: IDEActivityLogSection) -> LinkerStatistics? {
        guard hasPrintStatisticsLinkerFlag(commandDesc: logSection.commandDetailDesc) else {
            return nil
        }

        let text = logSection.text
        let range = NSRange(location: 0, length: text.count)
        let totalTimePattern = "ld total time:\\s*(.*?) milliseconds \\(\\s*(.*?)%\\)\\r"
        let totalTime = parseTimeAndPercentage(text, range, totalTimePattern)

        let optionParsingPattern = "option parsing time:\\s*(.*?) milliseconds \\(\\s*(.*?)%\\)\\r"
        let optionParsing = parseTimeAndPercentage(text, range, optionParsingPattern)

        let resolveSymbolPattern = "resolve symbols:\\s*(.*?) milliseconds \\(\\s*(.*?)%\\)\\r"
        let resolveSymbol = parseTimeAndPercentage(text, range, resolveSymbolPattern)

        let buildAtomPattern = "build atom list:\\s*(.*?) milliseconds \\(\\s*(.*?)%\\)\\r"
        let buildAtom = parseTimeAndPercentage(text, range, buildAtomPattern)

        let passesPattern = "passess:\\s*(.*?) milliseconds \\(\\s*(.*?)%\\)\\r"
        let passes = parseTimeAndPercentage(text, range, passesPattern)

        let writeOutputPattern = "write output:\\s*(.*?) milliseconds \\(\\s*(.*?)%\\)\\r"
        let writeOutput = parseTimeAndPercentage(text, range, writeOutputPattern)

        let paging = parsePagingInfo(text, range)

        var objectFiles = 0, objectFilesBytes = 0
        var archiveFiles = 0, archiveFilesBytes = 0
        var dylibFiles = 0
        var totalFileBytes = 0

        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal

        let fileInfoPattern = """
        processed\\s*(\\d+) object files,\\s*totaling\\s*(.*?) bytes\\r\
        processed\\s*(\\d+) archive files,\\s*totaling\\s*(.*?) bytes\\r\
        processed\\s*(\\d+) dylib files\\r\
        wrote output file\\s* totaling\\s*(.*) bytes\\r
        """
        if let regex = NSRegularExpression.fromPattern(fileInfoPattern) {
            if let match = regex.firstMatch(in: text, options: [], range: range) {
                if let objectFilesCountRange = Range(match.range(at: 1), in: text) {
                    objectFiles = Int(text[objectFilesCountRange]) ?? 0
                }
                if let objectFilesBytesRange = Range(match.range(at: 2), in: text) {
                    let number = numberFormatter.number(from: String(text[objectFilesBytesRange]))
                    objectFilesBytes = number?.intValue ?? 0
                }
                if let archiveFilesCountRange = Range(match.range(at: 3), in: text) {
                    archiveFiles = Int(text[archiveFilesCountRange]) ?? 0
                }
                if let archiveFilesBytesRange = Range(match.range(at: 4), in: text) {
                    let number = numberFormatter.number(from: String(text[archiveFilesBytesRange]))
                    archiveFilesBytes = number?.intValue ?? 0
                }
                if let dylibCountRange = Range(match.range(at: 5), in: text) {
                    dylibFiles = Int(text[dylibCountRange]) ?? 0
                }
                if let totalFilesBytesRange = Range(match.range(at: 6), in: text) {
                    let number = numberFormatter.number(from: String(text[totalFilesBytesRange]))
                    totalFileBytes = number?.intValue ?? 0
                }
            }
        }

        return LinkerStatistics(
            totalMS: totalTime.0,
            optionParsingMS: optionParsing.0,
            optionParsingPercent: optionParsing.1,
            objectFileProcessingMS: 0,
            objectFileProcessingPercent: 0,
            resolveSymbolsMS: resolveSymbol.0,
            resolveSymbolsPercent: resolveSymbol.1,
            buildAtomListMS: buildAtom.0,
            buildAtomListPercent: buildAtom.1,
            runPassesMS: passes.0,
            runPassesPercent: passes.1,
            writeOutputMS: writeOutput.0,
            writeOutputPercent: writeOutput.1,
            pageins: paging.0,
            pageouts: paging.1,
            faults: paging.2,
            objectFiles: objectFiles,
            objectFilesBytes: objectFilesBytes,
            archiveFiles: archiveFiles,
            archiveFilesBytes: archiveFilesBytes,
            dylibFiles: dylibFiles,
            wroteOutputFileBytes: totalFileBytes)
    }

    func hasTimeTraceCompilerFlag(commandDesc: String) -> Bool {
        commandDesc.range(of: Self.timeTraceCompilerFlag) != nil
    }

    func hasPrintStatisticsLinkerFlag(commandDesc: String) -> Bool {
        commandDesc.range(of: Self.printStatisticsLinkerFlag) != nil
    }
}
