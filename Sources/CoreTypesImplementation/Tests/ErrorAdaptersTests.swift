import CoreErrors
@testable import CoreTypesImplementation
import ErrorHandlingDomains // Add import for UmbraErrors
import XCTest

final class ErrorAdaptersTests: XCTestCase {
  func testExternalToCoreErrorMapping() {
    // Test mapping from an external error to CoreErrors.SecurityError
    struct ExternalError: Error, CustomStringConvertible {
      let reason: String
      var description: String { "External error: \(reason)" }
    }

    let externalError=ExternalError(reason: "API call failed")
    let mappedError=externalErrorToCoreError(externalError)

    // Check that we can convert the error to a string instead of checking for specific case
    let errorDescription=String(describing: mappedError)
    XCTAssertTrue(
      errorDescription.contains("External error"),
      "Mapped error should contain the original description"
    )
  }

  func testCoreErrorPassthrough() {
    // When passing a CoreErrors.SecurityError, it should be returned unchanged
    let originalError=CoreErrors.SecurityError.internalError("Test error")
    let mappedError=mapExternalToCoreError(originalError)

    XCTAssertEqual(
      originalError,
      mappedError,
      "Original CoreErrors.SecurityError should pass through unchanged"
    )
  }

  func testCoreToExternalErrorMapping() {
    // Test mapping from CoreErrors.SecurityError back to a generic Error
    let coreError=CoreErrors.SecurityError.internalError("Access error")
    let mappedError=mapCoreToExternalError(coreError)

    // Verify it's still a SecurityError
    XCTAssertTrue(
      mappedError is CoreErrors.SecurityError,
      "Mapped error should still be a SecurityError"
    )

    // Verify it's the same error
    if let securityError=mappedError as? CoreErrors.SecurityError {
      XCTAssertEqual(securityError, coreError, "Error should remain unchanged")
    } else {
      XCTFail("Error type was changed unexpectedly")
    }
  }

  func testSecureBytesErrorMapping() {
    // Test mapping SecureBytesError to CoreErrors.SecurityError

    // Memory allocation failure
    let allocError=SecureBytesError.allocationFailed
    let mappedAllocError=mapSecureBytesToCoreError(allocError)

    // Use string comparison instead of case pattern matching
    let allocErrorString=String(describing: mappedAllocError)
    XCTAssertTrue(
      allocErrorString.contains("internal"),
      "Error message doesn't match expected content"
    )

    // Invalid hex string
    let hexError=SecureBytesError.invalidHexString
    let mappedHexError=mapSecureBytesToCoreError(hexError)

    let hexErrorString=String(describing: mappedHexError)
    XCTAssertTrue(
      hexErrorString.contains("internal"),
      "Error message doesn't match expected content"
    )

    // Out of bounds error
    let boundsError=SecureBytesError.outOfBounds
    let mappedBoundsError=mapSecureBytesToCoreError(boundsError)

    let boundsErrorString=String(describing: mappedBoundsError)
    XCTAssertTrue(
      boundsErrorString.contains("internal"),
      "Error message doesn't match expected content"
    )
  }

  func testResultErrorMapping() {
    // Test mapping Result with different error types to Result<T, CoreErrors.SecurityError>

    // Test success case (should pass through)
    let successResult=Result<String, Error>.success("test data")
    let mappedSuccessResult=mapToSecurityResult(successResult)

    switch mappedSuccessResult {
      case let .success(value):
        XCTAssertEqual(value, "test data", "Success value should remain unchanged")
      case .failure:
        XCTFail("Success result should remain a success")
    }

    // Test failure case with error mapping
    struct TestError: Error, CustomStringConvertible {
      let message: String
      var description: String { message }
    }

    let failureResult=Result<String, Error>.failure(TestError(message: "Test error"))
    let mappedFailureResult=mapToSecurityResult(failureResult)

    switch mappedFailureResult {
      case .success:
        XCTFail("Failure result should remain a failure")
      case let .failure(error):
        XCTAssertTrue(
          error is CoreErrors.SecurityError,
          "Error should be mapped to SecurityError"
        )

        let errorString=String(describing: error)
        XCTAssertTrue(
          errorString.contains("Test error"),
          "Mapped error should contain original error description"
        )
    }
  }
}
