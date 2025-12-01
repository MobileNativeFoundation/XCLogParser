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
import OpenTelemetryApi
import OpenTelemetrySdk
import StdoutExporter
import OpenTelemetryProtocolExporterGrpc
import ResourceExtension
import GRPC
import NIO
import NIOHPACK

public struct OTELReporter: LogReporter {
    
    public init() {}

    public func report(build: Any, output: ReporterOutput, rootOutput: String) throws {
        guard let buildStep = build as? BuildStep else {
            throw XCLogParserError.errorCreatingReport("Type not supported \(type(of: build))")
        }
        
        let (tracer, processor) = createTracer()

        // recursively create spans
        createSpan(tracer: tracer, parentSpan: nil, buildStep: buildStep)

        // ensure that all spans are exported before program shutdown
        processor.forceFlush(timeout: TimeInterval(3000))
        
    }
}

func createSpan(tracer: Tracer, parentSpan: Span?, buildStep: BuildStep) {
    // skip details as this would generate 10.000s of spans
    // TODO make this configurable
    if buildStep.type == BuildStepType.detail {
        return
    }
    // do not create spans if they pulled from cache
    // TODO make this a config option?
    if buildStep.fetchedFromCache == true {
        return
    }
    
    let spanBuilder = tracer.spanBuilder(spanName: buildStep.title)
        .setStartTime(time: Date(timeIntervalSince1970: buildStep.startTimestamp))
    
    // set optional parentSpan
    if let parentSpan = parentSpan {
        spanBuilder.setParent(parentSpan)
    } else {
        spanBuilder.setNoParent()
    }
    
    
    let span = spanBuilder.startSpan()
    
    span.status = parseStatus(buildStep: buildStep)

    span.setAttribute(key: "xcode.build.step.type", value: buildStep.type.rawValue)
    span.setAttribute(key: "xcode.build.domain", value: buildStep.domain)
    span.setAttribute(key: "xcode.build.schema", value: buildStep.schema)
    span.setAttribute(key: "xcode.build.cacheUsed", value: buildStep.fetchedFromCache)
    
    
    // process child steps
    for childStep in buildStep.subSteps {
        createSpan(tracer: tracer, parentSpan: span, buildStep: childStep)
    }
    
    // end span after processing childs, to allow modifications by them.
    span.end(time: Date(timeIntervalSince1970: buildStep.endTimestamp))
}

func parseStatus(buildStep: BuildStep) -> Status {
    let status = buildStep.buildStatus
    switch status {
    case "succeeded":
        return Status.ok
    case "failed":
        return Status.error(description: "")
    default:
        return Status.error(description: "Build status is unexpected:" + status)
    }
}

func createTracer() -> (Tracer, SpanProcessor) {
    let instrumentationName = "XCLogParser"
    let instrumentationVersion = "semver:" + Version.current

    
    // read out local machine information and set custom resource attributes
    let resource = DefaultResources()
        .get()
        .merging(
            other: Resource.init(
                attributes: [
                    "service.name" : AttributeValue("serviceName") // TODO read out from standardized OTEL env variables
                ]))
    
    let configuration = ClientConnection.Configuration.default(
            target: .hostAndPort("localhost", 4317), // TODO read out from standardized OTEL env variables
            eventLoopGroup: MultiThreadedEventLoopGroup(numberOfThreads: 1)
    )
    let client = ClientConnection(configuration: configuration)
    let otlpTraceExporter = OtlpTraceExporter(channel: client)
    
    let stdoutExporter = StdoutExporter()
    let spanExporter = MultiSpanExporter(spanExporters: [otlpTraceExporter, stdoutExporter])

    let spanProcessor = SimpleSpanProcessor(spanExporter: spanExporter)
    
    OpenTelemetry.registerTracerProvider(tracerProvider:
    TracerProviderBuilder()
            .add(spanProcessor: spanProcessor)
            .with(resource: resource)
            .build()
    )

    let tracer = OpenTelemetry.instance.tracerProvider.get(instrumentationName: instrumentationName, instrumentationVersion: instrumentationVersion)
    
    return (tracer, spanProcessor)
}
