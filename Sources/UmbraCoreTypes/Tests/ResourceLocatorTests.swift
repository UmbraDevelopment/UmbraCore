import CoreErrors
@testable import UmbraCoreTypes
import UmbraCoreTypes_CoreErrors
import XCTest

final class ResourceLocatorTests: XCTestCase {
  // MARK: - Initialization Tests

  func testInitWithValidParams() throws {
    // When initializing with valid parameters
    let locator=try ResourceLocator(scheme: "file", path: "/path/to/resource")

    // Then it should create a valid ResourceLocator
    XCTAssertEqual(locator.scheme, "file")
    XCTAssertEqual(locator.path, "/path/to/resource")
    XCTAssertNil(locator.query)
    XCTAssertNil(locator.fragment)
  }

  func testInitWithInvalidPath() {
    // When initializing with an empty path
    // Then it should throw invalidPath error
    XCTAssertThrowsError(try ResourceLocator(scheme: "file", path: "")) { error in
      XCTAssertTrue(error is ResourceLocatorError)
      XCTAssertEqual(error as? ResourceLocatorError, ResourceLocatorError.invalidPath)
    }
  }

  func testFileLocator() throws {
    // When creating a file locator with a valid path
    let locator=try ResourceLocator.fileLocator(path: "/path/to/file")

    // Then it should create a ResourceLocator with "file" scheme
    XCTAssertEqual(locator.scheme, "file")
    XCTAssertEqual(locator.path, "/path/to/file")
    XCTAssertTrue(locator.isFileResource)
  }

  func testHttpLocator() throws {
    // When creating an HTTP locator with valid host and path
    let locator=try ResourceLocator.httpLocator(host: "example.com", path: "/api/resource")

    // Then it should create a ResourceLocator with "http" scheme
    XCTAssertEqual(locator.scheme, "http")
    XCTAssertEqual(locator.path, "example.com/api/resource")
    XCTAssertFalse(locator.isFileResource)
  }

  func testHttpsLocator() throws {
    // When creating an HTTPS locator with valid host and path
    let locator=try ResourceLocator.httpsLocator(host: "secure.example.com", path: "/api/resource")

    // Then it should create a ResourceLocator with "https" scheme
    XCTAssertEqual(locator.scheme, "https")
    XCTAssertEqual(locator.path, "secure.example.com/api/resource")
    XCTAssertFalse(locator.isFileResource)
  }

  // MARK: - String Representation Tests

  func testToString() throws {
    // Given a ResourceLocator with all components
    let locator=try ResourceLocator(
      scheme: "https",
      path: "example.com/path",
      query: "param=value",
      fragment: "section"
    )

    // When converting to string
    let string=locator.toString()

    // Then it should include all components
    XCTAssertEqual(string, "https://example.com/path?param=value#section")
  }

  // MARK: - Validation Tests

  func testValidateSuccess() throws {
    // Given a valid ResourceLocator
    let locator=try ResourceLocator(scheme: "file", path: "/path/to/resource")

    // When validating
    let result=try locator.validate()

    // Then it should return true
    XCTAssertTrue(result)
  }

  func testValidateResourceNotFound() {
    // Given a ResourceLocator with a non-existent path
    do {
      let locator=try ResourceLocator(scheme: "file", path: "/path/to/nonexistent")

      // When validating
      // Then it should throw resourceNotFound
      XCTAssertThrowsError(try locator.validate()) { error in
        XCTAssertEqual(error as? ResourceLocatorError, ResourceLocatorError.resourceNotFound)
      }
    } catch {
      XCTFail("Should not throw during initialization: \(error)")
    }
  }

  func testValidateAccessDenied() {
    // Given a ResourceLocator with a restricted path
    do {
      let locator=try ResourceLocator(scheme: "file", path: "/path/to/restricted")

      // When validating
      // Then it should throw accessDenied
      XCTAssertThrowsError(try locator.validate()) { error in
        XCTAssertEqual(error as? ResourceLocatorError, ResourceLocatorError.accessDenied)
      }
    } catch {
      XCTFail("Should not throw during initialization: \(error)")
    }
  }

  // MARK: - Error Mapping Tests

  func testMapToCoreErrors() {
    // Given a ResourceLocatorError
    let errors: [ResourceLocatorError]=[
      .invalidPath,
      .resourceNotFound,
      .accessDenied,
      .unsupportedScheme,
      .generalError("Test error message")
    ]

    // When mapping to CoreErrors
    for error in errors {
      let mappedError=mapToCoreErrors(error)

      // Then it should produce the correct CoreErrors type
      switch error {
        case .invalidPath:
          if
            let resourceError=mappedError as? CEResourceError,
            case .invalidState=resourceError
          {
            // Success
          } else {
            XCTFail("Expected invalidPath to map to CEResourceError.invalidState")
          }

        case .resourceNotFound:
          if
            let resourceError=mappedError as? CEResourceError,
            case .resourceNotFound=resourceError
          {
            // Success
          } else {
            XCTFail("Expected resourceNotFound to map to CEResourceError.resourceNotFound")
          }

        case .accessDenied:
          if
            let securityError=mappedError as? CESecurityError,
            case .invalidInput=securityError
          {
            // Success
          } else {
            XCTFail("Expected accessDenied to map to CESecurityError.invalidInput")
          }

        case .unsupportedScheme:
          if
            let resourceError=mappedError as? CEResourceError,
            case .operationFailed=resourceError
          {
            // Success
          } else {
            XCTFail("Expected unsupportedScheme to map to CEResourceError.operationFailed")
          }

        case .generalError:
          if
            let resourceError=mappedError as? CEResourceError,
            case .operationFailed=resourceError
          {
            // Success
          } else {
            XCTFail("Expected generalError to map to CEResourceError.operationFailed")
          }
      }
    }
  }

  func testMapFromCoreErrors() {
    // Given a set of CoreErrors.ResourceError values
    let errors: [CoreErrors.ResourceError]=[
      .invalidState,
      .resourceNotFound,
      .operationFailed,
      .acquisitionFailed,
      .poolExhausted
    ]

    // When mapping from CoreErrors
    for coreError in errors {
      let mappedError=mapFromCoreErrors(coreError)

      // Then it should produce the correct ResourceLocatorError or other type
      switch coreError {
        case .invalidState:
          XCTAssertEqual(mappedError as? ResourceLocatorError, ResourceLocatorError.invalidPath)

        case .resourceNotFound:
          XCTAssertEqual(
            mappedError as? ResourceLocatorError,
            ResourceLocatorError.resourceNotFound
          )

        case .operationFailed:
          XCTAssertEqual(
            mappedError as? ResourceLocatorError,
            ResourceLocatorError.generalError("Operation failed")
          )

        case .acquisitionFailed:
          XCTAssertEqual(mappedError as? SecureBytesError, SecureBytesError.allocationFailed)

        case .poolExhausted:
          if
            let resourceError=mappedError as? ResourceLocatorError,
            case let .generalError(message)=resourceError
          {
            XCTAssertEqual(message, "Resource pool exhausted")
          } else {
            XCTFail("Expected poolExhausted to map to ResourceLocatorError.generalError")
          }

        @unknown default:
          XCTFail("Unexpected error type: \(coreError)")
      }
    }
  }
}
