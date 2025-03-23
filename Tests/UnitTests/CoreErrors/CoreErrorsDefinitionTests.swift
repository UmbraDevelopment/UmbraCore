@testable import CoreErrors
import ErrorHandling
import ErrorHandlingDomains
import XCTest

final class CoreErrorsDefinitionTests: XCTestCase {
  // MARK: - SecurityError Tests

  func testSecurityErrorProperties() {
    // Test all cases have proper descriptions
    let testCases: [CoreErrors.SecurityError]=[
      .invalidKey(reason: "Test reason"),
      .invalidContext(reason: "Test reason"),
      .invalidParameter(name: "param", reason: "Test reason"),
      .operationFailed(operation: "test", reason: "Test reason"),
      .unsupportedAlgorithm(name: "algo"),
      .missingImplementation(component: "test"),
      .internalError(description: "Test error")
    ]

    for errorCase in testCases {
      // Ensure each error can be converted to canonical form and back
      let canonicalError=errorCase.toCanonicalError()
      XCTAssertNotNil(canonicalError, "Should convert to canonical form")

      let roundTrip=CoreErrors.SecurityError.fromCanonicalError(canonicalError)
      XCTAssertNotNil(roundTrip, "Should convert back from canonical form")
    }
  }

  func testSecurityErrorCanonicalMapping() {
    // Test specific mappings to ensure correctness
    let error=CoreErrors.SecurityError.invalidKey(reason: "Bad key")
    let canonical=error.toCanonicalError()

    XCTAssertTrue(
      canonical is ErrorHandlingDomains.UmbraErrors.GeneralSecurity.Core,
      "Should map to expected canonical type"
    )

    if let canonicalError=canonical as? ErrorHandlingDomains.UmbraErrors.GeneralSecurity.Core {
      if case let .invalidKey(reason)=canonicalError {
        XCTAssertEqual(reason, "Bad key", "Reason should be preserved in mapping")
      } else {
        XCTFail("Mapped to unexpected case")
      }
    }
  }

  // MARK: - CryptoError Tests

  func testCryptoErrorLocalisation() {
    // Test error descriptions are properly localised
    let testCases: [CryptoError]=[
      .invalidKeyLength(expected: 32, got: 16),
      .invalidIVLength(expected: 16, got: 8),
      .invalidSaltLength(expected: 16, got: 8),
      .invalidIterationCount(expected: 1000, got: 500),
      .keyGenerationFailed,
      .ivGenerationFailed,
      .encryptionFailed(reason: "Test reason"),
      .decryptionFailed(reason: "Test reason"),
      .tagGenerationFailed,
      .keyDerivationFailed(reason: "Test reason"),
      .authenticationFailed(reason: "Test reason"),
      .randomGenerationFailed(status: -1),
      .keyNotFound(identifier: "testKey"),
      .keyExists(identifier: "testKey"),
      .keychainError(status: -25300),
      .invalidKey(reason: "Test reason"),
      .invalidKeySize(reason: "Test reason"),
      .invalidKeyFormat(reason: "Test reason"),
      .invalidCredentialIdentifier(reason: "Test reason")
    ]

    for errorCase in testCases {
      // Verify all errors have non-empty localised descriptions
      XCTAssertNotNil(errorCase.errorDescription, "All errors should have descriptions")
      XCTAssertFalse(
        errorCase.errorDescription?.isEmpty ?? true,
        "Error description should not be empty"
      )
    }
  }

  // Add tests for other error types as needed
}
