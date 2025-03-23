import KeyManagementTypes
import XCTest

final class StorageLocationTests: XCTestCase {
  // MARK: - Canonical Type Tests

  func testCanonicalStorageLocationEquality() {
    let secureEnclave=KeyManagementTypes.StorageLocation.secureEnclave
    let keychain=KeyManagementTypes.StorageLocation.keychain
    let memory=KeyManagementTypes.StorageLocation.memory

    XCTAssertEqual(secureEnclave, secureEnclave)
    XCTAssertEqual(keychain, keychain)
    XCTAssertEqual(memory, memory)

    XCTAssertNotEqual(secureEnclave, keychain)
    XCTAssertNotEqual(secureEnclave, memory)
    XCTAssertNotEqual(keychain, memory)
  }

  func testCanonicalStorageLocationRawValue() {
    let secureEnclave=KeyManagementTypes.StorageLocation.secureEnclave
    let keychain=KeyManagementTypes.StorageLocation.keychain
    let memory=KeyManagementTypes.StorageLocation.memory

    XCTAssertEqual(secureEnclave.rawValue, "secureEnclave")
    XCTAssertEqual(keychain.rawValue, "keychain")
    XCTAssertEqual(memory.rawValue, "memory")
  }

  func testCanonicalStorageLocationCodable() throws {
    let original=KeyManagementTypes.StorageLocation.secureEnclave

    let encoder=JSONEncoder()
    let data=try encoder.encode(original)

    let decoder=JSONDecoder()
    let decoded=try decoder.decode(KeyManagementTypes.StorageLocation.self, from: data)

    XCTAssertEqual(original, decoded)
  }

  // MARK: - Raw Location Conversion Tests

  func testRawLocationConversion() {
    // Test conversion to raw locations
    let secureEnclave=KeyManagementTypes.StorageLocation.secureEnclave
    let keychain=KeyManagementTypes.StorageLocation.keychain
    let memory=KeyManagementTypes.StorageLocation.memory

    XCTAssertEqual(secureEnclave.toRawLocation(), .secureEnclave)
    XCTAssertEqual(keychain.toRawLocation(), .keychain)
    XCTAssertEqual(memory.toRawLocation(), .memory)

    // Test creation from raw locations
    XCTAssertEqual(
      KeyManagementTypes.StorageLocation.from(rawLocation: .secureEnclave),
      .secureEnclave
    )
    XCTAssertEqual(KeyManagementTypes.StorageLocation.from(rawLocation: .keychain), .keychain)
    XCTAssertEqual(KeyManagementTypes.StorageLocation.from(rawLocation: .memory), .memory)
  }

  // MARK: - RawLocation Enum Type Tests

  func testRawLocationEnum() {
    // Test raw string values
    XCTAssertEqual(StorageLocation.RawLocations.secureEnclave.rawValue, "secureEnclave")
    XCTAssertEqual(StorageLocation.RawLocations.keychain.rawValue, "keychain")
    XCTAssertEqual(StorageLocation.RawLocations.memory.rawValue, "memory")

    // Test equality
    XCTAssertEqual(
      StorageLocation.RawLocations.secureEnclave,
      StorageLocation.RawLocations.secureEnclave
    )
    XCTAssertNotEqual(
      StorageLocation.RawLocations.secureEnclave,
      StorageLocation.RawLocations.keychain
    )
  }
}
