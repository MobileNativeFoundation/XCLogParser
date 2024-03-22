# The Xcactivitylog format

Xcode logs are stored in files with the extension `.xcactivitylog`. Those files are gzipped to save storage. The files are encoded using a format called `SLF`.

## The SLF format

This information was first documented by Vincent Isambart in this [blog post](https://techlife.cookpad.com/entry/2017/12/08/124532).

A `SLF` document starts with the header `SLF0`. After the header, the document has a collection of encoded values. The SLF encoding format supports these types:

- Integer
- Double
- String
- Array
- Class names
- Class instances
- Null
- JSON

A value encoded is formed by 3 parts:

- Left hand side value (optional)
- Character type delimiter
- Right hand side value (optional)

### Integer

- Character type delimiter: `#`
- Example: `200#`
- Left hand side value: An unsigned 64 bits integer.

### Double

- Character type delimiter: `^`
- Example: `afd021ebae48c141^`
- Left hand side value: A little-endian floating point number, encoded in hexadecimal.

You can convert it to a Swift Double using the `bitPattern` property of `Double`:

```swift
guard let value = UInt64(input, radix: 16) else {
  return nil
}
let double =  Double(bitPattern: value.byteSwapped)
```

In the `xcactivitylog`'s files, this type of value is used to encode timestamps. Thus, the double represents a `timeInterval` value using `timeIntervalSinceReferenceDate`.

### Null

- Character type delimiter: `-`
- No left, nor right hand side value

### String

- Character type delimiter: `"`
- Example: `5"Hello`
- Left hand side value: An `Integer` with the number of characters that are part of the `String`.
- Right hand side value: The characters that are part of the `String`

The number of characters works as in `NSString` rather than in `String`: it counts the 16-bit code units within the string’s UTF-16 representation and not the number of Unicode extended grapheme clusters within the string like in Swift's `String`.

So you have to be careful to load the file not as an UTF-8 String, because it will give you a mismatch with the count in the `SLF` Format. Currently, we load the content of the file as an ASCII String to avoid that problem:

```swift
let content = String(data: unzippedXcactivitylog, encoding: .ascii)
```

Other example:
`6"Hello--9#`
In this case, there are three encoded values:

1. The String "Hello-"
2. A Null value.
3. The integer 9.

### Array

- Character type delimiter: `(`
- Example: `22(`
- Left hand side value: An `Integer` with the number of elements that are part of the `Array`.

The elements of an `Array` are `Class instances`

### JSON

- Character type delimiter: `*`
- Example: `"{\"wcStartTime\":732791618924407,\"maxRSS\":0,\"utime\":798,\"wcDuration\":852,\"stime\":798}"`
- Left hand side value: An `Integer` with the number of characters that are part of the `JSON` string.

The JSON is of the type `IDEFoundation.IDEActivityLogSectionAttachment`

### Class name

- Character type delimiter: `%`
- Example: `21%IDEActivityLogSection`
- Left hand side value: An `Integer` with the number of characters that are part of the `Class name`.
- Right hand side value: The characters that are part of the `Class name`

It follows the same rules as a `String`.

A given `Class name` only appears once: before its first `Class instance`. It's important to store the order in which you found a `Class name` in the log, because that index is used by the `Class instance`.

### Class instance

- Character type delimiter: `@`
- Example: `2@`
- Left hand side value: An `Integer` with the index of the `Class name` of the `Class instance`'s type.

In the case of `2@`, it means that the `Class instance`'s type is the `Class name` found in the 3rd position in the `SLF` document.

## Tokenizing the .xcactivitylog

With those rules, you can decode the log and tokenize it. For instance, given this log's content:

```
SLF010#21%IDEActivityLogSection1@0#39"Xcode.IDEActivityLogDomainType.BuildLog20"Build XCLogParserApp20"Build XCLogParserApp0074f8eaae48c141^8f19bcf4ae48c141^12(1@1#50"Xcode.IDEActivityLogDomainType.XCBuild.Preparation13"Prepare build13"Prepare build
```

You can get these tokens:

```swift
[type: "int", value: 10],
[type: "className", name: "IDEActivityLogSection"],
[type: "classInstance", className: "IDEActivityLogSection"],
[type: "int", value: 0],
[type: "string", value: "Xcode.IDEActivityLogDomainType.BuildLog"],
[type: "string", value: "Build XCLogParserApp"],
[type: "string", value: "Build XCLogParserApp"],
[type: "double", value: 580158292.767495],
[type: "double", value: 580158295.086277],
[type: "array", count: 12],
[type: "classInstance", className: "IDEActivityLogSection"],
[type: "string", value: "Xcode.IDEActivityLogDomainType.XCBuild.Preparation"],
[type: "string", value: "Prepare build"],
[type: "string", value: "Prepare build"],
```

The first integer is the version of the `SLF` format used. In Xcode 10.x and 11 Beta, the version is 10. The values after the version are the actual content of the log.

## Parsing an xcactivitylog

One of the limitations of the `SLF` format is that it only points to the place where a `Class instance` starts, it doesn't have information about where it ends or about the name of its properties. The only information we have about the class instance we have is its type (the `Class name`).

Inside the logs you can find these classes:

- `IDEActivityLogSection`
- `IDEActivityLogUnitTestSection`
- `IDEActivityLogMessage`
- `DVTDocumentLocation`
- `DVTTextDocumentLocation`
- `IDEActivityLogCommandInvocationSection`
- `IDEActivityLogMajorGroupSection`
- `IDEFoundation.IDEActivityLogSectionAttachment`

If you search for them, you will find that they belong to the IDEFoundation.framework. A private framework part of Xcode. You can class dump it to get the headers of those classes. Once you have the headers, you will have the name and type of the properties that belong to the class. Now, you can match them to the tokens you got from the log. Some of them are in the same order than in the headers, but for others it will be about trial and error.

In the project you can find those classes with their properties in the order in which they appear in the log in the file (IDEActivityModel.swift)[https://github.com/MobileNativeFoundation/XCLogParser/blob/master/Sources/XCLogParser/activityparser/IDEActivityModel.swift].
