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

import XCTest
@testable import XCLogParser

class IssuesReporterTests: XCTestCase {

    func testReport() throws {
        let issuesReporter = IssuesReporter()

        // Build with no issues
        let buildStep = getBuildStep()
        let fakeOutput = FakeOutput()
        try issuesReporter.report(build: buildStep, output: fakeOutput)
        guard let emptyIssues = try fakeOutput.getIssues() else {
            XCTFail("Issues should not be nil")
            return
        }
        XCTAssertTrue(emptyIssues.warnings.isEmpty && emptyIssues.errors.isEmpty)

        // Build with issues
        let stepWithIssues = getBuildStepWithIssues()
        let fakeOutputWithIssues = FakeOutput()
        try issuesReporter.report(build: stepWithIssues, output: fakeOutputWithIssues)
        guard let issues = try fakeOutputWithIssues.getIssues() else {
            XCTFail("Issues should not be nil")
            return
        }
        XCTAssertTrue(issues.warnings.count == 1)
        XCTAssertTrue(issues.errors.count == 1)
    }

    private func getBuildStep() -> BuildStep {
        let start = Date()
        let end = start.addingTimeInterval(100 * 100)
        let root = BuildStep(type: .main,
                             machineName: "",
                             buildIdentifier: "ABC",
                             identifier: "ABC1",
                             parentIdentifier: "",
                             domain: "",
                             title: "MyApp",
                             signature: "Build MyApp",
                             startDate: "",
                             endDate: "",
                             startTimestamp: start.timeIntervalSince1970,
                             endTimestamp: end.timeIntervalSince1970,
                             duration: 100 * 100,
                             detailStepType: .none,
                             buildStatus: "Build Failed",
                             schema: "MyApp",
                             subSteps: [],
                             warningCount: 1,
                             errorCount: 1,
                             architecture: "",
                             documentURL: "",
                             warnings: [],
                             errors: [],
                             notes: nil,
                             swiftFunctionTimes: nil,
                             fetchedFromCache: false,
                             compilationEndTimestamp: end.timeIntervalSince1970,
                             compilationDuration: 100 * 100,
                             clangTimeTraceFile: nil,
                             linkerStatistics: nil
        )
        return root
    }

    // swiftlint:disable:next function_body_length
    private func getBuildStepWithIssues() -> BuildStep {
        let start = Date()
        let end = start.addingTimeInterval(100 * 100)
        let root = BuildStep(type: .main,
                             machineName: "",
                             buildIdentifier: "ABC",
                             identifier: "ABC1",
                             parentIdentifier: "",
                             domain: "",
                             title: "MyApp",
                             signature: "Build MyApp",
                             startDate: "",
                             endDate: "",
                             startTimestamp: start.timeIntervalSince1970,
                             endTimestamp: end.timeIntervalSince1970,
                             duration: 100 * 100,
                             detailStepType: .none,
                             buildStatus: "Build Failed",
                             schema: "MyApp",
                             subSteps: [getTargetWithError()],
                             warningCount: 1,
                             errorCount: 1,
                             architecture: "",
                             documentURL: "",
                             warnings: [
                                Notice(type: .projectWarning,
                                       title: "project warning",
                                       clangFlag: nil,
                                       documentURL: "",
                                       severity: 2,
                                       startingLineNumber: 0,
                                       endingLineNumber: 0,
                                       startingColumnNumber: 0,
                                       endingColumnNumber: 0,
                                       characterRangeEnd: 0,
                                       characterRangeStart: 0,
                                       interfaceBuilderIdentifier: nil)
            ],
                             errors: [],
                             notes: nil,
                             swiftFunctionTimes: nil,
                             fetchedFromCache: false,
                             compilationEndTimestamp: end.timeIntervalSince1970,
                             compilationDuration: 100 * 100,
                             clangTimeTraceFile: nil,
                             linkerStatistics: nil
        )
        return root
    }

    // swiftlint:disable:next function_body_length
    private func getTargetWithError() -> BuildStep {
        let start = Date()
        let end = start.addingTimeInterval(100 * 100)
        return BuildStep(type: .target,
                         machineName: "",
                         buildIdentifier: "ABC",
                         identifier: "ABC2",
                         parentIdentifier: "",
                         domain: "",
                         title: "MyTarget",
                         signature: "Build MyTarget",
                         startDate: "",
                         endDate: "",
                         startTimestamp: start.timeIntervalSince1970,
                         endTimestamp: end.timeIntervalSince1970,
                         duration: 100 * 100,
                         detailStepType: .none,
                         buildStatus: "Build Failed",
                         schema: "MyApp",
                         subSteps: [],
                         warningCount: 1,
                         errorCount: 1,
                         architecture: "",
                         documentURL: "",
                         warnings: [],
                         errors: [
                            Notice(type: .swiftError,
                                   title: "Error",
                                   clangFlag: nil,
                                   documentURL: "file:///MyFile.swift",
                                   severity: 1,
                                   startingLineNumber: 10,
                                   endingLineNumber: 10,
                                   startingColumnNumber: 8,
                                   endingColumnNumber: 30,
                                   characterRangeEnd: 10,
                                   characterRangeStart: 10,
                                   interfaceBuilderIdentifier: nil)
            ],
                         notes: nil,
                         swiftFunctionTimes: nil,
                         fetchedFromCache: false,
                         compilationEndTimestamp: end.timeIntervalSince1970,
                         compilationDuration: 100 * 100,
                         clangTimeTraceFile: nil,
                         linkerStatistics: nil
        )
    }
}

private class FakeOutput: ReporterOutput {

    var data: Data?

    func write(report: Any) throws {
        if let reportData = report as? Data {
            data = reportData
        }
    }

    func getIssues() throws -> Issues? {
        guard let data = data else {
            return nil
        }
        let decoder = JSONDecoder()
        return try decoder.decode(Issues.self, from: data)
    }

}
