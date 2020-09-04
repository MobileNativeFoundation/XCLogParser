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

import XCTest
@testable import XCLogParser

final class StringBuildSpecificInformationRemovalTest: XCTestCase {
    func testRemoveProductBuildIdentifierWithLogContainingProductBuildIdentifierRemovesProductBuildIdentifier() {
        let log = """
        Some /Library/Developer/Xcode/DerivedData/Product-bolnckhlbzxpxoeyfujluasoupft/Build/Intermediates.noindex/
        """

        let result = log.removeProductBuildIdentifier()

        XCTAssertEqual(result, "Some /Library/Developer/Xcode/DerivedData/Product/Build/Intermediates.noindex/")
    }

    func testRemoveProductBuildIdentifierWithLogContainingMultipleProductBuildIdentifiersRemovesAllOfThem() {
        let log = """
        Some /Library/Developer/Xcode/DerivedData/Product-bolnckhlbzxpxoeyfujluasoupft/Build/Intermediates.noindex/
        is not an object file (not allowed in a library)
        /Library/Developer/Xcode/DerivedData/Product-bouasoupft/Build/
        """

        let result = log.removeProductBuildIdentifier()

        XCTAssertEqual(result, """
        Some /Library/Developer/Xcode/DerivedData/Product/Build/Intermediates.noindex/
        is not an object file (not allowed in a library)
        /Library/Developer/Xcode/DerivedData/Product/Build/
        """)
    }

    func testRemoveProductBuildIdentifierWithLogNotContainingProductBuildIdentifierIsNoop() {
        let log = "Some /Library/Developer/Xcode/DerivedData/Product/Build/Intermediates.noindex/"

        let result = log.removeProductBuildIdentifier()

        XCTAssertEqual(result, log)
    }

    func testRemoveHexadecimalNumbersWithLogContainingHexadecimalNumberRemovesHexadecimalNumber() {
        let log = """
        UserInfo={NSUnderlyingError=0x7fcdc8712290 {Error Domain=kCFErrorDomainCFNetwork Code=-1003 "(null)"
        UserInfo={_kCFStreamErrorCodeKey=8, _kCFStreamErrorDomainKey=12}}
        """

        let result = log.removeHexadecimalNumbers()

        XCTAssertEqual(result, """
        UserInfo={NSUnderlyingError=<hexadecimal_number> {Error Domain=kCFErrorDomainCFNetwork Code=-1003 \"(null)\"
        UserInfo={_kCFStreamErrorCodeKey=8, _kCFStreamErrorDomainKey=12}}
        """)
    }

    func testRemoveHexadecimalNumbersWithLogContainingMultipleHexadecimalNumbersRemovesAllOfThem() {
        let log = """
        {NSUnderlyingError=0x7fb6d57290c0 {Error Domain=kCFErrorDomainCFNetwork Code=-1005 "(null)"
        UserInfo={NSErrorPeerAddressKey=<CFData 0x7fb6d562c810 [0x7fffa8cc28e0]>{length = 16, capacity = 16,
        bytes = 0x100200500aad1b7e0000000000000000}
        """

        let result = log.removeHexadecimalNumbers()

        XCTAssertEqual(result, """
        {NSUnderlyingError=<hexadecimal_number> {Error Domain=kCFErrorDomainCFNetwork Code=-1005 "(null)"
        UserInfo={NSErrorPeerAddressKey=<CFData <hexadecimal_number> [<hexadecimal_number>]>{length = 16, capacity = 16,
        bytes = <hexadecimal_number>}
        """)
    }

    func testRemoveHexadecimalNumbersWithLogNotContainingHexadecimalNumbersIsNoop() {
        let log = """
        UserInfo={NSUnderlyingError=7fcdc8712290 {Error Domain=kCFErrorDomainCFNetwork Code=-1003 \"(null)\"
        UserInfo={_kCFStreamErrorCodeKey=8, _kCFStreamErrorDomainKey=12}}
        """

        let result = log.removeHexadecimalNumbers()

        XCTAssertEqual(result, log)
    }
}
