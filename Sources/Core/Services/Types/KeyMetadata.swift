import Foundation
import KeyManagementTypes

/// Metadata about a cryptographic key
///
/// - Important: This type is deprecated. Please use the canonical `KeyMetadata` instead.
///
/// The canonical implementation is available in the KeyManagementTypes module and provides
/// a standardised representation used across the UmbraCore framework.
///
/// - Note: To silence Swift 6 deprecation warnings, use `KeyMetadataLegacy` typealias instead of
///   referencing this type directly.
@available(*, deprecated, message: "Please use the canonical KeyMetadata instead")
public struct KeyMetadata: Sendable, Codable {
  /// Current status of the key
  public var status: KeyManagementTypes.KeyStatus

  /// Storage location of the key
  public let storageLocation: KeyManagementTypes.StorageLocation

  /// Access control settings for the key
  @available(
    *,
    deprecated,
    message: "Please use KeyManagementTypes.KeyMetadata.AccessControls instead"
  )
  public typealias AccessControls = KeyManagementTypes.KeyMetadata.AccessControls

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

  /// Version of the key
  public var version: Int

  /// Whether the key can be exported
  public var exportable: Bool

  /// Whether this is a system key
  public var isSystemKey: Bool

  /// Whether this key is process isolated
  public var isProcessIsolated: Bool

  /// Custom metadata for the key
  public var customMetadata: [String: String]?

  /// Create new key metadata
  /// - Parameters:
  ///   - status: Current status of the key
  ///   - storageLocation: Where the key is stored
  ///   - accessControls: Access control settings
  ///   - createdAt: Creation date
  ///   - lastModified: Last modification date
  ///   - expiryDate: Optional expiry date
  ///   - algorithm: Key algorithm
  ///   - keySize: Key size in bits
  ///   - identifier: Unique identifier
  ///   - version: Key version
  ///   - exportable: Whether the key can be exported
  ///   - isSystemKey: Whether this is a system key
  ///   - isProcessIsolated: Whether this key is process isolated
  ///   - customMetadata: Custom metadata for the key
  public init(
    status: KeyManagementTypes.KeyStatus = .active,
    storageLocation: KeyManagementTypes.StorageLocation,
    accessControls: AccessControls = .none,
    createdAt: Date = Date(),
    lastModified: Date = Date(),
    expiryDate: Date? = nil,
    algorithm: String,
    keySize: Int,
    identifier: String,
    version: Int = 1,
    exportable: Bool = false,
    isSystemKey: Bool = false,
    isProcessIsolated: Bool = false,
    customMetadata: [String: String]? = nil
  ) {
    self.status = status
    self.storageLocation = storageLocation
    self.accessControls = accessControls
    self.createdAt = createdAt
    self.lastModified = lastModified
    self.expiryDate = expiryDate
    self.algorithm = algorithm
    self.keySize = keySize
    self.identifier = identifier
    self.version = version
    self.exportable = exportable
    self.isSystemKey = isSystemKey
    self.isProcessIsolated = isProcessIsolated
    self.customMetadata = customMetadata
  }

  /// Create new key metadata with basic parameters
  /// - Parameters:
  ///   - storageLocation: Where the key is stored
  ///   - accessControls: Access control settings
  ///   - algorithm: Key algorithm
  ///   - keySize: Key size in bits
  ///   - expiryDate: Optional expiry date for the key
  public init(
    storageLocation: KeyManagementTypes.StorageLocation,
    accessControls: AccessControls = .none,
    algorithm: String,
    keySize: Int,
    expiryDate: Date? = nil
  ) {
    status = KeyManagementTypes.KeyStatus.active
    self.storageLocation = storageLocation
    self.accessControls = accessControls
    self.algorithm = algorithm
    self.keySize = keySize
    createdAt = Date()
    lastModified = Date()
    self.expiryDate = expiryDate
    identifier = UUID().uuidString
    version = 1
    exportable = false
    isSystemKey = false
    isProcessIsolated = false
    customMetadata = nil
  }

  /// Check if the key is expired
  /// - Returns: True if the key is expired
  public func isExpired() -> Bool {
    if let expiryDate {
      return expiryDate < Date()
    }
    return false
  }

  /// Create a new metadata with updated status
  /// - Parameter newStatus: The new status
  /// - Returns: Updated metadata
  public func withStatus(_ newStatus: KeyManagementTypes.KeyStatus) -> KeyMetadata {
    var updated = self
    updated.status = newStatus
    updated.lastModified = Date()
    return updated
  }
}

// MARK: - Raw Conversion Extension (for KeyManagementTypes)

/// Extension to provide conversion to/from the raw representation
/// This will be used by the KeyManagementTypes module through type extension
extension KeyManagementTypes.KeyMetadata {
  /// Raw representation that matches the canonical type's raw metadata
  public struct RawRepresentation: Sendable {
    public var status: KeyManagementTypes.KeyStatus
    public let storageLocation: KeyManagementTypes.StorageLocation
    public let accessControls: KeyManagementTypes.KeyMetadata.AccessControls
    public let createdAt: Date
    public var lastModified: Date
    public var expiryDate: Date?
    public let algorithm: String
    public let keySize: Int
    public let identifier: String
    public var version: Int
    public var exportable: Bool
    public var isSystemKey: Bool
    public var isProcessIsolated: Bool
    public var customMetadata: [String: String]?

    /// Initialise a new KeyMetadata.RawRepresentation
    /// - Parameters:
    ///   - status: Status of the key
    ///   - storageLocation: Storage location
    ///   - accessControls: Access control settings
    ///   - createdAt: Creation date
    ///   - lastModified: Last modification date
    ///   - expiryDate: Expiry date
    ///   - algorithm: Key algorithm
    ///   - keySize: Key size in bits
    ///   - identifier: Unique identifier
    ///   - version: Key version
    public init(
      status: KeyManagementTypes.KeyStatus = .active,
      storageLocation: KeyManagementTypes.StorageLocation,
      accessControls: KeyManagementTypes.KeyMetadata.AccessControls = .none,
      createdAt: Date = Date(),
      lastModified: Date = Date(),
      expiryDate: Date? = nil,
      algorithm: String = "AES-GCM",
      keySize: Int = 256,
      identifier: String = UUID().uuidString,
      version: Int = 1,
      exportable: Bool = false,
      isSystemKey: Bool = false,
      isProcessIsolated: Bool = false,
      customMetadata: [String: String]? = nil
    ) {
      self.status = status
      self.storageLocation = storageLocation
      self.accessControls = accessControls
      self.createdAt = createdAt
      self.lastModified = lastModified
      self.expiryDate = expiryDate
      self.algorithm = algorithm
      self.keySize = keySize
      self.identifier = identifier
      self.version = version
      self.exportable = exportable
      self.isSystemKey = isSystemKey
      self.isProcessIsolated = isProcessIsolated
      self.customMetadata = customMetadata
    }

    public init(
      status: KeyManagementTypes.KeyStatus = .active,
      storageLocation: KeyManagementTypes.StorageLocation,
      accessControls: KeyManagementTypes.KeyMetadata.AccessControls = .none,
      createdAtTimestamp: Int64,
      lastModifiedTimestamp: Int64,
      expiryTimestamp: Int64? = nil,
      algorithm: String,
      keySize: Int,
      identifier: String,
      version: Int = 1,
      exportable: Bool = false,
      isSystemKey: Bool = false,
      isProcessIsolated: Bool = false,
      customMetadata: [String: String]? = nil
    ) {
      self.status = status
      self.storageLocation = storageLocation
      self.accessControls = accessControls
      createdAt = Date(timeIntervalSince1970: TimeInterval(createdAtTimestamp))
      lastModified = Date(timeIntervalSince1970: TimeInterval(lastModifiedTimestamp))
      if let expiryTimestamp {
        expiryDate = Date(timeIntervalSince1970: TimeInterval(expiryTimestamp))
      } else {
        expiryDate = nil
      }
      self.algorithm = algorithm
      self.keySize = keySize
      self.identifier = identifier
      self.version = version
      self.exportable = exportable
      self.isSystemKey = isSystemKey
      self.isProcessIsolated = isProcessIsolated
      self.customMetadata = customMetadata
    }
  }

  /// Convert to the canonical raw representation
  /// - Returns: RawRepresentation that can be used with KeyManagementTypes
  public func toRawRepresentation() -> RawRepresentation {
    RawRepresentation(
      status: status,
      storageLocation: storageLocation,
      accessControls: accessControls,
      createdAt: createdAt,
      lastModified: lastModified,
      expiryDate: expiryDate,
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

  /// Create from the canonical raw representation
  /// - Parameter rawRepresentation: Raw representation from KeyManagementTypes
  /// - Returns: Canonical KeyMetadata
  public static func from(rawRepresentation: RawRepresentation) -> KeyManagementTypes.KeyMetadata {
    KeyManagementTypes.KeyMetadata(
      status: rawRepresentation.status,
      storageLocation: rawRepresentation.storageLocation,
      accessControls: rawRepresentation.accessControls,
      createdAt: rawRepresentation.createdAt,
      lastModified: rawRepresentation.lastModified,
      expiryDate: rawRepresentation.expiryDate,
      algorithm: rawRepresentation.algorithm,
      keySize: rawRepresentation.keySize,
      identifier: rawRepresentation.identifier,
      version: rawRepresentation.version,
      exportable: rawRepresentation.exportable,
      isSystemKey: rawRepresentation.isSystemKey,
      isProcessIsolated: rawRepresentation.isProcessIsolated,
      customMetadata: rawRepresentation.customMetadata
    )
  }
}

/// Extension to provide conversion to/from the raw representation
/// This will be used by KeyManagementTypes module through type extension
extension KeyManagementTypes.KeyStatus {
  /// The raw representation that matches the canonical type's raw status
  public func toRawRepresentation() -> KeyManagementTypes.KeyStatus {
    self
  }

  /// Create from the canonical raw representation
  /// - Parameter rawRepresentation: Raw representation from KeyManagementTypes
  /// - Returns: Canonical KeyStatus
  public static func from(rawRepresentation: KeyManagementTypes.KeyStatus) -> KeyManagementTypes
  .KeyStatus {
    rawRepresentation
  }
}

/// Extension to provide conversion to/from the raw representation
/// This will be used by KeyManagementTypes module through type extension
extension KeyManagementTypes.StorageLocation {
  /// Create from the canonical raw representation
  /// - Parameter rawRepresentation: Raw representation from KeyManagementTypes
  /// - Returns: Canonical StorageLocation
  public static func from(
    rawRepresentation: KeyManagementTypes
      .StorageLocation
  ) -> KeyManagementTypes.StorageLocation {
    rawRepresentation
  }
}
