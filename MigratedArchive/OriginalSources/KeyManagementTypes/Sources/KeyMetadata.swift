import Foundation

/// Metadata about a cryptographic key
///
/// This is the canonical implementation of KeyMetadata used across the UmbraCore framework.
/// It provides a comprehensive set of properties to describe cryptographic keys and
/// supports conversion between Foundation and non-Foundation environments.
public struct KeyMetadata: Sendable, Codable {
  /// Current status of the key
  public var status: KeyStatus

  /// Storage location of the key
  public let storageLocation: StorageLocation

  /// Access control settings for the key
  public enum AccessControls: String, Sendable, Codable, Equatable, Hashable {
    /// No special access controls
    case none
    /// Requires user authentication
    case requiresAuthentication
    /// Requires biometric authentication
    case requiresBiometric
    /// Requires both user and biometric authentication
    case requiresBoth
  }

  /// Access controls applied to the key
  public let accessControls: AccessControls

  /// Creation date of the key
  public let createdAt: Date

  /// Last modification date of the key
  public var lastModified: Date

  /// Expiry date of the key (if applicable)
  public var expiryDate: Date?

  /// Key algorithm and parameters
  public let algorithm: String

  /// Key size in bits
  public let keySize: Int

  /// Unique identifier for the key
  public let identifier: String

  /// Version of the key, incremented on rotation
  public var version: Int

  /// Whether the key can be exported
  public let exportable: Bool

  /// Whether the key is a system key
  public let isSystemKey: Bool

  /// Whether the key is isolated to the current process
  public var isProcessIsolated: Bool

  /// Custom metadata associated with the key
  public var customMetadata: [String: String]?

  /// Create a new key metadata with all properties
  /// - Parameters:
  ///   - status: Current status of the key
  ///   - storageLocation: Where the key is stored
  ///   - accessControls: Access control settings
  ///   - createdAt: Creation date
  ///   - lastModified: Last modification date
  ///   - expiryDate: Optional expiry date for the key
  ///   - algorithm: Key algorithm
  ///   - keySize: Key size in bits
  ///   - identifier: Unique identifier for the key
  ///   - version: Version of the key
  ///   - exportable: Whether the key can be exported
  ///   - isSystemKey: Whether the key is a system key
  ///   - isProcessIsolated: Whether the key is isolated to the current process
  ///   - customMetadata: Additional metadata
  public init(
    status: KeyStatus = .active,
    storageLocation: StorageLocation,
    accessControls: AccessControls = .none,
    createdAt: Date=Date(),
    lastModified: Date=Date(),
    expiryDate: Date?=nil,
    algorithm: String,
    keySize: Int,
    identifier: String,
    version: Int=1,
    exportable: Bool=false,
    isSystemKey: Bool=false,
    isProcessIsolated: Bool=false,
    customMetadata: [String: String]?=nil
  ) {
    self.status=status
    self.storageLocation=storageLocation
    self.accessControls=accessControls
    self.createdAt=createdAt
    self.lastModified=lastModified
    self.expiryDate=expiryDate
    self.algorithm=algorithm
    self.keySize=keySize
    self.identifier=identifier
    self.version=version
    self.exportable=exportable
    self.isSystemKey=isSystemKey
    self.isProcessIsolated=isProcessIsolated
    self.customMetadata=customMetadata
  }

  // MARK: - Timestamp-based conversion methods

  /// Get the creation timestamp (seconds since 1970)
  public var createdAtTimestamp: Int64 {
    Int64(createdAt.timeIntervalSince1970)
  }

  /// Get the last modification timestamp (seconds since 1970)
  public var lastModifiedTimestamp: Int64 {
    Int64(lastModified.timeIntervalSince1970)
  }

  /// Get the expiry timestamp (seconds since 1970) if available
  public var expiryTimestamp: Int64? {
    expiryDate.map { Int64($0.timeIntervalSince1970) }
  }

  /// Create a KeyMetadata instance using timestamps instead of Date objects
  /// - Parameters:
  ///   - status: Current status of the key
  ///   - storageLocation: Where the key is stored
  ///   - accessControls: Access control settings
  ///   - createdAtTimestamp: Creation time as Unix timestamp
  ///   - lastModifiedTimestamp: Last modification time as Unix timestamp
  ///   - expiryTimestamp: Optional expiry time as Unix timestamp
  ///   - algorithm: Key algorithm
  ///   - keySize: Key size in bits
  ///   - identifier: Unique identifier for the key
  ///   - version: Version of the key
  ///   - exportable: Whether the key can be exported
  ///   - isSystemKey: Whether the key is a system key
  ///   - isProcessIsolated: Whether the key is isolated to the current process
  ///   - customMetadata: Additional metadata
  /// - Returns: A fully initialised KeyMetadata instance
  public static func withTimestamps(
    status: KeyStatus = .active,
    storageLocation: StorageLocation,
    accessControls: AccessControls = .none,
    createdAtTimestamp: Int64,
    lastModifiedTimestamp: Int64,
    expiryTimestamp: Int64?=nil,
    algorithm: String,
    keySize: Int,
    identifier: String,
    version: Int=1,
    exportable: Bool=false,
    isSystemKey: Bool=false,
    isProcessIsolated: Bool=false,
    customMetadata: [String: String]?=nil
  ) -> KeyMetadata {
    KeyMetadata(
      status: status,
      storageLocation: storageLocation,
      accessControls: accessControls,
      createdAt: Date(timeIntervalSince1970: TimeInterval(createdAtTimestamp)),
      lastModified: Date(timeIntervalSince1970: TimeInterval(lastModifiedTimestamp)),
      expiryDate: expiryTimestamp.map { Date(timeIntervalSince1970: TimeInterval($0)) },
      algorithm: algorithm,
      keySize: keySize,
      identifier: identifier,
      version: version,
      exportable: exportable,
      isSystemKey: isSystemKey,
      isProcessIsolated: isProcessIsolated,
      customMetadata: customMetadata
    )
  }

  // MARK: - Helper methods

  /// Create a simplified version of this metadata with only essential fields
  /// - Returns: A simplified KeyMetadata with minimal requirements
  public func simplified() -> KeyMetadata {
    var simplified=self
    simplified.customMetadata=nil
    return simplified
  }

  /// Check if the key has expired
  /// - Returns: True if the key has an expiry date that has passed
  public func isExpired() -> Bool {
    guard let expiryDate else {
      return false
    }
    return Date() > expiryDate
  }

  /// Create a copy of this metadata with updated status
  /// - Parameter newStatus: The new status to apply
  /// - Returns: An updated copy of the metadata
  public func withStatus(_ newStatus: KeyStatus) -> KeyMetadata {
    var updated=self
    updated.status=newStatus
    updated.lastModified=Date()
    return updated
  }
}

// MARK: - CoreServicesTypesNoFoundation Conversions

extension KeyMetadata {
  /// Convert to CoreServicesTypesNoFoundation.KeyMetadata
  /// - Returns: A dictionary representation that can be used to create a
  /// CoreServicesTypesNoFoundation.KeyMetadata
  public func toCoreServicesNoFoundation() -> [String: Any] {
    // This is a type-erased conversion to avoid direct import
    // The result can be used to create CoreServicesTypesNoFoundation.KeyMetadata
    var dict: [String: Any]=[
      "status": status.toCoreServicesNoFoundation(),
      "storageLocation": storageLocation.toCoreServicesNoFoundation(),
      "accessControls": accessControls.rawValue,
      "createdAtTimestamp": createdAtTimestamp,
      "lastModifiedTimestamp": lastModifiedTimestamp,
      "algorithm": algorithm,
      "keySize": keySize,
      "identifier": identifier,
      "version": version,
      "exportable": exportable,
      "isSystemKey": isSystemKey,
      "isProcessIsolated": isProcessIsolated
    ]

    if let expiryTimestamp {
      dict["expiryTimestamp"]=expiryTimestamp
    }

    if let customMetadata {
      dict["customMetadata"]=customMetadata
    }

    return dict
  }

  /// Create from CoreServicesTypesNoFoundation.KeyMetadata
  /// - Parameter coreServicesNoFoundation: The CoreServicesTypesNoFoundation.KeyMetadata to convert
  /// from
  /// - Returns: The equivalent canonical KeyMetadata
  public static func fromCoreServicesNoFoundation(_ dict: [String: Any]) -> KeyMetadata {
    // Extract required properties
    guard
      let statusAny=dict["status"],
      let storageLocationAny=dict["storageLocation"],
      let accessControlsRawValue=dict["accessControls"] as? String,
      let createdAtTimestamp=dict["createdAtTimestamp"] as? Int64,
      let lastModifiedTimestamp=dict["lastModifiedTimestamp"] as? Int64,
      let algorithm=dict["algorithm"] as? String,
      let keySize=dict["keySize"] as? Int,
      let identifier=dict["identifier"] as? String
    else {
      fatalError("Missing required properties in KeyMetadata conversion")
    }

    // Convert status and storage location
    let status=KeyStatus.fromCoreServicesNoFoundation(statusAny)
    let storageLocation=StorageLocation.fromCoreServicesNoFoundation(storageLocationAny)

    // Get access controls
    guard let accessControls=AccessControls(rawValue: accessControlsRawValue) else {
      fatalError("Invalid access controls value: \(accessControlsRawValue)")
    }

    // Get optional properties
    let version=dict["version"] as? Int ?? 1
    let exportable=dict["exportable"] as? Bool ?? false
    let isSystemKey=dict["isSystemKey"] as? Bool ?? false
    let isProcessIsolated=dict["isProcessIsolated"] as? Bool ?? false
    let expiryTimestamp=dict["expiryTimestamp"] as? Int64
    let customMetadata=dict["customMetadata"] as? [String: String]

    // Create the KeyMetadata
    return withTimestamps(
      status: status,
      storageLocation: storageLocation,
      accessControls: accessControls,
      createdAtTimestamp: createdAtTimestamp,
      lastModifiedTimestamp: lastModifiedTimestamp,
      expiryTimestamp: expiryTimestamp,
      algorithm: algorithm,
      keySize: keySize,
      identifier: identifier,
      version: version,
      exportable: exportable,
      isSystemKey: isSystemKey,
      isProcessIsolated: isProcessIsolated,
      customMetadata: customMetadata
    )
  }
}
