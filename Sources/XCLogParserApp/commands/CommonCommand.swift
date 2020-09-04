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
import Commandant

let fileOption = Option(
    key: "file",
    defaultValue: "",
    usage: "The path to a .xcactivitylog file.")

let derivedDataOption = Option(
    key: "derived_data",
    defaultValue: "",
    usage: "The path to the DerivedData directory. " +
    "Use it if it's not the default ~/Library/Developer/Xcode/DerivedData/.")

let projectOption = Option(
    key: "project",
    defaultValue: "",
    usage: "The name of an Xcode project. " +
    "The tool will try to find the latest log folder with this prefix in the DerivedData directory. " +
    "Use with `--strictProjectName` for stricter name matching.")

let workspaceOption = Option(
    key: "workspace",
    defaultValue: "",
    usage: "The path to the .xcworkspace folder. " +
    "Used to find the Derived Data project directory if no `--project` flag is present.")

let xcodeprojOption = Option(
    key: "xcodeproj",
    defaultValue: "",
    usage: "The path to the .xcodeproj folder. " +
    "Used to find the Derived Data project directory if no `--project` and no `--workspace` flag is present.")

let redactedSwitch = Switch(flag: "r",
                            key: "redacted",
                            usage: "Redacts the username of the paths found in the log. " +
    "For instance, /Users/timcook/project will be /Users/<redacted>/project")

let withoutBuildSpecificInformationSwitch = Switch(flag: "w",
                                                   key: "without_build_specific_information",
                                                   usage: "Removes build specific information from the logs. " +
    "For instance, DerivedData/Product-bolnckhlbzxpxoeyfujluasoupft/Build will be DerivedData/Product/Build")

let strictProjectNameSwitch = Switch(key: "strictProjectName",
    usage: "Use strict name testing when trying to find the latest version " +
    "of the project in the DerivedData directory.")

let outputOption = Option(
    key: "output",
    defaultValue: "",
    usage: "Optional. Path to which the report will be written to." +
            "If not specified, the report will be written to the standard output")
let rootOutputOption = Option(key: "rootOutput",
                        defaultValue: "",
                        usage: "Optional. Add the project output into the given current path" +
                                "i.e: myGivenPath/report.json")
