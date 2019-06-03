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

class SwiftFunctionTimesParserTests: XCTestCase {

    func testParseFunctionTimes() {
        let text =
        "0.05ms\t/Users/user/myapp/MyView.swift:9:9\tgetter textLabel\r" +
        "4.96ms\t/Users/user/myapp/MyView.swift:11:14\tinitializer init(frame:)\r" +
        "0.04ms\t<invalid loc>\tgetter None\r"
        let parser = SwiftFunctionTimesParser()
        guard let functionTimes = parser.parseFunctionTimes(from: text) else {
            XCTFail("Function times should have two elements")
            return
        }
        XCTAssertEqual(2, functionTimes.count)
        let getter = functionTimes[0]
        let initializer = functionTimes[1]
        XCTAssertEqual(0.05, getter.durationMS)
        XCTAssertEqual(9, getter.startingLine)
        XCTAssertEqual(9, getter.startingColumn)
        XCTAssertEqual("file:///Users/user/myapp/MyView.swift", getter.file)
        XCTAssertEqual("getter textLabel", getter.signature)
        XCTAssertEqual("initializer init(frame:)", initializer.signature)

    }

}
