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

import XCTest
@testable import XCLogParser

class LogManifestTests: XCTestCase {

    private static let logManifest = """
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
<key>logFormatVersion</key>
<integer>11</integer>
<key>logs</key>
<dict>
<key>E8557234-04E4-40E7-A6D6-920AC64BCF21</key>
<dict>
<key>className</key>
<string>IDEActivityLogSection</string>
<key>documentTypeString</key>
<string>&lt;nil&gt;</string>
<key>domainType</key>
<string>Xcode.IDEActivityLogDomainType.BuildLog</string>
<key>fileName</key>
<string>E8557234-04E4-40E7-A6D6-920AC64BCF21.xcactivitylog</string>
<key>primaryObservable</key>
<dict>
<key>highLevelStatus</key>
<string>W</string>
</dict>
<key>schemeIdentifier-containerName</key>
<string>MyApp</string>
<key>schemeIdentifier-schemeName</key>
<string>MyApp</string>
<key>schemeIdentifier-sharedScheme</key>
<integer>1</integer>
<key>signature</key>
<string>Build MyApp</string>
<key>timeStartedRecording</key>
<real>579435259.73980498</real>
<key>timeStoppedRecording</key>
<real>579435412.54278696</real>
<key>title</key>
<string>Build MyApp</string>
<key>uniqueIdentifier</key>
<string>E8557234-04E4-40E7-A6D6-920AC64BCF21</string>
</dict>
</dict>
</dict>
</plist>

"""

    func testGetWithLogOptions() throws {
        let logDir = try TestUtils.createRandomTestDirWithPath("/DerivedData/ABC/Logs/Build")
        let logURL = logDir.appendingPathComponent("LogManifest.plist")
        try LogManifestTests.logManifest.write(to: logURL, atomically: true, encoding: .utf8)

        let logOptions = LogOptions(projectName: "",
                   xcworkspacePath: "",
                   xcodeprojPath: "",
                   derivedDataPath: "",
                   logManifestPath: logURL.path)
        let logEntries = try LogManifest().getWithLogOptions(logOptions)
        XCTAssertEqual(1, logEntries.count)
    }

    // swiftlint:disable function_body_length
    func testGetLatestLogEntry() throws {
        let firstStartedRecording = 570014939.87839794
        let firstStoppedRecording = 570014966.95137894
        let secondStartedRecording = 569841813.45673704
        let secondStoppedRecording = 569842953.09712994

        let mockLogEntries = ["599BC5A8-5E6A-4C16-A71E-A8D6301BAC07":
            ["className": "IDEActivityLogSection",
             "documentTypeString": "&lt;nil&gt;",
             "domainType": "Xcode.IDEActivityLogDomainType.BuildLog",
             "fileName": "599BC5A8-5E6A-4C16-A71E-A8D6301BAC07.xcactivitylog",
             "highLevelStatus": "E",
             "schemeIdentifier-containerName": "MyApp project",
             "schemeIdentifier-schemeName": "MyApp",
             "schemeIdentifier-sharedScheme": 1,
             "signature": "Build MyApp",
             "timeStartedRecording": firstStartedRecording,
             "timeStoppedRecording": firstStoppedRecording,
             "title": "Build My App",
             "uniqueIdentifier": "599BC5A8-5E6A-4C16-A71E-A8D6301BAC07"
            ], "D1FEAFFA-2E88-4221-9CD2-AB607529381D":
                ["className": "IDEActivityLogSection",
                 "documentTypeString": "&lt;nil&gt;",
                 "domainType": "Xcode.IDEActivityLogDomainType.BuildLog",
                 "fileName": "D1FEAFFA-2E88-4221-9CD2-AB607529381D.xcactivitylog",
                 "highLevelStatus": "E",
                 "schemeIdentifier-containerName": "MyApp project",
                 "schemeIdentifier-schemeName": "MyApp",
                 "schemeIdentifier-sharedScheme": 1,
                 "signature": "Build MyApp",
                 "timeStartedRecording": secondStartedRecording,
                 "timeStoppedRecording": secondStoppedRecording,
                 "title": "Build My App",
                 "uniqueIdentifier": "D1FEAFFA-2E88-4221-9CD2-AB607529381D"
            ]]
        let log: NSDictionary = ["logs": mockLogEntries]
        let logManifest = LogManifest()
        let logEntries = try logManifest.parse(dictionary: log, atPath: "")
        XCTAssertNotNil(logEntries)
        guard let latestLog = logEntries.first else {
            XCTFail("Latest log entry not found")
            return
        }

        let startDate = Date(timeIntervalSinceReferenceDate: firstStartedRecording)
        let endDate = Date(timeIntervalSinceReferenceDate: firstStoppedRecording)
        let calendar = Calendar.current
        guard let expectedDuration = calendar.dateComponents([.second], from: startDate, to: endDate).second else {
            XCTFail("Error creating an expected duration field")
            return
        }
        XCTAssertEqual(expectedDuration, latestLog.duration)
    }

}
