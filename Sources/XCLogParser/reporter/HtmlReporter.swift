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

/// Reporter that creates an HTML report.
/// It uses the html and javascript files from the Resources folder as templates
public struct HtmlReporter: LogReporter {

    /// Max number of Swift Type and Function Checks to present in the
    /// main index file
    static let maxSwifTypeChecks = 1_000

    /// Max number of slowest files to present in the main index file
    static let maxSlowestFiles = 20

    public func report(build: Any, output: ReporterOutput, rootOutput: String) throws {
        guard let steps = build as? BuildStep else {
            throw XCLogParserError.errorCreatingReport("Type not supported \(type(of: build))")
        }
        let buildDir = try createDir(for: steps, output: output, rootOutput: rootOutput)
        try writeMainFiles(build: steps, toDir: buildDir)
        try writeTargetFiles(build: steps, toDir: buildDir)
        try writeSharedResources(toDir: buildDir)
        print("Report written to \(buildDir)/index.html")
    }

    private func createDir(for build: BuildStep,
                           output: ReporterOutput,
                           rootOutput: String) throws -> String {
        var path = "build/xclogparser/reports"
        if let output = output as? FileOutput {
            path = output.path
        }
        if !rootOutput.isEmpty {
            path = FileOutput(path: rootOutput).path
        }
        let fileManager = FileManager.default
        var buildDir = "\(path)/\(dirFor(build: build))"
        if !rootOutput.isEmpty {
            buildDir = path
        }
        try fileManager.createDirectory(
            atPath: "\(buildDir)/css",
            withIntermediateDirectories: true,
            attributes: nil)
        try fileManager.createDirectory(
            atPath: "\(buildDir)/js",
            withIntermediateDirectories: true,
            attributes: nil)
        return buildDir
    }

    private func dirFor(build: BuildStep) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYYMMddHHmmss"
        return dateFormatter.string(from: Date(timeIntervalSince1970: Double(build.startTimestamp)))
    }

    /// Writes the HMTL and JS files of the main summary page. The one with the summary of the whole build
    private func writeMainFiles(build: BuildStep, toDir buildDir: String) throws {
        let targetsNoSteps = build.subSteps.map { target -> BuildStep in
            let noSteps = target.with(subSteps: [])
            return noSteps
        }
        let updatedBuild = build.with(subSteps: targetsNoSteps).flatten()
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted

        let json = try encoder.encode(updatedBuild)
        guard let jsonString = String(data: json, encoding: .utf8) else {
            throw  XCLogParserError.errorCreatingReport("Can't generate the Targets JSON files.")
        }
        let jsContent = HtmlReporterResources.buildJS.replacingOccurrences(of: "{{build}}", with: jsonString)
        try jsContent.write(toFile: "\(buildDir)/js/targets.js", atomically: true, encoding: .utf8)

        let appJSContent = HtmlReporterResources.appJS
            .replacingOccurrences(of: "{{target_name}}", with: "main")
            .replacingOccurrences(of: "{{file_name}}",
                                  with: "index.html")
            .replacingOccurrences(of: "{{steps_name}}",
                                  with: "step.html")

        try appJSContent.write(toFile: "\(buildDir)/js/app.js", atomically: true, encoding: .utf8)

        let htmlContent = HtmlReporterResources.indexHTML
            .replacingOccurrences(of: "{{data_file}}", with: "targets.js")
            .replacingOccurrences(of: "{{app_file}}", with: "app.js")
        try htmlContent.write(toFile: "\(buildDir)/index.html", atomically: true, encoding: .utf8)
        try writeTopFiles(build: build, toDir: buildDir)
    }

    /// Writes the HTML and JS for earch target in the build.
    // swiftlint:disable:next function_body_length
    private func writeTargetFiles(build: BuildStep, toDir buildDir: String) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        var stepsWithErrors: [BuildStep] = []
        var stepsWithWarnings: [BuildStep] = []
        try build.subSteps.forEach { target in
            stepsWithErrors.append(contentsOf: getStepsWithErrors(target: target))
            stepsWithWarnings.append(contentsOf: getStepsWithWarnings(target: target))
            let targetName = target.identifier.replacingOccurrences(of: " ", with: "_")
            let name = "\(targetName).js"
            let json = try encoder.encode(target.flatten())
            guard let jsonString = String(data: json, encoding: .utf8) else {
                throw  XCLogParserError.errorCreatingReport("Can't generate the Targets JSON files.")
            }
            let targetContent = "const buildData = \(jsonString);"
            try targetContent.write(toFile: "\(buildDir)/js/\(name)", atomically: true, encoding: .utf8)

            let appJSContent = HtmlReporterResources.appJS
                .replacingOccurrences(of: "{{target_name}}",
                                      with: target.identifier)
                .replacingOccurrences(of: "{{file_name}}",
                                      with: "\(targetName).html")
                .replacingOccurrences(of: "{{steps_name}}",
                                      with: "step_\(targetName).html")
            try appJSContent.write(toFile: "\(buildDir)/js/\(targetName)_app.js", atomically: true, encoding: .utf8)

            let htmlContent = HtmlReporterResources.indexHTML
                .replacingOccurrences(of: "{{data_file}}", with: "\(targetName).js")
                .replacingOccurrences(of: "{{app_file}}", with: "\(targetName)_app.js")
            try htmlContent.write(toFile: "\(buildDir)/\(targetName).html", atomically: true, encoding: .utf8)

            let stepHtmlContent = HtmlReporterResources.stepHTML
                .replacingOccurrences(of: "{{data_file}}", with: "\(targetName).js")
            try stepHtmlContent.write(toFile: "\(buildDir)/step_\(targetName).html",
                                      atomically: true,
                                      encoding: .utf8)
        }
        let jsonErrors = try encoder.encode(stepsWithErrors)
        let jsonWarnings = try encoder.encode(stepsWithWarnings)
        guard let errors = String(data: jsonErrors, encoding: .utf8),
              let warnings = String(data: jsonWarnings, encoding: .utf8) else {
            throw  XCLogParserError.errorCreatingReport("Can't generate the Issues JSON file.")
        }
        let errorsContent = "const stepsWithErrors = \(errors);"
        let warningsContent = "const stepsWithWarnings = \(warnings);"
        let issuesContent = "\(errorsContent)\n\(warningsContent)"
        try issuesContent.write(toFile: "\(buildDir)/js/errors_warnings.js",
                                atomically: true,
                                encoding: .utf8)
    }

    private func writeSharedResources(toDir buildDir: String) throws {
        try HtmlReporterResources.css.write(toFile: "\(buildDir)/css/styles.css", atomically: true, encoding: .utf8)
        try HtmlReporterResources.stepJS.write(toFile: "\(buildDir)/js/step.js", atomically: true, encoding: .utf8)
        try HtmlReporterResources.stepHTML.write(toFile: "\(buildDir)/step.html", atomically: true, encoding: .utf8)
    }

    private func getStepsWithErrors(target: BuildStep) -> [BuildStep] {
        return Array(target.subSteps.map { step -> [BuildStep] in
            var stepsWithErrors: [BuildStep] = []
            if step.detailStepType != .swiftAggregatedCompilation && step.errorCount > 0 {
                stepsWithErrors.append(step)
            }
            stepsWithErrors.append(contentsOf: step.subSteps.filter { $0.errorCount > 0 })
            return stepsWithErrors
        }.joined())

    }

    private func getStepsWithWarnings(target: BuildStep) -> [BuildStep] {
        return Array(target.subSteps.map { step -> [BuildStep] in
            var stepsWithWarnings: [BuildStep] = []
            if step.detailStepType != .swiftAggregatedCompilation && step.warningCount > 0 {
                stepsWithWarnings.append(step)
            }
            stepsWithWarnings.append(contentsOf: step.subSteps.filter { $0.warningCount > 0 })
            return stepsWithWarnings
        }.joined())
    }

    /// Precomputes and Writes the top slowest files and Swift Type checks
    /// of the whole build.
    private func writeTopFiles(build: BuildStep, toDir buildDir: String) throws {
        let steps = build.subSteps.map { $0.subSteps }.joined()
        let aggretatedAndSwiftSteps = steps.filter { !$0.fetchedFromCache &&
            ($0.detailStepType == .swiftCompilation || $0.detailStepType == .swiftAggregatedCompilation) }
        var swiftFunctionTimes: [SwiftFunctionTime] = []
        var swiftTypeCheckTimes: [SwiftTypeCheck] = []
        var swiftSteps: [BuildStep] = []

        aggretatedAndSwiftSteps.forEach { step in
            if step.detailStepType == .swiftAggregatedCompilation {
                let swiftSubSteps = step.subSteps.filter { $0.detailStepType == .swiftCompilation}
                    .map { subStep in
                        subStep.with(parentIdentifier: step.parentIdentifier)
                    }
                swiftSteps.append(contentsOf: swiftSubSteps)
                let functions = swiftSubSteps
                    .compactMap { $0.swiftFunctionTimes }
                    .joined()
                let typeChecks = swiftSubSteps
                    .compactMap { $0.swiftTypeCheckTimes }
                    .joined()
                swiftFunctionTimes.append(contentsOf: functions)
                swiftTypeCheckTimes.append(contentsOf: typeChecks)
            } else {
                swiftSteps.append(step)
                if let functions = step.swiftFunctionTimes {
                    swiftFunctionTimes.append(contentsOf: functions)
                }
                if let typeChecks = step.swiftTypeCheckTimes {
                    swiftTypeCheckTimes.append(contentsOf: typeChecks)
                }
            }
        }

        swiftSteps.sort { $0.compilationDuration > $1.compilationDuration }
        let cSteps = steps.filter { !$0.fetchedFromCache && $0.detailStepType == .cCompilation }
            .sorted { $0.compilationDuration > $1.compilationDuration }

        swiftFunctionTimes.sort { $0.durationMS > $1.durationMS }
        let topFunctions = Array(swiftFunctionTimes.prefix(Self.maxSwifTypeChecks))

        swiftTypeCheckTimes.sort { $0.durationMS > $1.durationMS }
        let topTypeChecks = Array(swiftTypeCheckTimes.prefix(Self.maxSwifTypeChecks))

        try write(
            slowestSwiftFiles: Array(swiftSteps.prefix(Self.maxSlowestFiles)),
            slowestCFiles: Array(cSteps.prefix(Self.maxSlowestFiles)),
            swiftFunctionTimes: topFunctions,
            swiftTypeCheckTimes: topTypeChecks,
            toDir: buildDir)

    }

    private func write(slowestSwiftFiles: [BuildStep],
                       slowestCFiles: [BuildStep],
                       swiftFunctionTimes: [SwiftFunctionTime],
                       swiftTypeCheckTimes: [SwiftTypeCheck],
                       toDir buildDir: String) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let functionsJson = try encoder.encode(swiftFunctionTimes)
        let typeChecksJson = try encoder.encode(swiftTypeCheckTimes)
        let swiftJson = try encoder.encode(slowestSwiftFiles)
        let cJson = try encoder.encode(slowestCFiles)
        guard let functionsString = String(data: functionsJson, encoding: .utf8),
              let typeChecksString = String(data: typeChecksJson, encoding: .utf8),
              let swiftString = String(data: swiftJson, encoding: .utf8),
              let cString = String(data: cJson, encoding: .utf8)
        else {
            throw  XCLogParserError.errorCreatingReport("Can't generate the Swift Type Checks JSON files.")
        }
        try """
        const cSlowestFiles = \(cString);

        const swiftSlowestFiles = \(swiftString);

        const topSwiftFunctions = \(functionsString);

        const topSwifTypeChecks = \(typeChecksString);
        """.write(toFile: "\(buildDir)/js/top_files.js", atomically: true, encoding: .utf8)
    }
}
