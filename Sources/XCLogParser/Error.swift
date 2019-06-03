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

public enum Error: Swift.Error {
    case invalidLogHeader(String)
    case invalidLine(String)
    case errorCreatingReport(String)
    case wrongLogManifestFile(String, String)
    case parseError(String)
}

extension Error: CustomStringConvertible {
    public var description: String {
        switch self {
        case .invalidLogHeader(let path):
            return "The file in \(path) is not a valid SLF log"
        case .invalidLine(let line):
            return "The line \(line) doesn't seem like a valid SLF line"
        case .errorCreatingReport(let error):
            return "Can't create the report: \(error)"
        case .wrongLogManifestFile(let path, let error):
            return "There was an error reading the latest build time " +
            " from the file \(path). Error: \(error)"
        case .parseError(let message):
            return "Error parsing the log: \(message)"
        }
    }
}
