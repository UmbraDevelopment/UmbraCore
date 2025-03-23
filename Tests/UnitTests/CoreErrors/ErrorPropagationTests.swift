@testable import CoreErrors
import ErrorHandling
import ErrorHandlingDomains
import XCTest

final class ErrorPropagationTests: XCTestCase {
  // MARK: - Error Propagation Across Boundaries Tests

  func testErrorPreservesInformationAcrossBoundaries() {
    // This test verifies that crucial error information is preserved
    // when errors cross module boundaries

    // Create original error
    let originalError=CryptoError.invalidKeyLength(expected: 32, got: 16)

    // Convert to canonical form (as would happen at module boundary)
    let canonicalError=originalError.toCanonical()

    // Simulate passing through a boundary by type erasure and recovery
    let anyError=canonicalError as Any

    // Different module recovers the error
    if
      let recoveredError=anyError as? UmbraErrors.Crypto.Core,
      case let .invalidParameters(_, parameter, reason)=recoveredError
    {
      // Verify essential information was preserved
      XCTAssertEqual(parameter, "keyLength", "Parameter name should be preserved")
      XCTAssertTrue(
        reason.contains("32") && reason.contains("16"),
        "Error should preserve expected and actual values"
      )
    } else {
      XCTFail("Error information was lost during boundary crossing")
    }
  }

  func testErrorsCanBeConvertedToUniformFormat() {
    // Test that errors from different domains can be normalised
    // into a consistent format for uniform error handling

    // Create errors from different domains
    let cryptoError=CryptoError.encryptionFailed(reason: "Bad key")
    let securityError=CoreErrors.SecurityError.invalidKey(reason: "Malformed key")

    // Convert both to canonical formats
    let canonicalCryptoError=cryptoError.toCanonical()
    let canonicalSecurityError=securityError.toCanonicalError()

    // Verify we can extract consistent information regardless of source
    func extractErrorInfo(_ error: Any) -> (domain: String, message: String)? {
      if let error=error as? UmbraErrors.Crypto.Core {
        return ("Crypto", String(describing: error))
      } else if let error=error as? ErrorHandlingDomains.UmbraErrors.GeneralSecurity.Core {
        return ("Security", String(describing: error))
      }
      return nil
    }

    let cryptoInfo=extractErrorInfo(canonicalCryptoError)
    let securityInfo=extractErrorInfo(canonicalSecurityError)

    XCTAssertNotNil(cryptoInfo, "Should extract information from crypto error")
    XCTAssertNotNil(securityInfo, "Should extract information from security error")
    XCTAssertEqual(cryptoInfo?.domain, "Crypto", "Should identify crypto domain")
    XCTAssertEqual(securityInfo?.domain, "Security", "Should identify security domain")
  }

  func testErrorLocalisation() {
    // Test that errors maintain proper localisation across boundaries

    // Create an error with a specific message
    let originalError=CryptoError.invalidKeyLength(expected: 32, got: 16)

    // Verify the error is properly localised
    XCTAssertNotNil(originalError.errorDescription, "Error should have localised description")
    XCTAssertTrue(
      originalError.errorDescription?.contains("32") ?? false,
      "Localised description should contain the expected value"
    )
    XCTAssertTrue(
      originalError.errorDescription?.contains("16") ?? false,
      "Localised description should contain the actual value"
    )

    // Convert to canonical form and check localisation is maintained
    let canonicalError=originalError.toCanonical()

    if
      let canonicalError=canonicalError as? UmbraErrors.Crypto.Core,
      case let .invalidParameters(_, _, reason)=canonicalError
    {
      XCTAssertTrue(
        reason.contains("32") && reason.contains("16"),
        "Canonical error should maintain numerical parameters"
      )
    } else {
      XCTFail("Failed to convert error to canonical form correctly")
    }
  }
}
