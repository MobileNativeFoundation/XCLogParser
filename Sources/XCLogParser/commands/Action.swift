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

/// Actions supported by the library
public enum Action {

    /// Dumps the content of an .xcactivitylog as a JSON document
    case dump(options: ActionOptions)

    /// Dumps the content of the LogManifest plist of a Log directory as a JSON Document
    case manifest(options: ActionOptions)

    /// Parses the content of an .xcactivitylog and generates different `BuildReport`s
    case parse(options: ActionOptions)
}
