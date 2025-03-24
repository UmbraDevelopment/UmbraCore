@testable import ErrorHandling
@testable import ErrorHandlingCommon
@testable import ErrorHandlingProtocols
import Foundation
import XCTest

/**
 * Tests for the UmbraError protocol implementation
 *
 * These tests verify that UmbraError implementations correctly handle
 * error description, context, source information, and underlying errors.
 */
final class UmbraErrorProtocolTests: XCTestCase {
  // Test implementation of UmbraError
  struct TestError: UmbraError, DomainError {
    static var domain: String { "Test" }
    let code: String
    let errorDescription: String
    var underlyingError: Error?
    var source: ErrorHandlingCommon.ErrorSource?
    var customContext: ErrorHandlingCommon.ErrorContext?

    var context: ErrorHandlingCommon.ErrorContext {
      customContext ?? ErrorHandlingCommon.ErrorContext(
        source: Self.domain,
        operation: "test",
        details: errorDescription
      )
    }

    func with(context: ErrorHandlingCommon.ErrorContext) -> TestError {
      var newError=self
      newError.customContext=context
      return newError
    }

    func with(underlyingError: Error) -> TestError {
      var newError=self
      newError.underlyingError=underlyingError
      return newError
    }

    func with(source: ErrorHandlingCommon.ErrorSource) -> TestError {
      var newError=self
      newError.source=source
      return newError
    }
  }

  /**
   * Test basic UmbraError properties
   */
  func testUmbraErrorBasicRequirements() {
    // Given
    let error=TestError(code: "E001", errorDescription: "Test error")

    // Then
    XCTAssertEqual(error.domain, "Test", "Domain should match the static domain property")
    XCTAssertEqual(error.code, "E001", "Code should match the provided code")
    XCTAssertEqual(
      error.errorDescription,
      "Test error",
      "Error description should match the provided description"
    )

    // Test description formatting
    XCTAssertEqual(
      error.description,
      "[Test:E001] Test error",
      "Description should be formatted as [domain:code] description"
    )
  }

  /**
   * Test error with source information
   */
  func testErrorWithSourceLocation() {
    // Given
    let error=TestError(code: "E001", errorDescription: "Test error")

    // When
    let errorWithSource=error.withSource(file: "TestFile.swift", function: "testFunction", line: 42)

    // Then
    XCTAssertNotNil(errorWithSource.source, "Source information should be set")
    XCTAssertEqual(
      errorWithSource.source?.file,
      "TestFile.swift",
      "File should match provided file"
    )
    XCTAssertEqual(
      errorWithSource.source?.function,
      "testFunction",
      "Function should match provided function"
    )
    XCTAssertEqual(errorWithSource.source?.line, 42, "Line should match provided line")

    // Verify description format
    XCTAssertTrue(
      errorWithSource.description.contains("[Test:E001]"),
      "Error description should contain domain and code"
    )
    XCTAssertTrue(
      errorWithSource.description.contains("TestFile.swift:42"),
      "Error description should contain file and line"
    )
  }

  /**
   * Test the default withSource implementation that uses caller's source location
   */
  func testWithSourceUsingCallerLocation() {
    // Given
    let error=TestError(code: "E002", errorDescription: "Test error with caller source")

    // When
    let errorWithSource=error.withSource()

    // Then
    XCTAssertNotNil(errorWithSource.source, "Source information should be set")
    XCTAssertEqual(
      errorWithSource.source?.function,
      #function,
      "Function should match current function"
    )
    XCTAssertTrue(
      errorWithSource.source?.file.contains("UmbraErrorProtocolTests.swift") ?? false,
      "File should match current file"
    )

    // Verify description contains source
    XCTAssertTrue(
      errorWithSource.description.contains(#function),
      "Error description should contain function name"
    )
  }

  /**
   * Test error with context
   */
  func testErrorWithContext() {
    // Given
    let error=TestError(code: "E003", errorDescription: "Test error")
    let newContext=ErrorHandlingCommon.ErrorContext(
      source: "TestSource",
      operation: "TestOperation",
      details: "Detailed info"
    )

    // When
    let errorWithContext=error.with(context: newContext)

    // Then
    XCTAssertEqual(
      errorWithContext.context.source,
      "TestSource",
      "Context source should match provided value"
    )
    XCTAssertEqual(
      errorWithContext.context.operation,
      "TestOperation",
      "Context operation should match provided value"
    )
    XCTAssertEqual(
      errorWithContext.context.details,
      "Detailed info",
      "Context details should match provided value"
    )
  }

  /**
   * Test error with underlying error
   */
  func testErrorWithUnderlyingError() {
    // Given
    let originalError=NSError(domain: "OriginalError", code: 100, userInfo: nil)
    let testError=TestError(code: "E002", errorDescription: "Wrapper error")

    // When
    let errorWithUnderlying=testError.with(underlyingError: originalError)

    // Then
    XCTAssertNotNil(errorWithUnderlying.underlyingError, "Underlying error should be set")
    XCTAssertEqual(
      (errorWithUnderlying.underlyingError as? NSError)?.domain,
      "OriginalError",
      "Underlying error domain should match original error"
    )
    XCTAssertEqual(
      (errorWithUnderlying.underlyingError as? NSError)?.code,
      100,
      "Underlying error code should match original error"
    )
  }

  /**
   * Test DomainError protocol implementation
   */
  func testDomainErrorImplementation() {
    // Given - Custom domain error type
    struct CustomDomainError: DomainError {
      static var domain: String { "CustomDomain" }
      let code: String
      let errorDescription: String
      var underlyingError: Error?
      var source: ErrorHandlingCommon.ErrorSource?

      // Default implementations for DomainError
      func with(context _: ErrorHandlingCommon.ErrorContext) -> Self { self }
      func with(underlyingError _: Error) -> Self { self }
      func with(source _: ErrorHandlingCommon.ErrorSource) -> Self { self }
    }

    // When
    let error=CustomDomainError(
      code: "D001",
      errorDescription: "Custom domain error"
    )

    // Then
    XCTAssertEqual(
      error.domain,
      "CustomDomain",
      "Domain should be derived from static domain property"
    )
  }
}
