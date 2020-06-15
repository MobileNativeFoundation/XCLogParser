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

extension Array where Element: Hashable {

    func removingDuplicates() -> [Element] {
        var addedDict = [Element: Bool]()
        return filter {
            addedDict.updateValue(true, forKey: $0) == nil
        }
    }

}

extension Array where Element: Notice {

    func getWarnings() -> [Notice] {
        return filter {
            $0.type == .swiftWarning ||
            $0.type == .clangWarning ||
            $0.type == .projectWarning ||
            $0.type == .analyzerWarning ||
            $0.type == .interfaceBuilderWarning ||
            $0.type == .deprecatedWarning
        }
    }

    func getErrors() -> [Notice] {
        return filter {
            $0.type == .swiftError ||
            $0.type == .error ||
            $0.type == .clangError ||
            $0.type == .linkerError ||
            $0.type == .packageLoadingError ||
            $0.type == .scriptPhaseError
        }
    }

    func getNotes() -> [Notice] {
        return filter {
            $0.type == .note
        }
    }
}
