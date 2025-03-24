@testable import ErrorHandlingModels
import XCTest

final class ErrorContextTests: XCTestCase {
  func testErrorContextCreation() {
    let context=ErrorContext(
      source: "TestService",
      code: "TEST_ERROR",
      message: "Test error message",
      metadata: ["operation": "testOperation", "details": "Test details"]
    )

    XCTAssertEqual(context.source, "TestService")
    XCTAssertEqual(context.code, "TEST_ERROR")
    XCTAssertEqual(context.message, "Test error message")
    XCTAssertEqual(context.metadata["operation"], "testOperation")
    XCTAssertEqual(context.metadata["details"], "Test details")
  }

  func testErrorContextDescription() {
    let context=ErrorContext(
      source: "TestService",
      code: "TEST_ERROR",
      message: "Test error message",
      metadata: [
        "operation": "testOperation",
        "details": "Test details",
        "file": "test.swift",
        "line": "42",
        "function": "testFunction()"
      ]
    )

    let description=context.description

    XCTAssertTrue(description.contains("TestService"))
    XCTAssertTrue(description.contains("TEST_ERROR"))
    XCTAssertTrue(description.contains("Test error message"))
    XCTAssertTrue(description.contains("testOperation"))
    XCTAssertTrue(description.contains("Test details"))
  }

  func testErrorContextWithoutDetails() {
    let context=ErrorContext(
      source: "TestService",
      message: "Test error message"
    )

    let description=context.description

    XCTAssertTrue(description.contains("TestService"))
    XCTAssertTrue(description.contains("Test error message"))
    XCTAssertFalse(description.contains("details"))
  }
}
