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

public final class Lexer {

    static let SLFHeader = "SLF"

    let typeDelimiters: CharacterSet
    let filePath: String
    var classNames = [String]()

    lazy var userDirRegex: NSRegularExpression? = {
        do {
            return try NSRegularExpression(pattern: "\\/Users\\/(\\w*)\\/")
        } catch {
            return nil
        }
    }()

    public init(filePath: String) {
        self.filePath = filePath
        self.typeDelimiters = CharacterSet(charactersIn: TokenType.all())
    }

    /// Tokenizes an xcactivitylog serialized in the `SLF` format
    /// - parameter contents: The contents of the .xcactivitylog
    /// - parameter redacted: If true, the user's directory will be replaced by `<redacted>`
    /// for privacy concerns.
    /// - returns: An array of all the `Token` in the log.
    /// - throws: An error if the document is not a valid SLF document
    public func tokenize(contents: String, redacted: Bool) throws -> [Token] {
        let scanner = Scanner(string: contents)
        guard scanSLFHeader(scanner: scanner) else {
            throw XCLogParserError.invalidLogHeader(filePath)
        }
        var tokens = [Token]()
        while !scanner.isAtEnd {
            guard let logTokens = scanSLFType(scanner: scanner, redacted: redacted), logTokens.isEmpty == false else {
                print(tokens)
                throw XCLogParserError.invalidLine(scanner.approximateLine)
            }
            tokens.append(contentsOf: logTokens)
        }
        return tokens
    }

    private func scanSLFHeader(scanner: Scanner) -> Bool {
        var format: NSString?
        return scanner.scanString(Lexer.SLFHeader, into: &format)
    }

    private func scanSLFType(scanner: Scanner, redacted: Bool) -> [Token]? {

        guard let payload = scanPayload(scanner: scanner) else {
            return nil
        }
        guard let tokenTypes = scanTypeDelimiter(scanner: scanner), tokenTypes.count > 0 else {
            return nil
        }

        return tokenTypes.compactMap { tokenType -> Token? in
            scanToken(scanner: scanner, payload: payload, tokenType: tokenType, redacted: redacted)
        }
    }

    private func scanPayload(scanner: Scanner) -> String? {
        var payload: String = ""
        var char: NSString?
        let hexChars = "abcdef0123456789"
        while scanner.scanCharacters(from: CharacterSet(charactersIn: hexChars), into: &char),
              let char = char as String? {
            payload.append(char)
        }
        return payload
    }

    private func scanTypeDelimiter(scanner: Scanner) -> [TokenType]? {
        var delimiters: NSString?
        if scanner.scanCharacters(from: typeDelimiters, into: &delimiters), let delimiters = delimiters {
            let delimiters = String(delimiters)
            if delimiters.count > 1 {
                //if we found a string, we discard other type delimiters because there are part of the string
                let tokenString = TokenType.string
                if let char = delimiters.first, tokenString.rawValue == String(char) {
                    scanner.scanLocation -= delimiters.count - 1
                    return [tokenString]
                }
            }
            //sometimes we found one or more nil list (-) next to the type delimiter
            //in that case we'll return the delimiter and one or more `Token.null`
            return delimiters.compactMap { character -> TokenType? in
                TokenType(rawValue: String(character))
            }
        }
        return nil
    }

    // swiftlint:disable:next cyclomatic_complexity
    private func scanToken(scanner: Scanner, payload: String, tokenType: TokenType, redacted: Bool) -> Token? {
        switch tokenType {
        case .int:
            guard let value = UInt64(payload) else {
                print("error parsing int")
                return nil
            }
            return .int(value)
        case .className:
            guard let className = scanString(length: payload, scanner: scanner, redacted: redacted) else {
                print("error parsing string")
                return nil
            }
            classNames.append(className)
            return .className(className)
        case .classNameRef:
            guard let value = Int(payload) else {
                print("error parsing classNameRef")
                return nil
            }
            let element = value - 1
            let className = classNames[element]
            return .classNameRef(className)
        case .string:
            guard let content = scanString(length: payload, scanner: scanner, redacted: redacted) else {
                print("error parsing string")
                return nil
            }
            return .string(content)
        case .double:
            guard let double = hexToInt(payload) else {
                print("error parsing double")
                return nil
            }
            return .double(double)
        case .null:
            return .null
        case .list:
            guard let value = Int(payload) else {
                print("error parsing list")
                return nil
            }
            return .list(value)
        }
    }

    private func scanString(length: String, scanner: Scanner, redacted: Bool) -> String? {
        guard let value = Int(length) else {
            print("error parsing string")
            return nil
        }
        #if swift(>=5.0)
        let start = String.Index(utf16Offset: scanner.scanLocation, in: scanner.string)
        let end = String.Index(utf16Offset: scanner.scanLocation + value, in: scanner.string)
        #else
        let start = String.Index(encodedOffset: scanner.scanLocation)
        let end = String.Index(encodedOffset: scanner.scanLocation + value)
        #endif
        scanner.scanLocation += value
        if redacted {
            return redactUserDir(string: String(scanner.string[start..<end]))
        }
        return String(scanner.string[start..<end])
    }

    private func hexToInt(_ input: String) -> Double? {
        guard let beValue = UInt64(input, radix: 16) else {
            return nil
        }
        let result =  Double(bitPattern: beValue.byteSwapped)
        return result
    }

    private func redactUserDir(string: String) -> String {
        guard let regex = userDirRegex else {
            return string
        }

        return regex.stringByReplacingMatches(in: string,
                                              options: .reportProgress,
                                              range: NSRange(location: 0, length: string.count),
                                              withTemplate: "/Users/<redacted>/")
    }

}

extension Scanner {
    var approximateLine: String {
        let endCount = string.count - scanLocation > 21 ? scanLocation + 21 : string.count - scanLocation
        #if swift(>=5.0)
        let start = String.Index(utf16Offset: scanLocation, in: self.string)
        let end = String.Index(utf16Offset: endCount, in: self.string)
        #else
        let start = String.Index(encodedOffset: scanLocation)
        let end = String.Index(encodedOffset: endCount)
        #endif
        if end <= start {
            return String(string[start..<string.endIndex])
        }
        return String(string[start..<end])
    }
}
