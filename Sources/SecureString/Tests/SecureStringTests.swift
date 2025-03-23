@testable import SecureString
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

  func testBytesInitializer() {
    let originalString="Hello from bytes"
    let bytes=Array(originalString.utf8)
    let secureString=SecureString(bytes: bytes)

    secureString.access { decryptedString in
      XCTAssertEqual(decryptedString, originalString)
    }
  }

  func testDescription() {
    let secureString=SecureString("sensitive data")

    // Description should not expose the content
    XCTAssertEqual(secureString.description, "<SecureString: length=\(secureString.length)>")

    // Debug description should also not expose the content
    XCTAssertEqual(
      secureString.debugDescription,
      "<SecureString: length=\(secureString.length), content=REDACTED>"
    )
  }

  func testAccessorWithReturnValue() {
    let secureString=SecureString("password123")

    // Test that the accessor can return values
    let hasUppercase=secureString.access { string in
      string.contains { $0.isUppercase }
    }

    let hasDigit=secureString.access { string in
      string.contains { $0.isNumber }
    }

    XCTAssertFalse(hasUppercase)
    XCTAssertTrue(hasDigit)
  }
}
