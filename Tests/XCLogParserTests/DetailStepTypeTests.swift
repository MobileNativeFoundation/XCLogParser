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

/// Signatures in this file are taken from an Xcode 26.5 build log, with paths and module names
/// replaced. Xcode renamed the Swift compilation tasks, so both spellings have to be recognized.
class DetailStepTypeTests: XCTestCase {

    func testSwiftCompileOfASingleFileIsASwiftCompilation() {
        let signature = "SwiftCompile normal arm64 /path/to/Foo/Bar.swift "
            + "(in target 'Foo' from project 'Foo')"

        XCTAssertEqual(.swiftCompilation, DetailStepType.getDetailType(signature: signature))
    }

    func testSwiftCompileOfABatchIsASwiftCompilation() {
        let signature = "SwiftCompile normal arm64 Compiling\\ Bar.swift,\\ Baz.swift "
            + "(in target 'Foo' from project 'Foo')"

        XCTAssertEqual(.swiftCompilation, DetailStepType.getDetailType(signature: signature))
    }

    func testCompileSwiftFromOlderXcodeVersionsIsStillASwiftCompilation() {
        let signature = "CompileSwift normal arm64 /path/to/Foo/Bar.swift"

        XCTAssertEqual(.swiftCompilation, DetailStepType.getDetailType(signature: signature))
    }

    func testSwiftDriverIsAnAggregatedCompilation() {
        let signature = "SwiftDriver Foo normal arm64 com.apple.xcode.tools.swift.compiler "
            + "(in target 'Foo' from project 'Foo')"

        XCTAssertEqual(.swiftAggregatedCompilation, DetailStepType.getDetailType(signature: signature))
    }

    func testCompileSwiftSourcesFromOlderXcodeVersionsIsStillAnAggregatedCompilation() {
        let signature = "CompileSwiftSources normal arm64 com.apple.xcode.tools.swift.compiler"

        XCTAssertEqual(.swiftAggregatedCompilation, DetailStepType.getDetailType(signature: signature))
    }

    /// `SwiftDriverJobDiscovery` shares its first eleven characters with `SwiftDriver`, and it is
    /// not a compilation step: a prefix without the trailing space would swallow it.
    func testSwiftDriverJobDiscoveryIsNotAnAggregatedCompilation() {
        let signature = "SwiftDriverJobDiscovery normal arm64 Emitting module for Foo "
            + "(in target 'Foo' from project 'Foo')"

        XCTAssertEqual(.other, DetailStepType.getDetailType(signature: signature))
    }

}
