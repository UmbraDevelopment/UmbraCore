@testable import ErrorHandling
@testable import ErrorHandlingCommon
@testable import ErrorHandlingInterfaces
import XCTest

// Add an extension to ErrorSource to provide the shortFile property
extension ErrorHandlingInterfaces.ErrorSource {
  var shortFile: String {
    (file as NSString).lastPathComponent
  }
}

final class TestErrorHandling_Common: XCTestCase {
  // MARK: - ErrorContext Tests

  func testErrorContextCreation() {
    // Test creation with minimal parameters
    let context=ErrorHandlingCommon.ErrorContext(
      source: "TestSource",
      operation: "testOperation"
    )

    XCTAssertEqual(context.source, "TestSource")
    XCTAssertEqual(context.operation, "testOperation")
    XCTAssertNil(context.details)
    XCTAssertNil(context.underlyingError)

    // Test creation with all parameters
    let underlyingError=NSError(domain: "TestDomain", code: 123, userInfo: nil)
    let fullContext=ErrorHandlingCommon.ErrorContext(
      source: "TestSource",
      operation: "testOperation",
      details: "Test details",
      underlyingError: underlyingError,
      file: "TestFile.swift",
      line: 42,
      function: "testFunction()"
    )

    XCTAssertEqual(fullContext.source, "TestSource")
    XCTAssertEqual(fullContext.operation, "testOperation")
    XCTAssertEqual(fullContext.details, "Test details")
    XCTAssertNotNil(fullContext.underlyingError)
    XCTAssertEqual(fullContext.file, "TestFile.swift")
    XCTAssertEqual(fullContext.line, 42)
    XCTAssertEqual(fullContext.function, "testFunction()")

    // Verify the underlying error is correct
    if let error=fullContext.underlyingError as? NSError {
      XCTAssertEqual(error.domain, "TestDomain")
      XCTAssertEqual(error.code, 123)
    } else {
      XCTFail("Underlying error not properly stored or retrieved")
    }
  }

  // MARK: - ErrorSource Tests

  func testErrorSourceCreation() {
    // Test creation with explicit parameters
    let source=ErrorHandlingCommon.ErrorSource(
      file: "TestFile.swift",
      function: "testFunction()",
      line: 42
    )

    XCTAssertEqual(source.file, "TestFile.swift")
    XCTAssertEqual(source.function, "testFunction()")
    XCTAssertEqual(source.line, 42)

    // Test shortFile property
    XCTAssertEqual(source.shortFile, "TestFile.swift")

    // Test creation with default parameters
    let defaultSource=ErrorHandlingCommon.ErrorSource()

    // Verify the current file, function, and line are captured
    XCTAssertTrue(defaultSource.file.hasSuffix("TestErrorHandling_Common.swift"))
    XCTAssertTrue(defaultSource.function.contains("testErrorSourceCreation"))
  }

  // MARK: - Error Extension Tests

  func testErrorExtensions() {
    // Define the expected values
    let expectedDescription="Test description"
    let expectedFailureReason="Test failure reason"
    let expectedRecoverySuggestion="Test recovery suggestion"
    let expectedHelpAnchor="Test help anchor"

    // Create a test error with the required userInfo
    let testError=NSError(
      domain: "TestDomain",
      code: 456,
      userInfo: [
        NSLocalizedDescriptionKey: expectedDescription,
        NSLocalizedFailureReasonErrorKey: expectedFailureReason,
        NSLocalizedRecoverySuggestionErrorKey: expectedRecoverySuggestion,
        NSHelpAnchorErrorKey: expectedHelpAnchor,
        NSUnderlyingErrorKey: NSError(domain: "UnderlyingDomain", code: 789, userInfo: nil)
      ]
    )

    // Test error extension properties - access via userInfo directly for NSError
    XCTAssertEqual(testError.localizedDescription, expectedDescription)
    XCTAssertEqual(
      testError.userInfo[NSLocalizedFailureReasonErrorKey] as? String,
      expectedFailureReason
    )
    XCTAssertEqual(
      testError.userInfo[NSLocalizedRecoverySuggestionErrorKey] as? String,
      expectedRecoverySuggestion
    )
    XCTAssertEqual(testError.userInfo[NSHelpAnchorErrorKey] as? String, expectedHelpAnchor)
    XCTAssertEqual(testError.domain, "TestDomain")
    XCTAssertEqual(testError.code, 456)

    // Test underlying error access
    guard let underlyingError=testError.userInfo[NSUnderlyingErrorKey] as? NSError else {
      XCTFail("Unable to access underlying error")
      return
    }

    XCTAssertEqual(underlyingError.domain, "UnderlyingDomain")
    XCTAssertEqual(underlyingError.code, 789)
  }
}
