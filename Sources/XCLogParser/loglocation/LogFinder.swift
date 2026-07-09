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
import PathKit
import XcodeHasher

/// Helper methods to locate Xcode's Log directory and its content
public struct LogFinder {

    let buildDirSettingsPrefix = "BUILD_DIR = "

    let xcodebuildPath: String

    let logManifestFile = "LogStoreManifest.plist"

    let emptyDirResponseMessage = """
    Error. Couldn't find the derived data directory.
    Please use the --filePath option to specify the path to the xcactivitylog file you want to parse.
    """

    var defaultDerivedData: URL? {
        guard let homeDirURL = URL.homeDir else {
            return nil
        }
        return homeDirURL.appendingPathComponent("Library/Developer/Xcode/DerivedData", isDirectory: true)
    }

    public init(
        xcodebuildPath: String = "/usr/bin/xcodebuild"
    ) {
        self.xcodebuildPath = xcodebuildPath
    }

    public func findLatestLogWithLogOptions(_ logOptions: LogOptions) throws -> URL {
        guard logOptions.xcactivitylogPath.isEmpty else {
            return URL(fileURLWithPath: Path(logOptions.xcactivitylogPath).absolute().string)
        }
        // get project dir
        let projectDir = try getProjectDirWithLogOptions(logOptions)

        // get latestLog
        return try URL(fileURLWithPath: getLatestLogInDir(projectDir))

    }
    
    public func findLatestLogsWithLogOptions(_ logOptions: LogOptions) throws -> [URL] {
        // get project dir
        let projectDir = try getProjectDirWithLogOptions(logOptions)

        // get latestLog
        return try getLatestLogsInDir(projectDir, since: logOptions.newerThan)
    }

    public func findLogManifestWithLogOptions(_ logOptions: LogOptions) throws -> URL {
        let logManifestURL = try findLogManifestURLWithLogOptions(logOptions)

        guard FileManager.default.fileExists(atPath: logManifestURL.path) else {
            throw LogError.noLogManifestFound(dir: logManifestURL.path)
        }
        return logManifestURL
    }

    public func findLogManifestURLWithLogOptions(_ logOptions: LogOptions) throws -> URL {
        guard logOptions.logManifestPath.isEmpty else {
            guard FileManager.default.fileExists(atPath: logOptions.logManifestPath) else {
                throw LogError.noLogManifestFound(dir: logOptions.logManifestPath)
            }
            return URL(fileURLWithPath: logOptions.logManifestPath)
        }

        // get project dir
        let projectDir = try getProjectDirWithLogOptions(logOptions)

        // get logManifest
        let logManifestURL = projectDir.appendingPathComponent(logManifestFile)

        return logManifestURL
    }

    private func getProjectDirWithLogOptions(_ logOptions: LogOptions) throws -> URL {
        // get derivedDataDir
        guard let derivedDataDir = getDerivedDataDirWithLogOptions(logOptions) else {
            throw LogError.noDerivedDataFound
        }
        // get project dir
        return try getProjectDir(withLogOptions: logOptions, andDerivedDataDir: derivedDataDir)
    }

    private func getDerivedDataDirWithLogOptions(_ logOptions: LogOptions) -> URL? {
        guard logOptions.derivedDataPath.isEmpty else {
            return URL(fileURLWithPath: logOptions.derivedDataPath)
        }

        if let customDerivedDataDir = getCustomDerivedDataDir() {
            return customDerivedDataDir
        }

        return defaultDerivedData
    }

    private func getProjectDir(withLogOptions logOptions: LogOptions,
                               andDerivedDataDir derivedData: URL) throws -> URL {
        // when xcodebuild is run with -derivedDataPath the logs are at the root level
        if logOptions.derivedDataPath.isEmpty == false {
            if FileManager.default.fileExists(atPath:
                                                derivedData.appendingPathComponent(logOptions.logType.path).path) {
                return derivedData.appendingPathComponent(logOptions.logType.path)
            }
        }
        if logOptions.projectLocation.isEmpty == false {
            let folderName = try getProjectFolderWithHash(logOptions.projectLocation, logType: logOptions.logType)
            return derivedData.appendingPathComponent(folderName)
        }
        if logOptions.projectName.isEmpty == false {
            return try findDerivedDataForProject(logOptions.projectName,
                                                 inDir: derivedData,
                                                 logType: logOptions.logType,
                                                 strictProjectName: logOptions.strictProjectName)
        }
        throw LogError.noLogFound(dir: derivedData.path)
    }

    private func getCustomDerivedDataDir() -> URL? {
        guard let xcodeOptions = UserDefaults.standard.persistentDomain(forName: "com.apple.dt.Xcode") else {
            return nil
        }
        guard let customLocation = xcodeOptions["IDECustomDerivedDataLocation"] as? String else {
            return nil
        }
        return URL(fileURLWithPath: customLocation)
    }

    /// Tries to find the derived data directory for a project with the name provided
    /// in the provided directory
    /// It looks for the latest folder that starts with the name of the project
    /// - parameter name: Name of the project
    /// - parameter inDir: URL of the derived data directory
    /// - returns: The path to the derived data of the project or nil if it is not found.
    public func findDerivedDataForProject(
        _ name: String,
        inDir derivedDataDir: URL,
        logType: LogType,
        strictProjectName: Bool
    ) throws -> URL {

        let fileManager = FileManager.default

        let files = try fileManager.contentsOfDirectory(at: derivedDataDir,
                                                        includingPropertiesForKeys: [.contentModificationDateKey],
                                                        options: .skipsHiddenFiles)
        let sorted = try files.filter { url in
            if strictProjectName {
                var dirName = url.lastPathComponent
                // Look for exact match first
                if dirName == name {
                    return true
                } else if let lastIndex = dirName.lastIndex(of: "-") {
                    // This looks for projectName-application_hash format
                    // There are times when there are multiple directories
                    // of a given project with different application hashes
                    dirName.removeSubrange(Range(uncheckedBounds: (lower: lastIndex, upper: dirName.endIndex)))
                    return dirName == name
                }
                return false
            }
            // Fallback to default behavior
            let dirName = url.lastPathComponent.lowercased()
            return dirName.starts(with: name.lowercased())
            }.sorted {
                let lhv = try $0.resourceValues(forKeys: [.contentModificationDateKey])
                let rhv = try $1.resourceValues(forKeys: [.contentModificationDateKey])
                guard let lhDate = lhv.contentModificationDate, let rhDate = rhv.contentModificationDate else {
                    return false
                }
                return lhDate.compare(rhDate) == .orderedDescending
        }
        guard let match = sorted.first else {
            throw LogError.xcodeBuildError("""
                Error. There is no directory for the project \(name) in the DerivedData
                folder in \(derivedDataDir.path). Please specify the path to the xcactivitylog
                with --file or the right DerivedData folder with --derived_data
                """)
        }
        return match.appendingPathComponent(logType.path)
    }

    /// Gets the full path of the Build/Logs directory for the given project
    /// The directory is inside of the DerivedData directory of the project
    /// It uses the BUILD_DIR directory listed by the command `xcodebuild -showBuildSettings`
    /// - parameter projectPath: The path to the .xcodeproj folder
    /// - returns: The full path to the `Build/Logs` directory
    /// - throws: An error if the derived data directory couldn't be found
    public func logsDirectoryForXcodeProject(projectPath: String, logType: LogType) throws -> String {
        let arguments = ["-project", projectPath, "-showBuildSettings"]
        if let result = try executeXcodeBuild(args: arguments) {
            return try parseXcodeBuildDir(result, logType: logType)
        }
        throw LogError.xcodeBuildError(emptyDirResponseMessage)
    }

    /// Gets the latest xcactivitylog file path for the given projectFolder
    /// in the given derived data folder
    /// - parameter projectFolder: The name of the project folder
    /// - parameter derivedDataDir: The path to the derived data folder
    /// - returns: The path to the latest xcactivitylog for the given project folder
    /// - throws an `Error` if no log is found
    public func getLatestLogForProjectFolder(_ projectFolder: String,
                                             inDerivedData derivedDataDir: URL) throws -> String {
        let logsDirectory = derivedDataDir.appendingPathComponent(projectFolder).appendingPathComponent("Logs/Build")
        return try getLatestLogInDir(logsDirectory)
    }

    /// Gets the available schemes in the given xcworkspace.
    /// Gets the list from the command xcodebuild -workspace -list
    /// - parameter workspace: The path to the .xcworkspace
    /// - throws an Error with the list of the available schemes
    public func logsDirectoryForWorkspace(_ workspace: String) throws {
        let error = """
        If you specify a workspace then you must also specify a scheme with -scheme.
        These are the available schemes in the workspace:
        """
        if let result = try executeXcodeBuild(args: ["-workspace", workspace, "-list"]) {
            guard !result.starts(with: "xcodebuild: error: ") else {
                throw LogError.xcodeBuildError(result.replacingOccurrences(of: "xcodebuild: ", with: ""))
            }
            let schemes = result.split(separator: "\n").filter {
                !$0.contains("Information about") && !$0.contains("Schemes:")
            }.map {
                $0.trimmingCharacters(in: .whitespacesAndNewlines)
            }.reduce(error) { "\($0)\n\($1)" }
            throw LogError.xcodeBuildError(schemes)
        }
    }

    /// Gets the full path of the Build/Logs directory for the given workspace and scheme
    /// The directory is inside of the DerivedData directory of the project
    /// It uses the BUILD_DIR directory listed by the command `xcodebuild -showBuildSettings`
    /// - parameter workspace: The path to the .xcworkspace folder
    /// - parameter andScheme: The name of the scheme
    /// - returns: The full path to the `Build/Logs` directory
    /// - throws: An error if the derived data directory can't be found.
    public func logsDirectoryForWorkspace(_ workspace: String, andScheme scheme: String, logType: LogType) throws -> String {
        let arguments = ["-workspace", workspace, "-scheme", scheme, "-showBuildSettings"]
        if let result = try executeXcodeBuild(args: arguments) {
            return try parseXcodeBuildDir(result, logType: logType)
        }
        throw LogError.xcodeBuildError(emptyDirResponseMessage)
    }

    /// Returns the latest xcactivitylog file path in the given directory
    /// - parameter dir: The full path for the directory
    /// - returns: The path for the latest xcactivitylog file in it.
    /// - throws: An `Error` if the directory doesn't exist or if there are no xcactivitylog files in it.
    public func getLatestLogInDir(_ dir: URL) throws -> String {
        let fileManager = FileManager.default
        let files = try fileManager.contentsOfDirectory(at: dir,
                                                        includingPropertiesForKeys: [.contentModificationDateKey],
                                                        options: .skipsHiddenFiles)
        let sorted = try files.filter { $0.path.hasSuffix(".xcactivitylog") }.sorted {
                let lhv = try $0.resourceValues(forKeys: [.contentModificationDateKey])
                let rhv = try $1.resourceValues(forKeys: [.contentModificationDateKey])
                guard let lhDate = lhv.contentModificationDate, let rhDate = rhv.contentModificationDate else {
                    return false
                }
                return lhDate.compare(rhDate) == .orderedDescending
        }
        guard let logPath = sorted.first else {
            throw LogError.noLogFound(dir: dir.path)
        }
        return logPath.path
    }
    
    /// Returns the latest xcactivitylog file path in the given directory
    /// - parameter dir: The full path for the directory
    /// - returns: The paths of the latest xcactivitylog file in it since given date.
    /// - throws: An `Error` if the directory doesn't exist or if there are no xcactivitylog files in it.
    public func getLatestLogsInDir(_ dir: URL, since date: Date?) throws -> [URL] {
        let fileManager = FileManager.default
        let files = try fileManager.contentsOfDirectory(at: dir,
                                                        includingPropertiesForKeys: [.contentModificationDateKey],
                                                        options: .skipsHiddenFiles)
        let sorted = try files
            .filter { $0.path.hasSuffix(".xcactivitylog") }
            .filter {
                guard let timestamp = date else { return true }
                guard
                    let lastModified = try? $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
                else { return false }
                return lastModified > timestamp
            }
            .sorted {
                let lhv = try $0.resourceValues(forKeys: [.contentModificationDateKey])
                let rhv = try $1.resourceValues(forKeys: [.contentModificationDateKey])
                guard let lhDate = lhv.contentModificationDate, let rhDate = rhv.contentModificationDate else {
                    return false
                }
                return lhDate.compare(rhDate) == .orderedDescending
            }
        guard !sorted.isEmpty else {
            throw LogError.noLogFound(dir: dir.path)
        }
        return sorted
    }

    /// Generates the Derived Data Build Logs Folder name for the given project path
    /// - parameter projectFilePath: A path (relative or absolut) to an .xcworkspace or an .xcodeproj directory
    /// - returns The name of the folder with the same hash Xcode generates.
    /// For instance MyApp-dtpdmwoqyxcbrmauwqvycvmftqah/Logs/Build
    public func getProjectFolderWithHash(_ projectFilePath: String, logType: LogType) throws -> String {
        let path = Path(projectFilePath).absolute()
        let projectName = path.lastComponent
            .replacingOccurrences(of: ".xcworkspace", with: "")
            .replacingOccurrences(of: ".xcodeproj", with: "")
        let hash = try XcodeHasher.hashString(for: path.string)
        return "\(projectName)-\(hash)".appending(logType.path)
    }

    private func executeXcodeBuild(args: [String]) throws -> String? {
        guard FileManager.default.isExecutableFile(atPath: xcodebuildPath) else {
            throw LogError.xcodeBuildError("Error: xcodebuild is not installed.")
        }
        let task: Process = Process()
        let pipe: Pipe = Pipe()

        task.launchPath = xcodebuildPath
        task.arguments = args
        task.standardOutput = pipe
        task.standardError = pipe
        task.launch()

        let handle = pipe.fileHandleForReading
        let data = handle.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)
    }

    private func parseXcodeBuildDir(_ response: String, logType: LogType) throws -> String {
        guard !response.starts(with: "xcodebuild: error: ") else {
            throw LogError.xcodeBuildError(response.replacingOccurrences(of: "xcodebuild: ", with: ""))
        }
        let buildDirSettings = response.split(separator: "\n").filter {
            $0.trimmingCharacters(in: .whitespacesAndNewlines).starts(with: buildDirSettingsPrefix)
        }
        if let settings = buildDirSettings.first {
            return settings.trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: buildDirSettingsPrefix, with: "")
                .replacingOccurrences(of: "Build/Products", with: logType.path)
        }
        throw LogError.xcodeBuildError(emptyDirResponseMessage)
    }
}
