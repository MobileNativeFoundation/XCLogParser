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
import XCLogParser
#if !swift(>=5.0)
import Result
#endif

struct DumpCommand: CommandProtocol {
    typealias Options = DumpOptions
    let verb = "dump"
    let function = "Dumps the xcactivitylog file into a JSON document"

    func run(_ options: DumpOptions) -> Result<(), CommandantError<Swift.Error>> {
        if !options.hasValidLogOptions() {
            return .failure(.usageError(description:
                """
                    Please, provide a way to locate the .xcactivitylog of your project.
                    You can use --file or --project or --workspace or --xcodeproj. \n
                    Type `xclogparser help parse` to get more information.`
                    """))
        }
        // Dump command only supports json reporter atm
        let reporter = Reporter.json
        let commandHandler = CommandHandler()
        let logOptions = LogOptions(projectName: options.projectName,
                                    xcworkspacePath: options.workspace,
                                    xcodeprojPath: options.xcodeproj,
                                    derivedDataPath: options.derivedData,
                                    xcactivitylogPath: options.logFile,
                                    strictProjectName: options.strictProjectName)
        let actionOptions = ActionOptions(reporter: reporter,
                                           outputPath: options.output,
                                           redacted: options.redacted)
        let action = Action.dump(options: actionOptions)
        let command = Command(logOptions: logOptions, action: action)
        do {
            try commandHandler.handle(command: command)

        } catch {
            return.failure(.commandError(error))
        }
        return .success(())
    }
}

struct DumpOptions: OptionsProtocol {
    let logFile: String
    let derivedData: String
    let projectName: String
    let workspace: String
    let xcodeproj: String
    let redacted: Bool
    let strictProjectName: Bool
    let output: String

    static func create(_ logFile: String)
        -> (_ derivedData: String)
        -> (_ projectName: String)
        -> (_ workspace: String)
        -> (_ xcodeproj: String)
        -> (_ redacted: Bool)
        -> (_ strictProjectName: Bool)
        -> (_ output: String) -> DumpOptions {
            return { derivedData in { projectName in { workspace in { xcodeproj in { redacted
                in { strictProjectName in { output in
                    self.init(logFile: logFile,
                              derivedData: derivedData,
                              projectName: projectName,
                              workspace: workspace,
                              xcodeproj: xcodeproj,
                              redacted: redacted,
                              strictProjectName: strictProjectName,
                              output: output)
                }}}}}}}
    }

    static func evaluate(_ mode: CommandMode) -> Result<DumpOptions, CommandantError<CommandantError<Swift.Error>>> {
        return create
            <*> mode <| fileOption
            <*> mode <| derivedDataOption
            <*> mode <| projectOption
            <*> mode <| workspaceOption
            <*> mode <| xcodeprojOption
            <*> mode <| redactedSwitch
            <*> mode <| strictProjectNameSwitch
            <*> mode <| outputOption
    }

    func hasValidLogOptions() -> Bool {
        return !logFile.isEmpty || !projectName.isEmpty || !workspace.isEmpty || !xcodeproj.isEmpty
    }

}
