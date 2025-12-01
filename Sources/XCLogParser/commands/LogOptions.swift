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

/// Represents the strategy to locate a Xcode Log resource
public struct LogOptions {
    /// The name of the Xcode project
    let projectName: String

    /// The path to an .xcworkspace
    let xcworkspacePath: String

    /// The path to an .xcodeprojPath
    let xcodeprojPath: String

    /// The path to the DerivedData directory
    let derivedDataPath: String

    /// The path to an .xcactivitylog file
    let xcactivitylogPath: String

    /// The path to a LogManifest.plist file
    let logManifestPath: String
    
    /// Type of logs to search for
    let logType: LogType

    /// Use strict Xcode project naming.
    let strictProjectName: Bool
    
    /// Timestamp to check
    let newerThan: Date?

    /// Computed property, return the xcworkspacePath if not empty or
    /// the xcodeprojPath if xcworkspacePath is empty
    var projectLocation: String {
        return xcworkspacePath.isEmpty ? xcodeprojPath : xcworkspacePath
    }

    public init(projectName: String,
                xcworkspacePath: String,
                xcodeprojPath: String,
                derivedDataPath: String,
                xcactivitylogPath: String,
                logType: LogType,
                strictProjectName: Bool = false,
                newerThan: Date? = nil) {
        self.projectName = projectName
        self.xcworkspacePath = xcworkspacePath
        self.xcodeprojPath = xcodeprojPath
        self.derivedDataPath = derivedDataPath
        self.xcactivitylogPath = xcactivitylogPath
        self.logType = logType
        self.logManifestPath  = String()
        self.strictProjectName = strictProjectName
        self.newerThan = newerThan
    }

    public init(projectName: String,
                xcworkspacePath: String,
                xcodeprojPath: String,
                derivedDataPath: String,
                logType: LogType,
                logManifestPath: String,
                strictProjectName: Bool = false,
                newerThan: Date? = nil) {
        self.projectName = projectName
        self.xcworkspacePath = xcworkspacePath
        self.xcodeprojPath = xcodeprojPath
        self.derivedDataPath = derivedDataPath
        self.logManifestPath = logManifestPath
        self.logType = logType
        self.xcactivitylogPath = String()
        self.strictProjectName = strictProjectName
        self.newerThan = newerThan
    }

}
