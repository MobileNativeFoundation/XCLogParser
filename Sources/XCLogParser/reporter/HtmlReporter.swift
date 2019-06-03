import Foundation
import Stencil

/// Reporter that creates an HTML report.
/// It uses the html and javascript files from the Resources folder as templates
public struct HtmlReporter: LogReporter {

    public func report(build: Any, output: ReporterOutput) throws {
        guard let steps = build as? BuildStep else {
            throw Error.errorCreatingReport("Type not supported \(type(of: build))")
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let json = try encoder.encode(steps.flatten())
        guard let jsonString = String(data: json, encoding: .utf8) else {
            throw  Error.errorCreatingReport("Can't generate the JSON file.")
        }
        try writeHtmlReport(for: steps, context: ["build": jsonString], output: output)
    }

    private func writeHtmlReport(for build: BuildStep, context: [String: String], output: ReporterOutput) throws {
        var path = "build/xclogparser/reports"
        if let output = output as? FileOutput {
            path = output.path
        }
        let fileManager = FileManager.default
        let buildDir = "\(path)/\(dirFor(build: build))"
        try fileManager.createDirectory(
            atPath: "\(buildDir)/css",
            withIntermediateDirectories: true,
            attributes: nil)
        try fileManager.createDirectory(
            atPath: "\(buildDir)/js",
            withIntermediateDirectories: true,
            attributes: nil)
        try HtmlReporterResources.css.write(toFile: "\(buildDir)/css/styles.css", atomically: true, encoding: .utf8)
        try HtmlReporterResources.appJS.write(toFile: "\(buildDir)/js/app.js", atomically: true, encoding: .utf8)
        try HtmlReporterResources.indexHTML.write(toFile: "\(buildDir)/index.html", atomically: true, encoding: .utf8)
        try HtmlReporterResources.stepJS.write(toFile: "\(buildDir)/js/step.js", atomically: true, encoding: .utf8)
        try HtmlReporterResources.stepHTML.write(toFile: "\(buildDir)/step.html", atomically: true, encoding: .utf8)
        let template = Template(templateString: HtmlReporterResources.buildJS)
        let rendered = try template.render(context)
        try rendered.write(toFile: "\(buildDir)/js/build.js", atomically: true, encoding: .utf8)
        print("Report written to \(buildDir)/index.html")
    }

    private func dirFor(build: BuildStep) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYYMMddHHmmss"
        return dateFormatter.string(from: Date(timeIntervalSince1970: Double(build.startTimestamp)))
    }

}
