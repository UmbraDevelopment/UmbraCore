@testable import ErrorHandling
import ErrorHandlingDomains
import XCTest

final class EnhancedErrorHandlingTests: XCTestCase {
  override func setUp() {
    super.setUp()
    // Clear the error registry before each test
    ErrorRegistry.shared.clearAll()
    // Register the security error mapper
    registerSecurityErrorMapper()
  }

  func testErrorSourceCreation() {
    let source=ErrorSource(file: "TestFile.swift", line: 42, function: "testFunction()")

    XCTAssertEqual(source.file, "TestFile.swift")
    XCTAssertEqual(source.line, 42)
    XCTAssertEqual(source.function, "testFunction()")
    XCTAssertEqual(source.fileName, "TestFile.swift")
  }

  func testErrorContextCreation() {
    let context=ErrorContext(
      source: "TestSource",
      code: "test_error",
      message: "Test message",
      metadata: ["key1": "value1", "key2": 42]
    )

    XCTAssertEqual(context.source, "TestSource")
    XCTAssertEqual(context.code, "test_error")
    XCTAssertEqual(context.message, "Test message")
    XCTAssertEqual(context.metadata.count, 2)
    XCTAssertEqual(context.value(for: "key1") as? String, "value1")
    XCTAssertEqual(context.typedValue(for: "key2", as: Int.self), 42)
  }

  func testErrorContextManipulation() {
    let context=ErrorContext(source: "TestSource", message: "Test message")

    // Add a single key-value pair
    let context2=context.adding(key: "key1", value: "value1")
    XCTAssertEqual(context2.typedValue(for: "key1", as: String.self), "value1")

    // Add multiple key-value pairs
    let context3=context2.adding(metadata: ["key2": 42, "key3": true])
    XCTAssertEqual(context3.typedValue(for: "key2", as: Int.self), 42)
    XCTAssertEqual(context3.typedValue(for: "key3", as: Bool.self), true)

    // Original context should remain unchanged
    XCTAssertNil(context.typedValue(for: "key1", as: String.self))
  }

  func testErrorContextMerging() {
    let context1=ErrorContext(
      source: "Source1",
      code: "code1",
      message: "Message1",
      metadata: ["key1": "value1"]
    )

    let context2=ErrorContext(
      source: "Source2",
      code: "code2",
      message: "Message2",
      metadata: ["key2": "value2"]
    )

    let merged=context1.merging(with: context2)

    XCTAssertEqual(merged.source, "Source2")
    XCTAssertEqual(merged.code, "code2")
    XCTAssertEqual(merged.message, "Message2")
    XCTAssertEqual(merged.typedValue(for: "key1", as: String.self), "value1")
    XCTAssertEqual(merged.typedValue(for: "key2", as: String.self), "value2")
  }

  func testSecurityErrorCreation() {
    let error=SecurityError.authenticationFailed("Invalid credentials")

    XCTAssertEqual(error.domain, "Security")
    XCTAssertEqual(error.code, "auth_failed")
    XCTAssertEqual(error.errorDescription, "Authentication failed: Invalid credentials")
    XCTAssertNil(error.source)
    XCTAssertNil(error.underlyingError)
  }

  func testSecurityErrorWithSource() {
    let source=ErrorSource(file: "TestFile.swift", line: 42, function: "testFunction()")
    let error=SecurityError.authenticationFailed("Invalid credentials")
      .with(source: source)

    XCTAssertEqual(error.source?.file, "TestFile.swift")
    XCTAssertEqual(error.source?.line, 42)
    XCTAssertEqual(error.source?.function, "testFunction()")
  }

  func testSecurityErrorWithContext() {
    let context=ErrorContext(
      source: "AuthService",
      code: "invalid_token",
      message: "Token expired",
      metadata: ["userId": "user123"]
    )

    let error=SecurityError.authenticationFailed("Invalid credentials")
      .with(context: context)

    XCTAssertEqual(error.context.source, "AuthService")
    XCTAssertEqual(error.context.code, "invalid_token")
    XCTAssertEqual(error.context.message, "Token expired")
    XCTAssertEqual(error.context.typedValue(for: "userId", as: String.self), "user123")
  }

  func testSecurityErrorWithUnderlyingError() {
    struct UnderlyingError: Error {
      let message: String
    }

    let underlying=UnderlyingError(message: "Network timeout")
    let error=SecurityError.connectionFailed("Connection failed")
      .with(underlyingError: underlying)

    XCTAssertNotNil(error.underlyingError)
    if let underlyingError=error.underlyingError as? UnderlyingError {
      XCTAssertEqual(underlyingError.message, "Network timeout")
    } else {
      XCTFail("Underlying error not preserved correctly")
    }
  }

  func testGenericUmbraErrorCreation() {
    let error=GenericUmbraError(
      domain: "Test",
      code: "test_error",
      errorDescription: "Test error"
    )

    XCTAssertEqual(error.domain, "Test")
    XCTAssertEqual(error.code, "test_error")
    XCTAssertEqual(error.errorDescription, "Test error")
    XCTAssertNil(error.source)
    XCTAssertNil(error.underlyingError)
  }

  func testErrorFactoryWithSource() {
    let error=SecurityError.authenticationFailed("Invalid credentials")
    let errorWithSource=ErrorFactory.makeError(error)

    XCTAssertNotNil(errorWithSource.source)
    XCTAssertEqual(errorWithSource.source?.fileName, "EnhancedErrorHandlingTests.swift")
  }

  func testErrorFactoryWithUnderlyingError() {
    let error=SecurityError.cryptoOperationFailed("Encryption failed")
    let underlying=CoreError.systemError("Bad key")
    let errorWithUnderlying=ErrorFactory.makeError(error, underlyingError: underlying)

    XCTAssertNotNil(errorWithUnderlying.source)
    XCTAssertNotNil(errorWithUnderlying.underlyingError)
    XCTAssertEqual(
      (errorWithUnderlying.underlyingError as? CoreError)?.errorDescription,
      "System error: Bad key"
    )
  }

  func testErrorFactoryWrapError() {
    struct SimpleError: Error {
      let message: String
    }

    let original=SimpleError(message: "Simple error")
    let wrapped=ErrorFactory.wrapError(
      original,
      domain: "Test",
      code: "wrapped_error",
      description: "Wrapped error"
    )

    XCTAssertEqual(wrapped.domain, "Test")
    XCTAssertEqual(wrapped.code, "wrapped_error")
    XCTAssertEqual(wrapped.errorDescription, "Wrapped error")
    XCTAssertNotNil(wrapped.source)
    XCTAssertNotNil(wrapped.underlyingError)

    if let underlying=wrapped.underlyingError as? SimpleError {
      XCTAssertEqual(underlying.message, "Simple error")
    } else {
      XCTFail("Underlying error not preserved correctly")
    }
  }

  func testSecurityErrorToCoreErrorMapping() {
    let securityError=SecurityError.authenticationFailed("Invalid credentials")
    let coreError=ErrorRegistry.shared.map(securityError, to: CoreError.self)

    XCTAssertNotNil(coreError)
    XCTAssertEqual(coreError, CoreError.authenticationFailed)
  }

  func testCoreErrorToSecurityErrorMapping() {
    let coreError=CoreError.insufficientPermissions
    let securityError=ErrorRegistry.shared.map(coreError, to: SecurityError.self)

    XCTAssertNotNil(securityError)
    switch securityError {
      case .authorizationFailed:
        // Expected result
        break
      default:
        XCTFail("Mapped to incorrect SecurityError type: \(String(describing: securityError))")
    }
  }

  func testErrorDescription() {
    let error=SecurityError.cryptoOperationFailed("Failed to encrypt data")
      .with(source: ErrorSource(file: "TestFile.swift", line: 42, function: "testFunction()"))

    let description=error.description
    XCTAssertTrue(description.contains("[Security:crypto_failed]"))
    XCTAssertTrue(description.contains("Failed to encrypt data"))
    XCTAssertTrue(description.contains("testFunction()"))
    XCTAssertTrue(description.contains("TestFile.swift:42"))
  }

  func testConvenienceFunctions() {
    let error=authenticationFailedError("Invalid credentials")

    XCTAssertEqual(error.code, "auth_failed")
    XCTAssertEqual(error.errorDescription, "Authentication failed: Invalid credentials")
    XCTAssertNotNil(error.source)
    XCTAssertEqual(error.source?.fileName, "EnhancedErrorHandlingTests.swift")
  }
}
