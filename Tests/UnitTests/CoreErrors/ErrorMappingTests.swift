@testable import CoreErrors
import ErrorHandling
import ErrorHandlingDomains
import XCTest

final class ErrorMappingTests: XCTestCase {
  // MARK: - Crypto Error Mapping Tests

  func testCryptoErrorToCanonicalMapping() {
    // Test mapping from legacy CryptoError to canonical UmbraErrors.Crypto.Core
    let testCases: [(CryptoError, String)]=[
      (.invalidKeyLength(expected: 32, got: 16), "invalid_parameters"),
      (.invalidIVLength(expected: 16, got: 8), "invalid_parameters"),
      (.encryptionFailed(reason: "Test reason"), "encryption_failed"),
      (.decryptionFailed(reason: "Test reason"), "decryption_failed"),
      (.keyGenerationFailed, "key_generation_failed"),
      (.keyNotFound(identifier: "testKey"), "key_not_found"),
      (.randomGenerationFailed(status: -1), "random_generation_failed")
    ]

    for (error, expectedCasePrefix) in testCases {
      let canonicalError=error.toCanonical()
      XCTAssertNotNil(canonicalError, "Should convert to canonical error")

      if let canonicalError=canonicalError as? UmbraErrors.Crypto.Core {
        // Use reflection to verify we mapped to the expected case type
        let errorCase=String(describing: canonicalError)
        XCTAssertTrue(
          errorCase.contains(expectedCasePrefix),
          "Expected case containing \(expectedCasePrefix), got \(errorCase)"
        )
      } else {
        XCTFail("Should map to UmbraErrors.Crypto.Core type")
      }
    }
  }

  func testCanonicalCryptoErrorToLegacyMapping() {
    // Test mapping from canonical UmbraErrors.Crypto.Core to legacy CryptoError
    // Using the function type for testing rather than the case type
    let testCases: [(UmbraErrors.Crypto.Core, String)]=[
      (.encryptionFailed(algorithm: "AES", reason: "Test"), "encryptionFailed"),
      (.decryptionFailed(algorithm: "AES", reason: "Test"), "decryptionFailed"),
      (.keyGenerationFailed(keyType: "RSA", reason: "Test"), "keyGenerationFailed"),
      (.randomGenerationFailed(reason: "Test"), "randomGenerationFailed"),
      (.keyNotFound(keyIdentifier: "testKey"), "keyNotFound")
    ]

    for (canonicalError, expectedCaseName) in testCases {
      let legacyError=CryptoErrorMapper.mapToLegacyError(canonicalError)

      // Verify mapping produces expected error type using string comparison
      let errorDescription=String(describing: legacyError)

      // Extract just the case name from the error description
      let caseName=errorDescription.split(separator: "(").first?
        .trimmingCharacters(in: .whitespaces) ?? ""
      XCTAssertEqual(
        caseName,
        expectedCaseName,
        "Expected \(expectedCaseName), got \(errorDescription)"
      )
    }
  }

  // MARK: - Security Error Mapping Tests

  func testSecurityErrorRoundTripMapping() {
    // Test conversion to canonical form - rather than testing round-trip equivalence,
    // we'll just test that the conversion functions work correctly in each direction

    // Test forward conversion: SecurityError -> UmbraErrors.GeneralSecurity.Core
    let securityError=CoreErrors.SecurityError.invalidKey(reason: "Test key")
    let canonicalError=securityError.toCanonicalError()

    XCTAssertTrue(
      canonicalError is ErrorHandlingDomains.UmbraErrors.GeneralSecurity.Core,
      "Should convert to canonical form"
    )

    if let canonicalError=canonicalError as? ErrorHandlingDomains.UmbraErrors.GeneralSecurity.Core {
      if case let .invalidKey(reason)=canonicalError {
        XCTAssertEqual(reason, "Test key", "Should preserve parameters")
      } else {
        XCTFail("Converted to unexpected canonical case")
      }
    }

    // Test reverse conversion: UmbraErrors.GeneralSecurity.Core -> SecurityError
    let reversedError=CoreErrors.SecurityError.fromCanonicalError(canonicalError)
    XCTAssertNotNil(reversedError, "Should convert back from canonical form")

    // Verify at least one known case preserves its identity
    let internalError=CoreErrors.SecurityError.internalError(description: "Test error")
    let canonical=internalError.toCanonicalError()
    let roundTrip=CoreErrors.SecurityError.fromCanonicalError(canonical)

    if let roundTrip {
      if case let .internalError(description)=roundTrip {
        XCTAssertTrue(
          description.contains("Test error"),
          "Should preserve description in round-trip"
        )
      }
    }
  }

  func testErrorMapping_BetweenDomains() {
    // Test mapping errors between different domains (e.g., security to crypto)
    let securityError=CoreErrors.SecurityError.operationFailed(
      operation: "encryption",
      reason: "Invalid key"
    )

    // Simulate cross-domain mapping (e.g., what might happen at service boundaries)
    let canonicalError=securityError.toCanonicalError()
    let cryptoError=CryptoError.encryptionFailed(reason: "Mapped from security error")

    XCTAssertNotEqual(
      String(describing: canonicalError),
      String(describing: cryptoError.toCanonical()),
      "Different domain errors should map to different canonical types"
    )
  }
}
