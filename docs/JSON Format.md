# XCLogParser JSON Format

A typical step is parsed and output as JSON with the following format:
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
    "errorCount" : 0,
    "warningCount" : 0,
    "errors" : [],
    "warnings" : [],
    "swiftFunctionTimes" : [],
    "fetchedFromCache" : false,
    "compilationEndTimestamp": 1545143336.649699,
    `compilationDuration`: 5.5941859483718872
}
```

The `type` field can assume three different values:
- `main`: the summary of the whole build process. It's usually the Xcode scheme that was built.
- `target`: a target that was built that belongs to a `main` type.
- `detail`: a step inside the target. Usually a script that was run during a Pre build phase, the compilation of a single file inside the target or other Build Rule.

Other fields:
- `buildIdentifier`: a unique identifier for the given build. It uses the machine name plus the IDEActivityLog's unique identifier so it should be unique across different hosts.
- `duration`: duration in seconds for the given step.
- `subSteps`: an array of build steps that belong to the given one.
- `parentIdentifier`: identifier of the step to which the given step belongs to.
- `schema`: the name of the schema that was run.
- `buildStatus`: `succeeded` or `failed`
- `machineName`: the name of the host. If provided, it uses the value of the parameter `machine_name`,  If not, it uses the name returned by `Host.current().localizedName`.
- `signature`: for build steps of type `detail` it has the actual command executed.
- `detailStepType`: only for build steps of type `detail` . It has some info about what was run inside that step.
- `warningCount`: the number of warnings thrown by the compiler for the given step.
- `warnings`: the list of warnings
- `errorCount`: the number of errors for the given step.
- `errors`: the list of errors.
- `swiftFunctionTimes`: Optional. If the step is a `swiftCompilation` and the app was compiled with the flags `-Xfrontend -debug-time-function-bodies` it will show the list of functions and their compilation time.
- `fetchedFromCache`: For a `detail` step, `true` indicates that the file wasn't processed nor compiled but fetched from Xcode's internal cache. For a `main` or `target` step, `true` indicates that all its sub steps were fetched from cache, `false` that at least one sub step was proccesed or compiled.
- `compilationEndTimestamp`: Timestamp in which the actual compilation finished. For a Target this could be before `endTimestamp` because in the new Xcode Build System linking can happen way after compilation.
- `compilationDuration` Actual duration in seconds of just the compilation phase. In a Target this could be significant shorter than the `duration`.

When possible, the `signature` content of `detail` steps is parsed to determine its type. This makes it easier to aggregate the data.

Value | Description
--- | ---
cCompilation | An Objective-C, C or C++ file was compiled
swiftCompilation | A Swift file was compiled
scriptExecution | A Build phase script was ran
createStaticLibrary | An Static library was created with Libtool
linker | The linker ran
copySwiftLibs | The Swift Runtime libs were copied
compileAssetsCatalog | An Assets catalog was compiled
compileStoryboard | An Storyboard file was compiled
writeAuxiliaryFile | An Auxiliary file was copied into derived data
linkStoryboards | Linking of Storyboards
copyResourceFile | A Resource file was copied
mergeSwiftModule | The merge swift module tool was executed
XIBCompilation | A XIB file was compiled
swiftAggregatedCompilation | Aggregated swift compilations
precompileBridgingHeader | Bridging header was precompiled
other | Neither of the above
none | For steps that are not of type `detail`

