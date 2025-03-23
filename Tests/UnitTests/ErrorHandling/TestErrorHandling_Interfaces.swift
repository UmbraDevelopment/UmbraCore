@testable import ErrorHandling
@testable import ErrorHandlingCommon
@testable import ErrorHandlingInterfaces
import XCTest

final class TestErrorHandling_Interfaces: XCTestCase {
  // MARK: - Test Implementations

  /// A simple implementation of UmbraError for testing
  struct TestError: UmbraError {
    let domain: String
    let code: String
    let errorDescription: String
    var source: ErrorHandlingInterfaces.ErrorSource?
    var underlyingError: Error?
    var context: ErrorHandlingInterfaces.ErrorContext

    init(
      domain: String="TestDomain",
      code: String="TEST001",
      description: String="Test error description",
      source: ErrorHandlingInterfaces.ErrorSource?=nil,
      underlyingError: Error?=nil,
      context: ErrorHandlingInterfaces.ErrorContext?=nil
    ) {
      self.domain=domain
      self.code=code
      errorDescription=description
      self.source=source
      self.underlyingError=underlyingError
      self.context=context ?? ErrorHandlingInterfaces.ErrorContext(
        source: "TestSource",
        operation: "testOperation"
      )
    }

    func with(context: ErrorHandlingInterfaces.ErrorContext) -> TestError {
      TestError(
        domain: domain,
        code: code,
        description: errorDescription,
        source: source,
        underlyingError: underlyingError,
        context: context
      )
    }

    func with(underlyingError: Error) -> TestError {
      TestError(
        domain: domain,
        code: code,
        description: errorDescription,
        source: source,
        underlyingError: underlyingError,
        context: context
      )
    }

    func with(source: ErrorHandlingInterfaces.ErrorSource) -> TestError {
      TestError(
        domain: domain,
        code: code,
        description: errorDescription,
        source: source,
        underlyingError: underlyingError,
        context: context
      )
    }

    var description: String {
      errorDescription
    }
  }

  // MARK: - UmbraError Protocol Tests

  func testUmbraErrorConformance() {
    // Create a basic error
    let error=TestError()

    // Test basic protocol properties
    XCTAssertEqual(error.domain, "TestDomain")
    XCTAssertEqual(error.code, "TEST001")
    XCTAssertEqual(error.errorDescription, "Test error description")
    XCTAssertEqual(error.description, "Test error description")
    XCTAssertNil(error.underlyingError)
    XCTAssertNil(error.source)
    XCTAssertEqual(error.context.source, "TestSource")
    XCTAssertEqual(error.context.operation, "testOperation")

    // Test with(context:) method
    let newContext=ErrorHandlingInterfaces.ErrorContext(
      source: "NewSource",
      operation: "newOperation",
      details: "New details"
    )
    let errorWithContext=error.with(context: newContext)
    XCTAssertEqual(errorWithContext.context.source, "NewSource")
    XCTAssertEqual(errorWithContext.context.operation, "newOperation")
    XCTAssertEqual(errorWithContext.context.details, "New details")

    // Test with(underlyingError:) method
    let underlyingError=NSError(domain: "UnderlyingDomain", code: 123)
    let errorWithUnderlying=error.with(underlyingError: underlyingError)
    XCTAssertNotNil(errorWithUnderlying.underlyingError)
    if let unwrapped=errorWithUnderlying.underlyingError as? NSError {
      XCTAssertEqual(unwrapped.domain, "UnderlyingDomain")
      XCTAssertEqual(unwrapped.code, 123)
    } else {
      XCTFail("Underlying error not properly stored or retrieved")
    }

    // Test with source method
    let source=ErrorHandlingInterfaces.ErrorSource(
      file: "TestFile.swift",
      line: 42,
      function: "testFunction()"
    )
    let errorWithSource=error.with(source: source)
    XCTAssertNotNil(errorWithSource.source)
    XCTAssertEqual(errorWithSource.source?.file, "TestFile.swift")
    XCTAssertEqual(errorWithSource.source?.line, 42)
    XCTAssertEqual(errorWithSource.source?.function, "testFunction()")
  }

  // MARK: - Error Context Tests

  func testErrorContextInterface() {
    // Create a context with minimal parameters
    let context=ErrorHandlingInterfaces.ErrorContext(
      source: "ContextSource",
      operation: "contextOperation"
    )

    // Test the basic interface
    XCTAssertEqual(context.source, "ContextSource")
    XCTAssertEqual(context.operation, "contextOperation")
    XCTAssertNil(context.details)
    XCTAssertNil(context.underlyingError)

    // File/line/function should be set to values from this test file
    XCTAssertTrue(context.file.hasSuffix("TestErrorHandling_Interfaces.swift"))
    XCTAssertTrue(context.function.contains("testErrorContextInterface"))

    // Test with underlying error
    let underlyingError=NSError(domain: "UnderlyingDomain", code: 456)
    let contextWithError=ErrorHandlingInterfaces.ErrorContext(
      source: "ContextSource",
      operation: "contextOperation",
      underlyingError: underlyingError
    )

    XCTAssertNotNil(contextWithError.underlyingError)
    if let unwrapped=contextWithError.underlyingError as? NSError {
      XCTAssertEqual(unwrapped.domain, "UnderlyingDomain")
      XCTAssertEqual(unwrapped.code, 456)
    } else {
      XCTFail("Underlying error not properly stored or retrieved")
    }
  }

  // MARK: - Error Source Tests

  func testErrorSourceInterface() {
    // Create a source with explicit parameters
    let source=ErrorHandlingInterfaces.ErrorSource(
      file: "SourceFile.swift",
      line: 123,
      function: "sourceFunction()"
    )

    // Test the basic interface
    XCTAssertEqual(source.file, "SourceFile.swift")
    XCTAssertEqual(source.line, 123)
    XCTAssertEqual(source.function, "sourceFunction()")

    // Test default parameters capturing current location
    let defaultSource=ErrorHandlingInterfaces.ErrorSource()
    XCTAssertTrue(defaultSource.file.hasSuffix("TestErrorHandling_Interfaces.swift"))
    XCTAssertTrue(defaultSource.function.contains("testErrorSourceInterface"))
  }
}
