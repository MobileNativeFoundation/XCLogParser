import XCTest
@testable import XCLogParser

final class BuildStatusSanitizerTests: XCTestCase {
    private let sut = BuildStatusSanitizer.self
    private let succeededStatus = "succeeded"
    private let failedStatus = "failed"
    private let stoppedStatus = "stopped"

    func testSanitizeWhenStringIsOnlySucceededThenReturnSucceeded() {
        let sanitizedStatus = sut.sanitize(originalStatus: succeededStatus)

        XCTAssertEqual(sanitizedStatus, succeededStatus)
    }

    func testSanitizeWhenStringIsOnlyFailedThenReturnFailed() {
        let sanitizedStatus = sut.sanitize(originalStatus: failedStatus)

        XCTAssertEqual(sanitizedStatus, failedStatus)
    }

    func testSanitizeWhenStringIsOnlyStoppedThenReturnStopped() {
        let sanitizedStatus = sut.sanitize(originalStatus: stoppedStatus)

        XCTAssertEqual(sanitizedStatus, stoppedStatus)
    }

    func testSanitizeWhenStringIsSucceededAndContainsCleanThenReturnSucceeded() {
        let sanitizedStatus = sut.sanitize(originalStatus: "Clean " + succeededStatus)

        XCTAssertEqual(sanitizedStatus, succeededStatus)
    }

    func testSanitizeWhenStringIsFailedAndContainsCleanThenReturnFailed() {
        let sanitizedStatus = sut.sanitize(originalStatus: "Clean " + failedStatus)

        XCTAssertEqual(sanitizedStatus, failedStatus)
    }

    func testSanitizeWhenStringIsStoppedAndContainsCleanThenReturnStopped() {
        let sanitizedStatus = sut.sanitize(originalStatus: "Clean " + stoppedStatus)

        XCTAssertEqual(sanitizedStatus, stoppedStatus)
    }

    func testSanitizeWhenStringIsSucceededAndContainsBuildThenReturnSucceeded() {
        let sanitizedStatus = sut.sanitize(originalStatus: "Build " + succeededStatus)

        XCTAssertEqual(sanitizedStatus, succeededStatus)
    }

    func testSanitizeWhenStringIsFailedAndContainsBuildThenReturnFailed() {
        let sanitizedStatus = sut.sanitize(originalStatus: "Build " + failedStatus)

        XCTAssertEqual(sanitizedStatus, failedStatus)
    }

    func testSanitizeWhenStringIsStoppedAndContainsBuildThenReturnStopped() {
        let sanitizedStatus = sut.sanitize(originalStatus: "Build " + stoppedStatus)

        XCTAssertEqual(sanitizedStatus, stoppedStatus)
    }

    func testSanitizeWhenStringIsSucceededAndContainsSurroundingSpacesThenReturnSucceededTrimmed() {
        let sanitizedStatus = sut.sanitize(originalStatus: " " + succeededStatus + " ")

        XCTAssertEqual(sanitizedStatus, succeededStatus)
    }

    func testSanitizeWhenStringIsFailedAndContainsSurroundingSpacesThenReturnFailedTrimmed() {
        let sanitizedStatus = sut.sanitize(originalStatus: " " + failedStatus + " ")

        XCTAssertEqual(sanitizedStatus, failedStatus)
    }

    func testSanitizeWhenStringIsStoppedAndContainsSurroundingSpacesThenReturnStoppedTrimmed() {
        let sanitizedStatus = sut.sanitize(originalStatus: " " + stoppedStatus + " ")

        XCTAssertEqual(sanitizedStatus, stoppedStatus)
    }
}
