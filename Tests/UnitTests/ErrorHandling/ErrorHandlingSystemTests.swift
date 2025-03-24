@testable import ErrorHandling
@testable import ErrorHandlingCore
@testable import ErrorHandlingDomains
@testable import ErrorHandlingLogging
@testable import ErrorHandlingMapping
@testable import ErrorHandlingModels
@testable import ErrorHandlingNotification
@testable import ErrorHandlingProtocols
@testable import ErrorHandlingRecovery
@testable import ErrorHandlingUtilities
import Foundation
import XCTest

final class ErrorHandlingSystemTests: XCTestCase {
  // MARK: - Test Mocks

  private enum RecoveryOption: ErrorHandlingProtocols.RecoveryOption {
    case retry
    case cancel

    var title: String {
      switch self {
        case .retry: "Retry"
        case .cancel: "Cancel"
      }
    }

    func perform() async {
      // No-op for testing
    }
  }

  private class MockNotificationHandler: ErrorNotificationHandler {
    var presentedNotifications: [ErrorNotification]=[]
    var dismissedIDs: [UUID]=[]
    var dismissedAll=false

    func present(notification: ErrorNotification) {
      presentedNotifications.append(notification)
    }

    func dismiss(notificationWithID id: UUID) {
      dismissedIDs.append(id)
    }

    func dismissAll() {
      dismissedAll=true
    }
  }

  private class MockRecoveryProvider: RecoveryOptionsProvider {
    var shouldProvideOptions=true
    var optionsToReturn: [ErrorHandlingProtocols.RecoveryOption]=[
      RecoveryOption.retry,
      RecoveryOption.cancel
    ]

    func recoveryOptions(for _: Error) async -> [ErrorHandlingProtocols.RecoveryOption] {
      if shouldProvideOptions {
        optionsToReturn
      } else {
        []
      }
    }
  }

  private class MockLogger: ErrorLoggingService {
    var loggedErrors: [(error: Error, level: ErrorSeverity)]=[]

    func log(_ error: Error, withSeverity severity: ErrorSeverity) {
      loggedErrors.append((error, severity))
    }

    func configure(destinations _: [LogDestination]) {
      // No-op for testing
    }
  }

  // MARK: - Test Properties

  private var errorHandler: ErrorHandler!
  private var mockNotificationHandler: MockNotificationHandler!
  private var mockRecoveryProvider: MockRecoveryProvider!
  private var mockLogger: MockLogger!

  // MARK: - Setup & Teardown

  override func setUp() {
    super.setUp()

    // Create a fresh ErrorHandler instance for each test
    ErrorHandler.resetSharedInstance()
    errorHandler=ErrorHandler.shared

    // Set up mocks
    mockNotificationHandler=MockNotificationHandler()
    mockRecoveryProvider=MockRecoveryProvider()
    mockLogger=MockLogger()

    // Configure the error handler with mocks
    errorHandler.setNotificationHandler(mockNotificationHandler)
    errorHandler.registerRecoveryProvider(mockRecoveryProvider)
    errorHandler.setLogger(mockLogger)
  }

  override func tearDown() {
    errorHandler=nil
    mockNotificationHandler=nil
    mockRecoveryProvider=nil
    mockLogger=nil

    super.tearDown()
  }

  // MARK: - Tests

  func testBasicErrorHandling() {
    // Given
    let error=SecurityError.authenticationFailed("Invalid credentials")

    // When
    errorHandler.handle(error, severity: .high)

    // Then
    XCTAssertEqual(mockLogger.loggedErrors.count, 1)
    XCTAssertEqual(mockLogger.loggedErrors[0].level, .high)

    XCTAssertEqual(mockNotificationHandler.presentedNotifications.count, 1)
    let notification=mockNotificationHandler.presentedNotifications[0]
    XCTAssertEqual(notification.severity, .high)
    XCTAssertTrue(notification.message.contains("Invalid credentials"))
  }

  func testErrorWithRecoveryOptions() {
    // Given
    let error=SecurityError.authenticationFailed("Invalid credentials")
    let recoveryOptions: [RecoveryOption]=[.retry, .cancel]
    mockRecoveryProvider.optionsToReturn=recoveryOptions

    // When
    errorHandler.handle(error, severity: .high)

    // Then
    XCTAssertEqual(mockRecoveryProvider.requestedErrors.count, 1)
    XCTAssertEqual(mockNotificationHandler.presentedNotifications.count, 1)

    let notification=mockNotificationHandler.presentedNotifications[0]
    XCTAssertNotNil(notification.recoveryOptions)
    XCTAssertEqual(notification.recoveryOptions?.count, 2)
  }

  func testErrorMapping() {
    // Given
    let externalError=NSError(
      domain: "UmbraErrors.Security.Protocols",
      code: 401,
      userInfo: [NSLocalizedDescriptionKey: "Authentication failed: Token expired"]
    )

    // When
    let securityErrorMapper=LegacySecurityErrorMapper()
    let mappedError=securityErrorMapper.mapFromAny(externalError)

    // Then
    XCTAssertNotNil(mappedError)
    if let mappedError {
      XCTAssertTrue(mappedError is SecurityError)

      // Verify the error is handled properly
      errorHandler.handle(mappedError, severity: .medium)

      XCTAssertEqual(mockLogger.loggedErrors.count, 1)
      XCTAssertEqual(mockNotificationHandler.presentedNotifications.count, 1)
    }
  }

  func testGenericUmbraErrorCreation() {
    // Given
    let error=GenericUmbraError(
      domain: "TestDomain",
      code: "test_error",
      description: "Test error description",
      context: ErrorContext(
        source: ErrorSource(
          file: #file,
          function: #function,
          line: #line
        ),
        metadata: ["key": "value"]
      )
    )

    // Then
    XCTAssertEqual(error.errorDomain, "TestDomain")
    XCTAssertEqual(error.errorCode, "test_error")
    XCTAssertEqual(error.errorDescription, "Test error description")
    XCTAssertNotNil(error.errorContext)
    XCTAssertEqual(error.errorContext?.metadata["key"] as? String, "value")
  }

  func testSecurityErrorHandlerWithMixedErrors() async {
    // Given
    let securityHandler=SecurityErrorHandler.shared
    securityHandler.errorHandler=errorHandler

    // When - Handle our direct SecurityError
    let ourError=SecurityError.permissionDenied("Insufficient privileges")
    await securityHandler.handleSecurityError(ourError)

    // Then
    XCTAssertEqual(mockLogger.loggedErrors.count, 1)
    XCTAssertEqual(mockNotificationHandler.presentedNotifications.count, 1)

    // When - Handle external error
    mockLogger.loggedErrors=[]
    mockNotificationHandler.presentedNotifications=[]

    let externalError=NSError(
      domain: "SecurityTypes.SecurityError",
      code: 403,
      userInfo: [NSLocalizedDescriptionKey: "Authorization failed: Access denied to resource"]
    )
    await securityHandler.handleSecurityError(externalError)

    // Then
    XCTAssertEqual(mockLogger.loggedErrors.count, 1)
    XCTAssertEqual(mockNotificationHandler.presentedNotifications.count, 1)
  }
}

// Extensions to support testing
extension ErrorHandler {
  static func resetSharedInstance() {
    // This is a testing utility to reset the shared instance
    _shared=ErrorHandler()
  }

  func setLogger(_ logger: ErrorLoggingService) {
    self.logger=logger
  }
}
