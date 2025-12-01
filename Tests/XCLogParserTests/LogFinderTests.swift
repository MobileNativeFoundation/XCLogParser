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
import XCTest
@testable import XCLogParser

class LogFinderTests: XCTestCase {

    let logFinder = LogFinder()
    var testDir: URL?
    var dirWithProject: URL?
    var dirWithSeveralProjects: URL?
    var derivedDataDir: URL?
    let projectName = "project.xcodeproj"
    let xcactivitylogName = "latest.xcactivitylog"

    override func setUp() {
        do {
            let testDir = try TestUtils.createRandomTestDir()
            self.testDir = testDir
            let dirWithProject = try TestUtils.createSubdir("project", in: testDir)
            self.dirWithProject = dirWithProject
            let dirWithSeveralProjects = try TestUtils.createSubdir("projects", in: testDir)
            self.dirWithSeveralProjects = dirWithSeveralProjects
            try TestUtils.createSubdir(projectName, in: dirWithSeveralProjects)
            try TestUtils.createSubdir("project1.xcodeproj", in: dirWithSeveralProjects)
            try TestUtils.createSubdir("project2.xcodeproj", in: dirWithSeveralProjects)
            try TestUtils.createSubdir("project3.xcodeproj", in: dirWithSeveralProjects)
            self.derivedDataDir = try TestUtils.createRandomTestDirWithPath("DerivedData/\(UUID().uuidString)")
        } catch let error {
            XCTFail("There was an error creating the temporary directories and files: \(error)")
        }

    }

    override func tearDown() {
        if let testDir = testDir {
            do {
                try FileManager.default.removeItem(at: testDir)
            } catch {
                print("Error deleting test dir \(error)")
            }
        }
        if let derivedDataDir = derivedDataDir {
            do {
                try FileManager.default.removeItem(at: derivedDataDir)
            } catch {
                print("Error deleting derivedDataDir test dir \(error)")
            }
        }
    }

    // Swift is crashing in Linux when trying to create a temp directory with a modificationDate
    #if !os(Linux)
    func testGetLatestLogForProjectFolder() throws {
        guard let derivedDataDir = derivedDataDir else {
            XCTFail("Unable to create test directories.")
            return
        }
        let projectFolder = try logFinder.getProjectFolderWithHash("/Users/user/projects/MyProject.xcworkspace", logType: .build)
        let logsFolder = projectFolder.appending("/Logs/Build")
        let projectLogFolder = derivedDataDir.appendingPathComponent(logsFolder, isDirectory: true)
        _ = try TestUtils.createSubdir(logsFolder, in: derivedDataDir)
        let now = Date()
        let olderDate = now.addingTimeInterval(-10)
        try TestUtils.createSubdir("anolder.xcactivitylog", in: projectLogFolder,
                      attributes: [FileAttributeKey.modificationDate: olderDate])
        try TestUtils.createSubdir(xcactivitylogName, in: projectLogFolder,
                      attributes: [FileAttributeKey.modificationDate: now])
        let latestLog = try logFinder.getLatestLogForProjectFolder(projectFolder,
                                                   inDerivedData: derivedDataDir)
        XCTAssertTrue(latestLog.contains(xcactivitylogName),
                      "latestLog \(latestLog) doesn't contains \(xcactivitylogName)")
    }
    #endif

    func testLogsDirectoryForXcodeProject() throws {
        guard let dirWithProject = self.dirWithProject else {
            XCTFail("The test directory couldn't be created")
            return
        }
        // since there is not a valid xcodeproj in the path, it should fail
        XCTAssertThrowsError(try logFinder.logsDirectoryForXcodeProject(projectPath: dirWithProject.path, logType: .build))
    }

    func testGetProjectFolderWithHash() throws {
        let projectPath = "/tmp/MyWorkspace.xcworkspace"
        let expectedProjectFolder = "MyWorkspace-fvaxjdltriwevoggjzpmzcohhhxf/Logs/Build/"
        let projectFolder = try logFinder.getProjectFolderWithHash(projectPath, logType: .build)
        XCTAssertEqual(expectedProjectFolder, projectFolder)
    }

    func testGetLogManifestPathWithWorkspace() throws {
        guard let derivedDataDir = derivedDataDir else {
            XCTFail("Unable to create test directories.")
            return
        }
        let logOptions = LogOptions(projectName: "",
                                    xcworkspacePath: "/tmp/MyWorkspace.xcworkspace",
                                    xcodeprojPath: "",
                                    derivedDataPath: derivedDataDir.path,
                                    logType: .build,
                                    logManifestPath: "")
        let logManifestURL = try logFinder.findLogManifestURLWithLogOptions(logOptions)
        let expectedPathPattern = "\(derivedDataDir.path)/MyWorkspace-fvaxjdltriwevoggjzpmzcohhhxf" +
                                  "/Logs/Build/LogStoreManifest.plist"
        XCTAssertEqual(expectedPathPattern, logManifestURL.path)
    }

    func testGetLogManifestPathWithXcodeProj() throws {
        let logOptions = LogOptions(projectName: "",
                                    xcworkspacePath: "",
                                    xcodeprojPath: "/tmp/MyApp.xcodeproj",
                                    derivedDataPath: "/projects/DerivedData",
                                    logType: .build,
                                    logManifestPath: "")
        let logManifestURL = try logFinder.findLogManifestURLWithLogOptions(logOptions)
        let expectedPathPattern = "/projects/DerivedData/" +
                                  "MyApp-dtpdmwoqyxcbrmauwqvycvmftqah/Logs/Build/LogStoreManifest.plist"
        XCTAssertEqual(expectedPathPattern, logManifestURL.path)
    }

    func testGetLogManifestPathForNonExistingFile() throws {
        let logOptions = LogOptions(projectName: "",
                                    xcworkspacePath: "",
                                    xcodeprojPath: "/tmp/MyApp.xcodeproj",
                                    derivedDataPath: "/projects/DerivedData",
                                    logType: .build,
                                    logManifestPath: "")
        XCTAssertThrowsError(try logFinder.findLogManifestWithLogOptions(logOptions))
    }

    func testGetLogsFromCustomDerivedData() throws {
        let customDerivedDataDir = try TestUtils.createRandomTestDir()
        let logsFolder = customDerivedDataDir.appendingPathComponent("/Logs/Build", isDirectory: true)
        _ = try TestUtils.createSubdir(logsFolder.path, in: customDerivedDataDir)
        _ = try TestUtils.createSubdir(xcactivitylogName, in: logsFolder,
                      attributes: [:])
        let logOptions = LogOptions(projectName: "",
                                    xcworkspacePath: "",
                                    xcodeprojPath: "/tmp/MyApp.xcodeproj",
                                    derivedDataPath: customDerivedDataDir.path,
                                    logType: .build,
                                    logManifestPath: "")

        let latestLog = try logFinder.findLatestLogWithLogOptions(logOptions)
        XCTAssertTrue(latestLog.path.contains(xcactivitylogName),
                      "latestLog \(latestLog) doesn't contains \(xcactivitylogName)")
    }

}
