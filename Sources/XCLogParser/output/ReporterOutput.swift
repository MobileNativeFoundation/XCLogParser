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

/// Protocol thar represents the output of a report
public protocol ReporterOutput {

    /// Writes the report to the output
    func write(report: Any) throws

}

public struct ReporterOutputFactory {

    /// Creates a `ReporterOutput` based on the path passed
    /// - parameter path: If the path is empty, the reporter will be writter using `StandardOutput`
    /// If not, a `FileOutput` will be used
    /// - returns: An instance of `ReporterOutput` configured with the given path
    public static func makeReporterOutput(path: String?) -> ReporterOutput {
        if let path = path, path.isEmpty == false {
            return FileOutput(path: path)
        }
        return StandardOutput()
    }

}
