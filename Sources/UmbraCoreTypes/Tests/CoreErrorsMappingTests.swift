import CoreErrors
@testable import UmbraCoreTypes
import UmbraCoreTypes_CoreErrors
import XCTest

final class CoreErrorsMappingTests: XCTestCase {
  // MARK: - Test Constants

  private enum Constants {
    static let testReason="Test error reason"
  }

  // MARK: - SecureBytesError Mapping Tests

  func testSecureBytesErrorMapping() {
    // Test mapping to CoreErrors
    let originalError=SecureBytesError.invalidHexString
    let mappedError=mapToCoreErrors(originalError)

    // Verify the mapped error
    guard let resourceError=mappedError as? CEResourceError else {
      XCTFail("Expected CEResourceError but got \(type(of: mappedError))")
      return
    }

    // Check specific case
    if case .operationFailed=resourceError {
      // Correct mapping
    } else {
      XCTFail("Expected operationFailed but got \(resourceError)")
    }
  }

  // MARK: - ResourceLocatorError Mapping Tests

  func testResourceLocatorErrorMapping() {
    // Test mapping to CoreErrors
    let originalError=ResourceLocatorError.resourceNotFound
    let mappedError=mapToCoreErrors(originalError)

    // Verify the mapped error
    guard let resourceError=mappedError as? CEResourceError else {
      XCTFail("Expected CEResourceError but got \(type(of: mappedError))")
      return
    }

    // Check specific case
    if case .resourceNotFound=resourceError {
      // Correct mapping
    } else {
      XCTFail("Expected resourceNotFound but got \(resourceError)")
    }
  }

  // MARK: - Bidirectional Mapping Tests

  func testBidirectionalMapping() {
    // Create a CoreErrors error
    let coreError=CEResourceError.invalidState

    // Map to UmbraCoreTypes
    let umbralError=mapFromCoreErrors(coreError)

    // Verify the mapped error
    XCTAssertTrue(
      umbralError is ResourceLocatorError,
      "Expected ResourceLocatorError but got \(type(of: umbralError))"
    )

    // Map back to CoreErrors
    let remappedError=mapToCoreErrors(umbralError)

    // Verify the re-mapped error
    XCTAssertTrue(
      remappedError is CEResourceError,
      "Expected CEResourceError but got \(type(of: remappedError))"
    )
  }

  // MARK: - Error Container Tests

  func testErrorContainer() {
    // Create an error container
    let container=ErrorContainer(
      domain: "test.domain",
      code: 123,
      userInfo: ["key": "value" as Any]
    )

    // Verify properties
    XCTAssertEqual(container.domain, "test.domain")
    XCTAssertEqual(container.code, 123)
    XCTAssertEqual(container.userInfo["key"] as? String, "value")
  }

  // MARK: - Namespace Resolution Tests

  func testNamespaceResolution() {
    // This test verifies that we can correctly resolve types from both modules
    // without namespace conflicts

    // Create types from different modules
    let coreError=CEResourceError.invalidState
    let localError=SecureBytesError.invalidHexString

    // Verify they're distinct types with proper namespace resolution
    XCTAssertTrue(type(of: coreError) == CEResourceError.self, "Expected CEResourceError")
    XCTAssertTrue(type(of: localError) == SecureBytesError.self, "Expected SecureBytesError")

    // This should compile without any ambiguity errors if namespace resolution is working
    XCTAssertNotEqual(
      String(describing: type(of: coreError)),
      String(describing: type(of: localError))
    )
  }
}
