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

/// Errors thrown by the LogFinder
public enum LogError: LocalizedError {
    case noDerivedDataFound
    case noLogFound(dir: String)
    case xcodeBuildError(String)
    case readingFile(String)
    case invalidFile(String)
    case noLogManifestFound(dir: String)
    case invalidLogManifest(String)

    public var errorDescription: String? { return description }

}

extension LogError: CustomStringConvertible {

    public var description: String {
        switch self {
        case .noDerivedDataFound:
            return "We couldn't find the derivedData directory. " +
            "If you use a custom derivedData directory, use the --derived_data option to pass it. "
        case .noLogFound(let dir):
            return "We couldn't find a log in the directory \(dir). " +
                "If the log is in a custom derivedData dir, use the --derived_data option. " +
                "You can also pass the full path to the xcactivity log with the --file option"
        case .xcodeBuildError(let error):
            return error
        case .readingFile(let path):
            return "Can't read file \(path)"
        case .invalidFile(let path):
            return "\(path) is not a valid xcactivitylog file"
        case .noLogManifestFound(let path):
            return "We couldn't find a logManifest in the path \(path). " +
            "If the LogManifest is in a custom derivedData directory, use the --derived_data option."
        case .invalidLogManifest(let path):
            return "\(path) is not a valid LogManifest file"
        }
    }

}
