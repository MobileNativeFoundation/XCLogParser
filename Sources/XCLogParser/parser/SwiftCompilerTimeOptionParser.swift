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

/// Parses `swiftc` commands for time compiler outputs
protocol SwiftCompilerTimeOptionParser {

    associatedtype SwiftcOption

    /// Returns true if the compiler command included the flag to generate
    /// this compiler report
    /// - Parameter commandDesc: The command description
    func hasCompilerFlag(commandDesc: String) -> Bool

    /// Parses the Set of commands to look for swift compiler time outputs of type `SwiftcOption`
    /// - Parameter commands: Dictionary of command descriptions and ocurrences
    /// - Returns: A dictionary using the key as file and the Compiler time output as value
    func parse(from commands: [String: Int]) -> [String: [SwiftcOption]]

}

extension SwiftCompilerTimeOptionParser {

    /// Parses /users/mnf/project/SomeFile.swift:10:12
    /// - Returns: ("file:///users/mnf/project/SomeFile.swift", 10, 12)
    // swiftlint:disable:next large_tuple
    func parseNameAndLocation(from fileAndLocation: String) -> (String, Int, Int)? {
        // /users/mnf/project/SomeFile.swift:10:12
        let fileAndLocationParts = fileAndLocation.components(separatedBy: ":")
        let rawFile = fileAndLocationParts[0]

        guard rawFile != "<invalid loc>" else {
            return nil
        }

        guard
            fileAndLocationParts.count == 3,
            let line = Int(fileAndLocationParts[1]),
            let column = Int(fileAndLocationParts[2])
        else {
            return nil
        }

        let file = prefixWithFileURL(fileName: rawFile)

        return (file, line, column)
    }

    /// Parses
    func parseCompileDuration(_ durationString: String) -> Double {
        if let duration = Double(durationString.replacingOccurrences(of: "ms", with: "")) {
            return duration
        }
        return 0.0
    }

    /// Transforms the fileName to a file URL to match the one in IDELogSection.documentURL
    /// It doesn't use `URL` class to do it, because it was slow in benchmarks
    /// - Parameter fileName: String with a fileName
    /// - Returns: A String with the URL to the file like `file:///`
    func prefixWithFileURL(fileName: String) -> String {
        return "file://\(fileName)"
    }
}
