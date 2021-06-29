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

extension BuildStep {

    func with(documentURL newDocumentURL: String) -> BuildStep {
        return BuildStep(type: type,
                         machineName: machineName,
                         buildIdentifier: buildIdentifier,
                         identifier: identifier,
                         parentIdentifier: parentIdentifier,
                         domain: domain,
                         title: title,
                         signature: signature,
                         startDate: startDate,
                         endDate: endDate,
                         startTimestamp: startTimestamp,
                         endTimestamp: endTimestamp,
                         duration: duration,
                         detailStepType: detailStepType,
                         buildStatus: buildStatus,
                         schema: schema,
                         subSteps: subSteps,
                         warningCount: warningCount,
                         errorCount: errorCount,
                         architecture: architecture,
                         documentURL: newDocumentURL,
                         warnings: warnings,
                         errors: errors,
                         notes: notes,
                         swiftFunctionTimes: swiftFunctionTimes,
                         fetchedFromCache: fetchedFromCache,
                         compilationEndTimestamp: compilationEndTimestamp,
                         compilationDuration: compilationDuration,
                         clangTimeTraceFile: clangTimeTraceFile,
                         linkerStatistics: linkerStatistics,
                         swiftTypeCheckTimes: swiftTypeCheckTimes
        )
    }

    func with(title newTitle: String) -> BuildStep {
        return BuildStep(type: type,
                         machineName: machineName,
                         buildIdentifier: buildIdentifier,
                         identifier: identifier,
                         parentIdentifier: parentIdentifier,
                         domain: domain,
                         title: newTitle,
                         signature: signature,
                         startDate: startDate,
                         endDate: endDate,
                         startTimestamp: startTimestamp,
                         endTimestamp: endTimestamp,
                         duration: duration,
                         detailStepType: detailStepType,
                         buildStatus: buildStatus,
                         schema: schema,
                         subSteps: subSteps,
                         warningCount: warningCount,
                         errorCount: errorCount,
                         architecture: architecture,
                         documentURL: documentURL,
                         warnings: warnings,
                         errors: errors,
                         notes: notes,
                         swiftFunctionTimes: swiftFunctionTimes,
                         fetchedFromCache: fetchedFromCache,
                         compilationEndTimestamp: compilationEndTimestamp,
                         compilationDuration: compilationDuration,
                         clangTimeTraceFile: clangTimeTraceFile,
                         linkerStatistics: linkerStatistics,
                         swiftTypeCheckTimes: swiftTypeCheckTimes)
    }

    func with(signature newSignature: String) -> BuildStep {
        return BuildStep(type: type,
                         machineName: machineName,
                         buildIdentifier: buildIdentifier,
                         identifier: identifier,
                         parentIdentifier: parentIdentifier,
                         domain: domain,
                         title: title,
                         signature: newSignature,
                         startDate: startDate,
                         endDate: endDate,
                         startTimestamp: startTimestamp,
                         endTimestamp: endTimestamp,
                         duration: duration,
                         detailStepType: detailStepType,
                         buildStatus: buildStatus,
                         schema: schema,
                         subSteps: subSteps,
                         warningCount: warningCount,
                         errorCount: errorCount,
                         architecture: architecture,
                         documentURL: documentURL,
                         warnings: warnings,
                         errors: errors,
                         notes: notes,
                         swiftFunctionTimes: swiftFunctionTimes,
                         fetchedFromCache: fetchedFromCache,
                         compilationEndTimestamp: compilationEndTimestamp,
                         compilationDuration: compilationDuration,
                         clangTimeTraceFile: clangTimeTraceFile,
                         linkerStatistics: linkerStatistics,
                         swiftTypeCheckTimes: swiftTypeCheckTimes)
    }

    func with(errors newErrors: [Notice]?, notes newNotes: [Notice]?, warnings newWarnings: [Notice]?) -> BuildStep {
        return BuildStep(type: type,
                         machineName: machineName,
                         buildIdentifier: buildIdentifier,
                         identifier: identifier,
                         parentIdentifier: parentIdentifier,
                         domain: domain,
                         title: title,
                         signature: signature,
                         startDate: startDate,
                         endDate: endDate,
                         startTimestamp: startTimestamp,
                         endTimestamp: endTimestamp,
                         duration: duration,
                         detailStepType: detailStepType,
                         buildStatus: buildStatus,
                         schema: schema,
                         subSteps: subSteps,
                         warningCount: newWarnings?.count ?? 0,
                         errorCount: newErrors?.count ?? 0,
                         architecture: architecture,
                         documentURL: documentURL,
                         warnings: newWarnings,
                         errors: newErrors,
                         notes: newNotes,
                         swiftFunctionTimes: swiftFunctionTimes,
                         fetchedFromCache: fetchedFromCache,
                         compilationEndTimestamp: compilationEndTimestamp,
                         compilationDuration: compilationDuration,
                         clangTimeTraceFile: clangTimeTraceFile,
                         linkerStatistics: linkerStatistics,
                         swiftTypeCheckTimes: swiftTypeCheckTimes)
    }

    func withFilteredNotices() -> BuildStep {
        let filteredNotes = filterNotices(notes)
        let filteredWarnings = filterNotices(warnings)
        let filtereredErrors = filterNotices(errors)
        return BuildStep(type: type,
                         machineName: machineName,
                         buildIdentifier: buildIdentifier,
                         identifier: identifier,
                         parentIdentifier: parentIdentifier,
                         domain: domain,
                         title: title,
                         signature: signature,
                         startDate: startDate,
                         endDate: endDate,
                         startTimestamp: startTimestamp,
                         endTimestamp: endTimestamp,
                         duration: duration,
                         detailStepType: detailStepType,
                         buildStatus: buildStatus,
                         schema: schema,
                         subSteps: subSteps,
                         warningCount: filteredWarnings?.count ?? 0,
                         errorCount: filtereredErrors?.count ?? 0,
                         architecture: architecture,
                         documentURL: documentURL,
                         warnings: filteredWarnings,
                         errors: filtereredErrors,
                         notes: filteredNotes,
                         swiftFunctionTimes: swiftFunctionTimes,
                         fetchedFromCache: fetchedFromCache,
                         compilationEndTimestamp: compilationEndTimestamp,
                         compilationDuration: compilationDuration,
                         clangTimeTraceFile: clangTimeTraceFile,
                         linkerStatistics: linkerStatistics,
                         swiftTypeCheckTimes: swiftTypeCheckTimes)
    }

    func with(subSteps newSubSteps: [BuildStep]) -> BuildStep {
        return BuildStep(type: type,
                         machineName: machineName,
                         buildIdentifier: buildIdentifier,
                         identifier: identifier,
                         parentIdentifier: parentIdentifier,
                         domain: domain,
                         title: title,
                         signature: signature,
                         startDate: startDate,
                         endDate: endDate,
                         startTimestamp: startTimestamp,
                         endTimestamp: endTimestamp,
                         duration: duration,
                         detailStepType: detailStepType,
                         buildStatus: buildStatus,
                         schema: schema,
                         subSteps: newSubSteps,
                         warningCount: warningCount,
                         errorCount: errorCount,
                         architecture: architecture,
                         documentURL: documentURL,
                         warnings: warnings,
                         errors: errors,
                         notes: notes,
                         swiftFunctionTimes: swiftFunctionTimes,
                         fetchedFromCache: fetchedFromCache,
                         compilationEndTimestamp: compilationEndTimestamp,
                         compilationDuration: compilationDuration,
                         clangTimeTraceFile: clangTimeTraceFile,
                         linkerStatistics: linkerStatistics,
                         swiftTypeCheckTimes: swiftTypeCheckTimes)
    }

    func with(newCompilationEndTimestamp: Double,
              andCompilationDuration newCompilationDuration: Double) -> BuildStep {
        return BuildStep(type: type,
                         machineName: machineName,
                         buildIdentifier: buildIdentifier,
                         identifier: identifier,
                         parentIdentifier: parentIdentifier,
                         domain: domain,
                         title: title,
                         signature: signature,
                         startDate: startDate,
                         endDate: endDate,
                         startTimestamp: startTimestamp,
                         endTimestamp: endTimestamp,
                         duration: duration,
                         detailStepType: detailStepType,
                         buildStatus: buildStatus,
                         schema: schema,
                         subSteps: subSteps,
                         warningCount: warningCount,
                         errorCount: errorCount,
                         architecture: architecture,
                         documentURL: documentURL,
                         warnings: warnings,
                         errors: errors,
                         notes: notes,
                         swiftFunctionTimes: swiftFunctionTimes,
                         fetchedFromCache: fetchedFromCache,
                         compilationEndTimestamp: newCompilationEndTimestamp,
                         compilationDuration: newCompilationDuration,
                         clangTimeTraceFile: clangTimeTraceFile,
                         linkerStatistics: linkerStatistics,
                         swiftTypeCheckTimes: swiftTypeCheckTimes)
    }

    func with(identifier newIdentifier: String) -> BuildStep {
        return BuildStep(type: type,
                         machineName: machineName,
                         buildIdentifier: buildIdentifier,
                         identifier: newIdentifier,
                         parentIdentifier: parentIdentifier,
                         domain: domain,
                         title: title,
                         signature: signature,
                         startDate: startDate,
                         endDate: endDate,
                         startTimestamp: startTimestamp,
                         endTimestamp: endTimestamp,
                         duration: duration,
                         detailStepType: detailStepType,
                         buildStatus: buildStatus,
                         schema: schema,
                         subSteps: subSteps,
                         warningCount: warningCount,
                         errorCount: errorCount,
                         architecture: architecture,
                         documentURL: documentURL,
                         warnings: warnings,
                         errors: errors,
                         notes: notes,
                         swiftFunctionTimes: swiftFunctionTimes,
                         fetchedFromCache: fetchedFromCache,
                         compilationEndTimestamp: compilationEndTimestamp,
                         compilationDuration: compilationDuration,
                         clangTimeTraceFile: clangTimeTraceFile,
                         linkerStatistics: linkerStatistics,
                         swiftTypeCheckTimes: swiftTypeCheckTimes)
    }

    func with(parentIdentifier newParentIdentifier: String) -> BuildStep {
        return BuildStep(type: type,
                         machineName: machineName,
                         buildIdentifier: buildIdentifier,
                         identifier: identifier,
                         parentIdentifier: newParentIdentifier,
                         domain: domain,
                         title: title,
                         signature: signature,
                         startDate: startDate,
                         endDate: endDate,
                         startTimestamp: startTimestamp,
                         endTimestamp: endTimestamp,
                         duration: duration,
                         detailStepType: detailStepType,
                         buildStatus: buildStatus,
                         schema: schema,
                         subSteps: subSteps,
                         warningCount: warningCount,
                         errorCount: errorCount,
                         architecture: architecture,
                         documentURL: documentURL,
                         warnings: warnings,
                         errors: errors,
                         notes: notes,
                         swiftFunctionTimes: swiftFunctionTimes,
                         fetchedFromCache: fetchedFromCache,
                         compilationEndTimestamp: compilationEndTimestamp,
                         compilationDuration: compilationDuration,
                         clangTimeTraceFile: clangTimeTraceFile,
                         linkerStatistics: linkerStatistics,
                         swiftTypeCheckTimes: swiftTypeCheckTimes)
    }

    private func filterNotices(_ notices: [Notice]?) -> [Notice]? {
        guard let notices = notices else {
            return nil
        }
        return self.documentURL.isEmpty ? [] : notices
    }
}
