// Copyright (c) 2020 Spotify AB.
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

public class LexRedactor: LogRedactor {
    private static let redactedTemplate = "/Users/<redacted>/"
    private lazy var userDirRegex: NSRegularExpression? = {
        do {
            return try NSRegularExpression(pattern: "/Users/([^/]+)/?")
        } catch {
            return nil
        }
    }()
    public var userDirToRedact: String?

    public init() {
    }

    public func redactUserDir(string: String) -> String {
        guard let regex = userDirRegex else {
            return string
        }
        if let userDirToRedact = userDirToRedact {
            return string.replacingOccurrences(of: userDirToRedact, with: Self.redactedTemplate)
        } else {
            guard let firstMatch = regex.firstMatch(in: string,
                                                    options: [],
                                                    range: NSRange(location: 0, length: string.count)) else {
                return string
            }
            let userDir = string.substring(firstMatch.range)
            userDirToRedact = userDir
            return string.replacingOccurrences(of: userDir, with: Self.redactedTemplate)
        }
    }
}
