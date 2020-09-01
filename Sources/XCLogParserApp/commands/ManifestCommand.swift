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

struct ManifestCommand: CommandProtocol {
    typealias Options = ManifestOptions
    let verb = "manifest"
    let function = "Shows the content of a LogManifest plist file as a JSON document."

    func run(_ options: ManifestOptions) -> Result<(), CommandantError<Swift.Error>> {
        if !options.isValid() {
            return .failure(.usageError(description:
                """
                Please, provide a way to locate the Log Manifest file.
                You can use --log_manifest, --project, --workspace or --xcodeproj. \n
                Type `xclogparser help manifest` to get more information.`
                """))
        }
        // Manifest command only supports json reporter atm
        let reporter = Reporter.json
        let commandHandler = CommandHandler()
        let logOptions = LogOptions(projectName: options.projectName,
                                    xcworkspacePath: options.workspace,
                                    xcodeprojPath: options.xcodeproj,
                                    derivedDataPath: options.derivedData,
                                    logManifestPath: options.logManifest,
                                    strictProjectName: options.strictProjectName)
        let actionOptions = ActionOptions(reporter: reporter,
                                          outputPath: options.output,
                                          redacted: false,
                                          withoutBuildSpecificInformation: false)
        let action = Action.manifest(options: actionOptions)
        let command = Command(logOptions: logOptions, action: action)
        do {
            try commandHandler.handle(command: command)

        } catch {
            return.failure(.commandError(error))
        }
        return .success(())
    }

}

struct ManifestOptions: OptionsProtocol {
    let derivedData: String
    let projectName: String
    let workspace: String
    let xcodeproj: String
    let logManifest: String
    let output: String
    let strictProjectName: Bool

    static func create(_ derivedData: String) ->
        (_ projectName: String) ->
        (_ workspace: String) ->
        (_ xcodeproj: String) ->
        (_ logManifest: String) ->
        (_ output: String) ->
        (_ strictProjectName: Bool) ->
        ManifestOptions {
            return { projectName in { workspace in { xcodeproj in { logManifest in { output in { strictProjectName in
                self.init(derivedData: derivedData,
                          projectName: projectName,
                          workspace: workspace,
                          xcodeproj: xcodeproj,
                          logManifest: logManifest,
                          output: output,
                          strictProjectName: strictProjectName)

                }}}}}}
    }

    static func evaluate(_ mode: CommandMode) -> Result<ManifestOptions,
        CommandantError<CommandantError<Swift.Error>>> {
            return create
                <*> mode <| derivedDataOption
                <*> mode <| projectOption
                <*> mode <| workspaceOption
                <*> mode <| xcodeprojOption
                <*> mode <| Option(key: "log_manifest",
                                   defaultValue: "",
                                   usage: "The path to an existing LogStoreManifest.plist.")
                <*> mode <| Option(key: "output",
                                   defaultValue: "",
                                   usage: "Optional. The path where to write the log entry.\n" +
                                   "If not specified, it will be writen to the Standard output")
                <*> mode <| strictProjectNameSwitch
    }

    func isValid() -> Bool {
        return !logManifest.isEmpty || !projectName.isEmpty || !workspace.isEmpty || !xcodeproj.isEmpty
    }

}
