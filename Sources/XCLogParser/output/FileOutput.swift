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
import Path

public final class FileOutput: ReporterOutput {

    let path: String

    public init(path: String) {
        let absolutePath = Path(path) ?? Path.cwd/path
        self.path = absolutePath.string
    }

    public func write(report: Any) throws {
        switch report {
        case let data as Data:
            try write(data: data)
        case let tokens as [Token]:
            try write(tokens: tokens)
        default:
            throw XCLogParserError.errorCreatingReport("Can't write the report. Type not supported \(type(of: report)).")
        }
    }

    private func write(data: Data) throws {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: path) {
            throw XCLogParserError.errorCreatingReport("Can't write the report to \(path). A file already exists.")
        }
        let url = URL(fileURLWithPath: path)
        try data.write(to: url)
        print("File written to \(path)")
    }

    private func write(tokens: [Token]) throws {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: path) == false
             else {
            throw XCLogParserError.errorCreatingReport("Can't write the report to \(path). A file already exists.")
        }
        fileManager.createFile(atPath: path, contents: nil, attributes: nil)
        guard let fileHandle = FileHandle.init(forWritingAtPath: path) else {
            throw XCLogParserError.errorCreatingReport("Can't write the report to \(path). File can't be created.")
        }
        defer {
            fileHandle.closeFile()
        }
        for token in tokens {
            guard let data = "\(token)\n".data(using: .utf8) else {
                throw XCLogParserError.errorCreatingReport("Can't write the report to \(path)." +
                                                            "Token can't be serialized \(token).")
            }
            fileHandle.write(data)
        }
        print("File written to \(path)")
    }

}
