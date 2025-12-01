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

struct ParseCommand: ParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "parse",
        abstract: "Parses the content of an xcactivitylog file"
    )
    
    @Option(name: .long, help: "Type of .xactivitylog file to look for.")
    var logs: LogType = .build

    @Option(name: .long, help: "The path to a .xcactivitylog file.")
    var file: String?

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

    @Option(name: .long,
            help: """
    Mandatory. The reporter to use. It could be `json`, `flatJson`, `summaryJson`,
    `chromeTracer`, `html` or `btr`
    """)
    var reporter: String?

    @Option(name: .customLong("machine_name"),
            help: """
    Optional. The name of the machine. If not specified, the host name will be used.
    """)
    var machineName: String?

    @Flag(help: """
    Redacts the username of the paths found in the log.
    For instance, /Users/timcook/project will be /Users/<redacted>/project
    """)
    var redacted: Bool = false

    @Flag(name: .customLong("without_build_specific_information"),
          help: """
    Removes build specific information from the logs.
    For instance, DerivedData/Product-bolnckhlbzxpxoeyfujluasoupft/Build
    will be DerivedData/Product/Build
    """)
    var withoutBuildSpecificInformation: Bool = false

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

    @Option(name: .customLong("rootOutput"),
            help: """
    Optional. Add the project output into the given current path,
    example: myGivenPath/report.json.
    """)
    var rootOutput: String?

    @Flag(name: .customLong("omit_warnings"),
          help: """
    If present, the report will omit the Warnings found in the log.
    Useful to reduce the size of the final report.
    """)
    var omitWarnings: Bool = false

    @Flag(name: .customLong("omit_notes"),
          help: """
    If present, the report will omit the Notes found in the log.
    Useful to reduce the size of the final report.
    """)
    var omitNotes: Bool = false

    @Flag(name: .customLong("trunc_large_issues"),
          help: """
    If present, for tasks with more than a 100 issues (warnings, notes or errors)
    Those will be truncated to a 100.
    Useful to reduce the amount of memory used and the size of the report.
    """)
    var truncLargeIssues: Bool = false

    mutating func validate() throws {
        if !hasValidLogOptions() {
            throw ValidationError("""
            Please, provide a way to locate the .xcactivity log of your project.
            You can use --file or --project or --workspace or --xcodeproj.
            Type `xclogparser help parse` to get more information.`
            """)
        }
        guard let reporter = reporter, reporter.isEmpty == false else {
            throw ValidationError("""
            You need to specify a reporter. Type `xclogparser help parse` to see the available ones.
            """)
        }
        guard Reporter(rawValue: reporter) != nil else {
            throw ValidationError("""
                \(reporter) is not a valid reporter. Please provide a valid reporter to use.
                Type `xclogparser help parse` to see the available ones.
                """)
        }
    }

    func run() throws {
        guard let reporter = reporter else {
            return
        }
        guard let xclReporter = Reporter(rawValue: reporter) else {
            return
        }
        let commandHandler = CommandHandler()
        let logOptions = LogOptions(projectName: project ?? "",
                                    xcworkspacePath: workspace ?? "",
                                    xcodeprojPath: xcodeproj ?? "",
                                    derivedDataPath: derivedData ?? "",
                                    xcactivitylogPath: file ?? "",
                                    logType: logs,
                                    strictProjectName: strictProjectName)
        let actionOptions = ActionOptions(reporter: xclReporter,
                                          outputPath: output ?? "",
                                          redacted: redacted,
                                          withoutBuildSpecificInformation: withoutBuildSpecificInformation,
                                          machineName: machineName,
                                          rootOutput: rootOutput ?? "",
                                          omitWarningsDetails: omitWarnings,
                                          omitNotesDetails: omitNotes,
                                          truncLargeIssues: truncLargeIssues)
        let action = Action.parse(options: actionOptions)
        let command = Command(logOptions: logOptions, action: action)
        try commandHandler.handle(command: command)
    }

    private func hasValidLogOptions() -> Bool {
        return !file.isBlank || !project.isBlank || !workspace.isBlank || !xcodeproj.isBlank
    }
}
