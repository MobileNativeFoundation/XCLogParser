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
import Commandant
import Result
import XCLogParser

struct ParseCommand: CommandProtocol {
    typealias Options = ParseOptions
    let verb = "parse"
    let function = "Parses the content of an xcactivitylog file"

    func run(_ options: ParseOptions) -> Result<(), CommandantError<Swift.Error>> {
        if !options.hasValidLogOptions() {
            return .failure(.usageError(description:
                """
                    Please, provide a way to locate the .xcactivity log of your project.
                    You can use --file or --project or --workspace or --xcodeproj. \n
                    Type `xclogparser help parse` to get more information.`
                    """))
        }
        if options.reporter.isEmpty {
            return .failure(.usageError(description:
                """
                You need to specify a reporter. Type `xclogparser help parse` to see the available ones.
                """))
        }
        guard let reporter = Reporter(rawValue: options.reporter) else {
            return .failure(.usageError(description:
                """
                \(options.reporter) is not a valid reporter. Please provide a valid reporter to use.
                Type `xclogparser help parse` to see the available ones.
                """))
        }
        let commandHandler = CommandHandler()
        let logOptions = LogOptions(projectName: options.projectName,
                                    xcworkspacePath: options.workspace,
                                    xcodeprojPath: options.xcodeproj,
                                    derivedDataPath: options.derivedData,
                                    xcactivitylogPath: options.logFile)
        let actionOptions = ActionOptions(reporter: reporter,
                                          outputPath: options.output,
                                          redacted: options.redacted)
        let action = Action.parse(options: actionOptions)
        let command = Command(logOptions: logOptions, action: action)
        do {
            try commandHandler.handle(command: command)
        } catch {
            return.failure(.commandError(error))
        }
        return .success(())
    }

}

struct ParseOptions: OptionsProtocol {
    let logFile: String
    let derivedData: String
    let projectName: String
    let workspace: String
    let xcodeproj: String
    let reporter: String
    let redacted: Bool
    let output: String

    static func create(_ logFile: String)
        -> (_ derivedData: String)
        -> (_ projectName: String)
        -> (_ workspace: String)
        -> (_ xcodeproj: String)
        -> (_ reporter: String)
        -> (_ redacted: Bool)
        -> (_ output: String) -> ParseOptions {
        return { derivedData in { projectName in { workspace in { xcodeproj in { reporter in { redacted in {
            output in
            self.init(logFile: logFile,
                      derivedData: derivedData,
                      projectName: projectName,
                      workspace: workspace,
                      xcodeproj: xcodeproj,
                      reporter: reporter,
                      redacted: redacted,
                      output: output)
            }}}}}}}
    }

    static func evaluate(_ mode: CommandMode) -> Result<ParseOptions, CommandantError<CommandantError<Swift.Error>>> {
        return create
            <*> mode <| fileOption
            <*> mode <| derivedDataOption
			<*> mode <| projectOption
            <*> mode <| workspaceOption
            <*> mode <| xcodeprojOption
            <*> mode <| Option(
                key: "reporter",
                defaultValue: "",
                usage: "The reporter to use. It could be `json`, `flatJson`, `chromeTracer`, `html` or `btr`")
            <*> mode <| redactedSwitch
            <*> mode <| outputOption
    }

    func hasValidLogOptions() -> Bool {
        return !logFile.isEmpty || !projectName.isEmpty || !workspace.isEmpty || !xcodeproj.isEmpty
    }

}
