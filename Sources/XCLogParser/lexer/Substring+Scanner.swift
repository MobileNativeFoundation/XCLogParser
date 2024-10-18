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

extension Substring {

    mutating func scan(count: Int) -> Substring? {
        let result = self.prefix(count)
        guard result.count == count else { return nil }

        self.removeFirst(count)
        return result
    }

    mutating func scan<C>(prefix: C) -> Bool where C: Collection, C.Element == Character {
        guard self.starts(with: prefix) else { return false }

        self.removeFirst(prefix.count)
        return true
    }

    mutating func scanCharacters(in allowedCharacters: Set<Character>) -> String? {
        var prefix: String = ""

        for character in self {
            if allowedCharacters.contains(character) {
                prefix.append(character)
            } else {
                break
            }
        }
        self.removeFirst(prefix.count)
        return prefix
    }

    mutating func moveStartIndex(offset: Int, originalString: String) {
        let newOriginalIndex = originalString.index(self.startIndex, offsetBy: offset)
        self = originalString[newOriginalIndex...self.endIndex]
    }
}
