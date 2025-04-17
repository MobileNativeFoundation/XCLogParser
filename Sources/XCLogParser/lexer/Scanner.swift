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

final class Scanner {

    let string: String

    private(set) var offset: Int
    private(set) lazy var stringEndIndex: String.Index = self.string.endIndex

    var isAtEnd: Bool {
        String.Index(compilerSafeOffset: self.offset, in: self.string) >= self.stringEndIndex
    }

    init(string: String) {
        self.string = string
        self.offset = 0
    }

    func scan(count: Int) -> String? {
        let start = String.Index(compilerSafeOffset: self.offset, in: self.string)
        let end = String.Index(compilerSafeOffset: self.offset + count, in: self.string)

        var result = self.string.substring(with: (start..<end))

        guard result.count == count else { return nil }

        self.offset = self.offset + count

        return String(result)
    }

    func scan(string value: String) -> Bool {
        guard self.string.starts(with: value) else { return false }

        self.offset = self.offset + value.count
        return true
    }

    func scanCharacters(from allowedCharacters: Set<Character>) -> String? {
        var prefix: String = ""
        var characterIndex = String.Index(compilerSafeOffset: self.offset, in: self.string)

        while characterIndex < self.stringEndIndex {
            let character = self.string[characterIndex]
            
            guard allowedCharacters.contains(character) else {
                break
            }

            prefix.append(character)
            self.offset = self.offset + 1
            characterIndex = String.Index(utf16Offset: self.offset, in: self.string)
        }

        return prefix
    }

    func moveOffset(by value: Int) {
        self.offset = self.offset + value
    }
}
