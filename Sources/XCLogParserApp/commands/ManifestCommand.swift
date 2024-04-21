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

import ArgumentParser
import XCLogParser

struct ManifestCommand: ParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "manifest",
        abstract: "Shows the content of a LogManifest plist file as a JSON document."
    )
    
    @Option(name: .long, help: "Type of .xactivitylog file to look for.")
    var logs: LogType = .build

    @Option(name: .customLong("long_manifest"), help: "The path to an existing LogStoreManifest.plist.")
    var logManifest: String?

    @Option(name: .customLong("derived_data"),
            help: """
    The path to the DerivedData directory.
    Use it if it's not the default ~/Library/Developer/Xcode/DerivedData/.
    """)
    var derivedData: String?

    @Option(name: .long,
            help: """
    The name of an Xcode project. The tool will try to find the latest log folder
    with this prefix in the DerivedData directory. Use with `--strictProjectName`
    for stricter name matching.
    """)
    var project: String?

    @Option(name: .long,
            help: """
    The path to the .xcworkspace folder. Used to find the Derived Data project directory
    if no `--project` flag is present.
    """)
    var workspace: String?

    @Option(name: .long,
            help: """
    The path to the .xcodeproj folder. Used to find the Derived Data project directory
    if no `--project` and no `--workspace` flag is present.
    """)
    var xcodeproj: String?

    @Flag(name: .customLong("strictProjectName"),
          help: """
    Use strict name testing when trying to find the latest version of the project
    in the DerivedData directory.
    """)
    var strictProjectName: Bool = false

    @Option(name: .long,
            help: """
    Optional. Path to which the report will be written to. If not specified,
    the report will be written to the standard output.
    """)
    var output: String?

    mutating func validate() throws {
        if !hasValidLogOptions() {
            throw ValidationError("""
            Please, provide a way to locate the .xcactivity log of your project.
            You can use --file or --project or --workspace or --xcodeproj.
            Type `xclogparser help manifest` to get more information.`
            """)
        }
    }

    func run() throws {
        let commandHandler = CommandHandler()
        let logOptions = LogOptions(projectName: project ?? "",
                                    xcworkspacePath: workspace ?? "",
                                    xcodeprojPath: xcodeproj ?? "",
                                    derivedDataPath: derivedData ?? "",
                                    logType: logs,
                                    logManifestPath: logManifest ?? "",
                                    strictProjectName: strictProjectName)

        let actionOptions = ActionOptions(reporter: .json,
                                          outputPath: output ?? "",
                                          redacted: false,
                                          withoutBuildSpecificInformation: false)
        let action = Action.manifest(options: actionOptions)
        let command = Command(logOptions: logOptions, action: action)

        try commandHandler.handle(command: command)
    }

    private func hasValidLogOptions() -> Bool {
        return !logManifest.isBlank || !project.isBlank || !workspace.isBlank || !xcodeproj.isBlank
    }
}
