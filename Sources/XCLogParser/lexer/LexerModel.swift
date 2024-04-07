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

public enum TokenType: String, CaseIterable {
    case int = "#"
    case className = "%"
    case classNameRef = "@"
    case string = "\""
    case double = "^"
    case null = "-"
    case list = "("
    case json = "*"

    static func all() -> String {
        return TokenType.allCases.reduce(String()) {
            return "\($0)\($1.rawValue)"
        }
    }
}

public enum Token: CustomDebugStringConvertible, Equatable {
    case int(UInt64)
    case className(String)
    case classNameRef(String)
    case string(String)
    case double(Double)
    case null
    case list(Int)
    case json(String)
}

extension Token {
    public var debugDescription: String {
        switch self {
        case .int(let value):
            return "[type: int, value: \(value)]"
        case .className(let name):
            return "[type: className, name: \"\(name)\"]"
        case .classNameRef(let name):
            return "[type: classNameRef, className: \"\(name)\"]"
        case .string(let value):
            return "[type: string, value: \"\(value)\"]"
        case .double(let value):
            return "[type: double, value: \(value)]"
        case .null:
            return "[type: nil]"
        case .list(let count):
            return "[type: list, count: \(count)]"
        case .json(let json):
            return "[type: json, value: \(json)]"
        }
    }
}
