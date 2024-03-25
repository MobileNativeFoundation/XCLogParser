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
    var userDirToRedact: String? {
        get {
            redactor.userDirToRedact
        }
        set {
            redactor.userDirToRedact = newValue
        }
    }
    private var redactor: LogRedactor

    public init(filePath: String) {
        self.filePath = filePath
        self.typeDelimiters = CharacterSet(charactersIn: TokenType.all())
        self.redactor = LexRedactor()
    }

    /// Tokenizes an xcactivitylog serialized in the `SLF` format
    /// - parameter contents: The contents of the .xcactivitylog
    /// - parameter redacted: If true, the user's directory will be replaced by `<redacted>`
    /// for privacy concerns.
    /// - parameter withoutBuildSpecificInformation: If true, build specific information will be removed from the logs.
    /// - returns: An array of all the `Token` in the log.
    /// - throws: An error if the document is not a valid SLF document
    public func tokenize(contents: String,
                         redacted: Bool,
                         withoutBuildSpecificInformation: Bool) throws -> [Token] {
        let scanner = Scanner(string: contents)
        guard scanSLFHeader(scanner: scanner) else {
            throw XCLogParserError.invalidLogHeader(filePath)
        }
        var tokens = [Token]()
        while !scanner.isAtEnd {
            guard let logTokens = scanSLFType(scanner: scanner,
                                              redacted: redacted,
                                              withoutBuildSpecificInformation: withoutBuildSpecificInformation),
                logTokens.isEmpty == false else {
                print(tokens)
                throw XCLogParserError.invalidLine(scanner.approximateLine)
            }
            tokens.append(contentsOf: logTokens)
        }
        return tokens
    }

    private func scanSLFHeader(scanner: Scanner) -> Bool {
        #if os(Linux)
        var format: String?
        #else
        var format: NSString?
        #endif
        return scanner.scanString(Lexer.SLFHeader, into: &format)
    }

    private func scanSLFType(scanner: Scanner, redacted: Bool, withoutBuildSpecificInformation: Bool) -> [Token]? {

        guard let payload = scanPayload(scanner: scanner) else {
            return nil
        }
        guard let tokenTypes = scanTypeDelimiter(scanner: scanner), tokenTypes.count > 0 else {
            return nil
        }

        return tokenTypes.compactMap { tokenType -> Token? in
            scanToken(scanner: scanner,
                      payload: payload,
                      tokenType: tokenType,
                      redacted: redacted,
                      withoutBuildSpecificInformation: withoutBuildSpecificInformation)
        }
    }

    private func scanPayload(scanner: Scanner) -> String? {
        var payload: String = ""
        #if os(Linux)
        var char: String?
        #else
        var char: NSString?
        #endif
        let hexChars = "abcdef0123456789"
        while scanner.scanCharacters(from: CharacterSet(charactersIn: hexChars), into: &char),
              let char = char as String? {
            payload.append(char)
        }
        return payload
    }

    private func scanTypeDelimiter(scanner: Scanner) -> [TokenType]? {
        #if os(Linux)
        var delimiters: String?
        #else
        var delimiters: NSString?
        #endif
        if scanner.scanCharacters(from: typeDelimiters, into: &delimiters), let delimiters = delimiters {
            let delimiters = String(delimiters)
            if delimiters.count > 1 {
                // if we found a string, we discard other type delimiters because there are part of the string
                let tokenString = TokenType.string
                if let char = delimiters.first, tokenString.rawValue == String(char) {
                    scanner.scanLocation -= delimiters.count - 1
                    return [tokenString]
                }
            }
            // sometimes we found one or more nil list (-) next to the type delimiter
            // in that case we'll return the delimiter and one or more `Token.null`
            return delimiters.compactMap { character -> TokenType? in
                TokenType(rawValue: String(character))
            }
        }
        return nil
    }

    private func scanToken(scanner: Scanner,
                           payload: String,
                           tokenType: TokenType,
                           redacted: Bool,
                           withoutBuildSpecificInformation: Bool) -> Token? {
        switch tokenType {
        case .int:
            return handleIntTokenTypeCase(payload: payload)
        case .className:
            return handleClassNameTokenTypeCase(scanner: scanner,
                                                payload: payload,
                                                redacted: redacted,
                                                withoutBuildSpecificInformation: withoutBuildSpecificInformation)
        case .classNameRef:
            return handleClassNameRefTokenTypeCase(payload: payload)
        case .string:
            return handleStringTokenTypeCase(scanner: scanner,
                                             payload: payload,
                                             redacted: redacted,
                                             withoutBuildSpecificInformation: withoutBuildSpecificInformation)
        case .double:
            return handleDoubleTokenTypeCase(payload: payload)
        case .null:
            return .null
        case .list:
            return handleListTokenTypeCase(payload: payload)
        case .json:
            return handleJSONTokenTypeCase(scanner: scanner,
                                           payload: payload,
                                           redacted: redacted,
                                           withoutBuildSpecificInformation: withoutBuildSpecificInformation)
        }
    }

    private func handleIntTokenTypeCase(payload: String) -> Token? {
        guard let value = UInt64(payload) else {
            print("error parsing int")
            return nil
        }
        return .int(value)
    }

    private func handleClassNameTokenTypeCase(scanner: Scanner,
                                              payload: String,
                                              redacted: Bool,
                                              withoutBuildSpecificInformation: Bool) -> Token? {
        guard let className = scanString(length: payload,
                                         scanner: scanner,
                                         redacted: redacted,
                                         withoutBuildSpecificInformation: withoutBuildSpecificInformation) else {
                                            print("error parsing string")
                                            return nil
        }
        classNames.append(className)
        return .className(className)
    }

    private func handleClassNameRefTokenTypeCase(payload: String) -> Token? {
        guard let value = Int(payload) else {
            print("error parsing classNameRef")
            return nil
        }
        let element = value - 1
        let className = classNames[element]
        return .classNameRef(className)
    }

    private func handleStringTokenTypeCase(scanner: Scanner,
                                           payload: String,
                                           redacted: Bool,
                                           withoutBuildSpecificInformation: Bool) -> Token? {
        guard let content = scanString(length: payload,
                                       scanner: scanner,
                                       redacted: redacted,
                                       withoutBuildSpecificInformation: withoutBuildSpecificInformation) else {
                                        print("error parsing string")
                                        return nil
        }
        return .string(content)
    }

    private func handleJSONTokenTypeCase(scanner: Scanner,
                                         payload: String,
                                         redacted: Bool,
                                         withoutBuildSpecificInformation: Bool) -> Token? {
        guard let content = scanString(length: payload,
                                       scanner: scanner,
                                       redacted: redacted,
                                       withoutBuildSpecificInformation: withoutBuildSpecificInformation) else {
                                        print("error parsing string")
                                        return nil
        }
        return .json(content)
    }

    private func handleDoubleTokenTypeCase(payload: String) -> Token? {
        guard let double = hexToInt(payload) else {
            print("error parsing double")
            return nil
        }
        return .double(double)
    }

    private func handleListTokenTypeCase(payload: String) -> Token? {
        guard let value = Int(payload) else {
            print("error parsing list")
            return nil
        }
        return .list(value)
    }

    private func scanString(length: String,
                            scanner: Scanner,
                            redacted: Bool,
                            withoutBuildSpecificInformation: Bool) -> String? {
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
        var result = String(scanner.string[start..<end])
        if redacted {
            result = redactor.redactUserDir(string: result)
        }
        if withoutBuildSpecificInformation {
            result = result
                .removeProductBuildIdentifier()
                .removeHexadecimalNumbers()
        }
        return result
    }

    private func hexToInt(_ input: String) -> Double? {
        guard let beValue = UInt64(input, radix: 16) else {
            return nil
        }
        let result =  Double(bitPattern: beValue.byteSwapped)
        return result
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
