@testable import ErrorHandling
@testable import ErrorHandlingCommon
@testable import ErrorHandlingCore
@testable import ErrorHandlingInterfaces
import XCTest

final class TestErrorHandling_Core: XCTestCase {
  // MARK: - Error Handler Tests

  func testErrorHandler() {
    // Create a test error handler
    let handler=MockErrorHandler()

    // Create a mock logger to verify logging behavior
    let mockLogger=MockErrorLogger()
    handler.registerLogger(mockLogger)

    // Create a test error
    let error=TestError(
      domain: "TestDomain",
      code: "TEST001",
      description: "Test error description"
    )

    // Test error handling
    Task {
      await handler.handle(
        error,
        severity: ErrorHandlingInterfaces.ErrorSeverity.error,
        file: "TestFile.swift",
        function: "testFunction()",
        line: 42
      )

      // Verify the error was logged
      XCTAssertEqual(mockLogger.loggedErrors.count, 1)
      XCTAssertEqual(mockLogger.loggedSeverities.first, .error)

      // Verify with other severity levels
      await handler.handle(
        error,
        severity: .warning,
        file: "TestFile.swift",
        function: "testFunction()",
        line: 42
      )

      XCTAssertEqual(mockLogger.loggedErrors.count, 2)
      XCTAssertEqual(mockLogger.loggedSeverities[1], .warning)
    }
  }

  // MARK: - Recovery Provider Tests

  @MainActor
  func testRecoveryProvider() {
    // Create a test error handler
    let handler=MockErrorHandler()

    // Create a mock recovery provider
    let mockProvider=MockRecoveryProvider()
    handler.registerRecoveryProvider(mockProvider)

    // Create a test error
    let error=TestError(
      domain: "TestDomain",
      code: "TEST001",
      description: "Test error description"
    )

    // Test recovery options retrieval
    Task {
      let options=await handler.getRecoveryOptions(for: error)

      // Verify recovery options were provided
      XCTAssertEqual(options.count, 2)
      XCTAssertEqual(options[0].title, "Option 1")
      XCTAssertEqual(options[1].title, "Option 2")

      // Verify domain handling logic
      XCTAssertTrue(mockProvider.canHandleCalledWithDomains.contains("TestDomain"))
    }
  }

  // MARK: - Notification Tests

  func testNotification() {
    // Create a test error handler
    let handler=MockErrorHandler()

    // Create a mock notification handler
    let mockNotifier=MockErrorNotifier()
    handler.registerNotifier(mockNotifier)

    // Create a test error
    let error=TestError(
      domain: "TestDomain",
      code: "TEST001",
      description: "Test error description"
    )

    // Create mock recovery options
    let options=[
      TestRecoveryOption(title: "Retry"),
      TestRecoveryOption(title: "Cancel")
    ]

    // Test error presentation
    Task {
      await handler.presentError(error, recoveryOptions: options)

      // Verify the error was presented
      XCTAssertEqual(mockNotifier.presentedErrors.count, 1)
      XCTAssertEqual(mockNotifier.presentedOptions.count, 1)
      XCTAssertEqual(mockNotifier.presentedOptions[0].count, 2)
      XCTAssertEqual((mockNotifier.presentedOptions[0][0] as? TestRecoveryOption)?.title, "Retry")
      XCTAssertEqual((mockNotifier.presentedOptions[0][1] as? TestRecoveryOption)?.title, "Cancel")
    }
  }

  // MARK: - Test Implementations

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
      source: ErrorHandlingInterfaces.ErrorSource?=nil,
      underlyingError: Error?=nil
    ) {
      self.domain=domain
      self.code=code
      errorDescription=description
      self.source=source
      self.underlyingError=underlyingError
      context=ErrorHandlingInterfaces.ErrorContext(source: domain, operation: "testOperation")
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
  }

  class MockErrorLogger: ErrorLoggingProtocol {
    var loggedErrors: [Error]=[]
    var loggedSeverities: [ErrorHandlingInterfaces.ErrorSeverity]=[]

    func log(error: some UmbraError, severity: ErrorHandlingInterfaces.ErrorSeverity) {
      loggedErrors.append(error)
      loggedSeverities.append(severity)
    }
  }

  @MainActor
  final class MockRecoveryProvider: RecoveryOptionsProvider {
    var canHandleCalledWithDomains: [String]=[]

    func canHandle(domain: String) -> Bool {
      canHandleCalledWithDomains.append(domain)
      return true
    }

    nonisolated func recoveryOptions(for _: some Error) -> [any RecoveryOption] {
      [
        TestRecoveryOption(title: "Option 1"),
        TestRecoveryOption(title: "Option 2")
      ]
    }
  }

  class MockErrorNotifier: ErrorNotificationProtocol {
    var presentedErrors: [Error]=[]
    var presentedOptions: [[any RecoveryOption]]=[]

    func presentError(_ error: some UmbraError, recoveryOptions: [any RecoveryOption]) {
      presentedErrors.append(error)
      presentedOptions.append(recoveryOptions)
    }
  }

  struct TestRecoveryOption: RecoveryOption {
    var id: UUID = .init()
    var title: String
    var description: String?
    var isDisruptive: Bool=false

    init(title: String, description: String?=nil, isDisruptive: Bool=false) {
      self.title=title
      self.description=description
      self.isDisruptive=isDisruptive
    }

    func perform() async {
      // This is a test recovery option that does nothing
    }
  }

  class MockErrorHandler {
    var logger: MockErrorLogger?
    var recoveryProvider: MockRecoveryProvider?
    var notifier: MockErrorNotifier?
    var handledErrors: [Error]=[]

    func registerLogger(_ logger: MockErrorLogger) {
      self.logger=logger
    }

    func registerRecoveryProvider(_ provider: MockRecoveryProvider) {
      recoveryProvider=provider
    }

    func registerNotifier(_ notifier: MockErrorNotifier) {
      self.notifier=notifier
    }

    func handle(
      _ error: Error,
      severity: ErrorHandlingInterfaces.ErrorSeverity,
      file _: String,
      function _: String,
      line _: Int
    ) async {
      handledErrors.append(error)
      if let umbraError=error as? (any UmbraError) {
        logger?.log(error: umbraError, severity: severity)
      }
    }

    func getRecoveryOptions(for error: Error) async -> [any RecoveryOption] {
      recoveryProvider?.recoveryOptions(for: error) ?? []
    }

    func presentError(_ error: Error, recoveryOptions: [any RecoveryOption]) async {
      if let umbraError=error as? (any UmbraError) {
        notifier?.presentError(umbraError, recoveryOptions: recoveryOptions)
      }
    }
  }
}
