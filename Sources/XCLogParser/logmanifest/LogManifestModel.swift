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

public enum LogManifestEntryType: String, Encodable {
    case xcode
    case xcodebuild

    private static let xcodeLogClassName = "IDEActivityLogSection"
    private static let xcodebuildLogClassName = "IDECommandLineBuildLog"

    public static func buildFromClassName(_ className: String) -> LogManifestEntryType? {
        if className == xcodeLogClassName {
            return .xcode
        }
        if className == xcodebuildLogClassName {
            return .xcodebuild
        }
        return nil
    }
}

public struct LogManifestEntry: Encodable {
    public let uniqueIdentifier: String
    public let title: String
    public let scheme: String
    public let fileName: String
    public let timestampStart: TimeInterval
    public let timestampEnd: TimeInterval
    public let duration: Double
    public let type: LogManifestEntryType
    public let statistics: LogManifestEntryStatistics
    
    public init(uniqueIdentifier: String, title: String, scheme: String, fileName: String,
                timestampStart: TimeInterval, timestampEnd: TimeInterval, duration: Double, type: LogManifestEntryType, statistics: LogManifestEntryStatistics) {
        self.uniqueIdentifier = uniqueIdentifier
        self.title = title
        self.scheme = scheme
        self.fileName = fileName
        self.timestampStart = timestampStart
        self.timestampEnd = timestampEnd
        self.duration = duration
        self.type = type
        self.statistics = statistics
    }

}

public struct LogManifestEntryStatistics: Encodable {
    public let totalNumberOfErrors: Int
    public let totalNumberOfAnalyzerIssues: Int
    public let highLevelStatus: String
    public let totalNumberOfTestFailures: Int
    public let totalNumberOfWarnings: Int
    
    public init(totalNumberOfErrors: Int, totalNumberOfAnalyzerIssues: Int, highLevelStatus: String, totalNumberOfTestFailures: Int, totalNumberOfWarnings: Int) {
        self.totalNumberOfErrors = totalNumberOfErrors
        self.totalNumberOfAnalyzerIssues = totalNumberOfAnalyzerIssues
        self.highLevelStatus = highLevelStatus
        self.totalNumberOfTestFailures = totalNumberOfTestFailures
        self.totalNumberOfWarnings = totalNumberOfWarnings
    }
}
