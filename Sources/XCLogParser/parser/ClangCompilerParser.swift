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

public class ClangCompilerParser {
    private static let timeTraceCompilerFlag = "-ftime-trace"

    private lazy var timeTraceRegexp: NSRegularExpression? = {
        let pattern = "Time trace json-file dumped to (.*?)\\r"
        return NSRegularExpression.fromPattern(pattern)
    }()

    public func parseTimeTraceFile(_ logSection: IDEActivityLogSection) -> String? {
        guard let regex = timeTraceRegexp else {
            return nil
        }

        guard hasTimeTraceCompilerFlag(commandDesc: logSection.commandDetailDesc) else {
            return nil
        }

        let text = logSection.text
        let range = NSRange(location: 0, length: text.count)
        let matches = regex.matches(in: text, options: .reportProgress, range: range)
        guard let fileRange = matches.first?.range(at: 1) else {
            return nil
        }

        return text.substring(fileRange)
    }

    func hasTimeTraceCompilerFlag(commandDesc: String) -> Bool {
        commandDesc.range(of: Self.timeTraceCompilerFlag) != nil
    }
}
