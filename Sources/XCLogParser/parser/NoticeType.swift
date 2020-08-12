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

/// The type of a Notice
public enum NoticeType: String, Codable {

    /// Notes
    case note

    /// A warning thrown by the Swift compiler
    case swiftWarning

    /// A warning thrown by the C compiler
    case clangWarning

    /// A warning at a project level. For instance:
    /// "Warning Swift 3 mode has been deprecated and will be removed in a later version of Xcode"
    case projectWarning

    /// An error in a non-compilation step. For instance creating a directory or running a shell script phase
    case error

    /// An error thrown by the Swift compiler
    case swiftError

    /// An error thrown by the C compiler
    case clangError

    /// A warning returned by Xcode static analyzer
    case analyzerWarning

    /// A warning inside an Interface Builder file
    case interfaceBuilderWarning

    /// A warning about the usage of a deprecated API
    case deprecatedWarning

    /// Error thrown by the Linker
    case linkerError

    /// Error loading Swift Packages
    case packageLoadingError

    /// Error running a Build Phase's script
    case scriptPhaseError

    // swiftlint:disable:next cyclomatic_complexity
    public static func fromTitle(_ title: String) -> NoticeType? {
        switch title {
        case "Swift Compiler Warning":
            return .swiftWarning
        case "Notice":
            return .note
        case "Swift Compiler Error":
            return .swiftError
        case Prefix("Lexical"), Suffix("Semantic Issue"), "Parse Issue", "Uncategorized":
            return .clangError
        case Suffix("Deprecations"):
            return .deprecatedWarning
        case "Warning", "Apple Mach-O Linker Warning", "Target Integrity":
            return .projectWarning
        case Suffix("Error"):
            return .error
        case Suffix("Notice"):
            return .note
        case Prefix("/* com.apple.ibtool.document.warnings */"):
            return .interfaceBuilderWarning
        case "Package Loading":
            return .packageLoadingError
        case Contains("Command PhaseScriptExecution"):
            return .scriptPhaseError
        case Prefix("error: Swiftc"):
            return .swiftError
        default:
            return .note
        }
    }
}
