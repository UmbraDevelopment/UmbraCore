@testable import Security
import XCTest

class SecureStringTests: XCTestCase {
  func testVersion() {
    XCTAssertFalse(SecureString.version.isEmpty)
  }

  func testCreationAndAccess() {
    let originalString="This is a secret string"
    let secureString=SecureString(originalString)

    // Test access method returns the original string
    secureString.access { decryptedString in
      XCTAssertEqual(decryptedString, originalString)
    }
  }

  func testLength() {
    let testString="Hello, world!"
    let secureString=SecureString(testString)

    // Check that length matches the original string's byte count
    XCTAssertEqual(secureString.length, testString.utf8.count)
  }

  func testIsEmpty() {
    // Test with empty string
    let emptySecureString=SecureString("")
    XCTAssertTrue(emptySecureString.isEmpty)

    // Test with non-empty string
    let nonEmptySecureString=SecureString("not empty")
    XCTAssertFalse(nonEmptySecureString.isEmpty)
  }

  func testEquality() {
    let string1=SecureString("test string")
    let string2=SecureString("test string")
    let string3=SecureString("different string")

    // Same content should be equal
    XCTAssertEqual(string1, string2)

    // Different content should not be equal
    XCTAssertNotEqual(string1, string3)
  }

  func testBytesInitialiser() {
    let originalString="Hello from bytes"
    let bytes=Array(originalString.utf8)
    let secureString=SecureString(bytes: bytes)

    secureString.access { decryptedString in
      XCTAssertEqual(decryptedString, originalString)
    }
  }

  func testHashable() {
    let string1=SecureString("test string")
    let string2=SecureString("test string")
    let string3=SecureString("different string")

    var dict=[SecureString: String]()
    dict[string1]="value1"

    // Same content should result in same hash
    XCTAssertEqual(dict[string2], "value1")

    // Different content should have different hash
    XCTAssertNil(dict[string3])
  }

  func testDescription() {
    let secureString=SecureString("test string")
    XCTAssertEqual(secureString.description, "<SecureString: length=11>")
  }

  func testDebugDescription() {
    let secureString=SecureString("test string")
    XCTAssertEqual(secureString.debugDescription, "<SecureString: length=11, content=REDACTED>")
  }

  func testThreadSafety() {
    let secureString=SecureString("shared string")

    // Create multiple concurrent accesses
    let expectation=XCTestExpectation(description: "Concurrent access completed")
    expectation.expectedFulfillmentCount=10

    for _ in 0..<10 {
      DispatchQueue.global().async {
        // Access the string multiple times
        for _ in 0..<100 {
          secureString.access { _ in
            // Just access the string
          }
        }
        expectation.fulfill()
      }
    }

    // Wait for all accesses to complete
    wait(for: [expectation], timeout: 5.0)
  }
}
