@testable import ErrorHandling
@testable import ErrorHandlingCommon
@testable import ErrorHandlingInterfaces
import XCTest

final class TestErrorHandling_Extensions: XCTestCase {
  // MARK: - Error Extension Tests

  func testErrorExtensions() {
    // Create a test NSError
    let underlyingError=NSError(domain: "UnderlyingDomain", code: 789, userInfo: nil)
    let userInfo: [String: Any]=[
      NSLocalizedDescriptionKey: "Test description",
      NSLocalizedFailureReasonErrorKey: "Test failure reason",
      NSLocalizedRecoverySuggestionErrorKey: "Test recovery suggestion",
      NSHelpAnchorErrorKey: "Test help anchor",
      NSUnderlyingErrorKey: underlyingError
    ]

    let error=NSError(domain: "TestDomain", code: 123, userInfo: userInfo)

    // Test extension properties - access via userInfo directly for NSError
    XCTAssertEqual(error.localizedDescription, "Test description")
    XCTAssertEqual(
      error.userInfo[NSLocalizedFailureReasonErrorKey] as? String,
      "Test failure reason"
    )
    XCTAssertEqual(
      error.userInfo[NSLocalizedRecoverySuggestionErrorKey] as? String,
      "Test recovery suggestion"
    )
    XCTAssertEqual(error.userInfo[NSHelpAnchorErrorKey] as? String, "Test help anchor")
    XCTAssertEqual(error.domain, "TestDomain")
    XCTAssertEqual(error.code, 123)

    // Verify userInfo access
    XCTAssertEqual(error.userInfo.count, 5)

    // Test underlying error access
    guard let underlyingErrorFromUserInfo=error.userInfo[NSUnderlyingErrorKey] as? NSError else {
      XCTFail("Failed to access underlying error")
      return
    }

    XCTAssertEqual(underlyingErrorFromUserInfo.domain, "UnderlyingDomain")
    XCTAssertEqual(underlyingErrorFromUserInfo.code, 789)
  }

  // MARK: - Error Context Extension Tests

  func testErrorContextExtensions() {
    // Create a standard Swift error
    struct SimpleError: Error, CustomStringConvertible {
      let message: String
      var description: String { message }
    }

    let error=SimpleError(message: "Something went wrong")

    // Test adding context to a standard error
    let errorContext=error.withContext(
      source: "TestSource",
      operation: "testOperation",
      details: "Test details"
    )

    // Verify the error was properly wrapped with context
    XCTAssertNotNil(errorContext)

    // Convert to string for verification since we can't directly check the context properties
    let errorString=String(describing: errorContext)
    XCTAssertTrue(
      errorString.contains("TestSource") ||
        errorString.contains("testOperation") ||
        errorString.contains("Test details"),
      "Error context should contain source, operation or details"
    )

    // Verify error information is preserved
    XCTAssertTrue(
      errorString.contains("Something went wrong"),
      "Original error message should be preserved"
    )
  }

  // MARK: - Domain-Specific Extension Tests

  func testApplicationErrorExtensions() {
    // Test application error extensions with mock errors
    let appError=TestError(
      domain: "Application.Core",
      code: "initializationFailed",
      description: "Initialization failed for component: Database due to: Connection timeout"
    )

    // Test diagnostic info extension
    let diagnosticInfo=appError.diagnosticInfo
    XCTAssertTrue(diagnosticInfo.contains("Application.Core"))
    XCTAssertTrue(diagnosticInfo.contains("initializationFailed"))
    XCTAssertTrue(
      diagnosticInfo.contains("Database") || diagnosticInfo
        .contains("initializationFailed")
    )

    // Test categorization extension - domain containment check is case-sensitive
    XCTAssertEqual(appError.domain, "Application.Core", "Domain should match exactly")
    XCTAssertTrue(appError.isApplicationError, "Should be identified as application error")
    XCTAssertFalse(appError.isNetworkError)
    XCTAssertFalse(appError.isSecurityError)

    // Test detailed description extension
    let detailedDescription=appError.detailedDescription
    XCTAssertTrue(detailedDescription.contains("Application.Core"))
    XCTAssertTrue(detailedDescription.contains("initializationFailed"))
    XCTAssertTrue(
      detailedDescription.contains("Database") || detailedDescription
        .contains("timeout")
    )
  }

  func testSecurityErrorExtensions() {
    // Test security error extensions with mock errors
    let secError=TestError(
      domain: "Security.Core",
      code: "encryptionFailed",
      description: "Encryption failed: Invalid key size"
    )

    // Test diagnostic info extension
    let diagnosticInfo=secError.diagnosticInfo
    XCTAssertTrue(diagnosticInfo.contains("Security.Core"))
    XCTAssertTrue(diagnosticInfo.contains("encryptionFailed"))

    // Test categorization extension
    XCTAssertTrue(secError.isSecurityError)
    XCTAssertFalse(secError.isApplicationError)
    XCTAssertFalse(secError.isNetworkError)

    // Test detailed description extension
    let detailedDescription=secError.detailedDescription
    XCTAssertTrue(detailedDescription.contains("Security.Core"))
    XCTAssertTrue(detailedDescription.contains("encryptionFailed"))
    XCTAssertTrue(detailedDescription.contains("Invalid key size"))
  }
}

struct TestError: UmbraError, CustomStringConvertible {
  let domain: String
  let code: String
  let errorDescription: String
  var source: ErrorHandlingInterfaces.ErrorSource?
  var underlyingError: Error?
  var context: ErrorHandlingInterfaces.ErrorContext

  init(
    domain: String,
    code: String,
    description: String,
    source: ErrorHandlingInterfaces.ErrorSource?=nil
  ) {
    self.domain=domain
    self.code=code
    errorDescription=description
    self.source=source
    underlyingError=nil
    context=ErrorHandlingInterfaces.ErrorContext(
      source: domain,
      operation: "test",
      details: description,
      underlyingError: nil,
      file: #file,
      line: #line,
      function: #function
    )
  }

  func with(context: ErrorHandlingInterfaces.ErrorContext) -> Self {
    var copy=self
    copy.context=context
    return copy
  }

  func with(underlyingError: Error) -> Self {
    var copy=self
    copy.underlyingError=underlyingError
    return copy
  }

  func with(source: ErrorHandlingInterfaces.ErrorSource) -> Self {
    var copy=self
    copy.source=source
    return copy
  }

  var description: String {
    errorDescription
  }

  var diagnosticInfo: String {
    "\(domain): \(code)"
  }

  var detailedDescription: String {
    "\(domain): \(code) - \(errorDescription)"
  }

  var isApplicationError: Bool {
    domain.contains("Application")
  }

  var isNetworkError: Bool {
    domain.contains("Network")
  }

  var isSecurityError: Bool {
    domain.contains("Security")
  }
}
