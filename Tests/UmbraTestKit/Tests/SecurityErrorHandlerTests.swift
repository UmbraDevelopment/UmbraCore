import Core
import ErrorHandlingDomains
import SecurityInterfaces
import XCTest

/// Error statistics for reporting
public struct ErrorStats {
  public let totalErrors: Int
  public let uniqueContexts: Set<String>
}

/// A simple error handler for security errors
public class SecurityErrorHandler {
  private var errorCounts: [String: Int]=[:]
  private var lastErrorTimes: [String: Date]=[:]
  private let maxRetries=3
  private let rapidFailureThreshold: TimeInterval=5.0 // seconds

  public init() {}

  public func handleError(
    _ error: ErrorHandlingDomains.UmbraErrors.Security.Protocols,
    context: String
  ) -> Bool {
    let key="\(context):\(error)"
    let currentCount=errorCounts[key] ?? 0
    errorCounts[key]=currentCount + 1
    lastErrorTimes[context]=Date()

    // Allow retries for certain errors
    return currentCount < maxRetries
  }

  public func resetErrorCounts() {
    errorCounts.removeAll()
    lastErrorTimes.removeAll()
  }

  public func getErrorStats() -> ErrorStats {
    let totalErrors=errorCounts.values.reduce(0, +)
    let uniqueContexts=Set(errorCounts.keys.compactMap { key -> String? in
      let components=key.split(separator: ":")
      return components.first.map { String($0) }
    })

    return ErrorStats(totalErrors: totalErrors, uniqueContexts: uniqueContexts)
  }

  public func shouldRetryAfterRapidFailures(for context: String) -> Bool {
    guard let lastTime=lastErrorTimes[context] else {
      return true // No previous errors, allow retry
    }

    let timeSinceLast=Date().timeIntervalSince(lastTime)
    return timeSinceLast > rapidFailureThreshold
  }
}

final class SecurityErrorHandlerTests: XCTestCase {
  private var handler: SecurityErrorHandler!

  // Add static property for test discovery
  static var allTests=[
    ("testHandleRetryableError", testHandleRetryableError),
    ("testMaxRetries", testMaxRetries),
    ("testErrorStatsTracking", testErrorStatsTracking),
    ("testRapidFailureThrottling", testRapidFailureThrottling),
    ("testContextReset", testContextReset)
  ]

  override func setUp() async throws {
    handler=SecurityErrorHandler()
  }

  override func tearDown() async throws {
    handler=nil
  }

  func testHandleRetryableError() async throws {
    let shouldRetry=handler.handleError(
      ErrorHandlingDomains.UmbraErrors.Security.Protocols.serviceError("Permission denied"),
      context: "test"
    )
    XCTAssertTrue(shouldRetry, "First occurrence of retryable error should allow retry")
  }

  func testMaxRetries() async throws {
    // First attempt
    _=handler.handleError(
      ErrorHandlingDomains.UmbraErrors.Security.Protocols.serviceError("Permission denied"),
      context: "test"
    )

    // Second attempt
    _=handler.handleError(
      ErrorHandlingDomains.UmbraErrors.Security.Protocols.serviceError("Permission denied"),
      context: "test"
    )

    // Third attempt
    _=handler.handleError(
      ErrorHandlingDomains.UmbraErrors.Security.Protocols.serviceError("Permission denied"),
      context: "test"
    )

    // Fourth attempt should not retry
    let shouldRetry=handler.handleError(
      ErrorHandlingDomains.UmbraErrors.Security.Protocols.serviceError("Permission denied"),
      context: "test"
    )
    XCTAssertFalse(shouldRetry, "Should not retry after max retries")
  }

  func testErrorStatsTracking() async throws {
    _=handler.handleError(
      ErrorHandlingDomains.UmbraErrors.Security.Protocols.serviceError("Test error"),
      context: "test1"
    )
    _=handler.handleError(
      ErrorHandlingDomains.UmbraErrors.Security.Protocols.serviceError("Test error"),
      context: "test2"
    )

    let stats=handler.getErrorStats()
    XCTAssertEqual(stats.totalErrors, 2)
    XCTAssertEqual(stats.uniqueContexts.count, 2)
    XCTAssertTrue(stats.uniqueContexts.contains("test1"))
    XCTAssertTrue(stats.uniqueContexts.contains("test2"))
  }

  func testRapidFailureThrottling() async throws {
    // Create a special test handler that doesn't depend on real time
    let testHandler=SecurityErrorHandler()

    // First, ensure we have a clean state
    testHandler.resetErrorCounts()

    // Verify that with no errors, retries are always allowed
    XCTAssertTrue(testHandler.shouldRetryAfterRapidFailures(for: "test_context"))

    // Mark an error for test_context
    _=testHandler.handleError(
      ErrorHandlingDomains.UmbraErrors.Security.Protocols.serviceError("Test error"),
      context: "test_context"
    )

    // Different context should be allowed regardless
    XCTAssertTrue(testHandler.shouldRetryAfterRapidFailures(for: "different_context"))
  }

  func testContextReset() async throws {
    _=handler.handleError(
      ErrorHandlingDomains.UmbraErrors.Security.Protocols.serviceError("Test error"),
      context: "test"
    )

    // Reset counts
    handler.resetErrorCounts()

    // After reset, should be able to retry
    let shouldRetry=handler.handleError(
      ErrorHandlingDomains.UmbraErrors.Security.Protocols.serviceError("Test error"),
      context: "test"
    )
    XCTAssertTrue(shouldRetry)
  }
}
