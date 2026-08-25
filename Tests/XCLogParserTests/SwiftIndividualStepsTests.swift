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

class SwiftIndividualStepsTests: XCTestCase {

    /// From Xcode 14 on, a batch compilation names its files in the command and the log carries a
    /// subSection per file. Synthesizing steps here would report every file twice.
    func testNoStepsAreSynthesizedWhenTheCommandNamesTheFiles() {
        let command = "SwiftCompile normal arm64 Compiling\\ Bar.swift,\\ Baz.swift "
            + "/path/to/Foo/Bar.swift /path/to/Foo/Baz.swift (in target 'Foo' from project 'Foo')"
        let section = makeSection(commandDetailDesc: command)
        var index = 0

        let steps = section.getSwiftIndividualSteps(buildStep: makeStep(),
                                                    parentCommandDetailDesc: "",
                                                    currentIndex: &index)

        XCTAssertNil(steps)
    }

    /// A whole module command lists the files without compiling them as separate sections, so the
    /// per-file steps have to be derived from the command itself.
    func testStepsAreSynthesizedForAWholeModuleCommand() {
        let command = "/usr/bin/swiftc -module-name Foo -whole-module-optimization "
            + "/path/to/Foo/Bar.swift /path/to/Foo/Baz.swift"
        let section = makeSection(commandDetailDesc: command)
        var index = 0

        let steps = section.getSwiftIndividualSteps(buildStep: makeStep(),
                                                    parentCommandDetailDesc: "",
                                                    currentIndex: &index)

        XCTAssertEqual(["Compile /path/to/Foo/Bar.swift", "Compile /path/to/Foo/Baz.swift"],
                       steps?.map { $0.title })
    }

    private func makeStep() -> BuildStep {
        makeFakeBuildStep(title: "Compiling Bar.swift, Baz.swift",
                          type: .detail,
                          detailStepType: .swiftCompilation,
                          startTimestamp: 0,
                          fetchedFromCache: false)
    }

    private func makeSection(commandDetailDesc: String) -> IDEActivityLogSection {
        IDEActivityLogSection(sectionType: 1,
                              domainType: "",
                              title: "Compiling Bar.swift, Baz.swift",
                              signature: "SwiftCompile normal arm64",
                              timeStartedRecording: 0,
                              timeStoppedRecording: 0,
                              subSections: [],
                              text: "",
                              messages: [],
                              wasCancelled: false,
                              isQuiet: false,
                              wasFetchedFromCache: false,
                              subtitle: "",
                              location: DVTDocumentLocation(documentURLString: "", timestamp: 0),
                              commandDetailDesc: commandDetailDesc,
                              uniqueIdentifier: "",
                              localizedResultString: "",
                              xcbuildSignature: "",
                              attachments: [],
                              unknown: 0)
    }

}
