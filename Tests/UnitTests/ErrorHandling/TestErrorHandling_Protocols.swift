@testable import ErrorHandling
@testable import ErrorHandlingCommon
@testable import ErrorHandlingInterfaces
import XCTest

final class TestErrorHandling_Protocols: XCTestCase {
  // MARK: - Error Protocol Conformance Tests

  func testErrorProtocolConformance() {
    // Test a custom error type conforming to protocols
    let customError = CustomErrorType(code: "CUSTOM001", message: "Custom error message")

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
    let handler = CustomErrorHandler()

    // Create a test error
    let error = TestError(
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
      let options = handler.getRecoveryOptions(for: error)

      // Verify recovery options were provided
      XCTAssertEqual(options.count, 2)
      XCTAssertEqual(options[0].title, "Retry")
      XCTAssertEqual(options[1].title, "Cancel")

      // Test error with context
      let context = ErrorHandlingInterfaces.ErrorContext(
        source: "TestSource",
        operation: "testOperation",
        details: nil,
        underlyingError: nil,
        file: #file,
        line: #line,
        function: #function
      )
      let errorWithContext = error.with(context: context)

      XCTAssertEqual(errorWithContext.context.source, "TestSource")
      XCTAssertEqual(errorWithContext.context.operation, "testOperation")
    }
  }

  // MARK: - Error Provider Protocol Tests

  func testErrorProviderProtocol() {
    // Create a custom error provider
    let provider = CustomErrorProvider()

    // Test error creation
    let error = provider.createError(code: "ERR001", message: "Provider error message")

    // Verify the error properties
    XCTAssertEqual(error.code, "ERR001")
    XCTAssertEqual(error.errorDescription, "Provider error message")
    XCTAssertEqual(error.domain, "CustomProvider")

    // Test error with context
    let context = ErrorHandlingInterfaces.ErrorContext(
      source: "TestSource",
      operation: "testOperation",
      details: nil,
      underlyingError: nil,
      file: #file,
      line: #line,
      function: #function
    )
    let errorWithContext = error.with(context: context)

    XCTAssertEqual(errorWithContext.context.source, "TestSource")
    XCTAssertEqual(errorWithContext.context.operation, "testOperation")
  }

  // MARK: - Recovery Options Provider Tests

  func testRecoveryOptionsProviderProtocol() {
    // Create a custom recovery options provider
    let provider = CustomRecoveryProvider()

    // Test domain handling capability
    XCTAssertTrue(provider.canHandle(domain: "TestDomain"))
    XCTAssertFalse(provider.canHandle(domain: "UnsupportedDomain"))

    // Create a test error
    let error = TestError(domain: "TestDomain", code: "TEST001", description: "Test error")

    // Test recovery options retrieval
    let options = provider.recoveryOptions(for: error)

    // Verify recovery options
    XCTAssertEqual(options.count, 2)
    XCTAssertEqual(options[0].title, "Retry Operation")
    XCTAssertEqual(options[1].title, "Cancel Operation")
  }

  // MARK: - Test Implementations

  struct CustomErrorType: Error, CustomStringConvertible, LocalizedError {
    let code: String
    let message: String

    var description: String {
      message
    }

    var errorDescription: String? {
      message
    }

    var failureReason: String? {
      "Custom failure reason"
    }

    var recoverySuggestion: String? {
      "Custom recovery suggestion"
    }

    var helpAnchor: String? {
      "custom_help"
    }
  }

  @MainActor
  class CustomErrorHandler: ErrorHandlingService {
    var handledErrors: [Error] = []
    var handledSeverities: [ErrorHandlingInterfaces.ErrorSeverity] = []
    private var logger: ErrorLoggingProtocol?
    private var notifier: ErrorNotificationProtocol?
    private var recoveryProviders: [RecoveryOptionsProvider] = []

    func handle(
      _ error: some UmbraError,
      severity: ErrorHandlingInterfaces.ErrorSeverity,
      file _: String = #file,
      function _: String = #function,
      line _: Int = #line
    ) {
      handledErrors.append(error)
      handledSeverities.append(severity)

      // Log the error if a logger is set
      logger?.log(error: error, severity: severity)

      // Present the error if a notifier is set
      if let notifier {
        let options = getRecoveryOptions(for: error)
        notifier.presentError(error, recoveryOptions: options)
      }
    }

    func getRecoveryOptions(for _: some UmbraError) -> [any RecoveryOption] {
      [
        TestRecoveryOption(title: "Retry"),
        TestRecoveryOption(title: "Cancel")
      ]
    }

    func setLogger(_ logger: ErrorLoggingProtocol) {
      self.logger = logger
    }

    func setNotificationHandler(_ handler: ErrorNotificationProtocol) {
      notifier = handler
    }

    func registerRecoveryProvider(_ provider: RecoveryOptionsProvider) {
      recoveryProviders.append(provider)
    }
  }

  final class CustomErrorProvider {
    func createError(code: String, message: String) -> some UmbraError {
      ProviderError(code: code, message: message)
    }

    struct ProviderError: UmbraError, CustomStringConvertible {
      let domain: String = "CustomProvider"
      let code: String
      let errorDescription: String
      var source: ErrorHandlingInterfaces.ErrorSource?
      var underlyingError: Error?
      var context: ErrorHandlingInterfaces.ErrorContext

      init(code: String, message: String) {
        self.code = code
        errorDescription = message
        source = nil
        underlyingError = nil
        context = ErrorHandlingInterfaces.ErrorContext(
          source: "CustomProvider",
          operation: "createError",
          details: nil,
          underlyingError: nil,
          file: #file,
          line: #line,
          function: #function
        )
      }

      func with(context: ErrorHandlingInterfaces.ErrorContext) -> Self {
        var copy = self
        copy.context = context
        return copy
      }

      func with(underlyingError: Error) -> Self {
        var copy = self
        copy.underlyingError = underlyingError
        return copy
      }

      func with(source: ErrorHandlingInterfaces.ErrorSource) -> Self {
        var copy = self
        copy.source = source
        return copy
      }

      var description: String {
        errorDescription
      }
    }
  }

  final class CustomRecoveryProvider: RecoveryOptionsProvider {
    func canHandle(domain: String) -> Bool {
      domain == "TestDomain"
    }

    func recoveryOptions(for _: some Error) -> [any ErrorHandlingInterfaces.RecoveryOption] {
      [
        TestRecoveryOption(title: "Retry Operation"),
        TestRecoveryOption(title: "Cancel Operation")
      ]
    }
  }

  struct TestError: UmbraError {
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
      source: ErrorHandlingInterfaces.ErrorSource? = nil,
      underlyingError: Error? = nil
    ) {
      self.domain = domain
      self.code = code
      errorDescription = description
      self.source = source
      self.underlyingError = underlyingError
      context = ErrorHandlingInterfaces.ErrorContext(source: domain, operation: "testOperation")
    }

    func with(context: ErrorHandlingInterfaces.ErrorContext) -> Self {
      var copy = self
      copy.context = context
      return copy
    }

    func with(underlyingError: Error) -> Self {
      var copy = self
      copy.underlyingError = underlyingError
      return copy
    }

    func with(source: ErrorHandlingInterfaces.ErrorSource) -> Self {
      var copy = self
      copy.source = source
      return copy
    }

    var description: String {
      errorDescription
    }
  }

  struct TestRecoveryOption: RecoveryOption {
    var id: UUID = .init()
    var title: String
    var description: String?
    var isDisruptive: Bool = false

    init(title: String, description: String? = nil, isDisruptive: Bool = false) {
      self.title = title
      self.description = description
      self.isDisruptive = isDisruptive
    }

    func perform() async {
      // This is a test recovery option that does nothing
    }
  }
}
