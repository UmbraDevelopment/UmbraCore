@testable import UmbraCoreTypes
import XCTest

class SecureBytesTests: XCTestCase {
  func testEmpty() {
    let bytes=SecureBytes()
    XCTAssertTrue(bytes.isEmpty)
    XCTAssertEqual(bytes.count, 0)
  }

  func testInitWithCapacity() {
    let bytes=SecureBytes(capacity: 10)
    XCTAssertEqual(bytes.count, 10)
    XCTAssertFalse(bytes.isEmpty)

    // All bytes should be initialized to zero
    for i in 0..<10 {
      XCTAssertEqual(bytes[i], 0)
    }
  }

  func testInitWithBytes() {
    let byteArray: [UInt8]=[1, 2, 3, 4, 5]
    let bytes=SecureBytes(bytes: byteArray)

    XCTAssertEqual(bytes.count, 5)
    for i in 0..<5 {
      XCTAssertEqual(bytes[i], UInt8(i + 1))
    }
  }

  func testInitWithUnsafeRawPointer() {
    let byteArray: [UInt8]=[10, 20, 30, 40, 50]
    let bytes=byteArray.withUnsafeBufferPointer { bufferPointer in
      SecureBytes(bytes: bufferPointer.baseAddress!, count: bufferPointer.count)
    }

    XCTAssertEqual(bytes.count, 5)
    for i in 0..<5 {
      XCTAssertEqual(bytes[i], byteArray[i])
    }
  }

  func testBase64Encoding() {
    let bytes=SecureBytes(bytes: [72, 101, 108, 108, 111]) // "Hello"
    let base64=bytes.base64EncodedString()
    XCTAssertEqual(base64, "SGVsbG8=")

    let decoded=SecureBytes(base64Encoded: base64)
    XCTAssertEqual(decoded, bytes)
  }

  func testHexEncoding() {
    let bytes=SecureBytes(bytes: [0xDE, 0xAD, 0xBE, 0xEF])
    let hex=bytes.hexEncodedString()
    XCTAssertEqual(hex, "deadbeef")
  }

  func testAppend() {
    var bytes=SecureBytes(bytes: [1, 2, 3])
    bytes.append(4)
    bytes.append(SecureBytes(bytes: [5, 6]))

    XCTAssertEqual(bytes.count, 6)
    for i in 0..<6 {
      XCTAssertEqual(bytes[i], UInt8(i + 1))
    }
  }

  func testConcatenation() {
    let bytes1=SecureBytes(bytes: [1, 2, 3])
    let bytes2=SecureBytes(bytes: [4, 5, 6])

    let combined=bytes1 + bytes2
    XCTAssertEqual(combined.count, 6)
    for i in 0..<6 {
      XCTAssertEqual(combined[i], UInt8(i + 1))
    }
  }

  func testSubscript() {
    var bytes=SecureBytes(bytes: [10, 20, 30, 40, 50])

    // Get
    XCTAssertEqual(bytes[2], 30)

    // Set
    bytes[2]=35
    XCTAssertEqual(bytes[2], 35)

    // Range get
    let slice=bytes[1..<4]
    XCTAssertEqual(slice.count, 3)
    XCTAssertEqual(slice[0], 20)
    XCTAssertEqual(slice[1], 35)
    XCTAssertEqual(slice[2], 40)

    // Range set
    bytes[1..<4]=SecureBytes(bytes: [25, 35, 45])
    XCTAssertEqual(bytes[1], 25)
    XCTAssertEqual(bytes[2], 35)
    XCTAssertEqual(bytes[3], 45)
  }

  func testSecureZero() {
    var bytes=SecureBytes(bytes: [1, 2, 3, 4, 5])
    bytes.secureZero()

    XCTAssertEqual(bytes.count, 5)
    for i in 0..<5 {
      XCTAssertEqual(bytes[i], 0)
    }
  }

  func testWithUnsafeBytes() {
    let bytes=SecureBytes(bytes: [10, 20, 30, 40, 50])

    bytes.withUnsafeBytes { buffer in
      XCTAssertEqual(buffer.count, 5)
      for i in 0..<5 {
        XCTAssertEqual(buffer[i], bytes[i])
      }
    }
  }

  func testWithUnsafeMutableBytes() {
    var bytes=SecureBytes(bytes: [10, 20, 30, 40, 50])

    bytes.withUnsafeMutableBytes { buffer in
      for i in 0..<buffer.count {
        buffer[i]=buffer[i] + 5
      }
    }

    XCTAssertEqual(bytes[0], 15)
    XCTAssertEqual(bytes[1], 25)
    XCTAssertEqual(bytes[2], 35)
    XCTAssertEqual(bytes[3], 45)
    XCTAssertEqual(bytes[4], 55)
  }

  func testArrayLiteralInitializer() {
    let bytes: SecureBytes=[1, 2, 3, 4, 5]

    XCTAssertEqual(bytes.count, 5)
    for i in 0..<5 {
      XCTAssertEqual(bytes[i], UInt8(i + 1))
    }
  }

  func testEquatable() {
    let bytes1=SecureBytes(bytes: [1, 2, 3])
    let bytes2=SecureBytes(bytes: [1, 2, 3])
    let bytes3=SecureBytes(bytes: [1, 2, 4])

    XCTAssertEqual(bytes1, bytes2)
    XCTAssertNotEqual(bytes1, bytes3)
  }

  func testHashable() {
    let bytes1=SecureBytes(bytes: [1, 2, 3])
    let bytes2=SecureBytes(bytes: [1, 2, 3])
    let bytes3=SecureBytes(bytes: [1, 2, 4])

    var hashSet=Set<SecureBytes>()
    hashSet.insert(bytes1)

    XCTAssertTrue(hashSet.contains(bytes2))
    XCTAssertFalse(hashSet.contains(bytes3))
  }

  func testCodable() throws {
    let original=SecureBytes(bytes: [10, 20, 30, 40, 50])

    let encoder=JSONEncoder()
    let data=try encoder.encode(original)

    let decoder=JSONDecoder()
    let decoded=try decoder.decode(SecureBytes.self, from: data)

    XCTAssertEqual(original, decoded)
  }
}
