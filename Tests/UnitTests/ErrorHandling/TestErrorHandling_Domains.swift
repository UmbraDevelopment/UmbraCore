@testable import ErrorHandling
@testable import ErrorHandlingCommon
@testable import ErrorHandlingDomains
@testable import ErrorHandlingInterfaces
import XCTest

final class TestErrorHandling_Domains: XCTestCase {
  // MARK: - General Errors Tests

  func testGeneralErrors() {
    // Test general error creation with mock errors
    let error=TestError(
      domain: "General",
      code: "invalidArgument",
      description: "Invalid argument: testParam = 'invalid'",
      source: nil
    )

    // Verify error properties
    XCTAssertEqual(error.domain, "General")
    XCTAssertEqual(error.code, "invalidArgument")
    XCTAssertTrue(error.errorDescription.contains("testParam"))
    XCTAssertTrue(error.errorDescription.contains("invalid"))

    // Test domain categorization
    XCTAssertTrue(error.domain.contains("General"))

    // Test adding context
    let context=ErrorHandlingInterfaces.ErrorContext(
      source: "TestSource",
      operation: "testOperation",
      details: "Test details",
      underlyingError: nil,
      file: #file,
      line: #line,
      function: #function
    )

    let errorWithContext=error.with(context: context)
    XCTAssertEqual(errorWithContext.context.source, "TestSource")
    XCTAssertEqual(errorWithContext.context.operation, "testOperation")

    // Test other general error types
    let notFoundError=TestError(
      domain: "General",
      code: "notFound",
      description: "Item not found: user with identifier 123"
    )
    XCTAssertTrue(notFoundError.errorDescription.contains("user"))
    XCTAssertTrue(notFoundError.errorDescription.contains("123"))

    let timeoutError=TestError(
      domain: "General",
      code: "timeout",
      description: "Operation timed out: network request after 30 seconds"
    )
    XCTAssertTrue(timeoutError.errorDescription.contains("network request"))
    XCTAssertTrue(timeoutError.errorDescription.contains("30"))
  }

  // MARK: - Security Errors Tests

  func testSecurityErrors() {
    // Test security error creation with mock errors
    let error=TestError(
      domain: "Security.Core",
      code: "encryptionFailed",
      description: "Encryption failed: Invalid key",
      source: nil
    )

    // Verify error properties
    XCTAssertTrue(error.domain.contains("Security"))
    XCTAssertEqual(error.code, "encryptionFailed")
    XCTAssertTrue(error.errorDescription.contains("Encryption failed"))
    XCTAssertTrue(error.errorDescription.contains("Invalid key"))

    // Test protocol errors
    let protocolError=TestError(
      domain: "Security.Protocol",
      code: "handshakeFailed",
      description: "TLS handshake failed: Certificate validation error"
    )
    XCTAssertTrue(protocolError.domain.contains("Protocol"))
    XCTAssertEqual(protocolError.code, "handshakeFailed")
    XCTAssertTrue(protocolError.errorDescription.contains("handshake"))
    XCTAssertTrue(protocolError.errorDescription.contains("Certificate"))
  }

  // MARK: - Network Errors Tests

  func testNetworkErrors() {
    // Test HTTP error creation
    let httpError=TestError(
      domain: "Network.HTTP",
      code: "statusCode",
      description: "HTTP error: Status code 404 - Not Found",
      source: nil
    )

    // Verify error properties
    XCTAssertTrue(httpError.domain.contains("Network"))
    XCTAssertTrue(httpError.domain.contains("HTTP"))
    XCTAssertEqual(httpError.code, "statusCode")
    XCTAssertTrue(httpError.errorDescription.contains("404"))
    XCTAssertTrue(httpError.errorDescription.contains("Not Found"))

    // Test connection error
    let connectionError=TestError(
      domain: "Network.Connection",
      code: "connectionFailed",
      description: "Connection failed: Host unreachable (example.com)"
    )
    XCTAssertTrue(connectionError.domain.contains("Connection"))
    XCTAssertTrue(connectionError.errorDescription.contains("Host unreachable"))
    XCTAssertTrue(connectionError.errorDescription.contains("example.com"))
  }

  // MARK: - Resource Errors Tests

  func testResourceErrors() {
    // Test file error creation with mock errors
    let fileError=TestError(
      domain: "Resource.File",
      code: "fileNotFound",
      description: "File not found: /path/to/file.txt"
    )

    // Verify error properties
    XCTAssertTrue(fileError.domain.contains("Resource"))
    XCTAssertTrue(fileError.code.contains("fileNotFound"))
    XCTAssertTrue(fileError.errorDescription.contains("/path/to/file.txt"))

    // Test permission error
    let permissionError=TestError(
      domain: "Resource.File",
      code: "permissionDenied",
      description: "Permission denied for operation: write on /path/to/file.txt"
    )
    XCTAssertTrue(permissionError.errorDescription.contains("/path/to/file.txt"))
    XCTAssertTrue(permissionError.errorDescription.contains("write"))

    // Test pool error
    let poolError=TestError(
      domain: "Resource.Pool",
      code: "resourceExhausted",
      description: "Resource exhausted: database connections"
    )
    XCTAssertTrue(poolError.errorDescription.contains("database connections"))
    XCTAssertTrue(poolError.errorDescription.contains("exhausted"))
  }

  // MARK: - Application Errors Tests

  func testApplicationErrors() {
    // Test application error creation
    let appError=ApplicationError.initializationError("Database: Connection failed")

    // Verify error properties
    XCTAssertTrue(appError.domain.contains("Application"))
    XCTAssertFalse(appError.code.isEmpty)
    XCTAssertTrue(appError.errorDescription.contains("Database"))
    XCTAssertTrue(appError.errorDescription.contains("Connection failed"))

    // Test lifecycle error
    let lifecycleError=ApplicationError.lifecycleError("Cache startup failed: Disk full")
    XCTAssertTrue(lifecycleError.errorDescription.contains("Cache"))
    XCTAssertTrue(lifecycleError.errorDescription.contains("Disk full"))
    XCTAssertTrue(lifecycleError.errorDescription.contains("startup"))

    // Test UI error
    let uiError=ApplicationError.renderingError("Chart rendering failed: Invalid data")
    XCTAssertTrue(uiError.errorDescription.contains("Chart"))
    XCTAssertTrue(uiError.errorDescription.contains("Invalid data"))
    XCTAssertTrue(uiError.errorDescription.contains("rendering"))
  }

  // MARK: - Test Support

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

    func with(underlyingError: any Error) -> Self {
      var copy=self
      copy.underlyingError=underlyingError
      return copy
    }

    func with(source: ErrorHandlingInterfaces.ErrorSource) -> Self {
      var copy=self
      copy.source=source
      return copy
    }

    // CustomStringConvertible conformance
    var description: String {
      var result="[\(domain).\(code)] \(errorDescription)"
      if let source {
        result += " - Source: \(source.file):\(source.line) (\(source.function))"
      }
      if let underlyingError {
        result += " - Caused by: \(underlyingError)"
      }
      return result
    }
  }
}
