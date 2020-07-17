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

class ChromeTracerOutputTests: XCTestCase {

    let output = ChromeTracerReporter()

    func testTargetToTraceEvent() {
        let root = getBuildStep()
        let result = output.toTraceEvents(rootStep: root)
        XCTAssertEqual(6, result.count)
        guard let threadEvent = result.first else {
            return
        }
        XCTAssertEqual("thread_name", threadEvent.name)
        XCTAssertEqual("M", threadEvent.ph.rawValue)
        XCTAssertEqual(1, threadEvent.pid)
        XCTAssertEqual(0, threadEvent.tid)

        let startTargetEvent = result[1]
        XCTAssertEqual("MyTarget", startTargetEvent.name)
        XCTAssertEqual("B", startTargetEvent.ph.rawValue)
        XCTAssertEqual(1, threadEvent.pid)
        XCTAssertEqual(0, threadEvent.tid)

        let endTargetEvent = result[2]
        XCTAssertEqual("MyTarget", endTargetEvent.name)
        XCTAssertEqual("E", endTargetEvent.ph.rawValue)
        XCTAssertEqual(1, endTargetEvent.pid)
        XCTAssertEqual(0, endTargetEvent.tid)

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
                             buildStatus: "Build succeeded",
                             schema: "MyApp",
                             subSteps: getTargets(start: start),
                             warningCount: 0,
                             errorCount: 0,
                             architecture: "",
                             documentURL: "",
                             warnings: nil,
                             errors: nil,
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

    // swiftlint:disable function_body_length
    private func getTargets(start: Date) -> [BuildStep] {
        let end = start.addingTimeInterval(50 * 100)
        let target1 = BuildStep(type: .target,
                             machineName: "",
                             buildIdentifier: "ABC",
                             identifier: "ABC1_1",
                             parentIdentifier: "ABC1",
                             domain: "",
                             title: "MyTarget",
                             signature: "Build MyTarget",
                             startDate: "",
                             endDate: "",
                             startTimestamp: start.timeIntervalSince1970,
                             endTimestamp: end.timeIntervalSince1970,
                             duration: 50 * 100,
                             detailStepType: .none,
                             buildStatus: "Build succeeded",
                             schema: "MyApp",
                             subSteps: [BuildStep](),
                             warningCount: 0,
                             errorCount: 0,
                             architecture: "",
                             documentURL: "",
                             warnings: nil,
                             errors: nil,
                             notes: nil,
                             swiftFunctionTimes: nil,
                             fetchedFromCache: false,
                             compilationEndTimestamp: end.timeIntervalSince1970,
                             compilationDuration: 50 * 100,
                             clangTimeTraceFile: nil,
                             linkerStatistics: nil
                             )

        let end2 = end.addingTimeInterval(50 * 100)
        let target2 = BuildStep(type: .target,
                                machineName: "",
                                buildIdentifier: "ABC",
                                identifier: "ABC1_2",
                                parentIdentifier: "ABC1",
                                domain: "",
                                title: "MyTarget2",
                                signature: "Build MyTarget2",
                                startDate: "",
                                endDate: "",
                                startTimestamp: end.timeIntervalSince1970,
                                endTimestamp: end2.timeIntervalSince1970,
                                duration: 50 * 100,
                                detailStepType: .none,
                                buildStatus: "Build succeeded",
                                schema: "MyApp",
                                subSteps: [BuildStep](),
                                warningCount: 0,
                                errorCount: 0,
                                architecture: "",
                                documentURL: "",
                                warnings: nil,
                                errors: nil,
                                notes: nil,
                                swiftFunctionTimes: nil,
                                fetchedFromCache: false,
                                compilationEndTimestamp: end2.timeIntervalSince1970,
                                compilationDuration: 50 * 100,
                                clangTimeTraceFile: nil,
                                linkerStatistics: nil
                                )
        return [target1, target2]

    }

}
