@testable import UmbraCoreTypes
import UmbraErrors
import UmbraErrorsCore
import XCTest

final class UmbraErrorsMappingTests: XCTestCase {
  // MARK: - Test Constants

  private enum Constants {
    static let testReason = "Test error reason"
  }

  // MARK: - SecureBytesError Mapping Tests

  func testSecureBytesErrorToUmbraError() {
    // Test mapping to UmbraErrors
    let originalError = SecureBytesError.invalidHexString
    let mappedError = originalError.toUmbraError()

    // Verify the mapped error is a ResourceError
    guard let resourceError = mappedError as? ResourceError else {
      XCTFail("Expected ResourceError but got \(type(of: mappedError))")
      return
    }

    // Check specific properties
    XCTAssertEqual(resourceError.code, SecureBytesErrorDomain.invalidHexString.rawValue)
    XCTAssertEqual(resourceError.type, .invalidResource)
  }

  // MARK: - ResourceLocatorError Mapping Tests

  func testResourceLocatorErrorToUmbraError() {
    // Test mapping to UmbraErrors
    let originalError = ResourceLocatorError.resourceNotFound
    let mappedError = originalError.toUmbraError()

    // Verify the mapped error is a ResourceError
    guard let resourceError = mappedError as? ResourceError else {
      XCTFail("Expected ResourceError but got \(type(of: mappedError))")
      return
    }

    // Check specific properties
    XCTAssertEqual(resourceError.code, ResourceLocatorErrorDomain.resourceNotFound.rawValue)
    XCTAssertEqual(resourceError.type, .notFound)
  }

  // MARK: - TimePoint Error Tests

  func testTimePointErrorToUmbraError() {
    // Test mapping to UmbraErrors
    let originalError = TimePointError.invalidFormat
    let mappedError = originalError.toUmbraError()

    // Verify the mapped error is a ResourceError
    guard let resourceError = mappedError as? ResourceError else {
      XCTFail("Expected ResourceError but got \(type(of: mappedError))")
      return
    }

    // Check specific properties
    XCTAssertEqual(resourceError.code, TimePointErrorDomain.invalidFormat.rawValue)
    XCTAssertEqual(resourceError.type, .invalidResource)
  }

  // MARK: - Error Context Tests

  func testErrorContext() {
    // Create an error context and add values
    var context = ErrorContext()
    context = context.adding(key: "key", value: "value")
    context = context.adding(key: "number", value: 123)

    // Verify properties
    XCTAssertEqual(context.typedValue(for: "key", as: String.self), "value")
    XCTAssertEqual(context.typedValue(for: "number", as: Int.self), 123)
    
    // Test adding multiple values at once
    var secondContext = ErrorContext()
    secondContext = secondContext.adding(key: "key2", value: "value2")
    
    let merged = context.adding(context: ["key2": "value2" as Any])
    XCTAssertEqual(merged.typedValue(for: "key", as: String.self), "value")
    XCTAssertEqual(merged.typedValue(for: "key2", as: String.self), "value2")
  }

  // MARK: - Error Source Tests
  
  func testErrorSource() {
    let source = ErrorSource(file: "TestFile.swift", line: 42, function: "testFunction()")
    
    XCTAssertEqual(source.file, "TestFile.swift")
    XCTAssertEqual(source.line, 42)
    XCTAssertEqual(source.function, "testFunction()")
  }
}
