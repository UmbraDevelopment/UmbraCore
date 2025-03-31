@testable import CoreTypesImplementation
import UmbraErrors
import UmbraErrorsCore
import XCTest

final class ErrorAdaptersTests: XCTestCase {
  func testExternalToCoreErrorMapping() {
    // Test mapping from an external error to UmbraErrors.Security.Core
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
    // When passing a UmbraErrors.Security.Core, it should be returned unchanged
    let originalError=UmbraErrors.Security.Core.internalError(description: "Test error")
    let mappedError=mapExternalToCoreError(originalError)

    XCTAssertEqual(
      originalError,
      mappedError,
      "Original UmbraErrors.Security.Core should pass through unchanged"
    )
  }

  func testCoreToExternalErrorMapping() {
    // Test mapping from UmbraErrors.Security.Core back to a generic Error
    let coreError=UmbraErrors.Security.Core.internalError(description: "Access error")
    let mappedError=mapCoreToExternalError(coreError)

    // Verify it's still a Security.Core error
    XCTAssertTrue(
      mappedError is UmbraErrors.Security.Core,
      "Mapped error should still be a Security.Core error"
    )

    // Verify it's the same error
    if let securityError=mappedError as? UmbraErrors.Security.Core {
      XCTAssertEqual(securityError, coreError, "Error should remain unchanged")
    } else {
      XCTFail("Error should remain a Security.Core error")
    }
  }

  func testSecureBytesErrorMapping() {
    // Test mapping SecureBytesError to UmbraErrors.Security.Core

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
    // Test mapping Result with different error types to Result<T, UmbraErrors.Security.Core>

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
          error is UmbraErrors.Security.Core,
          "Error should be mapped to Security.Core"
        )

        let errorString=String(describing: error)
        XCTAssertTrue(
          errorString.contains("Test error"),
          "Mapped error should contain original error description"
        )
    }
  }
}
