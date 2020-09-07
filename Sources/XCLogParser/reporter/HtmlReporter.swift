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

    public func report(build: Any, output: ReporterOutput, rootOutput: String) throws {
        guard let steps = build as? BuildStep else {
            throw XCLogParserError.errorCreatingReport("Type not supported \(type(of: build))")
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let json = try encoder.encode(steps.flatten())
        guard let jsonString = String(data: json, encoding: .utf8) else {
            throw  XCLogParserError.errorCreatingReport("Can't generate the JSON file.")
        }
        try writeHtmlReport(for: steps, jsonString: jsonString, output: output, rootOutput: rootOutput)
    }

    private func writeHtmlReport(for build: BuildStep,
                                 jsonString: String,
                                 output: ReporterOutput,
                                 rootOutput: String) throws {
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
        try HtmlReporterResources.css.write(toFile: "\(buildDir)/css/styles.css", atomically: true, encoding: .utf8)
        try HtmlReporterResources.appJS.write(toFile: "\(buildDir)/js/app.js", atomically: true, encoding: .utf8)
        try HtmlReporterResources.indexHTML.write(toFile: "\(buildDir)/index.html", atomically: true, encoding: .utf8)
        try HtmlReporterResources.stepJS.write(toFile: "\(buildDir)/js/step.js", atomically: true, encoding: .utf8)
        try HtmlReporterResources.stepHTML.write(toFile: "\(buildDir)/step.html", atomically: true, encoding: .utf8)
        let jsContent = HtmlReporterResources.buildJS.replacingOccurrences(of: "{{build}}", with: jsonString)
        try jsContent.write(toFile: "\(buildDir)/js/build.js", atomically: true, encoding: .utf8)
        print("Report written to \(buildDir)/index.html")
    }

    private func dirFor(build: BuildStep) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYYMMddHHmmss"
        return dateFormatter.string(from: Date(timeIntervalSince1970: Double(build.startTimestamp)))
    }
}
