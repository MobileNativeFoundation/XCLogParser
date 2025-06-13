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

public struct CommandHandler {

    let logFinder: LogFinder
    let activityLogParser: ActivityParser

    public init(
        logFinder: LogFinder = .init(),
        activityLogParser: ActivityParser = .init()
    ) {
        self.logFinder = logFinder
        self.activityLogParser = activityLogParser
    }

    public func handle(command: Command) throws {
        switch command.action {
        case .dump(let options):
            let logURL = try logFinder.findLatestLogWithLogOptions(command.logOptions)
            try handleDump(fromLogURL: logURL, options: options)
        case .manifest(let options):
            try handleManifestWithLogOptions(command.logOptions, andActionOptions: options)
        case .parse(let options):
            let logURL = try logFinder.findLatestLogWithLogOptions(command.logOptions)
            try handleParse(fromLogURL: logURL, options: options)
        }
    }

    func handleManifestWithLogOptions(_ logOptions: LogOptions,
                                      andActionOptions actionOptions: ActionOptions) throws {
        let logManifest = LogManifest()
        let logManifestEntries = try logManifest.getWithLogOptions(logOptions)
        let reporterOutput = ReporterOutputFactory.makeReporterOutput(path: actionOptions.outputPath)
        let logReporter = actionOptions.reporter.makeLogReporter()
        try logReporter.report(build: logManifestEntries, output: reporterOutput, rootOutput: actionOptions.rootOutput)
    }

    func handleDump(fromLogURL logURL: URL, options: ActionOptions) throws {
        let activityLog = try activityLogParser.parseActivityLogInURL(logURL,
                                                                      redacted: options.redacted,
                                                                      withoutBuildSpecificInformation: options.withoutBuildSpecificInformation) // swiftlint:disable:this line_length
        let reporterOutput = ReporterOutputFactory.makeReporterOutput(path: options.outputPath)
        let logReporter = options.reporter.makeLogReporter()
        try logReporter.report(build: activityLog, output: reporterOutput, rootOutput: options.rootOutput)
    }

    func handleParse(fromLogURL logURL: URL, options: ActionOptions) throws {
        let activityLog = try activityLogParser.parseActivityLogInURL(logURL,
                                                                      redacted: options.redacted,
                                                                      withoutBuildSpecificInformation:
                                                                        options.withoutBuildSpecificInformation)

        let buildParser = ParserBuildSteps(machineName: options.machineName,
                                           omitWarningsDetails: options.omitWarningsDetails,
                                           omitNotesDetails: options.omitNotesDetails,
                                           truncLargeIssues: options.truncLargeIssues)
        let buildSteps = try buildParser.parse(activityLog: activityLog)
        let reporterOutput = ReporterOutputFactory.makeReporterOutput(path: options.outputPath)
        let logReporter = options.reporter.makeLogReporter()
        try logReporter.report(build: buildSteps, output: reporterOutput, rootOutput: options.rootOutput)
    }

}
