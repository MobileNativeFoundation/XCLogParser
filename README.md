# XCLogParser

XCLogParser is a CLI tool that parses the `SLF` serialization format used by Xcode and `xcodebuild` to store its Build and Test logs (`xcactivitylog` files).

The tool supports creating reports of different kinds to analyze the content of the logs. XCLogParser can give a lot of insights in regards to **build times** for every module and file in your project, **warnings**, **errors** and **unit tests** results.

This is an example of a report created from the Build Log of the [Kickstarter iOS open source app](https://github.com/kickstarter/ios-oss).

![kickstarter build report](images/kickstarter-ios.png)

## How and Why

`XCLogParser` is written as a [SPM](https://github.com/apple/swift-package-manager/) executable and it supports three commands:

1. [Dump](#dump-command) the contents of an `xcactivitylog` into a `JSON` document.
2. [Parse](#parse-command) the contents of an `xcactivitylog` into different kind of reports (`flatJson`, `chromeTracer` and `html`).
3. Dump the [Manifest](#manifest-command) contents of a `LogStoreManifest.plist` file into a `JSON` document.

Depending on your needs, there are various use-cases where `XCLogParser` can help you:
- Understanding and detailed tracking of build times.
- Automatically retrieve unit test results, warnings and errors.
- Build other developer tools for usage outside Xcode.
- Automatically and continuously data delivery for historic analysis.

## Installation

You can compile the executable with the command `rake build[debug]` or `rake build[release]` or simply use the Swift Package Manager commands directly. You can also run `rake install` to install the executable in your `/usr/local/bin` directory.

We are currently working on adding more installation options.

## Xcode Integration

You can automate the parsing of `xcactivitylog` files with a post-scheme build action. In this way, the last build log can be parsed as soon as a build finishes. To do that, open the scheme editor in a projeect and expand the "Build" panel on the left side. You can then add a new "Post-action" run script and invoke the `xclogparser` executable with the required parameters:

```bash
xclogparser parse --project MyApp --reporter html --output MyAppLogs
open MyAppLogs
```

![](images/post-action-run-script.png)

This script assumes that the `xclogparser` executable is installed and present in your PATH.

>Note: Errors thrown in post-action run scripts are silenced, so it could be hard to notice simple mistakes.

The run script is executed in a temporary directory by Xcode, so you may find it useful to immediately open the generated output with `open MyAppLogs` at the end of the script.
The Finder will automatically open the output folder after a build completes and you can then view the generatd HTML page that contains a nice visualization of your build! ✨

## Log Types

### Build Logs

The `xcactivitylog` files are created by Xcode/`xcodebuild` a few seconds after a build completes. The log is placed in the `DerivedData/YourProjectName-UUID/Logs/Build` directory. It is a binary file in the `SLF` format compressed with gzip.

In the same directory, you will find a `LogStoreManifest.plist` file with the list of `xcactivitylog` files generated for the project. This file can be monitored in order to get notified every time a new log is ready.

### Test Logs

The test logs are created inside the `DerivedData/YourProjectName-UUID/Logs/Test` directory. Xcode and `xcodebuild` create different logs. You can find a good description about which ones are created in this [blog post](https://michele.io/test-logs-in-xcode/).

## Features

### Dump Command

Dumps the whole content of an `xcactivitylog` file as `JSON` document. You can use this command if you want to have a raw but easy to parse representation of a log.

Examples:

```bash
xclogparser dump --file path/to/log.xcactivitylog --output activity.json
xclogparser dump --project MyProject --output activity.json --redacted
```

An example output has been ommitted for brevity since it can contain a lot of information regarding a build.

<details>
  <summary>Available parameters</summary>

  | Parameter Name | Description | Required |
  |-----|---|-----|
  | `--file`  | The path to the `xcactivitylog`.  | No * |
  | `--project`  | The name of the project if you don't know the path to the log. The tool will try to find the latest Build log in a folder that starts with that name inside the `DerivedData` directory.  | No * |
  | `--worskapce`  | The path to the `xcworkspace` file if you don't know the path to the log. It will generate the folder name for the project in the `DerivedData` folder using Xcode's hash algorithm and it will try to locate the latest Build Log inside that directory.  | No * |
  | `--xcodeproj`  | The path to the `xcodeproj` file if you don't know the path to the log and if the project doesn't have a `xcworkspace` file. It will generate the folder name for the project in the `DerivedData` folder using Xcode's hash algorithm and it will try to locate the latest Build Log inside that directory.  | No * |
  | `--derived_data`  | The path to the derived data folder if you are using `xcodebuild` to build your project with the `-derivedDataPath` option.  | No |
  | `--output`  | If specified, the JSON file will be written to the given path. If not defined, the command will output to the standard output.  | No |
  | `--redacted`  | If specified, the username will be replaced by the word `redacted` in the file paths contained in the logs. Useful for privacy reasons but slightly decreases the performance.  | No |

  >No *: One of `--file`, `--project`, `--workspace`, `--xcodeproj` parameters is required.

</details>

### Parse Command

Parses the build information from a `xcactivitylog` and converts it into different representations such as a [JSON file](#JSON-Reporter), [flat JSON file](#FlatJson-Reporter), [Chrome Tracer file](#ChromeTracer-Reporter) or a static [HTML page](#HTML-Reporter).

Examples:

```bash
xclogparser parse --project MyApp --reporter json --output build.json
xclogparser parse --file /path/to/log.xcactivitylog --reporter chromeTracer
xclogparser parse --workspace /path/to/MyApp.xcworkspace --derived_data /path/to/custom/DerivedData --reporter html --redacted
```

Example output available in the [reporters](#reporters) section.

<details>
  <summary>Available parameters</summary>

  | Parameter Name | Description | Required |
  |-----|---|-----|
  | `--reporter`  | The reporter used to transform the logs. It can be either `json`, `flatJson`, `chromeTracer` or `html`. (required)  | Yes |
  | `--file`  | The path to the `xcactivitylog`.  | No * |
  | `--project`  | The name of the project if you don't know the path to the log. The tool will try to find the latest Build log in a folder that starts with that name inside the `DerivedData` directory.  | No * |
  | `--worskapce`  | The path to the `xcworkspace` file if you don't know the path to the log. It will generate the folder name for the project in the `DerivedData` folder using Xcode's hash algorithm and it will try to locate the latest Build Log inside that directory.  | No * |
  | `--xcodeproj`  | The path to the `xcodeproj` file if you don't know the path to the log and if the project doesn't have a `xcworkspace` file. It will generate the folder name for the project in the `DerivedData` folder using Xcode's hash algorithm and it will try to locate the latest Build Log inside that directory.  | No * |
  | `--derived_data`  | The path to the derived data folder if you are using `xcodebuild` to build your project with the `-derivedDataPath` option.  | No |
  | `--output`  | If specified, the JSON file will be written to the given path. If not defined, the command will output to the standard output.  | No |
  | `--redacted`  | If specified, the username will be replaced by the word `redacted` in the file paths contained in the logs. Useful for privacy reasons but slightly decreases the performance.  | No |

  >No *: One of `--file`, `--project`, `--workspace`, `--xcodeproj` parameters is required.

</details>

### Manifest Command

Outputs the contents of `LogStoreManifest.plist` which lists all the `xcactivitylog` files generated for the project as JSON.

Example:

```bash
xclogparser manifest --project MyApp
```

Example output:
```json
{
  "scheme" : "MyApp",
  "timestampEnd" : 1548337458,
  "fileName" : "D6539DED-8AC8-4508-9841-46606D0C794A.xcactivitylog",
  "title" : "Build MyApp",
  "duration" : 46,
  "timestampStart" : 1548337412,
  "uniqueIdentifier" : "D6539DED-8AC8-4508-9841-46606D0C794A",
  "type" : "xcode"
}
```

<details>
  <summary>Available parameters</summary>

  | Parameter Name | Description | Required |
  |-----|---|-----|
  | `--log_manifest`  | The path to an existing `LogStoreManifest.plist`.  | No * |
  | `--project`  | The name of the project if you don't know the path to the log. The tool will try to find the latest Build log in a folder that starts with that name inside the `DerivedData` directory.  | No * |
  | `--worskapce`  | The path to the `xcworkspace` file if you don't know the path to the log. It will generate the folder name for the project in the `DerivedData` folder using Xcode's hash algorithm and it will try to locate the latest Build Log inside that directory.  | No * |
  | `--xcodeproj`  | The path to the `xcodeproj` file if you don't know the path to the log and if the project doesn't have a `xcworkspace` file. It will generate the folder name for the project in the `DerivedData` folder using Xcode's hash algorithm and it will try to locate the latest Build Log inside that directory.  | No * |
  | `--derived_data`  | The path to the derived data folder if you are using `xcodebuild` to build your project with the `-derivedDataPath` option.  | No |
  | `--output`  | If specified, the JSON file will be written to the given path. If not defined, the command will output to the standard output.  | No |

  >No *: One of `--log-manifest`, `--project`, `--workspace`, `--xcodeproj` parameters is required.

</details>

## Reporters

The [parse command](#parse-command) has different types of reporters built-in that can represent and visualize the data of the logs:

- [JSON](#json-reporter)
- [Flat JSON](#flatojson-reporter)
- [Chrome Tracer](#chrometracer-reporter)
- [HTML](#html-reporter)

### JSON Reporter

This reporter parses the log and outputs it as JSON. It contains information about the duration of each step in the build, along other metadata and interesting information such as errors and warnings.

Example:

```bash
xclogparser parse --project MyApp --reporter json
```

<details>
  <summary>Example Output</summary>

  ```json
  {
      "detailStepType" : "swiftCompilation",
      "startTimestamp" : 1545143336.649699,
      "endTimestamp" : 1545143336.649699,
      "schema" : "MyApp",
      "domain" : "com.apple.dt.IDE.BuildLogSection",
      "parentIdentifier" : "095709ba230e4eda80ab43be3b68f99c_1545299644.4805899_20",
      "endDate" : "2018-12-18T14:28:56.650000+0000",
      "title" : "Compile \/Users\/<redacted>\/projects\/MyApp\/Libraries\/Utilities\/Sources\/Disposables\/Cancelable.swift",
      "identifier" : "095709ba230e4eda80ab43be3b68f99c_1545299644.4805899_185",
      "signature" : "CompileSwift normal x86_64 \/Users\/<redacted>\/MyApp\/Libraries\/Utilities\/Sources\/Disposables\/Cancelable.swift",
      "type" : "detail",
      "buildStatus" : "succeeded",
      "subSteps" : [

      ],
      "startDate" : "2018-12-18T14:28:56.650000+0000",
      "buildIdentifier" : "095709ba230e4eda80ab43be3b68f99c_1545299644.4805899",
      "machineName" : "095709ba230e4eda80ab43be3b68f99c",
      "duration" : 5.5941859483718872,
      "errors" : "",
      "warnings" : "",
      "errorCount" : 0,
      "warningCount" : 0,
      "errors" : [],
      "warnings" : [],
      "swiftFunctionTimes" : []
  }
  ```
</details>


For more information regarding each field, check out the [JSON format documentation](/docs/JSON Format.md).


### FlatJson Reporter

Parses the log as an array of JSON objects, with no nested steps (the field `subSteps` is always empty). Useful to dump the data into a database so it's easier to analyze.

The format of the JSON objects in the array is the same to the one used in the `json` reporter.

Example:

```bash
xclogparser parse --file path/to/log.xcactivitylog --reporter flatJson
```

<details>
  <summary>Example Output</summary>

  ```json
  [
    {
      "parentIdentifier" : "",
      "title" : "Build MobiusCore",
      "warningCount" : 0,
      "duration" : 0,
      "startTimestamp" : 1558590748,
      "signature" : "Build MobiusCore",
      "endDate" : "2019-05-23T05:52:28.274000Z",
      "errorCount" : 0,
      "domain" : "Xcode.IDEActivityLogDomainType.BuildLog",
      "type" : "main",
      "identifier" : "68a2bbd0048a454d91b3734b5d5dc45e_1558640253_1",
      "buildStatus" : "succeeded",
      "schema" : "MobiusCore",
      "subSteps" : [

      ],
      "endTimestamp" : 1558590748,
      "architecture" : "",
      "machineName" : "68a2bbd0048a454d91b3734b5d5dc45e",
      "buildIdentifier" : "68a2bbd0048a454d91b3734b5d5dc45e_1558640253",
      "startDate" : "2019-05-23T05:52:28.244000Z",
      "documentURL" : "",
      "detailStepType" : "none"
    },
    {
      "parentIdentifier" : "68a2bbd0048a454d91b3734b5d5dc45e_1558640253_1",
      "title" : "Prepare build",
      "warningCount" : 0,
      "duration" : 0,
      "startTimestamp" : 1558590748,
      "signature" : "Prepare build",
      "endDate" : "2019-05-23T05:52:28.261000Z",
      "errorCount" : 0,
      "domain" : "Xcode.IDEActivityLogDomainType.XCBuild.Preparation",
      "type" : "target",
      "identifier" : "68a2bbd0048a454d91b3734b5d5dc45e_1558640253_2",
      "buildStatus" : "succeeded",
      "schema" : "MobiusCore",
      "subSteps" : [

      ],
      "endTimestamp" : 1558590748,
      "architecture" : "",
      "machineName" : "68a2bbd0048a454d91b3734b5d5dc45e",
      "buildIdentifier" : "68a2bbd0048a454d91b3734b5d5dc45e_1558640253",
      "startDate" : "2019-05-23T05:52:28.254000Z",
      "documentURL" : "",
      "detailStepType" : "none"
    },{
      "parentIdentifier" : "68a2bbd0048a454d91b3734b5d5dc45e_1558640253_1",
      "title" : "Build target MobiusCore",
      "warningCount" : 0,
      "duration" : 4,
      "startTimestamp" : 1558590708,
      "signature" : "MobiusCore-fmrwijcuutzbrmbgantlsfqxegcg",
      "endDate" : "2019-05-23T05:51:51.890000Z",
      "errorCount" : 0,
      "domain" : "Xcode.IDEActivityLogDomainType.target.product-type.framework",
      "type" : "target",
      "identifier" : "68a2bbd0048a454d91b3734b5d5dc45e_1558640253_3",
      "buildStatus" : "succeeded",
      "schema" : "MobiusCore",
      "subSteps" : [

      ],
      "endTimestamp" : 1558590712,
      "architecture" : "",
      "machineName" : "68a2bbd0048a454d91b3734b5d5dc45e",
      "buildIdentifier" : "68a2bbd0048a454d91b3734b5d5dc45e_1558640253",
      "startDate" : "2019-05-23T05:51:48.206000Z",
      "documentURL" : "",
      "detailStepType" : "none"
    },
    ...
  ]
  ```
</details>


For more information regarding each field, check out the [JSON format documentation](https://github.com/spotify/XCLogParser/blob/master/docs/JSON%20Format.md).

### ChromeTracer Reporter

Parses the `xcactivitylog` as an array of JSON objects in the format used by the Chrome tracer. You can use this JSON to visualize the build times in the Chrome tracing tool inside Chrome: `chrome://tracing`.

Example:

```bash
xclogparser parse --file path/to/log.xcactivitylog --reporter chromeTracer
```

<details>
  <summary>Example Output</summary>

  <img src="images/kickstarter-ios-chrome-tracer.png">
</details>

### HTML Reporter

Generates an HTML report to visualize build times per module and file, along with warning and error messages.

Example:

```bash
xclogparser parse --file path/to/log.xcactivitylog --reporter html --output build/reports
```

<details>
  <summary>Example Output</summary>

  <img src="images/kickstarter-ios.png">
</details>

## Requirements and Compatibility

| Environment | Version     |
| ----------- |-------------|
| 🛠 Xcode    | 10.2        |
| 🐦 Language | Swift 4.2   |

## Status

XCLogParser is currently in alpha status. We are using it internally and tested it on various projects, but we need the help from the community to test and improve it with more iOS and Mac applications.

## Development and Contributing

1. Clone the repo with `git clone git@github.com/spotify/xclogparser.git`.
2. Run `rake gen_resources` to generate a static resource Swift file that is needed to compile the app.
3. Run `swift package generate-xcodeproj` to generate an Xcode project (or use any text editor).
4. Run tests in Xcode directly (CMD + U) or using `rake test`.
5. Create issue and discuss a possible solution or improvement.
6. Create a PR.

If you find a bug or you would like to propose an improvement, you're welcome to create an [issue](https://github.com/spotify/xclogparser/issues/new).

## Code of Conduct

This project adheres to the [Open Code of Conduct](https://github.com/spotify/code-of-conduct/blob/master/code-of-conduct.md). By participating, you are expected to honor this code.
