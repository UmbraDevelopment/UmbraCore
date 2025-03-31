import Foundation
import KeyManagementTypes
import XCTest

final class KeyMetadataTests: XCTestCase {
  // MARK: - Canonical Type Tests

  func testCanonicalKeyMetadataCreation() {
    let createdAt=Date()
    let expiryDate=Date(timeIntervalSinceNow: 86400 * 30) // 30 days

    let metadata=KeyManagementTypes.KeyMetadata(
      status: .active,
      storageLocation: .secureEnclave,
      accessControls: .requiresBiometric,
      createdAt: createdAt,
      lastModified: createdAt,
      expiryDate: expiryDate,
      algorithm: "AES-256-GCM",
      keySize: 256,
      identifier: "test-key-123",
      version: 1,
      exportable: false,
      isSystemKey: true,
      isProcessIsolated: true,
      customMetadata: ["purpose": "testing"]
    )

    // Test that all properties are set correctly
    XCTAssertEqual(metadata.status, .active)
    XCTAssertEqual(metadata.storageLocation, .secureEnclave)
    XCTAssertEqual(metadata.accessControls, .requiresBiometric)
    XCTAssertEqual(metadata.createdAt, createdAt)
    XCTAssertEqual(metadata.lastModified, createdAt)
    XCTAssertEqual(metadata.expiryDate, expiryDate)
    XCTAssertEqual(metadata.algorithm, "AES-256-GCM")
    XCTAssertEqual(metadata.keySize, 256)
    XCTAssertEqual(metadata.identifier, "test-key-123")
    XCTAssertEqual(metadata.version, 1)
    XCTAssertEqual(metadata.exportable, false)
    XCTAssertEqual(metadata.isSystemKey, true)
    XCTAssertEqual(metadata.isProcessIsolated, true)
    XCTAssertEqual(metadata.customMetadata?["purpose"], "testing")
  }

  func testCanonicalKeyMetadataWithTimestamps() {
    let createdTimestamp: Int64=1_627_084_800 // July 24, 2021 00:00:00 UTC
    let modifiedTimestamp: Int64=1_627_171_200 // July 25, 2021 00:00:00 UTC
    let expiryTimestamp: Int64=1_635_120_000 // October 24, 2021 00:00:00 UTC

    let metadata=KeyManagementTypes.KeyMetadata.withTimestamps(
      status: .active,
      storageLocation: .secureEnclave,
      accessControls: .requiresBiometric,
      createdAtTimestamp: createdTimestamp,
      lastModifiedTimestamp: modifiedTimestamp,
      expiryTimestamp: expiryTimestamp,
      algorithm: "AES-256-GCM",
      keySize: 256,
      identifier: "test-key-123",
      version: 1,
      exportable: false,
      isSystemKey: true,
      isProcessIsolated: true,
      customMetadata: ["purpose": "testing"]
    )

    // Test timestamp conversion
    XCTAssertEqual(metadata.createdAtTimestamp, createdTimestamp)
    XCTAssertEqual(metadata.lastModifiedTimestamp, modifiedTimestamp)
    XCTAssertEqual(metadata.expiryTimestamp, expiryTimestamp)

    // Test Date conversion
    XCTAssertEqual(metadata.createdAt.timeIntervalSince1970, Double(createdTimestamp))
    XCTAssertEqual(metadata.lastModified.timeIntervalSince1970, Double(modifiedTimestamp))
    XCTAssertEqual(metadata.expiryDate?.timeIntervalSince1970, Double(expiryTimestamp))
  }

  func testCanonicalKeyMetadataCodable() throws {
    let createdAt=Date()
    let metadata=KeyManagementTypes.KeyMetadata(
      status: .active,
      storageLocation: .secureEnclave,
      accessControls: .requiresBiometric,
      createdAt: createdAt,
      lastModified: createdAt,
      algorithm: "AES-256-GCM",
      keySize: 256,
      identifier: "test-key-123"
    )

    // Test encoding and decoding
    let encoder=JSONEncoder()
    let data=try encoder.encode(metadata)
    let decoder=JSONDecoder()
    let decodedMetadata=try decoder.decode(KeyManagementTypes.KeyMetadata.self, from: data)

    // Compare properties
    XCTAssertEqual(decodedMetadata.status, metadata.status)
    XCTAssertEqual(decodedMetadata.storageLocation, metadata.storageLocation)
    XCTAssertEqual(decodedMetadata.accessControls, metadata.accessControls)
    XCTAssertEqual(decodedMetadata.algorithm, metadata.algorithm)
    XCTAssertEqual(decodedMetadata.keySize, metadata.keySize)
    XCTAssertEqual(decodedMetadata.identifier, metadata.identifier)

    // Date comparison might have slight differences due to JSON serialisation precision
    XCTAssertEqual(
      Int(decodedMetadata.createdAt.timeIntervalSince1970),
      Int(metadata.createdAt.timeIntervalSince1970)
    )
  }

  func testSimplifiedMetadata() {
    let metadata=KeyManagementTypes.KeyMetadata(
      status: .active,
      storageLocation: .secureEnclave,
      accessControls: .requiresBiometric,
      algorithm: "AES-256-GCM",
      keySize: 256,
      identifier: "test-key-123",
      customMetadata: ["purpose": "testing"]
    )

    let simplified=metadata.simplified()

    // The simplified version should be identical except for customMetadata
    XCTAssertEqual(simplified.status, metadata.status)
    XCTAssertEqual(simplified.storageLocation, metadata.storageLocation)
    XCTAssertEqual(simplified.accessControls, metadata.accessControls)
    XCTAssertEqual(simplified.algorithm, metadata.algorithm)
    XCTAssertEqual(simplified.keySize, metadata.keySize)
    XCTAssertEqual(simplified.identifier, metadata.identifier)

    // Custom metadata should be nil in the simplified version
    XCTAssertNil(simplified.customMetadata)
  }

  func testIsExpired() {
    // Not expired (future date)
    let notExpired=KeyManagementTypes.KeyMetadata(
      status: .active,
      storageLocation: .secureEnclave,
      expiryDate: Date(timeIntervalSinceNow: 86400), // 1 day in future
      algorithm: "AES-256-GCM",
      keySize: 256,
      identifier: "test-key-123"
    )
    XCTAssertFalse(notExpired.isExpired())

    // Expired (past date)
    let expired=KeyManagementTypes.KeyMetadata(
      status: .active,
      storageLocation: .secureEnclave,
      expiryDate: Date(timeIntervalSinceNow: -86400), // 1 day in past
      algorithm: "AES-256-GCM",
      keySize: 256,
      identifier: "test-key-123"
    )
    XCTAssertTrue(expired.isExpired())

    // No expiry date
    let noExpiry=KeyManagementTypes.KeyMetadata(
      status: .active,
      storageLocation: .secureEnclave,
      algorithm: "AES-256-GCM",
      keySize: 256,
      identifier: "test-key-123"
    )
    XCTAssertFalse(noExpiry.isExpired())
  }

  func testWithStatus() {
    let original=KeyManagementTypes.KeyMetadata(
      status: .active,
      storageLocation: .secureEnclave,
      algorithm: "AES-256-GCM",
      keySize: 256,
      identifier: "test-key-123"
    )

    // Add small delay to ensure timestamps are different
    usleep(1000) // Sleep for 1 millisecond

    let updated=original.withStatus(.compromised)

    // Status should be updated
    XCTAssertEqual(updated.status, .compromised)

    // Other properties should remain the same
    XCTAssertEqual(updated.storageLocation, original.storageLocation)
    XCTAssertEqual(updated.algorithm, original.algorithm)
    XCTAssertEqual(updated.keySize, original.keySize)
    XCTAssertEqual(updated.identifier, original.identifier)

    // Last modified should be updated
    XCTAssertGreaterThan(updated.lastModified, original.lastModified)
  }

  // MARK: - Raw Metadata Conversion Tests

  func testRawMetadataConversion() {
    let createdAt=Date()
    let expiryDate=Date(timeIntervalSinceNow: 86400 * 30) // 30 days

    // Create original metadata
    let original=KeyManagementTypes.KeyMetadata(
      status: .active,
      storageLocation: .secureEnclave,
      accessControls: .requiresBiometric,
      createdAt: createdAt,
      lastModified: createdAt,
      expiryDate: expiryDate,
      algorithm: "AES-256-GCM",
      keySize: 256,
      identifier: "test-key-123",
      version: 1,
      exportable: false,
      isSystemKey: true,
      isProcessIsolated: true,
      customMetadata: ["purpose": "testing"]
    )

    // Convert to raw metadata
    let rawMetadata=original.toRawMetadata()

    // Test raw metadata values
    XCTAssertEqual(rawMetadata.status, KeyStatus.active.toRawStatus())
    XCTAssertEqual(rawMetadata.storageLocation, StorageLocation.secureEnclave.toRawLocation())
    XCTAssertEqual(rawMetadata.accessControls, .requiresBiometric)
    XCTAssertEqual(rawMetadata.createdAt, createdAt)
    XCTAssertEqual(rawMetadata.lastModified, createdAt)
    XCTAssertEqual(rawMetadata.expiryDate, expiryDate)
    XCTAssertEqual(rawMetadata.algorithm, "AES-256-GCM")
    XCTAssertEqual(rawMetadata.keySize, 256)
    XCTAssertEqual(rawMetadata.identifier, "test-key-123")
    XCTAssertEqual(rawMetadata.version, 1)
    XCTAssertEqual(rawMetadata.exportable, false)
    XCTAssertEqual(rawMetadata.isSystemKey, true)
    XCTAssertEqual(rawMetadata.isProcessIsolated, true)
    XCTAssertEqual(rawMetadata.customMetadata?["purpose"], "testing")

    // Convert back from raw metadata
    let converted=KeyManagementTypes.KeyMetadata.from(rawMetadata: rawMetadata)

    // Compare original and round-trip converted
    XCTAssertEqual(converted.status, original.status)
    XCTAssertEqual(converted.storageLocation, original.storageLocation)
    XCTAssertEqual(converted.accessControls, original.accessControls)
    XCTAssertEqual(
      Int(converted.createdAt.timeIntervalSince1970),
      Int(original.createdAt.timeIntervalSince1970)
    )
    XCTAssertEqual(
      Int(converted.lastModified.timeIntervalSince1970),
      Int(original.lastModified.timeIntervalSince1970)
    )
    XCTAssertEqual(
      Int(converted.expiryDate?.timeIntervalSince1970 ?? 0),
      Int(original.expiryDate?.timeIntervalSince1970 ?? 0)
    )
    XCTAssertEqual(converted.algorithm, original.algorithm)
    XCTAssertEqual(converted.keySize, original.keySize)
    XCTAssertEqual(converted.identifier, original.identifier)
    XCTAssertEqual(converted.version, original.version)
    XCTAssertEqual(converted.exportable, original.exportable)
    XCTAssertEqual(converted.isSystemKey, original.isSystemKey)
    XCTAssertEqual(converted.isProcessIsolated, original.isProcessIsolated)
    XCTAssertEqual(converted.customMetadata?["purpose"], original.customMetadata?["purpose"])
  }

  func testRawMetadataTimestampConversion() {
    let createdTimestamp: Int64=1_627_084_800 // July 24, 2021 00:00:00 UTC
    let modifiedTimestamp: Int64=1_627_171_200 // July 25, 2021 00:00:00 UTC
    let expiryTimestamp: Int64=1_635_120_000 // October 24, 2021 00:00:00 UTC

    // Create raw metadata with timestamps
    let rawMetadata=KeyMetadata.RawMetadata(
      status: .active,
      storageLocation: .secureEnclave,
      accessControls: .requiresBiometric,
      createdAtTimestamp: createdTimestamp,
      lastModifiedTimestamp: modifiedTimestamp,
      expiryTimestamp: expiryTimestamp,
      algorithm: "AES-256-GCM",
      keySize: 256,
      identifier: "test-key-123",
      version: 1,
      exportable: false,
      isSystemKey: true,
      isProcessIsolated: true,
      customMetadata: ["purpose": "testing"]
    )

    // Create KeyMetadata from raw metadata
    let metadata=KeyManagementTypes.KeyMetadata.from(rawMetadata: rawMetadata)

    // Test that timestamps were properly converted to Dates
    XCTAssertEqual(metadata.createdAtTimestamp, createdTimestamp)
    XCTAssertEqual(metadata.lastModifiedTimestamp, modifiedTimestamp)
    XCTAssertEqual(metadata.expiryTimestamp, expiryTimestamp)
    XCTAssertEqual(metadata.createdAt.timeIntervalSince1970, Double(createdTimestamp))
    XCTAssertEqual(metadata.lastModified.timeIntervalSince1970, Double(modifiedTimestamp))
    XCTAssertEqual(metadata.expiryDate?.timeIntervalSince1970, Double(expiryTimestamp))

    // Convert back to raw metadata and verify timestamps
    let convertedRaw=metadata.toRawMetadata()
    XCTAssertEqual(convertedRaw.createdAtTimestamp, createdTimestamp)
    XCTAssertEqual(convertedRaw.lastModifiedTimestamp, modifiedTimestamp)
    XCTAssertEqual(convertedRaw.expiryTimestamp, expiryTimestamp)
  }
}
