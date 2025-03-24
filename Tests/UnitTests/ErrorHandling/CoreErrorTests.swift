@testable import ErrorHandling
@testable import ErrorHandlingCommon
@testable import ErrorHandlingModels
@testable import ErrorHandlingProtocols
import XCTest

final class CoreErrorTests: XCTestCase {
  func testCoreErrorDescriptions() {
    // Test authentication failed error
    let authError=CoreError.authenticationFailed
    XCTAssertEqual(authError.errorDescription, "Authentication failed")

    // Test insufficient permissions error
    let permError=CoreError.insufficientPermissions
    XCTAssertEqual(permError.errorDescription, "Insufficient permissions to perform the operation")

    // Test invalid configuration error
    let configError=CoreError.invalidConfiguration("Missing API key")
    XCTAssertEqual(configError.errorDescription, "Invalid configuration: Missing API key")

    // Test system error
    let sysError=CoreError.systemError("Process terminated unexpectedly")
    XCTAssertEqual(sysError.errorDescription, "System error: Process terminated unexpectedly")
  }

  func testErrorSeverityLevels() {
    XCTAssertEqual(ErrorSeverity.critical.rawValue, "critical")
    XCTAssertEqual(ErrorSeverity.error.rawValue, "error")
    XCTAssertEqual(ErrorSeverity.warning.rawValue, "warning")
    XCTAssertEqual(ErrorSeverity.info.rawValue, "info")
  }

  func testServiceErrorTypes() {
    XCTAssertEqual(ServiceErrorType.configuration.description, "Configuration Error")
    XCTAssertEqual(ServiceErrorType.operation.description, "Operation Error")
    XCTAssertEqual(ServiceErrorType.network.description, "Network Error")
  }
}

// Example service error for testing
struct TestServiceError: ServiceErrorProtocol {
  let serviceName: String="TestService"
  let operation: String="testOperation"
  let details: String?="Test details"
  let underlyingError: Error?=nil
  let errorType: ServiceErrorType
  let contextInfo: [String: String]
  let message: String
  var severity: ErrorSeverity = .error
  var isRecoverable: Bool=false
  var recoverySteps: [String]?
  var errorContext: ErrorHandlingModels.ErrorContext?

  var category: String { errorType.rawValue }
  var description: String {
    "[\(severity.rawValue.uppercased())] \(errorType.description): \(message)"
  }

  var errorDescription: String? { message }

  func toDictionary() -> [String: Any] {
    [
      "type": String(describing: type(of: self)),
      "error_type": errorType.rawValue,
      "description": message,
      "context": contextInfo
    ]
  }
}

final class ServiceErrorTests: XCTestCase {
  func testServiceErrorType() {
    let error=TestServiceError(
      errorType: ServiceErrorType.configuration,
      contextInfo: ["key": "value"],
      message: "Test error"
    )

    XCTAssertEqual(error.severity, ErrorSeverity.error) // Default severity
    XCTAssertFalse(error.isRecoverable) // Default not recoverable
    XCTAssertEqual(error.category, "Configuration")
    XCTAssertEqual(error.description, "[ERROR] Configuration Error: Test error")

    let dict=error.toDictionary()
    XCTAssertEqual(dict["type"] as? String, "TestServiceError")
    XCTAssertEqual(dict["error_type"] as? String, "Configuration")
    XCTAssertEqual(dict["description"] as? String, "Test error")
    XCTAssertEqual((dict["context"] as? [String: String])?["key"], "value")
  }
}
