@testable import ErrorHandling
@testable import ErrorHandlingCommon
@testable import ErrorHandlingProtocols
@testable import ErrorHandlingRecovery
import Foundation
import XCTest

/**
 * Tests for the ErrorLoggingProtocol implementation
 *
 * These tests verify the error logging protocol and recovery option handling.
 */
final class ErrorLoggingProtocolTests: XCTestCase {
  // Mock implementation of ErrorLoggingProtocol for testing
  class MockErrorLogger: ErrorLoggingProtocol {
    var loggedErrors: [Error]=[]
    var loggedInfo: [String]=[]
    var loggedWarnings: [String]=[]
    var loggedWithSeverity: [(error: Error, severity: ErrorSeverity)]=[]
    var recoveryActions: [String: ErrorHandlingRecovery.RecoveryAction]=[:]

    // Required method from ErrorLoggingProtocol
    func log(error: some UmbraError, severity: ErrorSeverity) {
      loggedErrors.append(error)
      loggedWithSeverity.append((error, severity))
    }

    // Additional logging methods for testing
    func logError(_ error: Error, file _: String, function _: String, line _: Int) {
      loggedErrors.append(error)
    }

    func logInfo(_ message: String, file _: String, function _: String, line _: Int) {
      loggedInfo.append(message)
    }

    func logWarning(_ message: String, file _: String, function _: String, line _: Int) {
      loggedWarnings.append(message)
    }

    // Recovery option registration and retrieval
    func registerRecoveryOption(
      forErrorCode code: String,
      option: ErrorHandlingRecovery.RecoveryAction
    ) {
      recoveryActions[code]=option
    }

    func getRecoveryOption(forError error: Error) -> ErrorHandlingRecovery.RecoveryAction? {
      guard let umbraError=error as? UmbraError else { return nil }
      return recoveryActions[umbraError.code]
    }
  }

  // Test error type
  struct TestLoggingError: UmbraError, DomainError {
    static var domain: String { "TestLogging" }
    let code: String
    let errorDescription: String
    var underlyingError: Error?
    var source: ErrorHandlingCommon.ErrorSource?

    func with(context _: ErrorHandlingCommon.ErrorContext) -> Self { self }
    func with(underlyingError _: Error) -> Self { self }
    func with(source _: ErrorHandlingCommon.ErrorSource) -> Self { self }
  }

  private var errorLogger: MockErrorLogger!

  override func setUp() {
    super.setUp()
    errorLogger=MockErrorLogger()
  }

  /**
   * Test basic error logging functionality
   */
  func testErrorLogging() {
    // Given
    let error=TestLoggingError(code: "L001", errorDescription: "Test logging error")

    // When
    errorLogger.logError(error, file: "TestFile.swift", function: "testFunction", line: 42)

    // Then
    XCTAssertEqual(errorLogger.loggedErrors.count, 1, "Should have logged one error")
    XCTAssertTrue(
      errorLogger.loggedErrors[0] is TestLoggingError,
      "Logged error should be TestLoggingError"
    )

    // Verify the logged error properties
    if let loggedError=errorLogger.loggedErrors[0] as? TestLoggingError {
      XCTAssertEqual(loggedError.code, "L001", "Error code should match")
      XCTAssertEqual(
        loggedError.errorDescription,
        "Test logging error",
        "Error description should match"
      )
    }
  }

  /**
   * Test error logging with severity
   */
  func testErrorLoggingWithSeverity() {
    // Given
    let error=TestLoggingError(code: "L002", errorDescription: "Critical error")

    // When
    errorLogger.log(error: error, severity: .critical)

    // Then
    XCTAssertEqual(
      errorLogger.loggedWithSeverity.count,
      1,
      "Should have logged one error with severity"
    )
    XCTAssertEqual(
      errorLogger.loggedWithSeverity[0].severity,
      .critical,
      "Severity should be critical"
    )

    if let loggedError=errorLogger.loggedWithSeverity[0].error as? TestLoggingError {
      XCTAssertEqual(loggedError.code, "L002", "Error code should match")
    }
  }

  /**
   * Test info logging functionality
   */
  func testInfoLogging() {
    // When
    errorLogger.logInfo(
      "Test info message",
      file: "TestFile.swift",
      function: "testFunction",
      line: 42
    )

    // Then
    XCTAssertEqual(errorLogger.loggedInfo.count, 1, "Should have logged one info message")
    XCTAssertEqual(errorLogger.loggedInfo[0], "Test info message", "Info message should match")
  }

  /**
   * Test warning logging functionality
   */
  func testWarningLogging() {
    // When
    errorLogger.logWarning(
      "Test warning message",
      file: "TestFile.swift",
      function: "testFunction",
      line: 42
    )

    // Then
    XCTAssertEqual(errorLogger.loggedWarnings.count, 1, "Should have logged one warning message")
    XCTAssertEqual(
      errorLogger.loggedWarnings[0],
      "Test warning message",
      "Warning message should match"
    )
  }

  /**
   * Test recovery option registration and retrieval
   */
  func testRecoveryOptions() {
    // Given
    let errorCode="R001"
    let error=TestLoggingError(code: errorCode, errorDescription: "Recoverable error")

    // Create a RecoveryAction (concrete implementation of RecoveryOption)
    let recoveryAction=ErrorHandlingRecovery.RecoveryAction(
      id: "retry_connection",
      title: "Retry Connection",
      description: "Attempt to reconnect to the server",
      isDefault: true,
      handler: { /* Simple handler that always succeeds */ }
    )

    // When - Register recovery option
    errorLogger.registerRecoveryOption(forErrorCode: errorCode, option: recoveryAction)

    // Then - Verify we can retrieve it
    let retrievedOption=errorLogger.getRecoveryOption(forError: error)
    XCTAssertNotNil(retrievedOption, "Should retrieve a recovery option for this error")

    // Verify the recovery option properties
    XCTAssertEqual(retrievedOption?.title, "Retry Connection", "Title should match")
    XCTAssertEqual(
      retrievedOption?.description,
      "Attempt to reconnect to the server",
      "Description should match"
    )
    XCTAssertEqual(retrievedOption?.id, "retry_connection", "ID should match")
    XCTAssertTrue(retrievedOption?.isDefault ?? false, "Should be set as default")
  }

  /**
   * Test recovery option for non-registered error
   */
  func testRecoveryOptionForNonRegisteredError() {
    // Given
    let error=TestLoggingError(code: "UNKNOWN", errorDescription: "Unknown error")

    // When/Then
    let retrievedOption=errorLogger.getRecoveryOption(forError: error)
    XCTAssertNil(retrievedOption, "Should not retrieve a recovery option for non-registered error")
  }

  /**
   * Test recovery option for non-UmbraError type
   */
  func testRecoveryOptionForNonUmbraError() {
    // Given
    let nonUmbraError=NSError(domain: "Test", code: 100, userInfo: nil)

    // When/Then
    let retrievedOption=errorLogger.getRecoveryOption(forError: nonUmbraError)
    XCTAssertNil(retrievedOption, "Should not retrieve a recovery option for non-UmbraError")
  }

  /**
   * Test error logger with multiple recovery options
   */
  func testMultipleRecoveryOptions() {
    // Given
    let errorCodes=["NETWORK", "DISK", "PERMISSION"]
    let options=[
      ErrorHandlingRecovery.RecoveryAction(
        id: "retry_network",
        title: "Retry Network",
        description: "Retry network connection",
        handler: {}
      ),
      ErrorHandlingRecovery.RecoveryAction(
        id: "check_disk",
        title: "Check Disk",
        description: "Verify disk space",
        handler: {}
      ),
      ErrorHandlingRecovery.RecoveryAction(
        id: "request_permission",
        title: "Request Permission",
        description: "Ask for permission",
        handler: {}
      )
    ]

    // When - Register all options
    for (index, code) in errorCodes.enumerated() {
      errorLogger.registerRecoveryOption(forErrorCode: code, option: options[index])
    }

    // Then - Verify we can retrieve them individually
    for (index, code) in errorCodes.enumerated() {
      let error=TestLoggingError(code: code, errorDescription: "Test error")
      let retrievedOption=errorLogger.getRecoveryOption(forError: error)

      XCTAssertNotNil(retrievedOption, "Should retrieve recovery option for \(code)")
      XCTAssertEqual(
        retrievedOption?.title,
        options[index].title,
        "Title should match for \(code)"
      )
    }
  }
}
