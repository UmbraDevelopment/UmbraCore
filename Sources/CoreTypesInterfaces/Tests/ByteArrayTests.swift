@testable import CoreTypesInterfaces
import XCTest

final class ByteArrayTests: XCTestCase {
  func testInitialization() {
    let bytes: [UInt8] = [1, 2, 3, 4, 5]
    let byteArray = ByteArray(bytes: bytes)

    XCTAssertEqual(byteArray.rawBytes, bytes)
    XCTAssertEqual(byteArray.count, 5)
  }

  func testSliceInitialization() {
    let bytes: [UInt8] = [1, 2, 3, 4, 5]
    let slice = bytes[1...3]
    let byteArray = ByteArray(slice: slice)

    XCTAssertEqual(byteArray.rawBytes, [2, 3, 4])
    XCTAssertEqual(byteArray.count, 3)
  }

  func testSubscriptAccess() {
    let bytes: [UInt8] = [1, 2, 3, 4, 5]
    let byteArray = ByteArray(bytes: bytes)

    XCTAssertEqual(byteArray[0], 1)
    XCTAssertEqual(byteArray[4], 5)
  }

  func testRangeSubscriptAccess() {
    let bytes: [UInt8] = [1, 2, 3, 4, 5]
    let byteArray = ByteArray(bytes: bytes)
    let subArray = byteArray[1..<4]

    XCTAssertEqual(subArray.rawBytes, [2, 3, 4])
    XCTAssertEqual(subArray.count, 3)
  }

  func testSliceMethod() {
    let bytes: [UInt8] = [1, 2, 3, 4, 5]
    let byteArray = ByteArray(bytes: bytes)
    let sliced = byteArray.slice(from: 1, length: 3)

    XCTAssertEqual(sliced.rawBytes, [2, 3, 4])
    XCTAssertEqual(sliced.count, 3)
  }

  func testEmptyByteArray() {
    let empty = ByteArray.empty

    XCTAssertTrue(empty.rawBytes.isEmpty)
    XCTAssertEqual(empty.count, 0)
    XCTAssertTrue(empty.isEmpty)
  }

  func testEquality() {
    let byteArray1 = ByteArray(bytes: [1, 2, 3])
    let byteArray2 = ByteArray(bytes: [1, 2, 3])
    let byteArray3 = ByteArray(bytes: [3, 2, 1])

    XCTAssertEqual(byteArray1, byteArray2)
    XCTAssertNotEqual(byteArray1, byteArray3)
  }
}
