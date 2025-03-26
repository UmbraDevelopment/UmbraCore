@testable import UmbraCoreTypes
import UmbraErrors
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

  // MARK: - UmbraError Mapping Tests

  func testResourceLocatorErrorToUmbraError() {
    // Given ResourceLocatorError values
    let errors: [ResourceLocatorError]=[
      .invalidPath,
      .resourceNotFound,
      .accessDenied,
      .unsupportedScheme,
      .generalError("Test error message")
    ]

    // When mapping to UmbraErrors
    for error in errors {
      let umbralError=error.toUmbraError()

      // Then it should produce the correct UmbraError type
      XCTAssertTrue(
        umbralError is ResourceError,
        "Expected ResourceError but got \(type(of: umbralError))"
      )

      guard let resourceError=umbralError as? ResourceError else {
        XCTFail("Could not cast to ResourceError")
        continue
      }

      // Verify specific error properties based on the original error
      switch error {
        case .invalidPath:
          XCTAssertEqual(resourceError.code, ResourceLocatorErrorDomain.invalidPath.rawValue)
          XCTAssertEqual(resourceError.type, .invalidResource)

        case .resourceNotFound:
          XCTAssertEqual(resourceError.code, ResourceLocatorErrorDomain.resourceNotFound.rawValue)
          XCTAssertEqual(resourceError.type, .notFound)

        case .accessDenied:
          XCTAssertEqual(resourceError.code, ResourceLocatorErrorDomain.accessDenied.rawValue)
          XCTAssertEqual(resourceError.type, .notAvailable)

        case .unsupportedScheme, .generalError:
          // These would map to some appropriate ResourceError type in a real implementation
          // For now we'll just verify they return a ResourceError
          XCTAssertNotNil(resourceError.code)
      }
    }
  }
}
