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

class LexerTests: XCTestCase {

    let lexer = Lexer(filePath: "dummy.xcactivitylog")

    func testTokenizeInt() throws {
        let logContents = "SLF09#"
        let tokens = try lexer.tokenize(contents: logContents, redacted: false, withoutBuildSpecificInformation: false)
        XCTAssertEqual(1, tokens.count)
        let classNameToken = tokens[0]
        XCTAssertEqual(classNameToken, Token.int(9))
    }

    func testTokenizeClassName() throws {
        let logContents = "SLF09#21%IDEActivityLogSection"
        let tokens = try lexer.tokenize(contents: logContents, redacted: false, withoutBuildSpecificInformation: false)
        XCTAssertEqual(2, tokens.count)
        let classNameToken = tokens[1]
        XCTAssertEqual(classNameToken, Token.className("IDEActivityLogSection"))
    }

    func testTokenizeClassNameRef() throws {
        let logContents = "SLF09#21%IDEActivityLogSection1@"
        let tokens = try lexer.tokenize(contents: logContents, redacted: false, withoutBuildSpecificInformation: false)
        XCTAssertTrue(tokens.count == 3)
        let classNameReferenceToken = tokens[2]
        XCTAssertEqual(classNameReferenceToken, Token.classNameRef("IDEActivityLogSection"))
    }

    func testTokenizeString() throws {
        let logContents = "SLF09#21%IDEActivityLogSection1@39\"Xcode.IDEActivityLogDomainType.BuildLog"
        let tokens = try lexer.tokenize(contents: logContents, redacted: false, withoutBuildSpecificInformation: false)
        XCTAssertTrue(tokens.count == 4)
        let stringToken = tokens[3]
        XCTAssertEqual(stringToken, Token.string("Xcode.IDEActivityLogDomainType.BuildLog"))
    }

    func testTokenizeDouble() throws {
        let logContents = "SLF09#21%IDEActivityLogSection1@39\"Xcode.IDEActivityLogDomainType.BuildLog356098f239dfc041^"
        let tokens = try lexer.tokenize(contents: logContents, redacted: false, withoutBuildSpecificInformation: false)
        XCTAssertTrue(tokens.count == 5)
        let doubleToken = tokens[4]
        XCTAssertEqual(doubleToken, Token.double(566129637.19043601))
    }

    func testTokenizeListNil() throws {
        let logContents = "SLF09#21%IDEActivityLogSection1" +
                          "@39\"Xcode.IDEActivityLogDomainType.BuildLog356098f239dfc041^-"
        let tokens = try lexer.tokenize(contents: logContents, redacted: false, withoutBuildSpecificInformation: false)
        XCTAssertTrue(tokens.count == 6)
        let nilToken = tokens[5]
        XCTAssertEqual(nilToken, Token.null)
    }

    func testTokenizeList() throws {
        let logContents = "SLF09#21%IDEActivityLogSection1" +
                            "@39\"Xcode.IDEActivityLogDomainType.BuildLog356098f239dfc041^-242("
        let tokens = try lexer.tokenize(contents: logContents, redacted: false, withoutBuildSpecificInformation: false)
        XCTAssertTrue(tokens.count == 7)
        let listToken = tokens[6]
        XCTAssertEqual(listToken, Token.list(242))
    }

    func testTokenizeError() {
        // `=` is not a valid token identifier, we should throw an error
        let logContents = "SLF09#21%IDEActivityLogSection1" +
        "@39\"Xcode.IDEActivityLogDomainType.BuildLog356098f239dfc041^-242="
        XCTAssertThrowsError(try lexer.tokenize(contents: logContents,
                                                redacted: false,
                                                withoutBuildSpecificInformation: false))
    }

    func testTokenizeStringWithTokenDelimiters() throws {
        let logContents = "SLF09#21%IDEActivityLogSection1" +
        "@38\"##Xcode.IDEActivityLogDomainType.Build356098f239dfc0^-242("
        let tokens = try lexer.tokenize(contents: logContents, redacted: false, withoutBuildSpecificInformation: false)
        XCTAssertTrue(tokens.count == 7)

    }

    func testTokenizeStringRedacted() throws {
        let logContents = "SLF09#21%IDEActivityLogSection1@36\"Compile /Users/myuser/project/File.m"
        let tokens = try lexer.tokenize(contents: logContents, redacted: true, withoutBuildSpecificInformation: false)
        XCTAssertTrue(tokens.count == 4)
        let stringToken = tokens[3]
        XCTAssertEqual(stringToken, Token.string("Compile /Users/<redacted>/project/File.m"))
    }

    func testTokenizeStringWithoutBuildSpecificInformation() throws {
        let logContents = "SLF09#21%IDEActivityLogSection1@346\"/Applications/Xcode.app/Contents/Developer/" +
            "Toolchains/XcodeDefault.xctoolchain/usr/bin/libtool: file: /Users/myuser/Library/Developer/Xcode/" +
            "DerivedData/Product-bolnckhlbzxpxoeyfujluasoupft/Build/Intermediates.noindex/Product.build/" +
            "Debug-iphonesimulator/Library.build/Objects-normal/x86_64/Object.o is not an object file" +
        " (not allowed in a library)"

        let tokens = try lexer.tokenize(contents: logContents, redacted: false, withoutBuildSpecificInformation: true)
        XCTAssertTrue(tokens.count == 4)
        let stringToken = tokens[3]
        XCTAssertEqual(stringToken, Token.string("/Applications/Xcode.app/Contents/Developer/Toolchains/" +
            "XcodeDefault.xctoolchain/usr/bin/libtool: file: /Users/myuser/Library/Developer/Xcode/" +
            "DerivedData/Product/Build/Intermediates.noindex/Product.build/Debug-iphonesimulator/" +
            "Library.build/Objects-normal/x86_64/Object.o is not an object file (not allowed in a library)"))
    }

    func testTokenizeStringRedactedAndWithoutBuildSpecificInformation() throws {
        let logContents = "SLF09#21%IDEActivityLogSection1@346\"/Applications/Xcode.app/Contents/Developer/" +
            "Toolchains/XcodeDefault.xctoolchain/usr/bin/libtool: file: /Users/myuser/Library/Developer/Xcode/" +
            "DerivedData/Product-bolnckhlbzxpxoeyfujluasoupft/Build/Intermediates.noindex/Product.build/" +
            "Debug-iphonesimulator/Library.build/Objects-normal/x86_64/Object.o is not an object file" +
        " (not allowed in a library)"

        let tokens = try lexer.tokenize(contents: logContents, redacted: true, withoutBuildSpecificInformation: true)
        XCTAssertTrue(tokens.count == 4)
        let stringToken = tokens[3]
        XCTAssertEqual(stringToken, Token.string("/Applications/Xcode.app/Contents/Developer/Toolchains/" +
            "XcodeDefault.xctoolchain/usr/bin/libtool: file: /Users/<redacted>/Library/Developer/Xcode/" +
            "DerivedData/Product/Build/Intermediates.noindex/Product.build/Debug-iphonesimulator/" +
            "Library.build/Objects-normal/x86_64/Object.o is not an object file (not allowed in a library)"))
    }
}
