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

/// Represents the options of an Action
public struct ActionOptions {

    /// The `Reporter` to use
    public let reporter: Reporter

    /// The outputPath to write the report to.
    /// If empty, the report will be written to the StandardOutput
    public let outputPath: String

    /// Used for actions involving the .xcactivitylog.
    /// If true, the username will be redacted from the paths in the log.
    /// Used to protect the privacy of the users.
    public let redacted: Bool

    /// Used for actions involving the .xcactivitylog.
    /// If true, build specific information will be removed from the logs.
    /// Useful for grouping logs by its content.
    public let withoutBuildSpecificInformation: Bool

    /// Used in Parse actions. The current parsers use the host name to create a unique build identifier
    /// With this option, a user can override it and provide a name that will be used in that identifier.
    public let machineName: String?

    /// The rootOutput will generate the HTML output in the given folder
    public let rootOutput: String

    /// If true, the parse command won't add the Warnings details to the output.
    public let omitWarningsDetails: Bool

    /// If true, the parse command won't add the Notes details to the output.
    public let omitNotesDetails: Bool

    /// If true, tasks with more than a 100 issues (warnings, errors, notes) will be truncated to a 100
    public let truncLargeIssues: Bool

    public init(reporter: Reporter,
                outputPath: String,
                redacted: Bool,
                withoutBuildSpecificInformation: Bool,
                machineName: String? = nil,
                rootOutput: String = "",
                omitWarningsDetails: Bool = false,
                omitNotesDetails: Bool = false,
                truncLargeIssues: Bool = false
    ) {
        self.reporter = reporter
        self.outputPath = outputPath
        self.redacted = redacted
        self.withoutBuildSpecificInformation = withoutBuildSpecificInformation
        self.machineName = machineName
        self.rootOutput = rootOutput
        self.omitWarningsDetails = omitWarningsDetails
        self.omitNotesDetails = omitNotesDetails
        self.truncLargeIssues = truncLargeIssues
    }
}
