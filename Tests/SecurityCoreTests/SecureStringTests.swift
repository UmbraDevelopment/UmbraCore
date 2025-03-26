@testable import Security
import XCTest

final class SecureStringTests: XCTestCase {
  // MARK: - Properties

  private var emptyString: SecureString!
  private var sampleString: SecureString!

  // MARK: - Setup

  override func setUp() {
    super.setUp()
    emptyString=SecureString()
    sampleString=SecureString("Hello, world!")
  }

  override func tearDown() {
    emptyString=nil
    sampleString=nil
    super.tearDown()
  }

  // MARK: - Initialisation Tests

  func testEmptyInitialisation() {
    XCTAssertNotNil(emptyString)
    XCTAssertEqual(emptyString.count, 0)
    XCTAssertTrue(emptyString.isEmpty)
  }

  func testStringInitialization() {
    XCTAssertEqual(sampleString.count, 13)
    XCTAssertFalse(sampleString.isEmpty)
  }

  func testNilInitialization() {
    let nilString: String?=nil
    let secureString=SecureString(nilString)
    XCTAssertEqual(secureString.count, 0)
    XCTAssertTrue(secureString.isEmpty)
  }

  func testStringLiteralInitialization() {
    let literalString: SecureString="Test string"
    XCTAssertEqual(literalString.count, 11)
    XCTAssertFalse(literalString.isEmpty)
  }

  // MARK: - Access Tests

  func testStringValue() {
    XCTAssertEqual(sampleString.stringValue, "Hello, world!")
    XCTAssertEqual(emptyString.stringValue, "")
  }

  func testCount() {
    XCTAssertEqual(sampleString.count, 13)
    XCTAssertEqual(emptyString.count, 0)
  }

  func testIsEmpty() {
    XCTAssertTrue(emptyString.isEmpty)
    XCTAssertFalse(sampleString.isEmpty)
  }

  // MARK: - Secure Comparison Tests

  func testConstantTimeEquality() {
    let string1=SecureString("Secret value")
    let string2=SecureString("Secret value")
    let string3=SecureString("Different value")

    XCTAssertTrue(string1.secureCompare(string2))
    XCTAssertFalse(string1.secureCompare(string3))
  }

  func testEqualityOperator() {
    let string1=SecureString("Secret value")
    let string2=SecureString("Secret value")
    let string3=SecureString("Different value")

    XCTAssertTrue(string1 == string2)
    XCTAssertFalse(string1 == string3)
  }

  func testInequalityOperator() {
    let string1=SecureString("Secret value")
    let string2=SecureString("Secret value")
    let string3=SecureString("Different value")

    XCTAssertFalse(string1 != string2)
    XCTAssertTrue(string1 != string3)
  }

  // MARK: - String Representation Tests

  func testDescription() {
    XCTAssertEqual(emptyString.description, "SecureString(0 chars)")
    XCTAssertEqual(sampleString.description, "SecureString(13 chars)")
  }

  func testDebugDescription() {
    XCTAssertEqual(emptyString.debugDescription, "SecureString(0 chars: )")
    XCTAssertEqual(sampleString.debugDescription, "SecureString(13 chars: Hello, world!)")

    // Test masking of secure data
    let password=SecureString("SuperSecretPassword123!")
    XCTAssertEqual(password.debugDescription, "SecureString(23 chars: ********************)")
  }

  // MARK: - Appending Tests

  func testAppending() {
    let first=SecureString("Hello, ")
    let second=SecureString("world!")
    let combined=first.appending(second)

    XCTAssertEqual(combined.stringValue, "Hello, world!")
  }

  func testAppendingStringProtocol() {
    let secure=SecureString("Hello, ")
    let regular="world!"
    let combined=secure.appending(regular)

    XCTAssertEqual(combined.stringValue, "Hello, world!")
  }

  func testAppendingOperator() {
    let first=SecureString("Hello, ")
    let second=SecureString("world!")
    let combined=first + second

    XCTAssertEqual(combined.stringValue, "Hello, world!")
  }

  func testAppendingStringProtocolOperator() {
    let secure=SecureString("Hello, ")
    let regular="world!"
    let combined=secure + regular

    XCTAssertEqual(combined.stringValue, "Hello, world!")
  }

  func testMaskContentIfNeeded() {
    let password=SecureString("Password123")
    XCTAssertEqual(password.maskContentIfNeeded, "**********")

    let regularText=SecureString("Hello")
    XCTAssertEqual(regularText.maskContentIfNeeded, "Hello")
  }
}
