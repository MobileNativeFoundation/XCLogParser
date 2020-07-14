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

/// Wrap the statistics data produced by ld64 linker (-print_statistics)
public class LinkerStatistics: Encodable {
    public let totalMS: Double

    public let optionParsingMS: Double
    public let optionParsingPercent: Double

    public let objectFileProcessingMS: Double
    public let objectFileProcessingPercent: Double

    public let resolveSymbolsMS: Double
    public let resolveSymbolsPercent: Double

    public let buildAtomListMS: Double
    public let buildAtomListPercent: Double

    public let runPassesMS: Double
    public let runPassesPercent: Double

    public let writeOutputMS: Double
    public let writeOutputPercent: Double

    public let pageins: Int
    public let pageouts: Int
    public let faults: Int

    public let objectFiles: Int
    public let objectFilesBytes: Int

    public let archiveFiles: Int
    public let archiveFilesBytes: Int

    public let dylibFiles: Int
    public let wroteOutputFileBytes: Int

    public init(totalMS: Double,
                optionParsingMS: Double,
                optionParsingPercent: Double,
                objectFileProcessingMS: Double,
                objectFileProcessingPercent: Double,
                resolveSymbolsMS: Double,
                resolveSymbolsPercent: Double,
                buildAtomListMS: Double,
                buildAtomListPercent: Double,
                runPassesMS: Double,
                runPassesPercent: Double,
                writeOutputMS: Double,
                writeOutputPercent: Double,
                pageins: Int,
                pageouts: Int,
                faults: Int,
                objectFiles: Int,
                objectFilesBytes: Int,
                archiveFiles: Int,
                archiveFilesBytes: Int,
                dylibFiles: Int,
                wroteOutputFileBytes: Int) {
        self.totalMS = totalMS
        self.optionParsingMS = optionParsingMS
        self.optionParsingPercent = optionParsingPercent
        self.objectFileProcessingMS = objectFileProcessingMS
        self.objectFileProcessingPercent = objectFileProcessingPercent
        self.resolveSymbolsMS = resolveSymbolsMS
        self.resolveSymbolsPercent = resolveSymbolsPercent
        self.buildAtomListMS = buildAtomListMS
        self.buildAtomListPercent = buildAtomListPercent
        self.runPassesMS = runPassesMS
        self.runPassesPercent = runPassesPercent
        self.writeOutputMS = writeOutputMS
        self.writeOutputPercent = writeOutputPercent
        self.pageins = pageins
        self.pageouts = pageouts
        self.faults = faults
        self.objectFiles = objectFiles
        self.objectFilesBytes = objectFilesBytes
        self.archiveFiles = archiveFiles
        self.archiveFilesBytes = archiveFilesBytes
        self.dylibFiles = dylibFiles
        self.wroteOutputFileBytes = wroteOutputFileBytes
    }

}
