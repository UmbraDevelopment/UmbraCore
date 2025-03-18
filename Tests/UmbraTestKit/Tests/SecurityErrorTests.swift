import Core
import ErrorHandlingDomains
import SecurityInterfaces
import XCTest

final class SecurityErrorTests: XCTestCase {
    // Add static property for test discovery
    static var allTests = [
        ("testErrorDescription", testErrorDescription),
        ("testErrorEquality", testErrorEquality),
        ("testErrorMetadata", testErrorMetadata)
    ]

    func testErrorDescription() {
        let error = SecurityInterfaces.SecurityError.accessError("Access denied to /test/path")
        XCTAssertEqual(
            error.errorDescription,
            "Security access error: Access denied to /test/path"
        )
    }

    func testErrorEquality() {
        let error1 = SecurityInterfaces.SecurityError.accessError("Access denied to /test/path")
        let error2 = SecurityInterfaces.SecurityError.accessError("Access denied to /test/path")
        let error3 = SecurityInterfaces.SecurityError.accessError("Access denied to /different/path")

        XCTAssertEqual(error1.errorDescription, error2.errorDescription)
        XCTAssertNotEqual(error1.errorDescription, error3.errorDescription)
    }

    func testErrorMetadata() {
        let error = SecurityInterfaces.SecurityError.accessError("Access denied to /test/path")
        XCTAssertEqual(error.errorDescription, "Security access error: Access denied to /test/path")
    }
}
