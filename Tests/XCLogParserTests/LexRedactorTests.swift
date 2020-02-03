// Copyright (c) 2020 Spotify AB.
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
import XCTest
@testable import XCLogParser


class LexRedactorTests: XCTestCase {
    let redactor = LexRedactor()

    func testRedacting() {

        let redactedText = redactor.redactUserDir(string: "Some /Users/private/path")

        XCTAssertEqual(redactedText, "Some /Users/<redacted>/path")
    }

    func testMultiplePathsRedacting() {

        let redactedText = redactor.redactUserDir(string: "Some /Users/private/path and other /Users/private/path2")

        XCTAssertEqual(redactedText, "Some /Users/<redacted>/path and other /Users/<redacted>/path2")
    }

    func testRedactingFillsUserDir() {
        _ = redactor.redactUserDir(string: "Some /Users/private/path")

        XCTAssertEqual(redactor.userDirToRedact, "/Users/private/")
    }

    func testPredefinedUserDirIsRedacted() {
        redactor.userDirToRedact = "/Users/private/"

        let redactedText = redactor.redactUserDir(string: "Some /Users/private/path")

        XCTAssertEqual(redactedText, "Some /Users/<redacted>/path")
    }

    func testNotInPredefinedUserDirIsNotRedacted() {
        redactor.userDirToRedact = "/Users/priv/"

        let redactedText = redactor.redactUserDir(string: "Some /Users/private/path")

        XCTAssertEqual(redactedText, "Some /Users/private/path")
    }
}
