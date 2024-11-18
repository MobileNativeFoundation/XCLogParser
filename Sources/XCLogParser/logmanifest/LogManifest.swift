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

/// Parses a LogManifest.plist file.
/// That file has a list of the existing Xcode Logs inside a Derived Data's project directory
public struct LogManifest {

    public init() {}

    public func getWithLogOptions(_ logOptions: LogOptions) throws  -> [LogManifestEntry] {
        let logFinder = LogFinder()
        let logManifestURL = try logFinder.findLogManifestWithLogOptions(logOptions)
        let logManifestDictionary = try getDictionaryFromURL(logManifestURL)
        return try parse(dictionary: logManifestDictionary, atPath: logManifestURL.path)
    }

    public func parse(dictionary: NSDictionary, atPath path: String) throws -> [LogManifestEntry] {
        guard let logs = dictionary["logs"] as? [String: [String: Any]] else {
            throw LogError.invalidLogManifest("The file at \(path) is not a valid " +
                "LogManifest file.")
        }
        return try logs.compactMap { entry -> LogManifestEntry? in
            guard
                let fileName = entry.value["fileName"] as? String,
                let title = entry.value["title"] as? String,
                let uniqueIdentifier = entry.value["uniqueIdentifier"] as? String,
                let scheme = entry.value["schemeIdentifier-schemeName"] as? String,
                let timeStartedRecording = entry.value["timeStartedRecording"] as? Double,
                let timeStoppedRecording = entry.value["timeStoppedRecording"] as? Double,
                let className = entry.value["className"] as? String,
                let type = LogManifestEntryType.buildFromClassName(className),
                let primaryObservable = entry.value["primaryObservable"] as? [String: Any],
                let totalNumberOfAnalyzerIssues = primaryObservable["totalNumberOfAnalyzerIssues"] as? Int,
                let totalNumberOfErrors = primaryObservable["totalNumberOfErrors"] as? Int,
                let totalNumberOfWarnings = primaryObservable["totalNumberOfWarnings"] as? Int,
                let totalNumberOfTestFailures = primaryObservable["totalNumberOfTestFailures"] as? Int,
                let highLevelStatus = primaryObservable["highLevelStatus"] as? String
                else {
                    throw LogError.invalidLogManifest("The file at \(path) is not a valid " +
                        "LogManifest file.")
            }
            let startDate = Date(timeIntervalSinceReferenceDate: timeStartedRecording)
            let endDate = Date(timeIntervalSinceReferenceDate: timeStoppedRecording)
            let timestampStart = startDate.timeIntervalSince1970
            let timestampEnd = endDate.timeIntervalSince1970
            let statistics = LogManifestEntryStatistics(
                totalNumberOfErrors: totalNumberOfErrors,
                totalNumberOfAnalyzerIssues: totalNumberOfAnalyzerIssues,
                highLevelStatus: highLevelStatus,
                totalNumberOfTestFailures: totalNumberOfTestFailures,
                totalNumberOfWarnings: totalNumberOfWarnings
            )
            return LogManifestEntry(uniqueIdentifier: uniqueIdentifier,
                                    title: title,
                                    scheme: scheme,
                                    fileName: fileName,
                                    timestampStart: timestampStart,
                                    timestampEnd: timestampEnd,
                                    duration: timestampEnd - timestampStart,
                                    type: type,
                                    statistics: statistics
            )
            }.sorted(by: { lhs, rhs -> Bool in
                return lhs.timestampStart > rhs.timestampStart
            })
    }

    private func getDictionaryFromURL(_ logManifestURL: URL) throws -> NSDictionary {
        guard let logContents = NSDictionary(contentsOfFile: logManifestURL.path) else {
            throw LogError.invalidLogManifest("The file at \(logManifestURL.path) is not a valid " +
                "LogManifest file.")
        }
        return logContents
    }
}
