import Foundation

public enum Reporter: String {
    case json
    case flatJson
    case summaryJson
    case chromeTracer
    case html

    func makeLogReporter() -> LogReporter {
        switch self {
        case .chromeTracer:
            return ChromeTracerReporter()
        case .json:
            return JsonReporter()
        case .flatJson:
            return FlatJsonReporter()
        case .summaryJson:
            return SummaryJsonReporter()
        case .html:
            return HtmlReporter()
        }
    }
}
