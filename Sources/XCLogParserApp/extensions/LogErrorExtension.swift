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
import XCLogParser

extension LogError: CustomStringConvertible {

    public var description: String {
        switch self {
        case .noDerivedDataFound:
            return "We couldn't find a the derivedData directory. " +
                    "If you use a custom derivedData dir, use the --derivedData option to pass it. "
        case .noLogFound(let dir):
            return "We couldn't find a log in the directory \(dir). " +
                   "If the log is in a custom derivedData dir, use the --derivedData option. " +
                   "You can also pass the full path to the xcactivity log with the --file option"
        case .xcodeBuildError(let error):
            return error
        case .readingFile(let path):
            return "Can't read file \(path)"
        case .invalidFile(let path):
            return "\(path) is not a valid xcactivitylog file"
        case .noLogManifestFound(let path):
            return "We couldn't find a logManiifest in the path \(path). " +
                   "If the logManifest is in a custom derivedData dir, use the --derivedData option."
        case .invalidLogManifest(let path):
            return "\(path) is not a valid LogManifest file"
        }
    }

}
