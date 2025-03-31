import Core
import Interfaces
import Logging
import Notification
import Protocols
import Recovery
import UmbraErrorsCore
import XCTest

final class TestErrorHandling_Protocols: XCTestCase {
  // MARK: - Error Protocol Conformance Tests

  func testErrorProtocolConformance() {
    // Test a custom error type conforming to protocols
    let customError=CustomErrorType(code: "CUSTOM001", message: "Custom error message")

    // Verify error properties instead of checking protocol conformance
    // which is enforced by the compiler
    XCTAssertEqual(customError.code, "CUSTOM001")

    // Test conformance to CustomStringConvertible
    XCTAssertEqual(customError.description, "Custom error message")

    // Test conformance to LocalizedError
    XCTAssertEqual(customError.errorDescription, "Custom error message")
    XCTAssertEqual(customError.failureReason, "Custom failure reason")
    XCTAssertEqual(customError.recoverySuggestion, "Custom recovery suggestion")
    XCTAssertEqual(customError.helpAnchor, "custom_help")
  }

  // MARK: - Error Handler Protocol Tests

  @MainActor
  func testErrorHandlerProtocol() {
    // Create a custom error handler
    let handler=CustomErrorHandler()

    // Create a test error
    let error=TestError(
      domain: "TestDomain",
      code: "ERR001",
      description: "Invalid argument"
    )

    // Test handler implementation
    Task {
      // Handle the error
      handler.handle(error, severity: .error)

      // Verify the error was handled
      XCTAssertEqual(handler.handledErrors.count, 1)
      XCTAssertEqual(handler.handledSeverities.first, .error)

      // Test retrieving recovery options
      let options=handler.getRecoveryOptions(for: error)
      XCTAssertEqual(options.count, 2)
      XCTAssertEqual(options[0].title, "Retry")
      XCTAssertEqual(options[1].title, "Cancel")
    }
  }

  // MARK: - Error Context Tests

  func testErrorContextProtocol() {
    // Create a test error context
    let context=TestErrorContext(
      domain: "TestDomain",
      code: 123,
      description: "Test error context"
    )

    // Verify context properties
    XCTAssertEqual(context.domain, "TestDomain")
    XCTAssertEqual(context.code, 123)
    XCTAssertEqual(context.description, "Test error context")
  }

  // MARK: - Error Source Tests

  func testErrorSource() {
    // Create an error source
    let source=ErrorSource(
      file: "TestFile.swift",
      line: 42,
      function: "testFunction()"
    )

    // Verify source properties
    XCTAssertEqual(source.file, "TestFile.swift")
    XCTAssertEqual(source.line, 42)
    XCTAssertEqual(source.function, "testFunction()")
  }
}

// MARK: - Test Helpers

// Custom error type for testing
struct CustomErrorType: UmbraError, LocalizedError {
  let code: String
  let message: String

  var domain: String { "Test" }
  var errorDescription: String { message }
  var failureReason: String { "Custom failure reason" }
  var recoverySuggestion: String { "Custom recovery suggestion" }
  var helpAnchor: String { "custom_help" }
  var source: ErrorSource?
  var underlyingError: Error?
  var context: ErrorContext {
    BaseErrorContext(domain: domain, code: 0, description: message)
  }

  func with(context _: ErrorContext) -> Self { self }
  func with(underlyingError _: Error) -> Self { self }
  func with(source _: ErrorSource) -> Self { self }

  var description: String { message }
}

// Test error context
struct TestErrorContext: ErrorContext {
  let domain: String
  let code: Int
  let description: String
}

// Test error
struct TestError: UmbraError {
  let domain: String
  let code: String
  let description: String

  var errorDescription: String { description }
  var source: ErrorSource?
  var underlyingError: Error?
  var context: ErrorContext {
    BaseErrorContext(domain: domain, code: 0, description: description)
  }

  func with(context _: ErrorContext) -> Self { self }
  func with(underlyingError _: Error) -> Self { self }
  func with(source _: ErrorSource) -> Self { self }
}

// Custom error handler for testing
class CustomErrorHandler: ErrorHandlingService {
  var handledErrors: [Error]=[]
  var handledSeverities: [ErrorSeverity]=[]
  private var logger: ErrorLoggingProtocol?
  private var notifier: ErrorNotificationProtocol?
  private var recoveryProvider: RecoveryOptionsProvider?

  init() {}

  func setLogger(_ logger: ErrorLoggingProtocol) {
    self.logger=logger
  }

  func setNotificationHandler(_ notifier: ErrorNotificationProtocol) {
    self.notifier=notifier
  }

  func registerRecoveryProvider(_ provider: RecoveryOptionsProvider) {
    recoveryProvider=provider
  }

  func handle(
    _ error: some UmbraError,
    severity: ErrorSeverity,
    file _: String,
    function _: String,
    line _: Int
  ) {
    handledErrors.append(error)
    handledSeverities.append(severity)

    // Simulate logging
    logger?.log(error: error, severity: severity)

    // Notify if error is severe enough
    if severity >= .error {
      Task {
        _=await notifier?.notifyUser(
          about: error,
          severity: severity,
          level: severity.toNotificationLevel(),
          recoveryOptions: getRecoveryOptions(for: error)
        )
      }
    }
  }

  func getRecoveryOptions(for _: Error) -> [RecoveryOption] {
    // Return mock recovery options for testing
    [
      TestRecoveryOption(id: UUID(), title: "Retry"),
      TestRecoveryOption(id: UUID(), title: "Cancel")
    ]
  }
}

// Test recovery option
struct TestRecoveryOption: RecoveryOption {
  let id: UUID
  let title: String

  @MainActor
  func perform() async {}
}
