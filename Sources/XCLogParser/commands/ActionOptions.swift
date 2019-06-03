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
    let reporter: Reporter

    /// The outputPath to write the report to.
    /// If empty, the report will be written to the StandardOutput
    let outputPath: String

    /// Used for actions involving the .xcactivitylog.
    /// If true, the username will be redacted from the paths in the log.
    /// Used to protect the privacy of the users.
    let redacted: Bool

    public init(reporter: Reporter, outputPath: String, redacted: Bool) {
        self.reporter = reporter
        self.outputPath = outputPath
        self.redacted = redacted
    }
}
