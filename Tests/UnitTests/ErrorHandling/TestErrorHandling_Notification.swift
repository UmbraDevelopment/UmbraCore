@testable import ErrorHandling
@testable import ErrorHandlingCommon
@testable import ErrorHandlingCore
@testable import ErrorHandlingInterfaces
import XCTest

final class TestErrorHandling_Notification: XCTestCase {
  // MARK: - Error Notification Centre Tests

  func testErrorNotificationCentre() {
    // Create an error notification centre
    let notificationCentre=TestErrorNotificationCentre()

    // Create a test error with context
    let error=TestError(
      domain: "TestDomain",
      code: "TEST001",
      description: "Test error description",
      source: ErrorHandlingInterfaces.ErrorSource(
        file: "TestFile.swift",
        line: 42,
        function: "testFunction()"
      )
    )

    // Create a mock observer to receive notifications
    let mockObserver=MockErrorObserver()

    // Register the observer
    notificationCentre.addObserver(mockObserver, forDomains: ["TestDomain"])

    // Broadcast an error
    notificationCentre.broadcastError(error)

    // Verify the observer received the notification
    XCTAssertEqual(mockObserver.receivedErrors.count, 1)
    if let receivedError=mockObserver.receivedErrors.first as? TestError {
      XCTAssertEqual(receivedError.domain, "TestDomain")
      XCTAssertEqual(receivedError.code, "TEST001")
      XCTAssertEqual(receivedError.errorDescription, "Test error description")
    } else {
      XCTFail("Observer did not receive the expected error")
    }

    // Test removing the observer
    notificationCentre.removeObserver(mockObserver)

    // Broadcast another error
    notificationCentre.broadcastError(error)

    // Verify no new notifications were received
    XCTAssertEqual(mockObserver.receivedErrors.count, 1)
  }

  func testDomainSpecificObservers() {
    // Create an error notification centre
    let notificationCentre=TestErrorNotificationCentre()

    // Create test errors with different domains
    let securityError=TestError(
      domain: "Security",
      code: "SEC001",
      description: "Security error"
    )

    let networkError=TestError(
      domain: "Network",
      code: "NET001",
      description: "Network error"
    )

    // Create domain-specific observers
    let securityObserver=MockErrorObserver()
    let networkObserver=MockErrorObserver()
    let allDomainsObserver=MockErrorObserver()

    // Register observers for specific domains
    notificationCentre.addObserver(securityObserver, forDomains: ["Security"])
    notificationCentre.addObserver(networkObserver, forDomains: ["Network"])
    notificationCentre.addObserver(allDomainsObserver, forDomains: [])

    // Broadcast errors
    notificationCentre.broadcastError(securityError)
    notificationCentre.broadcastError(networkError)

    // Verify domain-specific observers only received relevant errors
    XCTAssertEqual(securityObserver.receivedErrors.count, 1)
    if let receivedError=securityObserver.receivedErrors.first as? TestError {
      XCTAssertEqual(receivedError.domain, "Security")
    } else {
      XCTFail("Security observer received wrong error type")
    }

    XCTAssertEqual(networkObserver.receivedErrors.count, 1)
    if let receivedError=networkObserver.receivedErrors.first as? TestError {
      XCTAssertEqual(receivedError.domain, "Network")
    } else {
      XCTFail("Network observer received wrong error type")
    }

    // Verify all-domains observer received all errors
    XCTAssertEqual(allDomainsObserver.receivedErrors.count, 2)
  }

  func testErrorNotificationFiltering() {
    // Create an error notification centre
    let notificationCentre=TestErrorNotificationCentre()

    // Create a test error
    let error=TestError(
      domain: "TestDomain",
      code: "TEST001",
      description: "Test error description"
    )

    // Create an observer with a filter
    let filteredObserver=FilteredErrorObserver(allowedCodes: ["TEST002"])

    // Register the filtered observer
    notificationCentre.addObserver(filteredObserver, forDomains: ["TestDomain"])

    // Broadcast an error that should be filtered out
    notificationCentre.broadcastError(error)

    // Verify the observer didn't receive the notification
    XCTAssertEqual(filteredObserver.receivedErrors.count, 0)

    // Create an error that should pass the filter
    let acceptedError=TestError(
      domain: "TestDomain",
      code: "TEST002",
      description: "Accepted error description"
    )

    // Broadcast the accepted error
    notificationCentre.broadcastError(acceptedError)

    // Verify the observer received the notification
    XCTAssertEqual(filteredObserver.receivedErrors.count, 1)
    if let receivedError=filteredObserver.receivedErrors.first as? TestError {
      XCTAssertEqual(receivedError.code, "TEST002")
    } else {
      XCTFail("Observer did not receive the expected error")
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

  class MockErrorObserver: ErrorObserver {
    var receivedErrors: [Error]=[]

    func onError(_ error: UmbraError) {
      receivedErrors.append(error)
    }
  }

  class FilteredErrorObserver: ErrorObserver {
    var receivedErrors: [Error]=[]
    var allowedCodes: [String]

    init(allowedCodes: [String]) {
      self.allowedCodes=allowedCodes
    }

    func onError(_ error: UmbraError) {
      if allowedCodes.contains(error.code) {
        receivedErrors.append(error)
      }
    }
  }

  class TestErrorNotificationCentre {
    private var observers: [(observer: ErrorObserver, domains: [String])]=[]

    func addObserver(_ observer: ErrorObserver, forDomains domains: [String]) {
      observers.append((observer: observer, domains: domains))
    }

    func removeObserver(_ observer: ErrorObserver) {
      observers.removeAll { $0.observer === observer }
    }

    func broadcastError(_ error: UmbraError) {
      for (observer, domains) in observers {
        // Check if the observer is interested in this error's domain
        if domains.isEmpty || domains.contains(error.domain) {
          observer.onError(error)
        }
      }
    }
  }

  protocol ErrorObserver: AnyObject {
    func onError(_ error: UmbraError)
  }
}
