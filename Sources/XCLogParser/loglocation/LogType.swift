//
//  LogType.swift
//  
//
//  Created by Danny Gilbert on 2/2/22.
//

import Foundation

public enum LogType: String {
    case build = "Build"
    case indexBuild = "Index Build"
    case install = "Install"
    case issues = "Issues"
    case package = "Package"
    case run = "Run"
    case test = "Test"
    case updateSigning = "Update Signing"
}

// MARK: - Log Location
public extension LogType {

    var path: String {
        "/Logs/\(self.rawValue)/"
    }
}
