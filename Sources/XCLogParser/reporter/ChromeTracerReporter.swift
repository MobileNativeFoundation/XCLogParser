import Foundation

/// Creates a JSON document with the format used by Chrome Tracer.
/// It can be visualized with the chrome://tracing tool
public struct ChromeTracerReporter: LogReporter {

    public func report(build: Any, output: ReporterOutput) throws {
        guard let steps = build as? BuildStep else {
            throw Error.errorCreatingReport("Type not supported \(type(of: build))")
        }
        let events = toTraceEvents(rootStep: steps)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(events)
        try output.write(report: data)
    }

    public func toTraceEvents(rootStep: BuildStep) -> [TrackEvent] {
        return rootStep.subSteps.enumerated().flatMap { (index, target) -> [TrackEvent] in
            return targetToTraceEvent(target: target, index: index)
        }
    }

    private func targetToTraceEvent(target: BuildStep, index: Int) -> [TrackEvent] {
        let threadEvent = toThreadEvent(target, index: index)
        let targetEvents = toTargetEvents(target, index: index)
        let stepsEvents = target.subSteps.map { step -> TrackEvent in
            return toTrackEvent(step, target: target, index: index)
        }
        return [threadEvent] + targetEvents + stepsEvents
    }

    private func toThreadEvent(_ target: BuildStep, index: Int) -> TrackEvent {
        let event = TrackEvent(name: TrackEvent.threadEventName, ph: .thread, pid: 1, tid: index)
        event.args["name"] = target.title
        return event
    }

    private func toTargetEvents(_ target: BuildStep, index: Int) -> [TrackEvent] {
        let startEvent = TrackEvent(name: target.title,
                                    ph: .durationStart,
                                    pid: 1,
                                    tid: index,
                                    cat: target.title,
                                    ts: Double(target.startTimestamp) * 1_000_000,
                                    id: index)

        let endEvent = TrackEvent(name: target.title,
                                  ph: .durationEnd,
                                  pid: 1,
                                  tid: index,
                                  cat: target.title,
                                  ts: Double(target.endTimestamp) * 1_000_000,
                                  id: index)
        return [startEvent, endEvent]
    }

    private func toTrackEvent(_ step: BuildStep, target: BuildStep, index: Int) -> TrackEvent {
        let event =  TrackEvent(name: step.title,
                                ph: .complete,
                                pid: 1,
                                tid: index,
                                cat: target.title,
                                ts: Double(step.startTimestamp) * 1_000_000,
                                id: index,
                                dur: Double(step.duration) * 1_000_000)
        event.args["signature"] = step.signature
        event.args["type"] = step.detailStepType.rawValue
        return event
    }

}

public enum TrackPhase: String {
    case thread = "M"
    case durationStart = "B"
    case durationEnd = "E"
    case complete = "X"
}
// swiftlint:disable identifier_name
/// The trace Event format used by chrome.
/// [Trace Event Format](https://docs.google.com/document/d/1CvAClvFfyA5R-PhYUmn5OOQtYMH4h6I0nSsKchNAySU)
public class TrackEvent: Encodable {

    static let threadEventName = "thread_name"

    let name: String

    let ph: TrackPhase
    let pid: Int
    let tid: Int
    let cat: String
    let ts: Double
    let id: Int
    let dur: Double
    var args: [String: String] = [String: String]()

    public init(name: String, ph: TrackPhase, pid: Int, tid: Int, cat: String, ts: Double, id: Int, dur: Double) {
        self.name = name
        self.ph = ph
        self.pid = pid
        self.tid = tid
        self.cat = cat
        self.ts = ts
        self.id = id
        self.dur = dur
    }

    public convenience init(name: String, ph: TrackPhase, pid: Int, tid: Int, cat: String, ts: Double, id: Int) {
        self.init(name: name, ph: ph, pid: pid, tid: tid, cat: cat, ts: ts, id: id, dur: 0.0)
    }

    public convenience init(name: String, ph: TrackPhase, pid: Int, tid: Int) {
        self.init(name: name, ph: ph, pid: pid, tid: tid, cat: "", ts: 0.0, id: 0, dur: 0.0)
    }

    private enum CodingKeys: String, CodingKey {
        case name
        case ph
        case pid
        case tid
        case args
        case cat
        case ts
        case id
        case dur
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(ph.rawValue, forKey: .ph)
        try container.encode(pid, forKey: .pid)
        try container.encode(tid, forKey: .tid)
        if !args.isEmpty {
            try container.encode(args, forKey: .args)
        }
        if ph != .thread {
            try container.encode(cat, forKey: .cat)
            try container.encode(ts, forKey: .ts)
            try container.encode(id, forKey: .id)
        }
        if ph == .complete {
            try container.encode(dur, forKey: .dur)
        }
    }
}
