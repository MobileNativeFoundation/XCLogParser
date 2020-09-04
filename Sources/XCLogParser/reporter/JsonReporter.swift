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

public struct JsonReporter: LogReporter {

    public func report(build: Any, output: ReporterOutput, rootOutput: String?) throws {
        switch build {
        case let steps as BuildStep:
            try report(encodable: steps, output: output)
        case let logEntries as [LogManifestEntry]:
            try report(encodable: logEntries, output: output)
        case let activityLog as IDEActivityLog:
            try report(encodable: activityLog, output: output)
        default:
            throw XCLogParserError.errorCreatingReport("Type not supported \(type(of: build))")
        }
    }

    private func report<T: Encodable>(encodable: T, output: ReporterOutput) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let json = try encoder.encode(encodable)
        try output.write(report: json)
    }

}
